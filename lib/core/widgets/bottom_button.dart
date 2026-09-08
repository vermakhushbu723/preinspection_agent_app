import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Full-width primary action button pinned at the bottom of a screen.
/// Port of `src/components/common/BottomButton.jsx`.
class BottomButton extends StatelessWidget {
  const BottomButton({
    super.key,
    this.label = 'Next',
    required this.onPressed,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onPressed == null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.btnPrimary,
          disabledBackgroundColor: const Color(0xFF93C5FD).withValues(
            alpha: 0.7,
          ),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
