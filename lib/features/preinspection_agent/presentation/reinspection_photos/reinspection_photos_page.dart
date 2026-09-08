import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/routing/app_back.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/media_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/page_title_bar.dart';
import '../../state/claim_flow_provider.dart';

const _totalExpected = 12;

enum _Status { required, submitted }

class _Badge extends StatelessWidget {
  const _Badge({required this.status});
  final _Status status;

  @override
  Widget build(BuildContext context) {
    final isSubmitted = status == _Status.submitted;
    final color = isSubmitted ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
    final bg = isSubmitted ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99), border: Border.all(color: color)),
      child: Text(isSubmitted ? 'Submitted' : 'Required', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Port of `ReinspectionPhotosPage.jsx`. The title bar literally reads "Add
/// Damage Photos" in the web app on this route too -- kept for parity.
///
/// The web version's "File" picker (PDF/JPG/PNG) is approximated with the
/// image gallery picker here, since true arbitrary-file selection would
/// need the separate `file_picker` package.
class ReinspectionPhotosPage extends ConsumerStatefulWidget {
  const ReinspectionPhotosPage({super.key});

  @override
  ConsumerState<ReinspectionPhotosPage> createState() => _ReinspectionPhotosPageState();
}

class _ReinspectionPhotosPageState extends ConsumerState<ReinspectionPhotosPage> {
  final _picker = ImagePicker();
  final _mediaStorage = MediaStorageService();
  final _scrollController = ScrollController();
  String? _mainPhotoPath;
  String? _billPath;

  void _scrollPhotos(int dir) {
    _scrollController.animateTo(
      (_scrollController.offset + dir * 110).clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickMainPhoto(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    final saved = await _mediaStorage.savePhoto('reinspection_main', file.path);
    setState(() => _mainPhotoPath = saved);
  }

  Future<void> _addExtraPhoto() async {
    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file == null) return;
    final saved = await _mediaStorage.savePhoto('reinspection_extra_${DateTime.now().millisecondsSinceEpoch}', file.path);
    ref.read(claimFlowProvider.notifier).addReinspectionPhoto(saved);
  }

  Future<void> _pickBill(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    final saved = await _mediaStorage.savePhoto('repair_bill', file.path);
    setState(() => _billPath = saved);
  }

  void _submit() {
    context.go(AppRoutes.repairSubmission);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(claimFlowProvider);
    final vehiclePhotos = flow.photos.values.toList();
    final uploadedCount = (_mainPhotoPath != null ? 1 : 0) + flow.reinspectionPhotos.length + (_billPath != null ? 1 : 0);
    final progress = (uploadedCount / _totalExpected).clamp(0, 1).toDouble();

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          PageTitleBar(
            title: 'Add Damage Photos',
            onBack: () => appBack(context, AppRoutes.submitted),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('No of photos uploaded', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text('$uploadedCount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFDAF0FE), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 18),
                              SizedBox(width: 8),
                              Text('Under repair/Reinspection photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                          ),
                          _Badge(status: _mainPhotoPath != null ? _Status.submitted : _Status.required),
                        ],
                      ),
                      if (_mainPhotoPath != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(_mainPhotoPath!), width: double.infinity, height: 140, fit: BoxFit.cover),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _pickMainPhoto(ImageSource.camera),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.btnPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Camera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickMainPhoto(ImageSource.gallery),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addExtraPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.btnPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Take More Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                if (flow.reinspectionPhotos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final path in flow.reinspectionPhotos)
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(path), width: 80, height: 80, fit: BoxFit.cover)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Vehicle Photos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        GestureDetector(onTap: () => _scrollPhotos(-1), child: const Icon(Icons.chevron_left, size: 18, color: AppColors.textSecondary)),
                        GestureDetector(onTap: () => _scrollPhotos(1), child: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary)),
                        const SizedBox(width: 4),
                        const Text('Swipe', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: vehiclePhotos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => Container(
                      width: 100,
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                      clipBehavior: Clip.antiAlias,
                      child: Image.file(File(vehiclePhotos[i]), fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Upload repair bill / invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFDAF0FE), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: _Badge(status: _billPath != null ? _Status.submitted : _Status.required),
                      ),
                      if (_billPath != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(_billPath!), width: double.infinity, height: 120, fit: BoxFit.cover),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _BillOption(
                                icon: Icons.photo_library_outlined,
                                label: 'GALLERY',
                                sublabel: 'Photos & Images',
                                color: const Color(0xFFF97316),
                                onTap: () => _pickBill(ImageSource.gallery),
                                hasBorder: true,
                              ),
                            ),
                            Expanded(
                              child: _BillOption(
                                icon: Icons.insert_drive_file_outlined,
                                label: 'FILE',
                                sublabel: 'Documents (PDF, JPG, PNG)',
                                color: const Color(0xFF3B82F6),
                                onTap: () => _pickBill(ImageSource.gallery),
                                hasBorder: true,
                              ),
                            ),
                            Expanded(
                              child: _BillOption(
                                icon: Icons.photo_camera_outlined,
                                label: 'CAMERA',
                                sublabel: 'Scan Invoice Now',
                                color: const Color(0xFF16A34A),
                                onTap: () => _pickBill(ImageSource.camera),
                                hasBorder: false,
                              ),
                            ),
                          ],
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.btnPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillOption extends StatelessWidget {
  const _BillOption({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
    required this.hasBorder,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          border: hasBorder ? const Border(right: BorderSide(color: Color(0xFFE2E8F0))) : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(sublabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
