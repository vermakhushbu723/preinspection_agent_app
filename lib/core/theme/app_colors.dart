import 'package:flutter/material.dart';

/// Global color palette. Ported 1:1 from the web app's
/// `src/constants/theme.js` so both apps stay visually in sync.
class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFFDAF0FE);
  static const Color primaryLight = Color(0xFF93C5FD);

  // Background colors
  static const Color bgCard = Color(0xFFDAF0FE);
  static const Color bgInput = Color(0x40DEDEDE);
  static const Color bgHeader = Color(0xFF00A0FE);
  static const Color bgPageTitle = Color(0xFF00A0FE);

  /// `linear-gradient(#DAF0FE, #009FFD 0%, #00A2FF 100%)`
  /// The first two colors both sit at the 0% stop in CSS, so the pale tone
  /// only ever shows as a hairline before it snaps to the rich blue.
  static const LinearGradient bgApp = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFDAF0FE), Color(0xFF009FFD), Color(0xFF00A2FF)],
    stops: [0.0, 0.0, 1.0],
  );

  // Button colors
  static const Color btnClaim = Color(0xFFE07B39);
  static const Color btnPreInspection = Color(0xFF4F46E5);
  static const Color btnPrimary = Color(0xFF01A0FE);
  static const Color btnCamera = Color(0xFF3B82F6);
  static const Color btnGallery = Color(0xFF3B82F6);

  // Status / Badge colors
  static const Color statusPending = Color(0xFFEF4444);
  static const Color statusCompleted = Color(0xFF22C55E);

  // Stats card colors
  static const LinearGradient cardTotalClaims = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2146B8), Color(0xFF1CA6D4)],
  );
  static const LinearGradient cardSurveyCompleted = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA1FF91), Color(0xFF8DFF7A)],
  );
  static const Color cardPendingSurvey = Color(0xFFFF7870);
  static const LinearGradient cardSearchClaim = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA588FF), Color(0xFF865FFF)],
  );

  // Text colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textBlue = Color(0xFF3B82F6);
  static const Color textOrange = Color(0xFFE07B39);
  static const Color textGreen = Color(0xFF22C55E);
  static const Color textRed = Color(0xFFEF4444);

  // Border colors
  static const Color borderLight = Color(0xFF000000);
  static const Color borderInput = Color(0xFFC5C5C5);

  // Icon accent colors
  static const Color iconClaim = Color(0xFF7C3AED);
  static const Color iconDL = Color(0xFFEF4444);
  static const Color iconRC = Color(0xFF16A34A);
  static const Color iconRepair = Color(0xFFEA580C);
  static const Color iconKYC = Color(0xFF0EA5E9);
  static const Color iconPhone = Color(0xFF0EA5E9);

  // Overlay
  static const Color overlay = Color(0x80000000);

  // Rotate / Location modal
  static const Color rotateBg = Color(0xFF3B82F6);
  static const Color rotateAccent = Color(0xFF00A0FE);
  static const Color locationAccent = Color(0xFFFF9609);
}

/// Border radii, ported from `RADIUS` in theme.js.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;
}
