import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Preinspection summary card shown on the Dashboard list. Port of
/// `src/pages/flows/preinspection/components/PreinspectionListCard.jsx`.
///
/// Takes plain fields rather than a domain model so this shared widget has
/// no dependency on the `preinspection_agent` feature layer.
class ClaimListCard extends StatelessWidget {
  const ClaimListCard({
    super.key,
    required this.insurerName,
    required this.claimNumber,
    required this.registrationNumber,
    required this.insuredName,
    required this.status,
    required this.onViewDetails,
  });

  final String insurerName;
  final String claimNumber;
  final String registrationNumber;
  final String insuredName;
  final String status;
  final VoidCallback onViewDetails;

  bool get _isCompleted => status == 'Completed';

  @override
  Widget build(BuildContext context) {
    final badgeColor = _isCompleted
        ? AppColors.statusCompleted
        : AppColors.statusPending;
    final badgeBg = _isCompleted
        ? const Color(0x2622C55E)
        : const Color(0x40F00000);

    final rows = <(IconData, String, String)>[
      (Icons.business_outlined, 'Insurer Name', insurerName),
      (Icons.assignment_outlined, 'PI Ref. Number', claimNumber),
      (
        Icons.directions_car_outlined,
        'Registration Number',
        registrationNumber,
      ),
      (Icons.person_outline, 'Owner Name', insuredName),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: badgeColor),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Icon(
                      row.$1,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 128,
                    child: Text(
                      row.$2,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$3,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            height: 1,
            color: Colors.black.withValues(alpha: 0.2),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewDetails,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: AppColors.primary, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
