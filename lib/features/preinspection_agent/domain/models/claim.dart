/// Mock claim record shown on the Dashboard. Port of the shape used in
/// `src/constants/demoClaims.js`.
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
  });

  final String id;
  final String insurerName;
  final String claimNumber;
  final String registrationNumber;
  final String insuredName;
  final String status; // 'Pending' | 'Completed'
  final String vehicle;
  final String surveyDate;
  final String location;
  final String amount;
}
