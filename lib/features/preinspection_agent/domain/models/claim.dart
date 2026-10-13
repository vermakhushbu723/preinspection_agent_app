/// One pre-inspection on the Dashboard (a card), from
/// `GET /field/inspections`. Field names keep the web app's claim shape so
/// the shared card widgets stay unchanged.
class Claim {
  const Claim({
    required this.id,
    required this.insurerName,
    required this.claimNumber,
    required this.registrationNumber,
    required this.insuredName,
    required this.status,
    required this.vehicle,
    required this.surveyDate,
    required this.location,
    required this.amount,
    this.inspectionStatus = '',
    this.workflow,
    this.canSubmitRepair = false,
    this.reviewRemarks,
  });

  factory Claim.fromJson(Map<String, dynamic> j) => Claim(
    id: j['id'] as String,
    insurerName: (j['insurerName'] ?? '') as String,
    claimNumber: (j['piRef'] ?? j['id']) as String,
    registrationNumber: (j['registrationNumber'] ?? '') as String,
    insuredName: (j['insuredName'] ?? '') as String,
    status: (j['status'] ?? 'Pending') as String,
    vehicle: (j['vehicle'] ?? '') as String,
    surveyDate: (j['surveyDate'] ?? '') as String,
    location: (j['location'] ?? '') as String,
    amount: (j['amount'] ?? '') as String,
    inspectionStatus: (j['inspectionStatus'] ?? '') as String,
    workflow: j['workflow'] as String?,
    canSubmitRepair: j['canSubmitRepair'] == true,
    reviewRemarks: j['reviewRemarks'] as String?,
  );

  final String id;
  final String insurerName;

  /// The PI Ref. Number (e.g. PI-100001).
  final String claimNumber;
  final String registrationNumber;
  final String insuredName;
  final String status; // 'Pending' | 'Completed'
  final String vehicle;
  final String surveyDate;
  final String location;
  final String amount;

  /// Server status: Assigned | Draft | Submitted | Approved | Rejected.
  final String inspectionStatus;

  /// 'damage' | 'others' once chosen on the photo capture screen.
  final String? workflow;

  /// A submitted damage survey still waiting for repair & reinspection photos.
  final bool canSubmitRepair;
  final String? reviewRemarks;
}
