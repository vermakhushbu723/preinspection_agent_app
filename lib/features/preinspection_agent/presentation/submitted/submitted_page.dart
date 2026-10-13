import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../state/claim_flow_provider.dart';

/// Port of `SubmittedPage.jsx`.
///
/// Two faces, decided by the case on the server:
///  * just submitted -- the SUBMITTED confirmation and a way back to the
///    dashboard;
///  * a submitted case reopened from the dashboard that needs repair
///    (not recommended / rejected / damage survey) -- the prompt to add
///    repair & reinspection photos, with a Continue button.
class SubmittedPage extends ConsumerStatefulWidget {
  const SubmittedPage({super.key});

  @override
  ConsumerState<SubmittedPage> createState() => _SubmittedPageState();
}

class _SubmittedPageState extends ConsumerState<SubmittedPage> {
  Future<void> _toDashboard() async {
    await ref.read(claimFlowProvider.notifier).resetSession();
    if (mounted) context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final already = ref.watch(claimFlowProvider).reopenedSubmitted;

    return Scaffold(
      body: Container(
        color: AppColors.primary,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 40,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF22C55E),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x5922C55E),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                'SUBMITTED',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              if (already) ...[
                const SizedBox(height: 16),
                const Text(
                  'This survey Already has\nDo you want to submit\nduring repair & reinspection\nPhotos & Repair bills',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.reinspectionPhotos),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.btnPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
              if (!already) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _toDashboard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.btnPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Back to Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
