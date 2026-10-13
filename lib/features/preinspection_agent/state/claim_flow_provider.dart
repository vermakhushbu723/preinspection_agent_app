import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/api_client.dart';
import '../data/preinspection_api.dart';
import '../domain/models/claim.dart';
import '../domain/models/owner_vehicle_details.dart';
import '../domain/workflow_option.dart';
import 'claim_flow_state.dart';

const _workflowOptionPrefKey = 'preinspection_agent.workflow_option';

/// Workflow option <-> the server's `workflow` value.
String workflowApiValue(WorkflowOption o) =>
    o == WorkflowOption.group1 ? 'damage' : 'others';
WorkflowOption? workflowFromApi(String? v) => switch (v) {
  'damage' => WorkflowOption.group1,
  'others' => WorkflowOption.group2,
  _ => null,
};

/// Owns the PreinspectionAgent session state and keeps it in sync with the
/// backend (admin-service): the owner & vehicle form and every choice are
/// saved to the server, each captured file is uploaded right away in the
/// background (see [ClaimFlowState.uploads]), and the submit actions first
/// make sure every upload went through.
class ClaimFlowNotifier extends StateNotifier<ClaimFlowState> {
  ClaimFlowNotifier(this._api) : super(const ClaimFlowState()) {
    _restoreWorkflowOption();
  }

  final PreinspectionApi _api;

  /// In-flight uploads by `kind/slot`.
  final Map<String, Future<void>> _inflight = {};

  Future<void> _restoreWorkflowOption() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_workflowOptionPrefKey);
    if (saved == WorkflowOption.group1.name) {
      state = state.copyWith(workflowOption: WorkflowOption.group1);
    } else if (saved == WorkflowOption.group2.name) {
      state = state.copyWith(workflowOption: WorkflowOption.group2);
    }
  }

  String _requireId() {
    final id = state.inspectionId;
    if (id == null) {
      throw const ApiException('Fill in the owner & vehicle details first.');
    }
    return id;
  }

  // ---------- opening a case ----------

  /// Dashboard: opens a pre-inspection from the server (an assigned case or
  /// one already started). Files already uploaded stay on the server; the
  /// form comes back prefilled.
  Future<void> openInspection(Claim claim) async {
    final data = await _api.getInspection(claim.id);
    final details =
        (data['details'] as Map?)?.cast<String, dynamic>() ?? const {};
    await resetSession();
    final uploads = <String, UploadInfo>{
      for (final m
          in (data['media'] as List? ?? const []).cast<Map<String, dynamic>>())
        '${m['kind']}/${m['slot']}': UploadInfo(
          kind: m['kind'] as String,
          slot: m['slot'] as String,
          path: '',
          status: UploadStatus.done,
          mediaId: m['id'] as String,
        ),
    };
    final workflow = workflowFromApi(data['workflow'] as String?);
    state = state.copyWith(
      inspectionId: claim.id,
      inspectionStatus: data['inspectionStatus'] as String?,
      reopenedSubmitted: claim.canSubmitRepair,
      ownerVehicleDetails: OwnerVehicleDetails.fromJson(details),
      workflowOption: workflow,
      uploads: uploads,
    );
  }

  /// Owner & Vehicle Details "Next": saves the form on the server (starts the
  /// pre-inspection the first time). Throws ApiException with the reason.
  Future<void> saveOwnerVehicleDetails(OwnerVehicleDetails details) async {
    final id = state.inspectionId;
    final data = id == null
        ? await _api.createInspection(details)
        : await _api.updateInspection(id, PreinspectionApi.ownerJson(details));
    state = state.copyWith(
      inspectionId: data['id'] as String,
      inspectionStatus: data['inspectionStatus'] as String?,
      ownerVehicleDetails: details,
    );
  }

  void setOwnerVehicleDetails(OwnerVehicleDetails details) {
    state = state.copyWith(ownerVehicleDetails: details);
  }

  /// Photo capture "Continue": which branch the survey takes (saved on the server).
  Future<void> setWorkflowOption(WorkflowOption option) async {
    state = state.copyWith(workflowOption: option);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_workflowOptionPrefKey, option.name);
    final id = state.inspectionId;
    if (id != null) {
      await _api.updateInspection(id, {'workflow': workflowApiValue(option)});
    }
  }

  // ---------- files ----------

  void _setUpload(String key, UploadInfo info) {
    state = state.copyWith(uploads: {...state.uploads, key: info});
  }

  /// Saves the file locally (already done by the caller) and uploads it into
  /// `kind/slot` in the background. Re-capturing a slot replaces it on the server.
  void _queueUpload(
    String kind,
    String slot,
    String path, {
    double? latitude,
    double? longitude,
    DateTime? capturedAt,
  }) {
    final key = '$kind/$slot';
    _setUpload(
      key,
      UploadInfo(
        kind: kind,
        slot: slot,
        path: path,
        status: UploadStatus.uploading,
        mediaId: state.uploads[key]?.mediaId,
        latitude: latitude,
        longitude: longitude,
        capturedAt: capturedAt ?? DateTime.now(),
      ),
    );
    _inflight[key] = _runUpload(key);
  }

  Future<void> _runUpload(String key) async {
    final info = state.uploads[key];
    final id = state.inspectionId;
    if (info == null || info.path.isEmpty) return;
    if (id == null) {
      _setUpload(
        key,
        info.copyWith(
          status: UploadStatus.failed,
          error: 'Fill in the owner & vehicle details first.',
        ),
      );
      return;
    }
    try {
      final media = await _api.uploadFile(
        id,
        info.kind,
        info.slot,
        info.path,
        latitude: info.latitude,
        longitude: info.longitude,
        capturedAt: info.capturedAt,
      );
      // Only mark done if the slot still holds this file (not re-captured meanwhile).
      if (state.uploads[key]?.path == info.path) {
        _setUpload(
          key,
          info.copyWith(status: UploadStatus.done, mediaId: media.id),
        );
      }
    } catch (e) {
      // ApiException (network / server) or a file that can no longer be read.
      if (state.uploads[key]?.path == info.path) {
        _setUpload(
          key,
          info.copyWith(
            status: UploadStatus.failed,
            error: e is ApiException ? e.message : 'Could not read the file',
          ),
        );
      }
    } finally {
      _inflight.remove(key);
    }
  }

  /// Waits for running uploads and retries failed ones. Throws if any file
  /// still could not be uploaded (offline etc.).
  Future<void> syncUploads() async {
    await Future.wait(_inflight.values.toList());
    for (final entry in state.uploads.entries.toList()) {
      if (entry.value.status != UploadStatus.done &&
          entry.value.path.isNotEmpty) {
        _setUpload(
          entry.key,
          entry.value.copyWith(status: UploadStatus.uploading),
        );
        _inflight[entry.key] = _runUpload(entry.key);
      }
    }
    await Future.wait(_inflight.values.toList());
    final failed = state.uploads.values
        .where((u) => u.status == UploadStatus.failed)
        .toList();
    if (failed.isNotEmpty) {
      throw ApiException(
        '${failed.length} file(s) could not be uploaded: ${failed.first.error ?? 'network error'}. Check your connection and try again.',
      );
    }
  }

  Future<void> _deleteRemote(String key) async {
    final info = state.uploads[key];
    final next = {...state.uploads}..remove(key);
    state = state.copyWith(uploads: next);
    final id = state.inspectionId;
    final pending = _inflight[key];
    if (pending != null) await pending;
    final mediaId = info?.mediaId;
    if (id != null && mediaId != null) {
      try {
        await _api.deleteMedia(id, mediaId);
      } catch (_) {
        // Best effort: an extra photo left on the server is harmless.
      }
    }
  }

  void setPhoto(
    String key,
    String filePath, {
    double? latitude,
    double? longitude,
  }) {
    state = state.copyWith(photos: {...state.photos, key: filePath});
    _queueUpload(
      'photo',
      key,
      filePath,
      latitude: latitude,
      longitude: longitude,
    );
  }

  void removePhoto(String key) {
    final next = {...state.photos}..remove(key);
    state = state.copyWith(photos: next);
    _deleteRemote('photo/$key');
  }

  /// Damage Review "Restart": drops every captured photo (here and on the server).
  void clearPhotos() {
    final keys = state.photos.keys.toList();
    state = state.copyWith(photos: const {});
    for (final k in keys) {
      _deleteRemote('photo/$k');
    }
  }

  void setWalkAroundVideo(String path, {double? latitude, double? longitude}) {
    state = state.copyWith(walkAroundVideoPath: path);
    _queueUpload(
      'video',
      'walkaround',
      path,
      latitude: latitude,
      longitude: longitude,
    );
  }

  void clearWalkAroundVideo() {
    state = state.copyWith(clearWalkAroundVideo: true);
    _deleteRemote('video/walkaround');
  }

  /// One document image; [slot] names it on the server (e.g. `rc_front`, `others_2`).
  void addDocumentUpload(
    String docId,
    String filePath, {
    required String slot,
  }) {
    final current = List<String>.from(state.documentUploads[docId] ?? []);
    current.add(filePath);
    state = state.copyWith(
      documentUploads: {...state.documentUploads, docId: current},
    );
    _queueUpload('document', slot, filePath);
  }

  void setCustomerDeclarationAccepted(bool accepted) {
    state = state.copyWith(customerDeclarationAccepted: accepted);
  }

  void setInspectorDeclarationAccepted(bool accepted) {
    state = state.copyWith(inspectorDeclarationAccepted: accepted);
  }

  void setCustomerSignature(Uint8List? bytes) {
    state = bytes == null
        ? state.copyWith(clearCustomerSignature: true)
        : state.copyWith(customerSignature: bytes);
  }

  void setInspectorSignature(Uint8List? bytes) {
    state = bytes == null
        ? state.copyWith(clearInspectorSignature: true)
        : state.copyWith(inspectorSignature: bytes);
  }

  void setSurveyRecommendation(String recommendation) {
    state = state.copyWith(surveyRecommendation: recommendation);
  }

  /// Repair & reinspection (after a submitted damage survey): `reinspection/<slot>` or `repair/<slot>`.
  void uploadAfterSurvey(String kind, String slot, String filePath) {
    _queueUpload(kind, slot, filePath);
  }

  void addReinspectionPhoto(String filePath) {
    state = state.copyWith(
      reinspectionPhotos: [...state.reinspectionPhotos, filePath],
    );
    _queueUpload(
      'reinspection',
      'extra-${DateTime.now().millisecondsSinceEpoch}',
      filePath,
    );
  }

  void setRepairBillPath(String path) {
    state = state.copyWith(repairBillPath: path);
    _queueUpload('repair', 'bill', path);
  }

  // ---------- submit ----------

  /// Damage Review / Vehicle Information "Submit": uploads whatever is still
  /// pending, then submits. For the "others" branch also sends both
  /// signatures, the declarations and the recommendation ('Approved' | 'Rejected').
  Future<void> submitSurvey({String? recommendation}) async {
    final id = _requireId();
    await syncUploads();
    if (state.workflowOption == WorkflowOption.group2) {
      final customer = state.customerSignature;
      final inspector = state.inspectorSignature;
      if (customer != null) {
        await _api.uploadPng(id, 'signature', 'customer', customer);
      }
      if (inspector != null) {
        await _api.uploadPng(id, 'signature', 'inspector', inspector);
      }
      await _api.updateInspection(id, {
        'customerDeclaration': state.customerDeclarationAccepted,
        'inspectorDeclaration': state.inspectorDeclarationAccepted,
        'agentRecommendation': ?recommendation,
      });
    }
    final data = await _api.submit(id);
    state = state.copyWith(
      inspectionStatus: data['inspectionStatus'] as String?,
      reopenedSubmitted: false,
    );
  }

  /// Repair Submission "Submit": uploads the repair / reinspection files, then submits them.
  Future<void> submitRepair() async {
    final id = _requireId();
    await syncUploads();
    await _api.submitRepair(id);
  }

  /// Clears the declaration + signature state so VehicleInformationPage
  /// starts fresh next time.
  void clearDeclarationsAndSignatures() {
    state = state.copyWith(
      customerDeclarationAccepted: false,
      inspectorDeclarationAccepted: false,
      clearCustomerSignature: true,
      clearInspectorSignature: true,
    );
  }

  /// Wipes the whole session so the next pre-inspection starts from a clean slate.
  Future<void> resetSession() async {
    await Future.wait(_inflight.values.toList());
    state = const ClaimFlowState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_workflowOptionPrefKey);
  }
}

final claimFlowProvider =
    StateNotifierProvider<ClaimFlowNotifier, ClaimFlowState>(
      (ref) => ClaimFlowNotifier(ref.watch(preinspectionApiProvider)),
    );
