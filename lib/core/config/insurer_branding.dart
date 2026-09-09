/// Branding for the tie-up insurer whose claims this install handles.
///
/// The header used to render `assets/images/logos/logo.png`, a single bitmap
/// with the insurer and IBima Assist lock-ups baked in side by side — so the
/// insurer could never be changed or hidden. That artwork is now split into
/// [partnerLogoAsset] and the app's own logo, and everything insurer-specific
/// (header logo, "Thank you for reporting..." line) reads from here.
///
/// Set [current] to [none] for an install with no tie-up: the header then
/// shows only the IBima Assist logo and the copy drops the company name,
/// instead of hard-coding one insurer everywhere.
class InsurerBranding {
  const InsurerBranding({this.name, this.logoAsset});

  /// Display name, e.g. `New India Assurance Co. Ltd.`
  final String? name;

  /// Asset path of the insurer's logo shown beside the IBima Assist logo.
  final String? logoAsset;

  /// No tie-up insurer — IBima Assist branding only.
  static const InsurerBranding none = InsurerBranding();

  /// The insurer this build is tied up with. Swap this (or point it at
  /// [none]) per deployment; nothing else needs to change.
  ///
  /// The preinspection app ships with no tie-up: the header shows the IBima
  /// Assist logo alone. Point this back at an [InsurerBranding] with a name
  /// and logo to bring partner branding back.
  static const InsurerBranding current = none;

  bool get hasLogo => logoAsset != null;
  bool get hasName => name != null && name!.isNotEmpty;
}
