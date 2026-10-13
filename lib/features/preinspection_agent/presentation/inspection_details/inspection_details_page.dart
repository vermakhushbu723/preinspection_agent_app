import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/insurer_branding.dart';
import '../../../../core/routing/app_back.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/orientation.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/bottom_button.dart';
import '../../../../core/widgets/location_modal.dart';
import '../../../../core/widgets/page_title_bar.dart';
import '../../../../core/widgets/rotate_device_modal.dart';
import '../../state/claim_flow_provider.dart';
import '../../state/session_provider.dart';

class _InspectionRow {
  const _InspectionRow(this.icon, this.label, this.value, this.iconBg);
  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
}

/// The case being inspected, from the saved owner & vehicle form and the
/// server's PI Ref. Number. (No policy number row: the form never collects one.)
List<_InspectionRow> _inspectionRows(WidgetRef ref) {
  final flow = ref.watch(claimFlowProvider);
  final d = flow.ownerVehicleDetails;
  String orDash(String v) => v.isEmpty ? '-' : v;
  // The insurer the signed-in agent works for (from the server), unless this
  // build is tied to a branded insurer.
  final insurer =
      InsurerBranding.current.name ??
      ref.watch(sessionProvider)?.user.organization ??
      '';
  return [
    _InspectionRow(
      Icons.business,
      'Insurance Company',
      orDash(insurer),
      const Color(0xFF3B82F6),
    ),
    _InspectionRow(
      Icons.person,
      'Insured Name',
      orDash(d.ownerName),
      const Color(0xFF22C55E),
    ),
    _InspectionRow(
      Icons.directions_car,
      'Vehicle Number',
      orDash(d.registrationNumber),
      const Color(0xFFEF4444),
    ),
    _InspectionRow(
      Icons.assignment,
      'PI Ref. Number',
      flow.inspectionId ?? '-',
      const Color(0xFF7C3AED),
    ),
  ];
}

class _Instruction {
  const _Instruction(this.icon, this.title, this.desc, this.color, this.bg);
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final Color bg;
}

const _instructions = [
  _Instruction(
    Icons.screen_rotation,
    'Enable Auto-Rotate',
    'Switch on auto-rotate and hold your phone horizontally to capture the full vehicle frame.',
    Color(0xFF00E4DF),
    Color(0x4000E4DF),
  ),
  _Instruction(
    Icons.location_on,
    'Turn On GPS Location',
    'Ensure location services are enabled to verify inspection time and location.',
    Color(0xFF7532FC),
    Color(0x407532FC),
  ),
  _Instruction(
    Icons.camera_alt,
    'Capture 360° Photos',
    'Take clear photos of the front, rear, and both sides of the vehicle.',
    Color(0xFF01A0FE),
    Color(0x4000A7F8),
  ),
  _Instruction(
    Icons.description_outlined,
    'Ensure Document Clarity',
    'Place documents on a flat surface with good lighting. Avoid shadows and glare.',
    Color(0xFFFF8427),
    Color(0x40FF8427),
  ),
  _Instruction(
    Icons.fact_check_outlined,
    'Final Review Before Submission',
    'Double-check that all images are clear and the vehicle is fully visible.',
    Color(0xFFFF1578),
    Color(0x40FF1578),
  ),
];

/// Port of `InspectionDetailsPage.jsx`.
class InspectionDetailsPage extends ConsumerStatefulWidget {
  const InspectionDetailsPage({super.key});

  @override
  ConsumerState<InspectionDetailsPage> createState() =>
      _InspectionDetailsPageState();
}

class _InspectionDetailsPageState extends ConsumerState<InspectionDetailsPage> {
  bool _showLocation = false;
  bool _showRotate = false;

  void _handleStartPhotos() => setState(() => _showLocation = true);

  void _handleLocationAllow() => setState(() {
    _showLocation = false;
    _showRotate = true;
  });

  Future<void> _handleRotateAllow() async {
    setState(() => _showRotate = false);
    await AppOrientation.lockLandscape();
    if (mounted) context.go(AppRoutes.photoCaptureSelection);
  }

  @override
  Widget build(BuildContext context) {
    final inspectionData = _inspectionRows(ref);
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const AppHeader(),
              PageTitleBar(
                title: 'Inspection Details',
                onBack: () => appBack(context, AppRoutes.documentUpload),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderInput),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          for (var i = 0; i < inspectionData.length; i++)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                border: i < inspectionData.length - 1
                                    ? const Border(
                                        bottom: BorderSide(
                                          color: AppColors.borderInput,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: inspectionData[i].iconBg
                                          .withValues(alpha: 0.13),
                                      border: Border.all(
                                        color: inspectionData[i].iconBg,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      inspectionData[i].icon,
                                      size: 18,
                                      color: inspectionData[i].iconBg,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 128,
                                    child: Text(
                                      inspectionData[i].label,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      inspectionData[i].value,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please read following important instructions before you start survey',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final ins in _instructions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: ins.bg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: ins.color,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(ins.icon, size: 16, color: ins.color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ins.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: ins.color,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ins.desc,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    BottomButton(
                      label: 'Start Taking Photos',
                      onPressed: _handleStartPhotos,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showLocation) LocationModal(onAllow: _handleLocationAllow),
          if (_showRotate) RotateDeviceModal(onAllow: _handleRotateAllow),
        ],
      ),
    );
  }
}
