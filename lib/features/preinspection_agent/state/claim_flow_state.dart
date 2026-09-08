import 'dart:typed_data';

import '../domain/models/owner_vehicle_details.dart';
import '../domain/workflow_option.dart';

/// Single in-memory session state for the whole PreinspectionAgent flow.
///
/// This is the Flutter replacement for the web app's mix of
/// `sessionStorage` (owner/vehicle form, declarations, signatures),
/// `localStorage` (`damage_photos`, `walk_around_video_url`), and the two
/// Redux slices (`vehicleSlice`, `workflowSlice`) — kept here as one
/// Riverpod-managed object instead of scattered browser storage keys.
class ClaimFlowState {
  const ClaimFlowState({
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
  });

  final OwnerVehicleDetails ownerVehicleDetails;
  final WorkflowOption? workflowOption;

  /// Capture key (e.g. `front-side`, `additional-damage-1`) -> saved file
  /// path.
  final Map<String, String> photos;
  final String? walkAroundVideoPath;

  /// Document type id -> list of saved file paths (some doc types allow
  /// multiple photos, e.g. front+back or the "Other" bucket).
  final Map<String, List<String>> documentUploads;

  final bool customerDeclarationAccepted;
  final bool inspectorDeclarationAccepted;
  final Uint8List? customerSignature;
  final Uint8List? inspectorSignature;

  /// 'Approved' | 'Rejected' | null (not chosen yet).
  final String? surveyRecommendation;

  final List<String> reinspectionPhotos;
  final String? repairBillPath;

  bool get bothSignaturesPresent =>
      customerSignature != null && inspectorSignature != null;

  ClaimFlowState copyWith({
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
  }) {
    return ClaimFlowState(
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
    );
  }
}
