import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/theme_colors.dart';

// Ports of the moonboon_app widgets Home draws today (origin/dev), so the
// prototype is built from the same parts, not lookalikes:
//   MyDayRowShell + MyDayTimestampPill  lib/ui/home/new_home/my_day/my_day_row.dart
//   NapSuggestionCard                   lib/ui/home/new_home/my_day/suggestion/nap_suggestion_card.dart
//   _OverviewCard                       lib/ui/home/new_home/my_day/my_day_overview_cards.dart
//   DashedRoundedBorder                 lib/ui/common/dashed_rounded_border.dart
//   Button (custom 28, outlined)        lib/ui/common/button.dart
// Copy and structure follow Figma "Home - IA" › Suggested naps.

// ── Tokens (lib/utilities/theme/tokens) ──────────────────────────────────────

abstract final class AppSpacing {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32;
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
}

abstract final class AppRadius {
  static const double xl = 24;
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(100));
}

abstract final class AppShadow {
  static const List<BoxShadow> sm = [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))];
  static const List<BoxShadow> md = [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4))];
}

abstract final class AppBorder {
  static const double thin = 1;
}

abstract final class AppOpacity {
  static const double medium = 0.5, heavy = 0.7;
}

/// The app's text styles (app_text_styles.dart), which differ from this
/// repo's Material text theme in weights and line heights.
abstract final class AppText {
  static const TextStyle headlineSmall = TextStyle(fontFamily: 'KeplerStd', fontSize: 32, fontWeight: FontWeight.w400, height: 1);
  static const TextStyle headlineMedium = TextStyle(fontFamily: 'KeplerStd', fontSize: 38, fontWeight: FontWeight.w400, height: 36 / 38);
  static const TextStyle titleMedium = TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 28 / 18);
  static const TextStyle bodySmall = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14);
  static const TextStyle labelMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 20 / 14);
  static const TextStyle labelSmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 16 / 12);
}

// ── MyDayRowShell ─────────────────────────────────────────────────────────────

/// One My day row: illustration, label, a quieter detail, a trailing pill.
/// [isPlaceholder] dashes the outline — a slot waiting to be filled, which is
/// how predicted naps are drawn (as in moonboon_app PR #876).
class MyDayRowShell extends StatelessWidget {
  final String icon;
  final String label;
  final String? detail;
  final Widget? trailing;
  final bool isPlaceholder;
  final bool isFramed;
  final VoidCallback? onTap;

  const MyDayRowShell({
    super.key,
    required this.icon,
    required this.label,
    this.detail,
    this.trailing,
    this.isPlaceholder = false,
    this.isFramed = true,
    this.onTap,
  });

  static const double _iconSize = 32;

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final row = Padding(
      padding: AppSpacing.cardPadding,
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          SizedBox(width: _iconSize, height: _iconSize, child: Image.asset(icon, fit: BoxFit.contain)),
          Expanded(
            child: Row(
              spacing: AppSpacing.sm,
              children: [
                Flexible(
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodySmall.copyWith(color: c.textTertiary)),
                ),
                if (detail case final detail?)
                  Text(detail, maxLines: 1, style: AppText.labelSmall.copyWith(color: c.brandSecondary)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
    if (!isFramed) return row;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.overlayLevel2, borderRadius: AppRadius.xlAll),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadius.xlAll,
          onTap: onTap,
          child: isPlaceholder ? DashedRoundedBorder(color: c.borderNormal, child: row) : row,
        ),
      ),
    );
  }
}

/// The row's trailing white pill. [ago] holds "ago" back in a lighter tone,
/// as MyDayTimestampPill does; anything else ("in 1h 30m", "Now",
/// "Not tracked") is one label.
class MyDayPill extends StatelessWidget {
  final String label;
  final bool ago;
  const MyDayPill(this.label, {super.key, this.ago = false});

  /// "1h ago" / "35m ago", rounded the way the app rounds (hours past 60m).
  factory MyDayPill.elapsed(int minutes) =>
      MyDayPill(minutes < 60 ? '${math.max(minutes, 1)}m' : '${minutes ~/ 60}h', ago: true);

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final style = AppText.labelSmall.copyWith(color: c.brandSecondary);
    return Container(
      height: 21,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(color: c.surfacePrimary, borderRadius: AppRadius.pillAll, boxShadow: AppShadow.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: style),
          if (ago) Text(' ago', style: style.copyWith(color: c.brandSecondary.withValues(alpha: AppOpacity.heavy))),
        ],
      ),
    );
  }
}

// ── NapSuggestionCard ─────────────────────────────────────────────────────────

/// The auto-track suggestion card, opened up for predictions: header with ×,
/// the nap on its own white card (an unframed [MyDayRowShell]), and the
/// small Confirm/Adjust-style button pair underneath.
class MyDaySuggestionCard extends StatelessWidget {
  final String title;
  final String detail;
  final Widget trailing;
  final VoidCallback? onDismiss;
  final (String, VoidCallback)? primary;
  final (String, VoidCallback)? secondary;
  final VoidCallback? onOpen;

  const MyDaySuggestionCard({
    super.key,
    required this.title,
    required this.detail,
    required this.trailing,
    this.onDismiss,
    this.primary,
    this.secondary,
    this.onOpen,
  });

  static const double _buttonHeight = 28;
  static const double _dismissTargetSize = 44;

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final hasButtons = primary != null || secondary != null;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.overlayLevel2, borderRadius: AppRadius.xlAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.xs, 0),
            child: Row(
              children: [
                Expanded(child: Text(title, style: AppText.labelSmall.copyWith(color: c.textTertiary))),
                if (onDismiss != null)
                  SizedBox.square(
                    dimension: _dismissTargetSize,
                    child: InkWell(
                      borderRadius: AppRadius.pillAll,
                      onTap: onDismiss,
                      child: Icon(Icons.close_rounded, size: 16, color: c.textTertiary),
                    ),
                  )
                else
                  const SizedBox(height: _dismissTargetSize),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: DecoratedBox(
              decoration: BoxDecoration(color: c.surfacePrimary, borderRadius: AppRadius.xlAll, boxShadow: AppShadow.sm),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: AppRadius.xlAll,
                  onTap: onOpen,
                  child: MyDayRowShell(
                    isFramed: false,
                    icon: 'assets/naps/nap_pillow.png',
                    label: 'Nap',
                    detail: detail,
                    trailing: trailing,
                  ),
                ),
              ),
            ),
          ),
          if (hasButtons)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
              child: Row(
                spacing: AppSpacing.sm,
                children: [
                  if (primary case (final label, final onTap))
                    Expanded(child: SmallButton(label: label, onTap: onTap, height: _buttonHeight)),
                  if (secondary case (final label, final onTap))
                    Expanded(child: SmallButton(label: label, onTap: onTap, height: _buttonHeight, outlined: true)),
                ],
              ),
            )
          else
            const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

/// Button(size: custom) — filled is apricot + textOnCta, outlined is
/// transparent with a borderNormal edge and textPrimary label.
class SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  final double height;
  const SmallButton({super.key, required this.label, required this.onTap, this.outlined = false, this.height = 28});

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    return Material(
      color: outlined ? Colors.transparent : c.surfaceTertiary,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.pillAll,
        side: outlined ? BorderSide(color: c.borderNormal) : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Center(
            child: Text(label, style: AppText.labelMedium.copyWith(color: outlined ? c.textPrimary : c.textOnCta)),
          ),
        ),
      ),
    );
  }
}

// ── Overview cards ────────────────────────────────────────────────────────────

class OverviewCard extends StatelessWidget {
  final String value;
  final String label;
  const OverviewCard({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: c.overlayLevel2,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: c.brandTertiary, width: AppBorder.thin),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicWidth(child: Text(value, style: AppText.headlineSmall.copyWith(color: c.textTertiary))),
          IntrinsicWidth(child: Text(label, style: AppText.labelSmall.copyWith(color: c.textTertiary))),
        ],
      ),
    );
  }
}

// ── DashedRoundedBorder ──────────────────────────────────────────────────────

class DashedRoundedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  const DashedRoundedBorder({super.key, required this.child, required this.color, this.radius = AppRadius.xl, this.strokeWidth = AppBorder.thin});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DashedPainter(color, radius, strokeWidth), child: child);
}

class _DashedPainter extends CustomPainter {
  final Color color;
  final double radius, strokeWidth;
  const _DashedPainter(this.color, this.radius, this.strokeWidth);

  static const double _dash = 6, _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final inset = strokeWidth / 2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth),
        Radius.circular(radius),
      ));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        final e = math.min(d + _dash, m.length);
        canvas.drawPath(m.extractPath(d, e), paint);
        d = e + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter o) => o.color != color || o.radius != radius || o.strokeWidth != strokeWidth;
}
