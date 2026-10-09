import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/theme_colors.dart';
import 'shared.dart';

/// V1 — The Frosted Pair · card grid (2-up, production card)
/// Bet: change nothing but the rule — the two production cards are always
/// there, side by side, and a device you don't own is the same card, frosted.
class V1FrostedPairPage extends StatelessWidget {
  final Ownership initial;

  const V1FrostedPairPage({super.key, this.initial = Ownership.none});

  @override
  Widget build(BuildContext context) {
    return HomeDevicesPlayground(
      initial: initial,
      title: 'V1',
      sectionBuilder: (context, ownership, onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          spacing: 8,
          children: [
            for (final kind in DeviceKind.values)
              Expanded(
                child: CompactDeviceCard(
                  kind: kind,
                  owned: ownership.owns(kind),
                  onTap: () => onTap(kind),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The production new-home card (106pt, artwork cropped by the edges) with an
/// unowned state: artwork frosted, idle outline, "Tap to set up" as the status.
class CompactDeviceCard extends StatelessWidget {
  final DeviceKind kind;
  final bool owned;
  final VoidCallback onTap;

  const CompactDeviceCard({
    super.key,
    required this.kind,
    required this.owned,
    required this.onTap,
  });

  static const double height = 106;
  static const double _labelInset = 14;

  // Production geometry from new_home_monitor_card / new_home_motor_card.
  ({Size size, double right, double top, double minLeft}) get _geometry =>
      switch (kind) {
        DeviceKind.monitor => (
          size: const Size(123, 153),
          right: 3,
          top: -14,
          minLeft: 64,
        ),
        DeviceKind.bouncer => (
          size: const Size(210, 263),
          right: -37,
          top: -73,
          minLeft: 31,
        ),
      };

  /// The owned monitor streams into its card, as in production.
  bool get _isLive => owned && kind == DeviceKind.monitor;

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    final g = _geometry;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: owned ? c.surfacePrimary : c.overlayLevel1,
          borderRadius: BorderRadius.circular(24),
          border: owned ? null : Border.all(color: c.brandTertiary, width: 1),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final left = math.max(
              constraints.maxWidth - g.size.width - g.right,
              g.minLeft,
            );
            final artwork = Image.asset(kind.packshot, fit: BoxFit.cover);
            return Stack(
              children: [
                Positioned(
                  left: left,
                  top: g.top,
                  width: g.size.width,
                  height: g.size.height,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    child: owned
                        ? KeyedSubtree(key: const ValueKey('o'), child: artwork)
                        : Opacity(
                            key: const ValueKey('f'),
                            opacity: 0.6,
                            child: Frosted(sigma: 6, veil: 0, child: artwork),
                          ),
                  ),
                ),
                if (_isLive) ...[
                  Positioned.fill(
                    child: Image.asset(
                      kind.photo,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.35),
                    ),
                  ),
                  const Positioned.fill(child: PhotoScrim()),
                ],
                Positioned(
                  left: _labelInset,
                  top: _labelInset,
                  width: _isLive
                      ? constraints.maxWidth - _labelInset * 2
                      : math.max(103, left - _labelInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kind.name,
                        maxLines: 2,
                        style: t.labelLarge?.copyWith(
                          color: _isLive ? onPhoto() : c.textTertiary,
                        ),
                      ),
                      Text(
                        owned ? kind.ownedStatus : 'Tap to set up',
                        style: t.bodySmall?.copyWith(
                          color: _isLive
                              ? onPhoto(0.8)
                              : owned
                              ? c.textQuaternary
                              : c.textInactive,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
