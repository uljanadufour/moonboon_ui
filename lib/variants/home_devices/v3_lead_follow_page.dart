import 'package:flutter/material.dart';

import '../../theme/theme_colors.dart';
import 'shared.dart';

/// V3 — Lead & Follow · hero + companion (asymmetric)
/// Bet: what you own leads — it takes two thirds of the row as a photo card
/// with a white status band — and what you don't follows as a narrow frosted
/// sliver. Equal when the account is all-or-nothing.
class V3LeadFollowPage extends StatelessWidget {
  final Ownership initial;

  const V3LeadFollowPage({super.key, this.initial = Ownership.none});

  static const double _height = 184;

  @override
  Widget build(BuildContext context) {
    return HomeDevicesPlayground(
      initial: initial,
      title: 'V3',
      sectionBuilder: (context, ownership, onTap) {
        final mixed =
            ownership == Ownership.monitor || ownership == Ownership.bouncer;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: _height,
            child: Row(
              spacing: 8,
              children: [
                // Owned leads on the left; monitor-first otherwise.
                for (final kind in [
                  ...DeviceKind.values.where(ownership.owns),
                  ...DeviceKind.values.where((k) => !ownership.owns(k)),
                ])
                  Expanded(
                    key: ValueKey(kind),
                    flex: mixed ? (ownership.owns(kind) ? 66 : 34) : 50,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, ?current],
                      ),
                      child: ownership.owns(kind)
                          ? _LeadCard(
                              key: const ValueKey('lead'),
                              kind: kind,
                              onTap: () => onTap(kind),
                            )
                          : _FollowCard(
                              key: const ValueKey('follow'),
                              kind: kind,
                              onTap: () => onTap(kind),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LeadCard extends StatelessWidget {
  final DeviceKind kind;
  final VoidCallback onTap;

  const _LeadCard({super.key, required this.kind, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    final isMonitor = kind == DeviceKind.monitor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surfacePrimary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    kind.photo,
                    fit: BoxFit.cover,
                    alignment: isMonitor
                        ? const Alignment(0, -0.35)
                        : const Alignment(0, -0.5),
                  ),
                  if (isMonitor)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeColors.light.surfacePrimary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 5,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: ThemeColors.light.feedbackSuccess,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              'Live',
                              style: t.labelSmall?.copyWith(
                                color: ThemeColors.light.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kind.ownedStatus,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.labelSmall?.copyWith(
                            color: c.textQuaternary,
                          ),
                        ),
                        Text(
                          kind.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.labelLarge?.copyWith(color: c.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: c.textQuaternary,
                    size: 20,
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

class _FollowCard extends StatelessWidget {
  final DeviceKind kind;
  final VoidCallback onTap;

  const _FollowCard({super.key, required this.kind, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.overlayLevel1,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.brandTertiary, width: 1),
        ),
        child: Column(
          children: [
            Expanded(
              child: Frosted(
                sigma: 6,
                veil: 0.3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                  child: Image.asset(
                    kind.packshot,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  Text(
                    kind.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: t.labelMedium?.copyWith(color: c.textTertiary),
                  ),
                  Text(
                    'Tap to set up',
                    textAlign: TextAlign.center,
                    style: t.labelSmall?.copyWith(color: c.textInactive),
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
