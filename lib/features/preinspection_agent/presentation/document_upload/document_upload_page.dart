import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/routing/app_back.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/media_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/bottom_button.dart';
import '../../../../core/widgets/document_picker_modal.dart';
import '../../../../core/widgets/page_title_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../state/claim_flow_provider.dart';

class _DocType {
  const _DocType(
    this.id,
    this.label,
    this.desc,
    this.icon,
    this.bg,
    this.border, {
    this.required = false,
    this.frontBack = false,
    this.isOther = false,
  });

  final String id;
  final String label;
  final String desc;
  final IconData icon;
  final Color bg;
  final Color border;
  final bool required;
  final bool frontBack;
  final bool isOther;

  DocPickerMode get mode => isOther
      ? DocPickerMode.other
      : (frontBack ? DocPickerMode.frontBack : DocPickerMode.multiple);
}

// Preinspection document checklist (port of the PreinspectionAgent
// DocumentUploadPage.jsx). Every row is mandatory here, and the claim-only
// rows (Claim Form, Driving License, Repair Estimate) are replaced by the
// previous policy copy and PUC.
const _docList = [
  _DocType(
    'policy_copy',
    'Previous policy copy',
    'Insurance Claim Application Form',
    Icons.description_outlined,
    Color(0x408A64FF),
    Color(0xFF8A64FF),
    required: true,
  ),
  _DocType(
    'puc',
    'PUC',
    'DL Of Driver At the time of accident',
    Icons.receipt_long_outlined,
    Color(0x40DB6F37),
    Color(0xFFDB6F37),
    required: true,
  ),
  _DocType(
    'rc',
    'Registration Certificate',
    'Registration Certificate of insured vehicle',
    Icons.directions_car_outlined,
    Color(0x40009348),
    Color(0xFF009348),
    required: true,
    frontBack: true,
  ),
  _DocType(
    'aadhar',
    'Aadhar Card',
    'Aadhar of the insured Person',
    Icons.perm_identity,
    Color(0x401FA0D9),
    Color(0xFF1FA0D9),
    required: true,
    frontBack: true,
  ),
  _DocType(
    'pan',
    'Pan Card',
    'Pan of the insured person',
    Icons.perm_identity,
    Color(0x401FA0D9),
    Color(0xFF1FA0D9),
    required: true,
    frontBack: true,
  ),
  _DocType(
    'others',
    'Others',
    'PUC, Fitness,Police papers & any other documents required in support of claim',
    Icons.phone_outlined,
    Color(0x4001A0FE),
    Color(0xFF01A0FE),
    required: true,
    isOther: true,
  ),
];

/// Port of `DocumentUploadPage.jsx`.
///
/// The web app drives the "Submited"/"pending" badge purely off
/// `doc.required`, so every mandatory document claimed to be submitted before
/// anything was uploaded. Here the badge, the tick icon and the progress line
/// all read the same real capture state: a document only turns Submitted once
/// its images are saved from the picker sheet.
class DocumentUploadPage extends ConsumerStatefulWidget {
  const DocumentUploadPage({super.key});

  @override
  ConsumerState<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends ConsumerState<DocumentUploadPage> {
  final _mediaStorage = MediaStorageService();
  final Map<String, List<(String, String)>> _otherDocuments =
      {}; // docId -> [(name, path)]

  Future<void> _openPicker(_DocType doc, ImageSource source) async {
    if (!mounted) return;
    await DocumentPickerModal.show(
      context,
      docName: doc.label,
      mode: doc.mode,
      source: source,
      onSaveSides: (sides) async {
        for (final entry in sides.entries) {
          final saved = await _mediaStorage.savePhoto(
            '${doc.id}_${entry.key}',
            entry.value,
          );
          ref.read(claimFlowProvider.notifier).addDocumentUpload(doc.id, saved);
        }
      },
      onSaveMulti: (name, paths) async {
        final saved = <String>[];
        for (final p in paths) {
          saved.add(
            await _mediaStorage.savePhoto('${doc.id}_${saved.length}', p),
          );
        }
        for (final s in saved) {
          ref.read(claimFlowProvider.notifier).addDocumentUpload(doc.id, s);
        }
        if (doc.isOther) {
          setState(() {
            final list = _otherDocuments.putIfAbsent(doc.id, () => []);
            for (final s in saved) {
              list.add((name, s));
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploads = ref.watch(claimFlowProvider).documentUploads;
    bool isUploaded(_DocType d) => uploads[d.id]?.isNotEmpty ?? false;
    final completedCount = _docList.where(isUploaded).length;
    final totalCount = _docList.length;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          PageTitleBar(
            title: 'Document Upload',
            subtitle: 'Upload All Required Documents',
            onBack: () => appBack(context, AppRoutes.ownerVehicleDetails),
          ),
          // Progress is a single slim line + count rather than the old boxed
          // card, which used to push the first document below the fold.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: totalCount == 0 ? 0 : completedCount / totalCount,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$completedCount / $totalCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              children: [
                for (final doc in _docList)
                  _DocCard(
                    doc: doc,
                    uploaded: isUploaded(doc),
                    otherDocuments: _otherDocuments[doc.id] ?? const [],
                    onCamera: () => _openPicker(doc, ImageSource.camera),
                    onGallery: () => _openPicker(doc, ImageSource.gallery),
                  ),
                const SizedBox(height: 4),
                BottomButton(
                  label: 'Next',
                  onPressed: () => context.go(AppRoutes.inspectionDetails),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.doc,
    required this.uploaded,
    required this.otherDocuments,
    required this.onCamera,
    required this.onGallery,
  });

  final _DocType doc;

  /// Whether images for this document have actually been saved.
  final bool uploaded;
  final List<(String, String)> otherDocuments;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: doc.bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: doc.border),
                      ),
                      child: Icon(doc.icon, color: doc.border, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        doc.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      uploaded ? Icons.check_circle : Icons.hourglass_empty,
                      size: 16,
                      color: uploaded
                          ? AppColors.statusCompleted
                          : AppColors.statusPending,
                    ),
                    if (doc.required)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          '*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusPending,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: uploaded
                      ? const Color(0x3322C55E)
                      : const Color(0x33EF4444),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: uploaded
                        ? AppColors.statusCompleted
                        : AppColors.statusPending,
                  ),
                ),
                child: Text(
                  uploaded ? 'Submitted' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: uploaded
                        ? AppColors.textGreen
                        : AppColors.statusPending,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 1, bottom: 8),
            child: Text(
              doc.desc,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (doc.isOther && otherDocuments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in otherDocuments)
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.$1,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Camera',
                  onPressed: onCamera,
                  height: 34,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  label: 'Gallery',
                  onPressed: onGallery,
                  height: 34,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
