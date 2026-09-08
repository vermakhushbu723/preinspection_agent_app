import 'package:flutter/material.dart';

import '../config/insurer_branding.dart';
import '../theme/app_colors.dart';

/// Logo band shown at the top of most screens. Port of
/// `src/components/common/AppHeader.jsx`.
///
/// Renders the tie-up insurer's logo (when [InsurerBranding.current] has one)
/// beside the IBima Assist logo — previously both were baked into a single
/// `logo.png`, which meant the insurer branding could never be swapped out or
/// dropped for an install without a tie-up.
///
/// The web version hides itself on the customer/inspector declaration routes
/// by inspecting the current pathname; here each declaration screen simply
/// omits `AppHeader` from its own layout instead, which is the more idiomatic
/// Flutter equivalent of a route-conditional shared component.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, this.branding = InsurerBranding.current});

  final InsurerBranding branding;

  /// Rendered logo height. Kept compact so the band doesn't eat a third of
  /// the screen before the page content even starts.
  static const double _logoHeight = 44;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.bgApp),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (branding.hasLogo) ...[
                Flexible(
                  child: Image.asset(
                    branding.logoAsset!,
                    height: _logoHeight,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Image.asset(
                  'assets/images/logos/app_logo.png',
                  height: _logoHeight,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Text(
                    'IBima Assist',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_logoHeight + 18);
}
