import 'package:flutter/material.dart';

import '../../theme/theme_colors.dart';
import 'plan.dart';
import 'shared.dart';

/// E1 · Next nap (Figma Exploration 1, "Using existing components"): the
/// "Smart nap suggestion" card on top of today's rows, changing in place. If
/// the monitor tracks the nap, its auto-track card replaces it — never both.
class E1NextNapPage extends StatelessWidget {
  final NapPlan? plan;
  const E1NextNapPage({super.key, this.plan});

  @override
  Widget build(BuildContext context) {
    return NapsPlayground(
      plan: plan,
      title: 'E1 · Next nap',
      builder: (context, plan) {
        final card = lifecycleCard(context, plan, e1: true);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (card != null) ...[card, const SizedBox(height: AppSpacing.xs)],
            ...sleptRows(plan),
          ],
        );
      },
    );
  }
}

/// E2 · List (Figma Exploration 2, "A · List overview"): "Coming up" above
/// "Earlier". Predicted naps and bedtime are dashed My day rows (as in
/// moonboon_app PR #876); the nap in its moment becomes the suggestion card.
class E2ListPage extends StatelessWidget {
  final NapPlan? plan;
  const E2ListPage({super.key, this.plan});

  @override
  Widget build(BuildContext context) {
    return NapsPlayground(
      plan: plan,
      title: 'E2 · List',
      builder: (context, plan) {
        final focus = plan.focus;
        final card = lifecycleCard(context, plan);
        final rows = <Widget>[];
        for (final s in plan.slots) {
          final p = plan.phaseOf(s);
          if (s == focus && card != null) {
            rows.add(card);
          } else if (p == Phase.upcoming || p == Phase.window) {
            rows.add(predictedRow(
              plan,
              icon: kPillow,
              label: 'Nap',
              detail: 'around ${hhmm(s.predStart)} · ${dur(s.predLength)}',
              at: s.predStart,
            ));
          } else {
            continue;
          }
          rows.add(const SizedBox(height: AppSpacing.xs));
        }
        final bed = plan.bedtime;
        if (bed > plan.now) {
          rows.add(predictedRow(plan, icon: kMoon, label: 'Bedtime', detail: 'around ${hhmm(bed)}', at: bed));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Label('Coming up'),
            ...rows,
            const SizedBox(height: AppSpacing.lg),
            const _Label('Earlier'),
            ...sleptRows(plan),
          ],
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
    child: Text(text, style: AppText.labelSmall.copyWith(color: context.color.textTertiary)),
  );
}
