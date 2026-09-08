import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_back.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/orientation.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/page_title_bar.dart';
import '../../data/vehicle_assets.dart';
import '../../domain/vehicle_category.dart';
import '../../domain/workflow_option.dart';
import '../../state/claim_flow_provider.dart';

class _Section {
  const _Section(this.label, this.prefix, this.guides);
  final String label;
  final String prefix;

  /// Angles a surveyor is expected to shoot for this side, as
  /// `(angleId, caption)`. Rendered as always-visible reference thumbnails
  /// so it stays clear *which* shots this section wants -- they are a
  /// guide, not captured output, so they never get replaced by the photos.
  final List<(String, String)> guides;
}

const _sections = [
  _Section('Front side', 'front', [
    ('front-lh', 'Front Left'),
    ('front-side', 'Front'),
    ('front-rh-side', 'Front Right'),
  ]),
  _Section('Left side', 'lh', [
    ('front-lh', 'Front Left'),
    ('lh-side', 'Left'),
    ('rear-lh-side', 'Rear Left'),
  ]),
  _Section('Right side', 'rh', [
    ('front-rh-side', 'Front Right'),
    ('rh-side', 'Right'),
    ('rear-rh-side', 'Rear Right'),
  ]),
  _Section('Rear side', 'rear', [
    ('rear-lh-side', 'Rear Left'),
    ('rear-side', 'Rear'),
    ('rear-rh-side', 'Rear Right'),
  ]),
];

/// Port of `AddDamagePhotosPage.jsx` (Group 1 workflow branch).
class AddDamagePhotosPage extends ConsumerStatefulWidget {
  const AddDamagePhotosPage({super.key});

  @override
  ConsumerState<AddDamagePhotosPage> createState() => _AddDamagePhotosPageState();
}

class _AddDamagePhotosPageState extends ConsumerState<AddDamagePhotosPage> {
  /// Section prefix -> index of the reference shot the surveyor tapped.
  /// Damage close-ups are taken *per portion*, so the capture button has to
  /// know which portion of the side is being shot. Defaults to the first
  /// reference so the button is never dead.
  final Map<String, int> _selectedGuide = {};

  @override
  void initState() {
    super.initState();
    AppOrientation.lockPortrait();
  }

  List<MapEntry<String, String>> _photosForPrefix(Map<String, String> photos, String prefix) {
    return photos.entries.where((e) => e.key.startsWith(prefix)).toList();
  }

  Future<void> _addPhoto(String prefix) async {
    final existing = _photosForPrefix(ref.read(claimFlowProvider).photos, prefix).length;
    final key = '$prefix-damage-${existing + 1}';
    await context.push(AppRoutes.cameraCapturePath(key));
    // Whatever the camera route did to the orientation, this page is portrait.
    await AppOrientation.lockPortrait();
  }

  Future<void> _addAdditionalPhoto(int nextIndex) async {
    await context.push(AppRoutes.cameraCapturePath('additional-damage-$nextIndex'));
    await AppOrientation.lockPortrait();
  }

  void _removePhoto(String key) {
    ref.read(claimFlowProvider.notifier).removePhoto(key);
  }

  Future<void> _submit() async {
    final notifier = ref.read(claimFlowProvider.notifier);
    if (ref.read(claimFlowProvider).workflowOption == null) {
      await notifier.setWorkflowOption(WorkflowOption.group1);
    }
    if (mounted) context.go(AppRoutes.damageReview);
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(claimFlowProvider);
    final photos = flow.photos;
    final category = flow.ownerVehicleDetails.vehicleCategory;
    final additionalPhotos = photos.entries.where((e) => e.key.startsWith('additional-damage')).toList();
    final completedCount = _sections.where((s) => _photosForPrefix(photos, s.prefix).isNotEmpty).length;
    final totalCount = _sections.length + 1;
    final progress = totalCount == 0 ? 0 : ((completedCount / totalCount) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.bgCard,
      body: Column(
        children: [
          const AppHeader(),
          PageTitleBar(
            title: 'Add Damage Photos',
            onBack: () => appBack(context, AppRoutes.photoCaptureSelection),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFDAF0FE),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$completedCount Of $totalCount Completed',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            Text('$progress%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final section in _sections)
                    _PhotoSection(
                      label: section.label,
                      guides: section.guides,
                      category: category,
                      photos: _photosForPrefix(photos, section.prefix).map((e) => e.value).toList(),
                      selectedGuide: _selectedGuide[section.prefix] ?? 0,
                      onSelectGuide: (i) => setState(() => _selectedGuide[section.prefix] = i),
                      onCapture: () => _addPhoto(section.prefix),
                    ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Additional Photos Of Damage',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        if (additionalPhotos.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final entry in additionalPhotos)
                                  _RemovableThumbnail(path: entry.value, onRemove: () => _removePhoto(entry.key)),
                              ],
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _addAdditionalPhoto(additionalPhotos.length),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.btnPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              additionalPhotos.isNotEmpty ? '+ Add Another Photo' : 'Capture',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (completedCount >= _sections.length)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusCompleted,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save & Submit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.label,
    required this.guides,
    required this.category,
    required this.photos,
    required this.selectedGuide,
    required this.onSelectGuide,
    required this.onCapture,
  });

  final String label;
  final List<(String, String)> guides;
  final VehicleCategory category;
  final List<String> photos;
  final int selectedGuide;
  final ValueChanged<int> onSelectGuide;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          // Reference shots for this side. These stay put no matter how many
          // photos are taken -- the captured ones stack up underneath.
          Row(
            children: [
              for (final (i, (angleId, caption)) in guides.indexed)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onSelectGuide(i),
                      child: Column(
                        children: [
                          Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: i == selectedGuide ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: i == selectedGuide ? AppColors.primary : AppColors.borderInput,
                                width: i == selectedGuide ? 2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              VehicleAssets.angleImage(category, angleId),
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.directions_car, color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            caption,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: i == selectedGuide ? FontWeight.bold : FontWeight.normal,
                              color: i == selectedGuide ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (photos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final path in photos)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(path), width: 72, height: 72, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF22C55E)),
                            child: const Icon(Icons.check, size: 9, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCapture,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.btnPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Capture ${guides[selectedGuide.clamp(0, guides.length - 1)].$2}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemovableThumbnail extends StatelessWidget {
  const _RemovableThumbnail({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(File(path), width: 72, height: 72, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444)),
              child: const Icon(Icons.close, size: 9, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
