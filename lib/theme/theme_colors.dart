import 'package:flutter/material.dart';

class ThemeColors {
  final Color brandPrimary;
  final Color brandSecondary;
  final Color brandTertiary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textQuaternary;
  final Color textInverse;
  final Color textInactive;
  /// Label on the apricot CTA surface (surfaceTertiary): black in both themes.
  final Color textOnCta;
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color surfaceTertiary;
  final Color surfaceQuaternary;
  final Color surfaceSubdued;
  final Color borderSubdued;
  final Color borderNormal;
  final Color borderStrong;
  final Color feedbackError;
  final Color feedbackSuccess;
  final Color feedbackInfo;
  final Color overlayLevel1;
  final Color overlayLevel2;
  final Color overlayBrand;
  final Color overlayNavButton;

  const ThemeColors({
    required this.brandPrimary,
    required this.brandSecondary,
    required this.brandTertiary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textQuaternary,
    required this.textInverse,
    required this.textInactive,
    this.textOnCta = const Color(0xFF010101),
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.surfaceTertiary,
    required this.surfaceQuaternary,
    required this.surfaceSubdued,
    required this.borderSubdued,
    required this.borderNormal,
    required this.borderStrong,
    required this.feedbackError,
    required this.feedbackSuccess,
    required this.feedbackInfo,
    required this.overlayLevel1,
    required this.overlayLevel2,
    required this.overlayBrand,
    required this.overlayNavButton,
  });

  // Light — matches production moonboon_app ThemeColors.light exactly
  static const ThemeColors light = ThemeColors(
    brandPrimary:      Color(0xFFB59E85), // clay
    brandSecondary:    Color(0xFF70695F), // olive
    brandTertiary:     Color(0xFFE5D5C5), // mutedApricot
    textPrimary:       Color(0xFF010101), // black
    textSecondary:     Color(0xFF464545), // obsadianGrey
    textTertiary:      Color(0xFF70695F), // olive
    textQuaternary:    Color(0xFFB59E85), // clay
    textInverse:       Color(0xFFFFFEFD), // white
    textInactive:      Color(0xFFCDCDCD),
    surfacePrimary:    Color(0xFFFFFEFD), // white
    surfaceSecondary:  Color(0xFFF1E8DE), // creme
    surfaceTertiary:   Color(0xFFE5D5C5), // mutedApricot
    surfaceQuaternary: Color(0xFFE5D5C5), // mutedApricot (same as tertiary in light)
    surfaceSubdued:    Color(0x80F5E6D3), // mutedApricot @50%
    borderSubdued:     Color(0xFFF1E8DE), // creme
    borderNormal:      Color(0xFFDDD6CC), // stone
    borderStrong:      Color(0xFF70695F), // olive
    feedbackError:     Color(0xFFB94A48),
    feedbackSuccess:   Color(0xFF5E8A66),
    feedbackInfo:      Color(0xFF4A6A85),
    overlayLevel1:     Color(0x33FFFFFF), // white @20%
    overlayLevel2:     Color(0x80FFFFFF), // white @50%
    overlayBrand:      Color(0x80E5D5C5), // mutedApricot @50%
    overlayNavButton:  Color(0xE6F1E8DE), // creme @90%
  );

  static const ThemeColors dark = ThemeColors(
    brandPrimary:      Color(0xFFB59E85),
    brandSecondary:    Color(0xFFE5D5C5),
    brandTertiary:     Color(0xFF70695F),
    textPrimary:       Color(0xFFF5F3F1),
    textSecondary:     Color(0xFFC4AA8E),
    textTertiary:      Color(0xFF8C8178),
    textQuaternary:    Color(0xFF8C8178),
    textInverse:       Color(0xFF1A1008),
    textInactive:      Color(0xFF707070),
    surfacePrimary:    Color(0xFF0F0D0B),
    surfaceSecondary:  Color(0xFF1E1A16),
    surfaceTertiary:   Color(0xFF2E2820), // barely lifts off page — the problem
    surfaceQuaternary: Color(0xFF3D352C),
    surfaceSubdued:    Color(0xFF070503),
    borderSubdued:     Color(0xFF2E2820),
    borderNormal:      Color(0xFFB59E85),
    borderStrong:      Color(0xFFB59E85),
    feedbackError:     Color(0xFFEF5350),
    feedbackSuccess:   Color(0xFF66BB6A),
    feedbackInfo:      Color(0xFF5B86A3),
    overlayLevel1:     Color(0x33000000),
    overlayLevel2:     Color(0x80000000),
    overlayBrand:      Color(0x80B59E85),
    overlayNavButton:  Color(0xE60F0D0B),
  );

  // Variant B — stronger lift + warmer midtones: more contrast throughout
  static const ThemeColors darkVariantB = ThemeColors(
    brandPrimary:      Color(0xFFB59E85),
    brandSecondary:    Color(0xFFE5D5C5),
    brandTertiary:     Color(0xFF70695F),
    textPrimary:       Color(0xFFF5F3F1),
    textSecondary:     Color(0xFFD4C4A8), // brighter — body text more legible
    textTertiary:      Color(0xFFA09688), // brighter
    textQuaternary:    Color(0xFF9C8878),
    textInverse:       Color(0xFF1A1008),
    textInactive:      Color(0xFF707070),
    surfacePrimary:    Color(0xFF0F0D0B),
    surfaceSecondary:  Color(0xFF1E1A16),
    surfaceTertiary:   Color(0xFF5C4E42), // warm mid-brown — CTAs unmistakeable
    surfaceQuaternary: Color(0xFF746257), // light enough to feel elevated
    surfaceSubdued:    Color(0xFF070503),
    borderSubdued:     Color(0xFF3D352C),
    borderNormal:      Color(0xFFB59E85),
    borderStrong:      Color(0xFFC4AA8E),
    feedbackError:     Color(0xFFEF5350),
    feedbackSuccess:   Color(0xFF66BB6A),
    feedbackInfo:      Color(0xFF5B86A3),
    overlayLevel1:     Color(0x33000000),
    overlayLevel2:     Color(0x80000000),
    overlayBrand:      Color(0x80B59E85),
    overlayNavButton:  Color(0xE60F0D0B),
  );

  // Variant C — max CTA contrast + subtle track ring (best of both worlds)
  // surfaceTertiary: near-sand buttons, unmistakeable against near-black
  // surfaceQuaternary: stays close to base Dark so loader track ring is subtle but present
  static const ThemeColors darkVariantC = ThemeColors(
    brandPrimary:      Color(0xFFB59E85),
    brandSecondary:    Color(0xFFE5D5C5),
    brandTertiary:     Color(0xFF70695F),
    textPrimary:       Color(0xFFF5F3F1),
    textSecondary:     Color(0xFFE5D5C5), // = moonboon_app origin/dev dark
    textTertiary:      Color(0xFFA09688),
    textQuaternary:    Color(0xFF9C8878),
    textInverse:       Color(0xFF1A1008),
    textInactive:      Color(0xFF707070),
    surfacePrimary:    Color(0xFF0F0D0B),
    surfaceSecondary:  Color(0xFF1E1A16),
    surfaceTertiary:   Color(0xFFE5D5C5), // = moonboon_app origin/dev dark
    surfaceQuaternary: Color(0xFF3D352C), // base Dark value — track ring subtle but visible
    surfaceSubdued:    Color(0xFF070503),
    borderSubdued:     Color(0xFF3D352C),
    borderNormal:      Color(0xFFB59E85),
    borderStrong:      Color(0xFFD4C4A8),
    feedbackError:     Color(0xFFEF5350),
    feedbackSuccess:   Color(0xFF66BB6A),
    feedbackInfo:      Color(0xFF5B86A3),
    overlayLevel1:     Color(0x33000000),
    overlayLevel2:     Color(0x80000000),
    overlayBrand:      Color(0x80B59E85),
    overlayNavButton:  Color(0xE60F0D0B),
  );

  // Dark Original — token mapping live in production before Variant C was adopted
  // Sourced from moonboon_app git @ ff81aa89~1 (lib/utilities/theme/theme_colors.dart)
  static const ThemeColors darkOriginal = ThemeColors(
    brandPrimary:      Color(0xFFB59E85), // clay
    brandSecondary:    Color(0xFFE5D5C5), // mutedApricot
    brandTertiary:     Color(0xFF70695F), // olive
    textPrimary:       Color(0xFFFFFEFD), // white
    textSecondary:     Color(0xFFB59E85), // clay
    textTertiary:      Color(0xFF70695F), // olive
    textQuaternary:    Color(0xFF464545), // obsadianGrey
    textInverse:       Color(0xFF010101), // black
    textInactive:      Color(0xFF707070),
    surfacePrimary:    Color(0xFF010101), // black
    surfaceSecondary:  Color(0xFF292929), // offBlack
    surfaceTertiary:   Color(0xFF464545), // obsadianGrey
    surfaceQuaternary: Color(0xFF70695F), // olive
    surfaceSubdued:    Color(0x80F5E6D3), // mutedApricot @50%
    borderSubdued:     Color(0xFF464545), // obsadianGrey
    borderNormal:      Color(0xFFB59E85), // clay
    borderStrong:      Color(0xFFB59E85), // clay
    feedbackError:     Color(0xFFEF5350),
    feedbackSuccess:   Color(0xFF66BB6A),
    feedbackInfo:      Color(0xFF5B86A3),
    overlayLevel1:     Color(0x33000000),
    overlayLevel2:     Color(0x80000000),
    overlayBrand:      Color(0x8070695F), // olive @50%
    overlayNavButton:  Color(0xE6292929), // offBlack @90%
  );
}

// Wraps ThemeColors as a Flutter ThemeExtension so context.color works with any variant
class ThemeColorsData extends ThemeExtension<ThemeColorsData> {
  final ThemeColors colors;
  const ThemeColorsData(this.colors);

  @override
  ThemeColorsData copyWith({ThemeColors? colors}) =>
      ThemeColorsData(colors ?? this.colors);

  @override
  ThemeColorsData lerp(ThemeExtension<ThemeColorsData>? other, double t) => this;
}

extension ThemeColorsExtension on BuildContext {
  ThemeColors get color =>
      Theme.of(this).extension<ThemeColorsData>()?.colors ??
      (Theme.of(this).brightness == Brightness.dark
          ? ThemeColors.dark
          : ThemeColors.light);
}
