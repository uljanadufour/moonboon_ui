import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../theme/theme_colors.dart';
import '../home_devices/shared.dart' show DeviceKind;
import '../home_devices/v1_frosted_pair_page.dart' show CompactDeviceCard;
import 'plan.dart';

/// App-wide dark switch the prototype bar can flip (main.dart listens).
final ValueNotifier<bool> appDark = ValueNotifier<bool>(false);

const String kPillow = 'assets/naps/nap_pillow.png';
const String kMoon = 'assets/naps/bedtime_moon.png';
const String kSun = 'assets/naps/woke_up_sun.png';

// ── Playground: prototype bar + Home around a version's sleep section ────────

/// Mock new Home (avatar + wordmark, devices, the day section, + button) with a
/// prototype bar on top to jump the simulated clock and flip the theme.
class NapsPlayground extends StatefulWidget {
  final String title;
  final String sectionTitle;
  final NapPlan? plan;
  final Widget Function(BuildContext context, NapPlan plan) builder;

  const NapsPlayground({
    super.key,
    required this.title,
    required this.builder,
    this.sectionTitle = 'Sleep patterns',
    this.plan,
  });

  /// Screenshot remote: where the scroll view starts.
  static double initialScroll = 0;

  @override
  State<NapsPlayground> createState() => _NapsPlaygroundState();
}

class _NapsPlaygroundState extends State<NapsPlayground> {
  late final NapPlan _plan = widget.plan ?? NapPlan();
  final _scroll = ScrollController(initialScrollOffset: NapsPlayground.initialScroll);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: c.surfaceSecondary,
      body: ListenableBuilder(
        listenable: _plan,
        builder: (context, _) => Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _ProtoBar(title: widget.title, plan: _plan),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _HomeAppBar(),
                          const _DevicesSection(),
                          const SizedBox(height: 28),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
                            child: Text(
                              widget.sectionTitle,
                              style: t.titleMedium?.copyWith(color: c.textTertiary),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: StatPills(plan: _plan),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: widget.builder(context, _plan),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(right: 24, bottom: 40, child: _PlusButton(plan: _plan)),
          ],
        ),
      ),
    );
  }
}

class _ProtoBar extends StatelessWidget {
  final String title;
  final NapPlan plan;
  const _ProtoBar({required this.title, required this.plan});

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    Widget chip(String label, bool on, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: on ? c.textTertiary : c.overlayBrand,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: t.labelSmall?.copyWith(color: on ? c.textInverse : c.textTertiary),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 0, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: c.textTertiary, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Text(
                  title,
                  style: t.labelMedium?.copyWith(color: c.textTertiary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Now ${hhmm(plan.now)}',
                style: t.labelMedium?.copyWith(color: c.textPrimary),
              ),
              const SizedBox(width: 6),
              _MiniIcon(
                icon: Icons.add_alarm_rounded,
                tooltip: '+15 min',
                onTap: () => plan.setNow(plan.now + 15),
              ),
              _MiniIcon(
                icon: Icons.restart_alt_rounded,
                tooltip: 'Reset',
                onTap: plan.reset,
              ),
              ValueListenableBuilder(
                valueListenable: appDark,
                builder: (_, dark, _) => _MiniIcon(
                  icon: dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  tooltip: 'Theme',
                  onTap: () => appDark.value = !dark,
                ),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              spacing: 6,
              children: [
                for (final (m, label) in NapPlan.moments)
                  chip('${hhmm(m)} · $label', plan.now == m, () => plan.setNow(m)),
                chip('Monitor detects nap', false, plan.monitorDetects),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _MiniIcon({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    icon: Icon(icon, size: 20, color: context.color.textTertiary),
    onPressed: onTap,
  );
}

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          ClipOval(
            child: Container(
              width: 40,
              height: 40,
              color: c.surfaceTertiary,
              child: Image.asset('assets/naps/avatar_bunny.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 24),
          Image.asset('assets/naps/moonboon_wordmark.png', height: 22, color: c.textPrimary),
        ],
      ),
    );
  }
}

class _DevicesSection extends StatelessWidget {
  const _DevicesSection();

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 24, 10),
          child: Row(
            children: [
              Expanded(
                child: Text('Devices', style: t.titleMedium?.copyWith(color: c.textTertiary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: c.surfaceTertiary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('Add', style: t.labelSmall?.copyWith(color: c.textOnCta)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            spacing: 8,
            children: [
              for (final kind in DeviceKind.values.reversed)
                Expanded(
                  child: CompactDeviceCard(kind: kind, owned: true, onTap: () {}),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The + button. While a nap runs from the app it becomes the ongoing pill.
class _PlusButton extends StatelessWidget {
  final NapPlan plan;
  const _PlusButton({required this.plan});

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    final running = plan.slots.where((s) => plan.phaseOf(s) == Phase.running).firstOrNull;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: running == null ? 0 : 18),
      constraints: const BoxConstraints(minWidth: 56),
      decoration: BoxDecoration(
        color: c.surfacePrimary,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.dark.surfacePrimary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: running == null
          ? Icon(Icons.add, color: c.textPrimary)
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Image.asset(kPillow, width: 20),
                Text(
                  'Napping · ${short(plan.now - running.start!)}',
                  style: t.labelMedium?.copyWith(color: c.textPrimary),
                ),
              ],
            ),
    );
  }
}

// ── Building blocks shared by the versions ──────────────────────────────────

class StatPills extends StatelessWidget {
  final NapPlan plan;
  const StatPills({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final napped = plan.timeNapped;
    final h = napped ~/ 60, m = napped % 60;
    return Row(
      spacing: 8,
      children: [
        Expanded(flex: 12, child: _Pill(value: h > 0 ? '${h}h ${m}m' : '${m}m', label: 'Time napped')),
        Expanded(flex: 11, child: _Pill(value: '${NapPlan.nightWakings}', label: 'Night wakings')),
        Expanded(flex: 10, child: _Pill(value: '${plan.napCount}', label: 'Naps')),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String value;
  final String label;
  const _Pill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: c.overlayLevel2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: t.headlineSmall?.copyWith(fontSize: 26, color: c.textTertiary),
          ),
          const SizedBox(height: 2),
          Text(label, style: t.labelSmall?.copyWith(fontSize: 11, color: c.textQuaternary)),
        ],
      ),
    );
  }
}

/// How a row is drawn: a real event, a prediction, or the one in focus.
enum RowStyle { slept, predicted, focus, live }

/// The Home event row: illustration, title, quiet detail, trailing chip.
class EventRow extends StatelessWidget {
  final String asset;
  final String title;
  final String detail;
  final String trailing;
  final RowStyle style;
  final VoidCallback? onTap;

  const EventRow({
    super.key,
    required this.asset,
    required this.title,
    required this.detail,
    required this.trailing,
    this.style = RowStyle.slept,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    final predicted = style == RowStyle.predicted || style == RowStyle.focus;
    final row = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: switch (style) {
          RowStyle.slept => c.overlayLevel2,
          RowStyle.predicted => Colors.transparent,
          RowStyle.focus => c.overlayLevel2,
          RowStyle.live => c.surfacePrimary,
        },
        borderRadius: BorderRadius.circular(18),
        border: style == RowStyle.live ? Border.all(color: c.borderNormal) : null,
      ),
      child: Row(
        children: [
          Opacity(opacity: style == RowStyle.predicted ? 0.6 : 1, child: Image.asset(asset, width: 22)),
          const SizedBox(width: 10),
          Text(title, style: t.labelMedium?.copyWith(color: c.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall?.copyWith(fontSize: 12, color: c.textQuaternary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: predicted ? Colors.transparent : c.surfaceSecondary,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              trailing,
              style: t.labelSmall?.copyWith(fontSize: 11, color: c.textTertiary),
            ),
          ),
        ],
      ),
    );
    final framed = predicted
        ? DashedBorder(
            radius: 18,
            color: style == RowStyle.focus ? c.brandPrimary : c.borderNormal,
            child: row,
          )
        : row;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: framed);
  }
}

/// Small action pill pair used by every lifecycle card.
class ActionPair extends StatelessWidget {
  final String primary;
  final String secondary;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const ActionPair({
    super.key,
    required this.primary,
    required this.secondary,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Expanded(child: PillButton(label: primary, onTap: onPrimary)),
        Expanded(child: PillButton(label: secondary, onTap: onSecondary, ghost: true)),
      ],
    );
  }
}

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool ghost;
  final double height;

  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.ghost = false,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ghost ? c.surfacePrimary : c.surfaceTertiary,
          borderRadius: BorderRadius.circular(100),
          border: ghost ? Border.all(color: c.borderSubdued) : null,
        ),
        child: Text(
          label,
          style: t.labelMedium?.copyWith(color: ghost ? c.textQuaternary : c.textOnCta),
        ),
      ),
    );
  }
}

/// The "Smart nap suggestion" card pattern (same as auto-track): a small
/// header with ×, the nap row inside, and optional actions and a hint.
class SuggestionCard extends StatelessWidget {
  final String header;
  final VoidCallback? onClose;
  final Widget row;
  final Widget? actions;
  final String? hint;
  final bool solid;

  const SuggestionCard({
    super.key,
    required this.header,
    required this.row,
    this.onClose,
    this.actions,
    this.hint,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    final body = Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      decoration: BoxDecoration(
        color: c.overlayLevel2,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: Text(header, style: t.labelSmall?.copyWith(color: c.textQuaternary)),
              ),
              if (onClose != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 18, color: c.textTertiary),
                  onPressed: onClose,
                )
              else
                const SizedBox(height: 40),
            ],
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            decoration: BoxDecoration(
              color: c.surfacePrimary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                row,
                if (actions != null)
                  Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 10), child: actions),
              ],
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
              child: Text(hint!, style: t.labelSmall?.copyWith(fontSize: 11, color: c.textQuaternary)),
            ),
        ],
      ),
    );
    return solid ? body : DashedBorder(radius: 22, color: c.borderNormal, child: body);
  }
}

/// Inner row of a [SuggestionCard] (no fill: the card provides it).
class CardRow extends StatelessWidget {
  final String asset;
  final String title;
  final String detail;
  final String trailing;
  const CardRow({super.key, required this.asset, required this.title, required this.detail, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          const SizedBox(width: 14),
          Image.asset(asset, width: 22),
          const SizedBox(width: 10),
          Text(title, style: t.labelMedium?.copyWith(color: c.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(detail,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(fontSize: 12, color: c.textQuaternary)),
          ),
          Text(trailing, style: t.labelSmall?.copyWith(fontSize: 11, color: c.textTertiary)),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

/// The lifecycle card for the nap in focus, shared by every version: the same
/// pattern as the auto-track suggestion, so parents learn one way to confirm.
/// Returns null when there's nothing to act on (an upcoming nap).
Widget? lifecycleCard(BuildContext context, NapPlan plan, {bool showUpcoming = false}) {
  final s = plan.focus;
  if (s == null) return null;
  final n = plan.now;
  final name = NapPlan.baby;
  switch (plan.phaseOf(s)) {
    case Phase.upcoming:
      if (!showUpcoming) return null;
      return SuggestionCard(
        header: s.snoozes > 0 ? 'Next nap · moved later' : 'Smart nap suggestion',
        onClose: () => plan.skip(s),
        row: CardRow(
          asset: kPillow,
          title: 'Nap',
          detail: '(${hhmm(s.predStart)} · ${dur(s.predLength)})',
          trailing: 'in ${short(s.windowStart - n > 0 ? s.predStart - n : 0)}',
        ),
      );
    case Phase.window:
      return SuggestionCard(
        header: 'Nap window now · ${hhmm(s.windowStart)} – ${hhmm(s.windowEnd)}',
        onClose: () => plan.skip(s),
        row: CardRow(
          asset: kPillow,
          title: 'Nap',
          detail: '(around ${hhmm(s.predStart)} · ${dur(s.predLength)})',
          trailing: 'Now',
        ),
        actions: ActionPair(
          primary: 'Start nap',
          secondary: 'Not yet',
          onPrimary: () => plan.startNap(s),
          onSecondary: () => plan.notYet(s),
        ),
      );
    case Phase.running:
      return SuggestionCard(
        solid: true,
        header: 'Napping now',
        row: CardRow(
          asset: kPillow,
          title: 'Nap',
          detail: 'since ${hhmm(s.start!)} · likely until ${hhmm(r5(s.start! + s.predLength))}',
          trailing: short(n - s.start!),
        ),
        actions: PillButton(label: '$name woke up', onTap: () => plan.wokeUpNow(s)),
      );
    case Phase.autoRunning:
      return SuggestionCard(
        solid: true,
        header: 'Auto tracking with monitor',
        row: CardRow(
          asset: kPillow,
          title: 'Nap',
          detail: 'since ${hhmm(s.start!)} · likely until ${hhmm(s.predEnd)}',
          trailing: short(n - s.start!),
        ),
      );
    case Phase.askConfirm:
      return SuggestionCard(
        header: 'Did $name nap around ${hhmm(s.predStart)}?',
        onClose: () => plan.skip(s),
        row: CardRow(
          asset: kPillow,
          title: 'Nap',
          detail: '(${hhmm(s.predStart)} – ${hhmm(s.predEnd)} · ${dur(s.predLength)})',
          trailing: 'Not tracked',
        ),
        actions: ActionPair(
          primary: 'Confirm',
          secondary: 'Adjust',
          onPrimary: () => plan.confirm(s),
          onSecondary: () => showAdjustSheet(context, plan, s),
        ),
        hint: "× if $name didn't nap. We'll replan her afternoon.",
      );
    case Phase.autoReview:
      return SuggestionCard(
        header: 'Auto tracked with monitor',
        onClose: () => plan.skip(s),
        row: CardRow(
          asset: kPillow,
          title: 'Nap',
          detail: '(${hhmm(s.start!)} – ${hhmm(s.end!)} · ${dur(s.end! - s.start!)})',
          trailing: '${short(n - s.end!)} ago',
        ),
        actions: ActionPair(
          primary: 'Confirm',
          secondary: 'Adjust',
          onPrimary: () => plan.confirm(s),
          onSecondary: () => showAdjustSheet(context, plan, s),
        ),
      );
    case Phase.done:
    case Phase.skipped:
      return null;
  }
}

/// Rows for what's been slept today, newest first.
List<Widget> sleptRows(NapPlan plan, {int? limit}) {
  final list = plan.slept.where((s) => s.end <= plan.now || s.kind == 'Night sleep').toList();
  return [
    for (final s in limit == null ? list : list.take(limit))
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: EventRow(
          asset: s.kind == 'Nap' ? kPillow : kMoon,
          title: s.kind,
          detail: s.kind == 'Nap' ? '${hhmm(s.start)} – ${hhmm(s.end)} · ${dur(s.length)}' : dur(s.length),
          trailing: '${short(plan.now - s.end)} ago',
        ),
      ),
  ];
}

/// The existing nap review sheet, pre-filled with the predicted times.
Future<void> showAdjustSheet(BuildContext context, NapPlan plan, NapSlot s) {
  var start = s.start ?? s.predStart;
  var end = s.end ?? s.predEnd;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: ThemeColors.dark.surfaceSecondary.withValues(alpha: 0.38),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        final c = ctx.color;
        final t = Theme.of(ctx).textTheme;
        Widget stepper(String label, Mins v, ValueChanged<Mins> on) => Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: c.surfaceSecondary, borderRadius: BorderRadius.circular(100)),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: t.labelLarge?.copyWith(color: c.textSecondary))),
              IconButton(icon: Icon(Icons.remove_rounded, color: c.textTertiary), onPressed: () => set(() => on(v - 5))),
              SizedBox(
                width: 56,
                child: Text(hhmm(v), textAlign: TextAlign.center, style: t.titleMedium),
              ),
              IconButton(icon: Icon(Icons.add_rounded, color: c.textTertiary), onPressed: () => set(() => on(v + 5))),
            ],
          ),
        );
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(color: c.surfacePrimary, borderRadius: BorderRadius.circular(36)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: c.borderNormal, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset(kPillow, height: 56),
                const SizedBox(height: 12),
                Text('Review nap', textAlign: TextAlign.center, style: t.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  dur((end - start).clamp(0, 600)),
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: c.textQuaternary),
                ),
                const SizedBox(height: 20),
                stepper('Fell asleep', start, (v) => start = v),
                const SizedBox(height: 8),
                stepper('Woke up', end, (v) => end = v),
                const SizedBox(height: 24),
                PillButton(
                  label: 'Save nap',
                  height: 52,
                  onTap: () {
                    plan.confirm(s, start: start, end: end);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// ── Dashes ───────────────────────────────────────────────────────────────────

/// A dashed rounded-rect outline around [child] (predicted = not real yet).
class DashedBorder extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color color;
  const DashedBorder({super.key, required this.child, required this.radius, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _DashedRRectPainter(radius, color),
    child: child,
  );
}

class _DashedRRectPainter extends CustomPainter {
  final double radius;
  final Color color;
  _DashedRRectPainter(this.radius, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(radius)));
    canvas.drawPath(
      dashPath(path, 3, 3),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) => old.color != color || old.radius != radius;
}

Path dashPath(Path source, double dash, double gap) {
  final out = Path();
  for (final PathMetric m in source.computeMetrics()) {
    var d = 0.0;
    while (d < m.length) {
      out.addPath(m.extractPath(d, d + dash), Offset.zero);
      d += dash + gap;
    }
  }
  return out;
}
