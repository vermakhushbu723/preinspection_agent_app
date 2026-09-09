import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/bottom_button.dart';

class _DocumentItem {
  const _DocumentItem(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
}

// Preinspection document checklist (port of the PreinspectionAgent
// ClaimStartPage.jsx): previous policy copy, PUC, RC and KYC — no claim
// form / repair estimate, which belong to the claim flow.
const _documents = [
  _DocumentItem(Icons.description_outlined, 'Previous policy copy', Color(0xFF7C3AED)),
  _DocumentItem(Icons.badge_outlined, 'PUC', Color(0xFFEF4444)),
  _DocumentItem(Icons.directions_car_outlined, 'Registration Certificate', Color(0xFF16A34A)),
  _DocumentItem(Icons.perm_identity, 'KYC ( Aadhar & PAN Card )', Color(0xFF0EA5E9)),
];

const _tollFreeNumber = '+91 1234567890';

/// Port of `ClaimStartPage.jsx`.
class ClaimStartPage extends StatelessWidget {
  const ClaimStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCard,
      body: Column(
        children: [
          const AppHeader(),
          // The title is white text, so it has to sit ON the blue band (the
          // web app puts it inside the header) — painted over the page
          // background it was invisible. This container continues the
          // header's blue so the two read as one band.
          Container(
            width: double.infinity,
            color: AppColors.bgHeader,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: const Text(
              'Thank you for using risk inspection services',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
              ),
            ),
          ),
          // Everything below scrolls as one list, so the last row can never be
          // clipped half-way by the pinned Start button.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderInput),
                  ),
                  child: const Text(
                    'Before you click the "Start" button, please keep following documents '
                    'handy; as essential to proceed further in survey',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 14),
                for (final doc in _documents)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: doc.color.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: doc.color, width: 1.5),
                          ),
                          child: Icon(doc.icon, color: doc.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            doc.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Help line is guidance, not a document to keep handy, so it
                // reads as its own note rather than a sixth checklist row.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderInput),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined, color: AppColors.iconPhone, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'If You Need Any Help Please Contact Our Toll Free Number',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _tollFreeNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: BottomButton(
                label: 'Start',
                onPressed: () => context.go(AppRoutes.ownerVehicleDetails),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
