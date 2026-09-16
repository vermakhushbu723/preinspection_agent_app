import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_back.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/page_title_bar.dart';
import '../../../../core/widgets/signature_pad.dart';
import '../../state/claim_flow_provider.dart';

/// Vehicle/insured detail values here are the web app's own hardcoded demo
/// values for this screen (note: they differ from the ones shown on
/// DamageReviewPage in the web app too — that's the source, not a
/// transcription error) — kept verbatim for exact parity.
class _Row {
  const _Row(this.icon, this.color, this.label, this.value);
  final IconData icon;
  final Color color;
  final String label;
  final String value;
}

const _vehicleDetails = [
  _Row(Icons.directions_car, Color(0xFF3B82F6), 'Make', 'Volkswagen'),
  _Row(Icons.adjust, Color(0xFFEF4444), 'Model', 'Polo'),
  _Row(Icons.palette, Color(0xFFA855F7), 'Variant', 'DSG Automatic'),
  _Row(Icons.inventory_2_outlined, Color(0xFFF97316), 'Body Type', 'Sedan'),
  _Row(Icons.build_outlined, Color(0xFF14B8A6), 'Mfg Year', '2017'),
  _Row(
    Icons.badge_outlined,
    Color(0xFF6366F1),
    'Registration Number',
    'MH 44 CD 2545',
  ),
  _Row(Icons.speed, Color(0xFFEC4899), 'Odometer', 'N/A'),
  _Row(Icons.map_outlined, Color(0xFF22C55E), 'State', 'MH'),
  _Row(
    Icons.calendar_today_outlined,
    Color(0xFFF59E0B),
    'Registration Date',
    '17/10/2017',
  ),
];

const _insuredDetails = [
  _Row(Icons.person, Color(0xFF0EA5E9), 'Insured Name', 'User Full Name'),
  _Row(
    Icons.phone_android,
    Color(0xFF22C55E),
    'Mobile Number',
    '+91 1234567890',
  ),
  _Row(
    Icons.email_outlined,
    Color(0xFFF59E0B),
    'Email Address',
    'useremail@gmail.com',
  ),
  _Row(
    Icons.description_outlined,
    Color(0xFFA855F7),
    'PI Ref.Number',
    '123456789CAR20',
  ),
  _Row(
    Icons.business,
    Color(0xFFEF4444),
    'Insurance Co',
    'XYZ Insurance company ltd',
  ),
];

/// Port of `VehicleInformationPage.jsx` (Group 2 workflow branch terminal
/// screen before Submitted).
class VehicleInformationPage extends ConsumerStatefulWidget {
  const VehicleInformationPage({super.key});

  @override
  ConsumerState<VehicleInformationPage> createState() =>
      _VehicleInformationPageState();
}

class _VehicleInformationPageState
    extends ConsumerState<VehicleInformationPage> {
  String? _recommendation; // 'approved' | 'rejected'

  void _submit() {
    final flow = ref.read(claimFlowProvider);
    if (!flow.bothSignaturesPresent) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          content: const Text('Please capture both signatures'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    ref.read(claimFlowProvider.notifier).clearDeclarationsAndSignatures();
    // Preinspection ends back on the dashboard rather than the claim
    // flow's Submitted screen.
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(claimFlowProvider);
    final photoPaths = flow.photos.values.toList();

    return Scaffold(
      backgroundColor: AppColors.bgCard,
      body: Column(
        children: [
          const AppHeader(),
          PageTitleBar(
            title: 'Vehicle Information',
            onBack: () => appBack(context, AppRoutes.addOthersPhotos),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle Photos',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: [
                          for (var i = 0; i < 6; i++)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: i < photoPaths.length
                                  ? Image.file(
                                      File(photoPaths[i]),
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.photo_camera_outlined,
                                      color: Color(0xFF9CA3AF),
                                    ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final row in _vehicleDetails)
                        _InformationRow(row: row),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Insured Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final row in _insuredDetails)
                        _InformationRow(row: row),
                    ],
                  ),
                ),
                _SignatureSection(
                  title: 'Customer/Representative signature',
                  subtitle: 'Please sign in the box below',
                  iconBg: const Color(0xFFDBEAFE),
                  iconColor: const Color(0xFF1D4ED8),
                  icon: Icons.person,
                  accepted: flow.customerDeclarationAccepted,
                  value: flow.customerSignature,
                  onChanged: (bytes) => ref
                      .read(claimFlowProvider.notifier)
                      .setCustomerSignature(bytes),
                  declarationLabel: 'Customer Declaration',
                  onDeclarationTap: () =>
                      context.push(AppRoutes.customerDeclaration),
                ),
                _SignatureSection(
                  title: 'Inspection agent signature',
                  subtitle: 'Please sign in the box below',
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFB45309),
                  icon: Icons.edit,
                  accepted: flow.inspectorDeclarationAccepted,
                  value: flow.inspectorSignature,
                  onChanged: (bytes) => ref
                      .read(claimFlowProvider.notifier)
                      .setInspectorSignature(bytes),
                  declarationLabel: 'Inspector Declaration',
                  onDeclarationTap: () =>
                      context.push(AppRoutes.inspectorDeclaration),
                ),
                _Card(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 43,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFDCFCE7),
                              border: Border.all(
                                color: const Color(0xFF22C55E),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF22C55E),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Recommendation',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Is this Preinspection recommended?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _RecommendationRadio(
                            label: 'Yes',
                            color: const Color(0xFF22C55E),
                            selected: _recommendation == 'approved',
                            onTap: () =>
                                setState(() => _recommendation = 'approved'),
                          ),
                          const SizedBox(width: 8),
                          _RecommendationRadio(
                            label: 'No',
                            color: const Color(0xFFEF4444),
                            selected: _recommendation == 'rejected',
                            onTap: () =>
                                setState(() => _recommendation = 'rejected'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Restart Survey',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.btnPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Submit Survey',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(14)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6)],
      ),
      child: child,
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.row});
  final _Row row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: row.color.withValues(alpha: 0.13),
                border: Border.all(color: row.color, width: 1.5),
              ),
              child: Icon(row.icon, size: 16, color: row.color),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: Text(
                row.label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                row.value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationRadio extends StatelessWidget {
  const _RecommendationRadio({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? color : Colors.white,
              border: Border.all(color: color, width: selected ? 6 : 2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureSection extends StatefulWidget {
  const _SignatureSection({
    required this.title,
    required this.subtitle,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.accepted,
    required this.value,
    required this.onChanged,
    required this.declarationLabel,
    required this.onDeclarationTap,
  });

  final String title;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final bool accepted;
  final Uint8List? value;
  final ValueChanged<Uint8List?> onChanged;
  final String declarationLabel;
  final VoidCallback onDeclarationTap;

  @override
  State<_SignatureSection> createState() => _SignatureSectionState();
}

class _SignatureSectionState extends State<_SignatureSection> {
  final _padController = SignaturePadController();

  void _clear() {
    _padController.clear();
    widget.onChanged(null);
  }

  Future<void> _save() async {
    final bytes = await _padController.export();
    if (!mounted) return;
    if (_padController.isEmpty || bytes == null) return;
    widget.onChanged(bytes);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signature saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.iconBg,
                ),
                child: Icon(widget.icon, size: 18, color: widget.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _padController.undo,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Undo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              SignaturePad(
                value: widget.value,
                onChanged: widget.onChanged,
                controller: _padController,
                height: 132,
                showClearButton: false,
                enabled: widget.accepted,
              ),
              if (!widget.accepted)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: widget.onDeclarationTap,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xE0F1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Accept the ${widget.declarationLabel} to sign here',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: widget.onDeclarationTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    widget.declarationLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onDeclarationTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: widget.accepted,
                          onChanged: null,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'I Agree',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clear,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5F2FF),
                      foregroundColor: const Color(0xFF0D6EFD),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.accepted ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.btnPrimary,
                      disabledBackgroundColor: AppColors.btnPrimary.withValues(
                        alpha: 0.6,
                      ),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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
