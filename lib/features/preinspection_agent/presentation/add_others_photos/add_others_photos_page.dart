import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_back.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/orientation.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/bottom_button.dart';
import '../../../../core/widgets/page_title_bar.dart';
import '../../domain/workflow_option.dart';
import '../../state/claim_flow_provider.dart';

class _Slot {
  const _Slot(this.key, this.bg);
  final String key;
  final String bg;
}

class _Card {
  const _Card(this.title, this.slots);
  final String title;
  final List<_Slot> slots;
}

const _bgBase = 'assets/images/instruction_bg';

const _photoCards = [
  _Card('Dashboard', [_Slot('dashboard', '$_bgBase/Dashboard.jpg')]),
  _Card('Front side after opening all doors', [
    _Slot('others-front-side', '$_bgBase/Front-side-after-opening-all-doors.png'),
  ]),
  _Card('Rear side after opening all doors', [
    _Slot('others-rear-side', '$_bgBase/Rear-side-after-opening-all-doors.png'),
  ]),
  _Card('Front under body', [_Slot('front-under-body', '$_bgBase/Front-under-body.png')]),
  _Card('Front / Windshield / Rear', [
    _Slot('windshield-front', '$_bgBase/WINDSHIELD1.png'),
    _Slot('windshield-rear', '$_bgBase/WINDSHIELD2.png'),
  ]),
  _Card('Selfie along with the vehicle', [
    _Slot('selfie-with-vehicle', '$_bgBase/Selfie-along-with-the-veichle.jpg'),
  ]),
  _Card('Open hood: Engine compartment view', [_Slot('open-hood', '$_bgBase/Open-hood.png')]),
  _Card('Take a close-up of the tyre numbers', [
    _Slot('tyre-1', '$_bgBase/tyre.png'),
    _Slot('tyre-2', '$_bgBase/tyre.png'),
    _Slot('tyre-3', '$_bgBase/tyre.png'),
    _Slot('tyre-4', '$_bgBase/tyre.png'),
  ]),
];

/// Port of `AddOthersPhotosPage.jsx` (Group 2 workflow branch). The web
/// version hardcodes its progress bar to a fixed "3 Of 7 Completed" / 48%
/// regardless of actual capture state — kept as-is here for exact parity.
class AddOthersPhotosPage extends ConsumerStatefulWidget {
  const AddOthersPhotosPage({super.key});

  @override
  ConsumerState<AddOthersPhotosPage> createState() => _AddOthersPhotosPageState();
}

class _AddOthersPhotosPageState extends ConsumerState<AddOthersPhotosPage> {
  @override
  void initState() {
    super.initState();
    AppOrientation.lockPortrait();
  }

  Future<void> _capture(String key) async {
    await context.push(AppRoutes.cameraCapturePath(key));
    // Whatever the camera route did to the orientation, this page is portrait.
    await AppOrientation.lockPortrait();
  }

  String _nextSlotKey(_Card card, Map<String, String> photos) {
    for (final slot in card.slots) {
      if (!photos.containsKey(slot.key)) return slot.key;
    }
    return card.slots.last.key;
  }

  Future<void> _next() async {
    await ref.read(claimFlowProvider.notifier).setWorkflowOption(WorkflowOption.group2);
    if (mounted) context.go(AppRoutes.vehicleInformation);
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(claimFlowProvider).photos;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppHeader(),
          PageTitleBar(title: 'Add Others Photos', onBack: () => appBack(context, AppRoutes.photoCaptureSelection)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('3 Of 7 Completed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Text('48%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: const LinearProgressIndicator(
                    value: 0.48,
                    minHeight: 8,
                    backgroundColor: Color(0x4D93C5FD),
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 24),
                for (final card in _photoCards)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF))),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final slot in card.slots)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: GestureDetector(
                                    onTap: () => _capture(slot.key),
                                    child: AspectRatio(
                                      aspectRatio: card.slots.length > 1 ? 1 : 16 / 9,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: photos.containsKey(slot.key)
                                            ? Image.file(File(photos[slot.key]!), fit: BoxFit.cover)
                                            : Opacity(
                                                opacity: 0.4,
                                                child: Image.asset(
                                                  slot.bg,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) => Container(color: const Color(0xFFE5E7EB)),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        BottomButton(label: 'Capture', onPressed: () => _capture(_nextSlotKey(card, photos))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white.withValues(alpha: 0.95),
              padding: const EdgeInsets.all(16),
              child: BottomButton(label: 'Next', onPressed: _next),
            ),
          ),
        ],
      ),
    );
  }
}
