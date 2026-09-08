import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';

enum DocPickerMode { frontBack, single, multiple, other }

/// Document camera/gallery picker. Visual layout is a faithful port of
/// `src/components/modals/DocumentCameraModal.jsx`'s selection screens
/// (front/back tiles, or a multi-image grid with an optional name field);
/// unlike the web version it doesn't embed a second live camera viewfinder
/// inside the modal itself — tapping a tile launches the OS
/// camera/gallery picker directly (via `image_picker`), since the app
/// already has a full custom camera screen (`CameraCapturePage`) for the
/// main photo-capture flows and duplicating that live-preview UI here
/// wouldn't add anything a user could see differently.
///
/// Every mode commits through an explicit **Save** button: picking a front /
/// back image only stages it in the sheet, so nothing is recorded against the
/// claim (and no document flips to "Submitted") until the user actually
/// saves — and they can re-shoot a bad photo before committing.
class DocumentPickerModal extends StatefulWidget {
  const DocumentPickerModal({
    super.key,
    required this.docName,
    required this.mode,
    required this.source,
    this.onSaveSides,
    this.onSaveMulti,
    this.existingSideImages = const {},
  });

  final String docName;
  final DocPickerMode mode;
  final ImageSource source;
  /// Called once, on Save, with every staged side (`{'Front Side': path}`).
  final void Function(Map<String, String> sides)? onSaveSides;
  final void Function(String name, List<String> paths)? onSaveMulti;
  final Map<String, String> existingSideImages;

  static Future<void> show(
    BuildContext context, {
    required String docName,
    required DocPickerMode mode,
    required ImageSource source,
    void Function(Map<String, String> sides)? onSaveSides,
    void Function(String name, List<String> paths)? onSaveMulti,
    Map<String, String> existingSideImages = const {},
  }) {
    return showDialog(
      context: context,
      barrierColor: AppColors.overlay,
      builder: (_) => DocumentPickerModal(
        docName: docName,
        mode: mode,
        source: source,
        onSaveSides: onSaveSides,
        onSaveMulti: onSaveMulti,
        existingSideImages: existingSideImages,
      ),
    );
  }

  @override
  State<DocumentPickerModal> createState() => _DocumentPickerModalState();
}

class _DocumentPickerModalState extends State<DocumentPickerModal> {
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  final List<String> _multiImages = [];
  final Map<String, String> _sideImages = {};

  bool get _isMulti =>
      widget.mode == DocPickerMode.multiple || widget.mode == DocPickerMode.other;
  bool get _isOther => widget.mode == DocPickerMode.other;
  bool get _isSingle => widget.mode == DocPickerMode.single;

  @override
  void initState() {
    super.initState();
    _sideImages.addAll(widget.existingSideImages);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickForSide(String side) async {
    final file = await _picker.pickImage(source: widget.source, imageQuality: 85);
    if (file == null) return;
    // Staged only -- committed by _saveSides() so the user can retake a side
    // before it counts against the document.
    setState(() => _sideImages[side] = file.path);
  }

  bool get _canSaveSides => _sideImages.values.any((p) => p.isNotEmpty);

  void _saveSides() {
    if (!_canSaveSides) return;
    widget.onSaveSides?.call(Map.of(_sideImages));
    Navigator.of(context).pop();
  }

  Future<void> _addMultiImage() async {
    final file = await _picker.pickImage(source: widget.source, imageQuality: 85);
    if (file == null) return;
    setState(() => _multiImages.add(file.path));
  }

  void _removeMultiImage(int index) {
    setState(() => _multiImages.removeAt(index));
  }

  bool get _canSaveMulti =>
      _multiImages.isNotEmpty && (!_isOther || _nameController.text.trim().isNotEmpty);

  void _saveMulti() {
    if (!_canSaveMulti) return;
    final name = _isOther ? _nameController.text.trim() : widget.docName;
    widget.onSaveMulti?.call(name, List.of(_multiImages));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _isMulti ? _buildMultiPanel() : _buildSelectionPanel(),
      ),
    );
  }

  Widget _buildMultiPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _isOther
                  ? TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Enter document name',
                        border: UnderlineInputBorder(),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )
                  : Text(
                      widget.docName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _multiImages.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(File(_multiImages[i]), width: 72, height: 72, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _removeMultiImage(i),
                      child: const CircleAvatar(
                        radius: 9,
                        backgroundColor: AppColors.statusPending,
                        child: Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            GestureDetector(
              onTap: _addMultiImage,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFFF8FBFF),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: AppColors.primary, size: 18),
                    Text('Add', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_multiImages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Tap "Add" to add one or more images for this document.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canSaveMulti ? _saveMulti : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCompleted,
              disabledBackgroundColor: const Color(0xFF9CA3AF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Save${_multiImages.isNotEmpty ? ' (${_multiImages.length})' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionPanel() {
    final sides = _isSingle ? ['Document'] : ['Front Side', 'Back Side'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.docName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final side in sides) ...[
              GestureDetector(
                onTap: () => _pickForSide(side),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderInput, width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _sideImages[side] != null
                          ? Image.file(File(_sideImages[side]!), fit: BoxFit.cover)
                          : Icon(
                              widget.source == ImageSource.gallery
                                  ? Icons.photo_library_outlined
                                  : Icons.photo_camera_outlined,
                              size: 32,
                              color: AppColors.textSecondary,
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(_isSingle ? 'Upload Document' : side),
                  ],
                ),
              ),
              if (sides.length > 1 && side == sides.first)
                Container(width: 1, height: 100, color: AppColors.borderLight, margin: const EdgeInsets.symmetric(horizontal: 20)),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _canSaveSides
              ? 'Tap an image to retake it, then press Save.'
              : 'Tap a tile to capture, then press Save.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canSaveSides ? _saveSides : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCompleted,
              disabledBackgroundColor: const Color(0xFF9CA3AF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Save${_canSaveSides ? ' (${_sideImages.length})' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
