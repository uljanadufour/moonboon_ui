import 'package:flutter/material.dart';

import '../../theme/theme_colors.dart';
import 'shared.dart';

/// V5 — The Nursery Shelf · spatial, one composed scene
/// Bet: the devices are one system, so show them as one object — a single
/// wide card where both products stand side by side; an unowned product is a
/// soft, out-of-focus silhouette in its place, and tapping it brings it in.
class V5NurseryShelfPage extends StatelessWidget {
  final Ownership initial;

  const V5NurseryShelfPage({super.key, this.initial = Ownership.none});

  @override
  Widget build(BuildContext context) {
    return HomeDevicesPlayground(
      initial: initial,
      title: 'V5',
      showHeading: false,
      sectionBuilder: (context, ownership, onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _Shelf(ownership: ownership, onTap: onTap),
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  final Ownership ownership;
  final void Function(DeviceKind) onTap;

  const _Shelf({required this.ownership, required this.onTap});

  String get _headline => switch (ownership) {
    Ownership.both => 'Vera\'s nursery',
    Ownership.none => 'Vera\'s nursery, waiting',
    _ => 'Vera\'s nursery',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surfacePrimary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          // The shelf the products stand on.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 92,
            child: ColoredBox(color: c.overlayLevel1),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Text(
                  _headline,
                  style: t.headlineSmall?.copyWith(
                    fontSize: 24,
                    color: c.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                height: 236,
                child: Row(
                  children: [
                    for (final kind in DeviceKind.values)
                      Expanded(
                        child: _Spot(
                          kind: kind,
                          owned: ownership.owns(kind),
                          onTap: () => onTap(kind),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Spot extends StatelessWidget {
  final DeviceKind kind;
  final bool owned;
  final VoidCallback onTap;

  const _Spot({required this.kind, required this.owned, required this.onTap});

  String get _cutout => switch (kind) {
    DeviceKind.monitor => 'assets/images/babymonitor_packshot_full.png',
    DeviceKind.bouncer => 'assets/images/motor_premium_packshot.png',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    final product = Image.asset(_cutout, fit: BoxFit.contain);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 480),
                child: owned
                    ? KeyedSubtree(key: const ValueKey('o'), child: product)
                    : Opacity(
                        key: const ValueKey('f'),
                        opacity: 0.55,
                        child: Frosted(sigma: 8, veil: 0, child: product),
                      ),
              ),
            ),
          ),
          Text(
            kind.name,
            style: t.labelLarge?.copyWith(
              color: owned ? c.textTertiary : c.textQuaternary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: owned ? c.surfacePrimary : c.overlayLevel1,
              borderRadius: BorderRadius.circular(100),
              border: owned
                  ? null
                  : Border.all(color: c.brandTertiary, width: 1),
            ),
            child: Text(
              owned ? kind.ownedStatus : 'Tap to set up',
              style: t.labelSmall?.copyWith(
                color: owned ? c.textQuaternary : c.textInactive,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
