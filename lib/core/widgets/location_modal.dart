import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../theme/app_colors.dart';
import 'bottom_button.dart';

enum _LocationStatus { checking, off, denied, unsupported }

/// Location permission gate — mandatory before photo capture starts. Port of
/// `src/components/modals/LocationModal.jsx`.
class LocationModal extends StatefulWidget {
  const LocationModal({super.key, required this.onAllow});

  final VoidCallback onAllow;

  @override
  State<LocationModal> createState() => _LocationModalState();
}

class _LocationModalState extends State<LocationModal> {
  _LocationStatus _status = _LocationStatus.checking;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _runCheck();
  }

  Future<void> _runCheck() async {
    setState(() {
      _status = _LocationStatus.checking;
      _errorMsg = '';
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _status = _LocationStatus.off;
        _errorMsg =
            "Your phone's Location (GPS) is OFF. Please turn it ON from your phone settings first.";
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _status = _LocationStatus.denied;
        _errorMsg =
            'Location permission is denied for this app. Please allow location access in your device settings and try again.';
      });
      return;
    }

    try {
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      widget.onAllow();
    } catch (_) {
      setState(() {
        _status = _LocationStatus.off;
        _errorMsg =
            "Couldn't get your location. Please make sure GPS / Location Services is turned ON and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChecking = _status == _LocationStatus.checking;
    final isOff = _status == _LocationStatus.off;
    final isDenied = _status == _LocationStatus.denied;
    final isError = isOff || isDenied || _status == _LocationStatus.unsupported;

    String buttonLabel = 'Checking…';
    if (isOff) buttonLabel = "I've Turned It On";
    if (isDenied) buttonLabel = 'Try Again';

    return Container(
      color: AppColors.rotateBg,
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(28),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isError
                    ? const Color(0x26EF4444)
                    : const Color(0x40FF9609),
                border: Border.all(
                  color: isError ? AppColors.statusPending : const Color(0xFFFF9609),
                ),
              ),
              child: Icon(
                Icons.location_on,
                size: 42,
                color: isError ? AppColors.statusPending : const Color(0xFFFF9609),
              ),
            ),
            Text(
              isOff
                  ? 'Turn On Location First'
                  : isDenied
                      ? 'Permission Required'
                      : 'Checking Location',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isError ? AppColors.statusPending : AppColors.locationAccent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isChecking ? 'Please wait while we check your location…' : _errorMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
            ),
            if (isOff) ...[
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: _BulletList(items: [
                  'Open your phone Settings.',
                  'Turn ON Location / GPS.',
                  'Come back and tap "I\'ve Turned It On".',
                ]),
              ),
            ],
            if (isDenied) ...[
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: _BulletList(items: [
                  "Open this app's permissions in your device settings.",
                  'Allow Location access for this app.',
                  'Tap "Try Again" below.',
                ]),
              ),
            ],
            if (!isError && !isChecking)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Location is mandatory to verify inspection time and place.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 16),
            BottomButton(
              label: buttonLabel,
              disabled: isChecking,
              onPressed: isChecking ? null : _runCheck,
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '•  $item',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}
