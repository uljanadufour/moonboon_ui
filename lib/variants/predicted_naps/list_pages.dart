import 'package:flutter/material.dart';

import '../../theme/theme_colors.dart';
import 'plan.dart';
import 'shared.dart';

/// E1 · Next nap — existing components only. The "Smart nap suggestion" card
/// sits on top of today's list and walks through the nap's life in place.
class E1NextNapPage extends StatelessWidget {
  final NapPlan? plan;
  const E1NextNapPage({super.key, this.plan});

  @override
  Widget build(BuildContext context) {
    return NapsPlayground(
      plan: plan,
      title: 'E1 · Next nap card',
      builder: (context, plan) {
        final card = lifecycleCard(context, plan, showUpcoming: true);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (card != null) ...[card, const SizedBox(height: 12)],
            ...sleptRows(plan),
          ],
        );
      },
    );
  }
}

/// E2 · List — the rest of the day joins the list as "Coming up": dashed
/// predicted rows, the nap in focus turns into the lifecycle card in place.
class E2ListPage extends StatelessWidget {
  final NapPlan? plan;
  const E2ListPage({super.key, this.plan});

  @override
  Widget build(BuildContext context) {
    return NapsPlayground(
      plan: plan,
      title: 'E2 · Coming up list',
      builder: (context, plan) {
        final focus = plan.focus;
        final card = lifecycleCard(context, plan);
        final rows = <Widget>[];
        for (final s in plan.slots) {
          final p = plan.phaseOf(s);
          if (s == focus && card != null) {
            rows.add(card);
          } else if (p == Phase.upcoming || p == Phase.window) {
            rows.add(
              EventRow(
                asset: kPillow,
                title: 'Nap',
                detail: 'around ${hhmm(s.predStart)} · ${dur(s.predLength)}',
                trailing: 'in ${short(s.predStart - plan.now)}',
                style: s == focus ? RowStyle.focus : RowStyle.predicted,
              ),
            );
          } else {
            continue;
          }
          rows.add(const SizedBox(height: 8));
        }
        final bed = plan.bedtime;
        if (bed > plan.now) {
          rows.add(
            EventRow(
              asset: kMoon,
              title: 'Bedtime',
              detail: 'around ${hhmm(bed)}',
              trailing: 'in ${short(bed - plan.now)}',
              style: focus == null ? RowStyle.focus : RowStyle.predicted,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Label('Coming up'),
            ...rows,
            const SizedBox(height: 16),
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
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.color.textQuaternary),
    ),
  );
}
