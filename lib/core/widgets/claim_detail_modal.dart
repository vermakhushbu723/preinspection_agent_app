import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Bottom-sheet claim detail view. Port of
/// `src/components/common/ClaimDetailModal.jsx`.
class ClaimDetailModal extends StatelessWidget {
  const ClaimDetailModal({
    super.key,
    required this.insurerName,
    required this.claimNumber,
    required this.registrationNumber,
    required this.insuredName,
    required this.vehicle,
    required this.surveyDate,
    required this.location,
    required this.amount,
    required this.status,
  });

  final String insurerName;
  final String claimNumber;
  final String registrationNumber;
  final String insuredName;
  final String vehicle;
  final String surveyDate;
  final String location;
  final String amount;
  final String status;

  static Future<void> show(
    BuildContext context, {
    required String insurerName,
    required String claimNumber,
    required String registrationNumber,
    required String insuredName,
    required String vehicle,
    required String surveyDate,
    required String location,
    required String amount,
    required String status,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClaimDetailModal(
        insurerName: insurerName,
        claimNumber: claimNumber,
        registrationNumber: registrationNumber,
        insuredName: insuredName,
        vehicle: vehicle,
        surveyDate: surveyDate,
        location: location,
        amount: amount,
        status: status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Insurer', insurerName),
      ('Claim No.', claimNumber),
      ('Reg. No.', registrationNumber),
      ('Insured', insuredName),
      ('Vehicle', vehicle),
      ('Survey Date', surveyDate),
      ('Location', location),
      ('Claim Amount', amount),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Claim Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'Completed'
                      ? AppColors.statusCompleted
                      : AppColors.statusPending,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.$1, style: const TextStyle(color: AppColors.textSecondary)),
                  Text(row.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
