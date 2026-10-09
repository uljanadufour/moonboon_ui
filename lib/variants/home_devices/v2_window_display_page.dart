import 'package:flutter/material.dart';

import '../../theme/theme_colors.dart';
import 'shared.dart';
import 'v1_frosted_pair_page.dart';

/// V2 — The Window Display · stacked full-width, full-bleed imagery
/// Bet: an unowned device deserves a shop window, not a slot — owned devices
/// collapse to compact working rows, unowned ones are a tall blurred photo
/// with a single serif promise you tap to step into.
class V2WindowDisplayPage extends StatelessWidget {
  final Ownership initial;

  const V2WindowDisplayPage({super.key, this.initial = Ownership.none});

  @override
  Widget build(BuildContext context) {
    return HomeDevicesPlayground(
      initial: initial,
      title: 'V2',
      sectionBuilder: (context, ownership, onTap) {
        // Owned first: what you use daily sits above what you could add.
        final kinds = [
          ...DeviceKind.values.where(ownership.owns),
          ...DeviceKind.values.where((k) => !ownership.owns(k)),
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            spacing: 8,
            children: [
              for (final kind in kinds)
                AnimatedSwitcher(
                  key: ValueKey(kind),
                  duration: const Duration(milliseconds: 380),
                  child: ownership.owns(kind)
                      ? CompactDeviceCard(
                          key: const ValueKey('owned'),
                          kind: kind,
                          owned: true,
                          onTap: () => onTap(kind),
                        )
                      : _WindowCard(
                          key: const ValueKey('window'),
                          kind: kind,
                          onTap: () => onTap(kind),
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WindowCard extends StatelessWidget {
  final DeviceKind kind;
  final VoidCallback onTap;

  const _WindowCard({super.key, required this.kind, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 196,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surfacePrimary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Frosted(
              sigma: 7,
              veil: 0.5,
              child: Image.asset(
                kind.photo,
                fit: BoxFit.cover,
                alignment: kind == DeviceKind.monitor
                    ? const Alignment(0, -0.3)
                    : const Alignment(0, -0.55),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: Column(
                children: [
                  Text(
                    kind.name.toUpperCase(),
                    style: t.labelSmall?.copyWith(
                      color: c.textQuaternary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    kind.promise,
                    textAlign: TextAlign.center,
                    style: t.headlineSmall?.copyWith(
                      fontSize: 26,
                      height: 1.1,
                      color: c.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Text(
                        'Tap to set up',
                        style: t.labelMedium?.copyWith(color: c.textTertiary),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: c.textTertiary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
