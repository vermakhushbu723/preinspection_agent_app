import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_back.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../state/claim_flow_provider.dart';

const _defaultVehiclePhotos = [
  'assets/images/vehicles/car/RearLeft.png',
  'assets/images/vehicles/car/Left.png',
  'assets/images/vehicles/car/Right.png',
  'assets/images/vehicles/car/FrontRight.png',
  'assets/images/vehicles/car/Front.png',
  'assets/images/vehicles/car/Rear.png',
];

class _Row {
  const _Row(this.icon, this.color, this.label, this.value, {this.muted = false});
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool muted;
}

/// Vehicle & insured detail values shown here are the web app's own
/// hardcoded demo values (not wired to the real claim) -- kept verbatim
/// for exact parity with the reference site.
const _vehicleDetails = [
  _Row(Icons.directions_car, Color(0xFF2563EB), 'Make', 'Volkswagen Polo'),
  _Row(Icons.adjust, Color(0xFFDB2777), 'Model', 'GT Tsi'),
  _Row(Icons.palette, Color(0xFF7C3AED), 'Variant', 'DSG Automatic'),
  _Row(Icons.inventory_2_outlined, Color(0xFFEA580C), 'Body Type', 'Hatch Back', muted: true),
  _Row(Icons.factory_outlined, Color(0xFF0891B2), 'Mfg Year', '2017'),
  _Row(Icons.badge_outlined, Color(0xFF16A34A), 'Registration number', 'MH 49 DS 2345'),
  _Row(Icons.speed, Color(0xFFDC2626), 'Odometer', '141470 KMS'),
  _Row(Icons.place_outlined, Color(0xFF0D9488), 'State', 'MH'),
  _Row(Icons.calendar_today_outlined, Color(0xFF4F46E5), 'Registration Date', '17/03/2017'),
];

const _insuredDetails = [
  _Row(Icons.person, Color(0xFF22C55E), 'Insured Name', 'User Full Name'),
  _Row(Icons.phone_android, Color(0xFFEC4899), 'Mobile Number', '+91 1234567890'),
  _Row(Icons.email_outlined, Color(0xFFF97316), 'Email Address', 'Username@gmail.com'),
  _Row(Icons.assignment_outlined, Color(0xFF7C3AED), 'Claim number', '123456789CAR20', muted: true),
  _Row(Icons.description_outlined, Color(0xFF22C55E), 'Policy Number', '123456789CAR20', muted: true),
  _Row(Icons.business, Color(0xFF3B82F6), 'Insurance Co', 'XYZ insurance comapny ltd'),
];

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
      (_scrollController.offset + dir * 110).clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _restart() async {
    ref.read(claimFlowProvider.notifier).clearPhotos();
    context.go(AppRoutes.inspectionDetails);
  }

  void _submit() => context.go(AppRoutes.submitted);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(claimFlowProvider);
    final captured = flow.photos.values.toList();
    final vehiclePhotos = captured.isNotEmpty ? captured : _defaultVehiclePhotos;
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
                        onTap: () => appBack(context, AppRoutes.addDamagePhotos),
                        child: const Text('‹', style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                      const SizedBox(width: 6),
                      const Text('Vehicle Information', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 22, bottom: 6),
                  child: Text('Upload All Reqired Documents', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
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
                    const Text('Vehicle Photos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        GestureDetector(onTap: () => _scrollPhotos(-1), child: const Icon(Icons.chevron_left, size: 18, color: AppColors.textSecondary)),
                        GestureDetector(onTap: () => _scrollPhotos(1), child: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary)),
                        const SizedBox(width: 2),
                        const Text('Swipe', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                            border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: isCategoryAsset
                              ? Image.asset(vehiclePhotos[i], fit: BoxFit.contain)
                              : Image.file(File(vehiclePhotos[i]), fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                _DetailCard(title: 'Vehicle Details', rows: _vehicleDetails),
                const SizedBox(height: 8),
                _DetailCard(title: 'Insured Details', rows: _insuredDetails),
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
                      side: const BorderSide(color: AppColors.borderInput, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Restart Survey', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.btnPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Submit Survey', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          ),
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: i < rows.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))) : null,
              ),
              child: Row(
                children: [
                  SizedBox(width: 26, child: Icon(rows[i].icon, size: 16, color: rows[i].color)),
                  SizedBox(
                    width: 118,
                    child: Text(rows[i].label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: rows[i].muted ? const Color(0xFF94A3B8) : AppColors.textPrimary),
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
