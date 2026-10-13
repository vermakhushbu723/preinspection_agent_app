import 'dart:typed_data';

import '../domain/models/owner_vehicle_details.dart';
import '../domain/workflow_option.dart';

/// Upload state of one file (keyed `kind/slot`, e.g. `photo/front-side`).
enum UploadStatus { uploading, done, failed }

class UploadInfo {
  const UploadInfo({
    required this.kind,
    required this.slot,
    required this.path,
    required this.status,
    this.mediaId,
    this.error,
    this.latitude,
    this.longitude,
    this.capturedAt,
  });

  final String kind;
  final String slot;
  final String path;
  final UploadStatus status;

  /// Server id once uploaded (needed to delete it again).
  final String? mediaId;
  final String? error;
  final double? latitude;
  final double? longitude;
  final DateTime? capturedAt;

  UploadInfo copyWith({UploadStatus? status, String? mediaId, String? error}) =>
      UploadInfo(
        kind: kind,
        slot: slot,
        path: path,
        status: status ?? this.status,
        mediaId: mediaId ?? this.mediaId,
        error: error,
        latitude: latitude,
        longitude: longitude,
        capturedAt: capturedAt,
      );
}

/// Single in-memory session state for the whole PreinspectionAgent flow.
///
/// Files are kept on the device (paths here) and uploaded to the backend as
/// they are captured -- see [uploads] and `ClaimFlowNotifier`.
class ClaimFlowState {
  const ClaimFlowState({
    this.inspectionId,
    this.inspectionStatus,
    this.reopenedSubmitted = false,
    this.ownerVehicleDetails = OwnerVehicleDetails.empty,
    this.workflowOption,
    this.photos = const {},
    this.walkAroundVideoPath,
    this.documentUploads = const {},
    this.customerDeclarationAccepted = false,
    this.inspectorDeclarationAccepted = false,
    this.customerSignature,
    this.inspectorSignature,
    this.surveyRecommendation,
    this.reinspectionPhotos = const [],
    this.repairBillPath,
    this.uploads = const {},
  });

  /// Server id = PI Ref. Number (e.g. PI-100001); null until the owner form is saved
  /// (or the agent opened an assigned case).
  final String? inspectionId;

  /// Assigned | Draft | Submitted | Approved | Rejected.
  final String? inspectionStatus;

  /// Opened an already-submitted damage survey from the dashboard (Submitted
  /// screen then offers the repair & reinspection photos).
  final bool reopenedSubmitted;

  final OwnerVehicleDetails ownerVehicleDetails;
  final WorkflowOption? workflowOption;

  /// Capture key (e.g. `front-side`, `additional-damage-1`) -> saved file path.
  final Map<String, String> photos;
  final String? walkAroundVideoPath;

  /// Document type id -> list of saved file paths.
  final Map<String, List<String>> documentUploads;

  final bool customerDeclarationAccepted;
  final bool inspectorDeclarationAccepted;
  final Uint8List? customerSignature;
  final Uint8List? inspectorSignature;

  /// 'Approved' | 'Rejected' | null (not chosen yet).
  final String? surveyRecommendation;

  final List<String> reinspectionPhotos;
  final String? repairBillPath;

  /// `kind/slot` -> upload state of every file sent to the server.
  final Map<String, UploadInfo> uploads;

  bool get bothSignaturesPresent =>
      customerSignature != null && inspectorSignature != null;

  int get pendingUploads =>
      uploads.values.where((u) => u.status != UploadStatus.done).length;
  int get failedUploads =>
      uploads.values.where((u) => u.status == UploadStatus.failed).length;

  ClaimFlowState copyWith({
    String? inspectionId,
    String? inspectionStatus,
    bool? reopenedSubmitted,
    OwnerVehicleDetails? ownerVehicleDetails,
    WorkflowOption? workflowOption,
    Map<String, String>? photos,
    String? walkAroundVideoPath,
    bool clearWalkAroundVideo = false,
    Map<String, List<String>>? documentUploads,
    bool? customerDeclarationAccepted,
    bool? inspectorDeclarationAccepted,
    Uint8List? customerSignature,
    bool clearCustomerSignature = false,
    Uint8List? inspectorSignature,
    bool clearInspectorSignature = false,
    String? surveyRecommendation,
    List<String>? reinspectionPhotos,
    String? repairBillPath,
    Map<String, UploadInfo>? uploads,
  }) {
    return ClaimFlowState(
      inspectionId: inspectionId ?? this.inspectionId,
      inspectionStatus: inspectionStatus ?? this.inspectionStatus,
      reopenedSubmitted: reopenedSubmitted ?? this.reopenedSubmitted,
      ownerVehicleDetails: ownerVehicleDetails ?? this.ownerVehicleDetails,
      workflowOption: workflowOption ?? this.workflowOption,
      photos: photos ?? this.photos,
      walkAroundVideoPath: clearWalkAroundVideo
          ? null
          : (walkAroundVideoPath ?? this.walkAroundVideoPath),
      documentUploads: documentUploads ?? this.documentUploads,
      customerDeclarationAccepted:
          customerDeclarationAccepted ?? this.customerDeclarationAccepted,
      inspectorDeclarationAccepted:
          inspectorDeclarationAccepted ?? this.inspectorDeclarationAccepted,
      customerSignature: clearCustomerSignature
          ? null
          : (customerSignature ?? this.customerSignature),
      inspectorSignature: clearInspectorSignature
          ? null
          : (inspectorSignature ?? this.inspectorSignature),
      surveyRecommendation: surveyRecommendation ?? this.surveyRecommendation,
      reinspectionPhotos: reinspectionPhotos ?? this.reinspectionPhotos,
      repairBillPath: repairBillPath ?? this.repairBillPath,
      uploads: uploads ?? this.uploads,
    );
  }
}
