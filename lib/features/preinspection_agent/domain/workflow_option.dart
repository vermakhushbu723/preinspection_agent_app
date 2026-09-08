/// The two branches the flow can take after PhotoCaptureSelection. Port of
/// `WORKFLOW_TYPES` in `src/store/workflowSlice.js`.
///
/// - [group1]: AddDamagePhotos -> DamageReview -> Submitted ->
///   ReinspectionPhotos -> RepairSubmission (loops back to Dashboard).
/// - [group2]: AddOthersPhotos -> VehicleInformation -> declarations ->
///   Submitted.
enum WorkflowOption { group1, group2 }
