import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/insurer_branding.dart';
import '../../../../core/routing/app_back.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../state/claim_flow_provider.dart';
import '../../state/claim_flow_state.dart';
import '../../state/session_provider.dart';

const _defaultVehiclePhotos = [
  'assets/images/vehicles/car/RearLeft.png',
  'assets/images/vehicles/car/Left.png',
  'assets/images/vehicles/car/Right.png',
  'assets/images/vehicles/car/FrontRight.png',
  'assets/images/vehicles/car/Front.png',
  'assets/images/vehicles/car/Rear.png',
];

class _Row {
  const _Row(this.icon, this.color, this.label, this.value) : muted = false;
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool muted;
}

/// Vehicle & insured rows from the saved owner & vehicle form and the
/// server's PI Ref. Number (no Body Type / Policy Number rows: the form never
/// collects them).
List<_Row> _vehicleDetails(ClaimFlowState flow) {
  final d = flow.ownerVehicleDetails;
  String v(String x) => x.isEmpty ? '-' : x;
  return [
    _Row(Icons.directions_car, const Color(0xFF2563EB), 'Make', v(d.make)),
    _Row(Icons.adjust, const Color(0xFFDB2777), 'Model', v(d.model)),
    _Row(Icons.palette, const Color(0xFF7C3AED), 'Variant', v(d.variant)),
    _Row(
      Icons.factory_outlined,
      const Color(0xFF0891B2),
      'Mfg Year',
      v(d.manufacturingYear),
    ),
    _Row(
      Icons.badge_outlined,
      const Color(0xFF16A34A),
      'Registration number',
      v(d.registrationNumber),
    ),
    _Row(
      Icons.speed,
      const Color(0xFFDC2626),
      'Odometer',
      d.odometer.isEmpty ? '-' : '${d.odometer} KMS',
    ),
    _Row(Icons.place_outlined, const Color(0xFF0D9488), 'State', v(d.state)),
    _Row(
      Icons.calendar_today_outlined,
      const Color(0xFF4F46E5),
      'Registration Date',
      v(d.registrationDate),
    ),
  ];
}

List<_Row> _insuredDetails(ClaimFlowState flow, String insurer) {
  final d = flow.ownerVehicleDetails;
  String v(String x) => x.isEmpty ? '-' : x;
  return [
    _Row(Icons.person, const Color(0xFF22C55E), 'Insured Name', v(d.ownerName)),
    _Row(
      Icons.phone_android,
      const Color(0xFFEC4899),
      'Mobile Number',
      d.mobile.isEmpty ? '-' : '+91 ${d.mobile}',
    ),
    _Row(
      Icons.email_outlined,
      const Color(0xFFF97316),
      'Email Address',
      v(d.email),
    ),
    _Row(
      Icons.assignment_outlined,
      const Color(0xFF7C3AED),
      'PI Ref. Number',
      flow.inspectionId ?? '-',
    ),
    _Row(Icons.business, const Color(0xFF3B82F6), 'Insurance Co', v(insurer)),
  ];
}

/// Port of `DamageReviewPage.jsx`.
class DamageReviewPage extends ConsumerStatefulWidget {
  const DamageReviewPage({super.key});

  @override
  ConsumerState<DamageReviewPage> createState() => _DamageReviewPageState();
}

class _DamageReviewPageState extends ConsumerState<DamageReviewPage> {
  final _scrollController = ScrollController();
  int _photoIndex = 0;

  void _scrollPhotos(int dir) {
    _scrollController.animateTo(
      (_scrollController.offset + dir * 110).clamp(
        0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _restart() async {
    ref.read(claimFlowProvider.notifier).clearPhotos();
    context.go(AppRoutes.inspectionDetails);
  }

  bool _submitting = false;

  /// Uploads anything still pending, then submits the survey on the server.
  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(claimFlowProvider.notifier).submitSurvey();
      if (mounted) context.go(AppRoutes.submitted);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(claimFlowProvider);
    final captured = flow.photos.values.toList();
    final vehiclePhotos = captured.isNotEmpty
        ? captured
        : _defaultVehiclePhotos;
    final isCategoryAsset = captured.isEmpty;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Container(
            color: AppColors.bgPageTitle,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 2),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            appBack(context, AppRoutes.addDamagePhotos),
                        child: const Text(
                          '‹',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Vehicle Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 22, bottom: 6),
                  child: Text(
                    'Upload All Reqired Documents',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vehicle Photos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _scrollPhotos(-1),
                          child: const Icon(
                            Icons.chevron_left,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _scrollPhotos(1),
                          child: const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'Swipe',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: vehiclePhotos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final selected = i == _photoIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _photoIndex = i),
                        child: Container(
                          width: 78,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: isCategoryAsset
                              ? Image.asset(
                                  vehiclePhotos[i],
                                  fit: BoxFit.contain,
                                )
                              : Image.file(
                                  File(vehiclePhotos[i]),
                                  fit: BoxFit.contain,
                                ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                _DetailCard(
                  title: 'Vehicle Details',
                  rows: _vehicleDetails(flow),
                ),
                const SizedBox(height: 8),
                _DetailCard(
                  title: 'Insured Details',
                  rows: _insuredDetails(
                    flow,
                    InsurerBranding.current.name ??
                        ref.watch(sessionProvider)?.user.organization ??
                        '',
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _restart,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(
                          color: AppColors.borderInput,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Restart Survey',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.btnPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Submit Survey',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Icon(rows[i].icon, size: 16, color: rows[i].color),
                  ),
                  SizedBox(
                    width: 118,
                    child: Text(
                      rows[i].label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: rows[i].muted
                            ? const Color(0xFF94A3B8)
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
