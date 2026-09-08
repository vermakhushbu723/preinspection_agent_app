import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/owner_vehicle_details.dart';
import '../domain/workflow_option.dart';
import 'claim_flow_state.dart';

const _workflowOptionPrefKey = 'preinspection_agent.workflow_option';
const _surveySubmittedPrefKey = 'preinspection_agent.survey_submitted';

/// Owns the PreinspectionAgent session state. Port of the combined behavior of
/// `vehicleSlice.js` + `workflowSlice.js` (Redux) and the sessionStorage /
/// localStorage reads scattered across the flow's pages.
class ClaimFlowNotifier extends StateNotifier<ClaimFlowState> {
  ClaimFlowNotifier() : super(const ClaimFlowState()) {
    _restoreWorkflowOption();
  }

  Future<void> _restoreWorkflowOption() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_workflowOptionPrefKey);
    if (saved == WorkflowOption.group1.name) {
      state = state.copyWith(workflowOption: WorkflowOption.group1);
    } else if (saved == WorkflowOption.group2.name) {
      state = state.copyWith(workflowOption: WorkflowOption.group2);
    }
  }

  void setOwnerVehicleDetails(OwnerVehicleDetails details) {
    state = state.copyWith(ownerVehicleDetails: details);
  }

  Future<void> setWorkflowOption(WorkflowOption option) async {
    state = state.copyWith(workflowOption: option);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_workflowOptionPrefKey, option.name);
  }

  void setPhoto(String key, String filePath) {
    state = state.copyWith(photos: {...state.photos, key: filePath});
  }

  void removePhoto(String key) {
    final next = {...state.photos}..remove(key);
    state = state.copyWith(photos: next);
  }

  void clearPhotos() {
    state = state.copyWith(photos: const {});
  }

  void setWalkAroundVideo(String path) {
    state = state.copyWith(walkAroundVideoPath: path);
  }

  void clearWalkAroundVideo() {
    state = state.copyWith(clearWalkAroundVideo: true);
  }

  void addDocumentUpload(String docId, String filePath) {
    final current = List<String>.from(state.documentUploads[docId] ?? []);
    current.add(filePath);
    state = state.copyWith(
      documentUploads: {...state.documentUploads, docId: current},
    );
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

  void addReinspectionPhoto(String filePath) {
    state = state.copyWith(
      reinspectionPhotos: [...state.reinspectionPhotos, filePath],
    );
  }

  void setRepairBillPath(String path) {
    state = state.copyWith(repairBillPath: path);
  }

  /// Clears the declaration + signature state so VehicleInformationPage
  /// starts fresh next time (mirrors the web app clearing
  /// `decl_customer/decl_inspector/sign_customer/sign_inspector` on submit).
  void clearDeclarationsAndSignatures() {
    state = state.copyWith(
      customerDeclarationAccepted: false,
      inspectorDeclarationAccepted: false,
      clearCustomerSignature: true,
      clearInspectorSignature: true,
    );
  }

  /// Records that this survey has been submitted, and reports whether it had
  /// *already* been submitted before this call.
  ///
  /// Drives the two faces of the Submitted screen: a plain "SUBMITTED"
  /// confirmation the first time, and the "this survey already has -- do you
  /// want to submit repair & reinspection photos?" prompt when a submitted
  /// case is opened again. Deliberately survives [resetSession], which only
  /// clears the in-flight claim.
  Future<bool> markSurveySubmitted() async {
    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getBool(_surveySubmittedPrefKey) ?? false;
    if (!already) await prefs.setBool(_surveySubmittedPrefKey, true);
    return already;
  }

  /// Wipes the whole session (mirrors `localStorage.clear()` on the
  /// terminal RepairSubmissionPage / ReinspectionPhotosPage screens) so the
  /// next claim starts from a clean slate.
  Future<void> resetSession() async {
    state = const ClaimFlowState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_workflowOptionPrefKey);
  }
}

final claimFlowProvider =
    StateNotifierProvider<ClaimFlowNotifier, ClaimFlowState>(
      (ref) => ClaimFlowNotifier(),
    );
