import 'package:flutter/material.dart';

import '../../theme/theme_colors.dart';
import 'shared.dart';

/// V4 — The Deck · horizontal carousel of portrait cards
/// Bet: a fixed-height swipeable row of tall photo cards — owned first,
/// unowned frosted and peeking off the edge — keeps home's height the same in
/// every state and scales to a third or fourth device without a new layout.
class V4DeckPage extends StatelessWidget {
  final Ownership initial;

  const V4DeckPage({super.key, this.initial = Ownership.none});

  @override
  Widget build(BuildContext context) {
    return HomeDevicesPlayground(
      initial: initial,
      title: 'V4',
      sectionBuilder: (context, ownership, onTap) {
        final kinds = [
          ...DeviceKind.values.where(ownership.owns),
          ...DeviceKind.values.where((k) => !ownership.owns(k)),
        ];
        final width = MediaQuery.of(context).size.width * 0.62;
        return SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: kinds.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final kind = kinds[i];
              return SizedBox(
                key: ValueKey(kind),
                width: width,
                child: _DeckCard(
                  kind: kind,
                  owned: ownership.owns(kind),
                  onTap: () => onTap(kind),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DeckCard extends StatelessWidget {
  final DeviceKind kind;
  final bool owned;
  final VoidCallback onTap;

  const _DeckCard({
    required this.kind,
    required this.owned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    // The monitor photo carries a baked-in cream frame down its sides;
    // scaling it inside the card's clip crops the frame out.
    final photo = Transform.scale(
      scale: kind == DeviceKind.monitor ? 1.28 : 1,
      child: Image.asset(
        kind.photo,
        fit: BoxFit.cover,
        alignment: kind == DeviceKind.monitor
            ? const Alignment(0, -0.2)
            : const Alignment(0, -0.4),
      ),
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surfacePrimary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, ?current],
              ),
              child: owned
                  ? KeyedSubtree(key: const ValueKey('o'), child: photo)
                  : Frosted(
                      key: const ValueKey('f'),
                      sigma: 12,
                      veil: 0.4,
                      child: photo,
                    ),
            ),
            if (owned)
              const PhotoScrim(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
              ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    owned ? kind.ownedStatus : 'Not set up yet',
                    style: t.labelSmall?.copyWith(
                      color: owned ? onPhoto(0.85) : c.textQuaternary,
                    ),
                  ),
                  Text(
                    kind.name,
                    style: t.headlineSmall?.copyWith(
                      fontSize: 24,
                      color: owned ? onPhoto() : c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!owned)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c.surfacePrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: c.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
