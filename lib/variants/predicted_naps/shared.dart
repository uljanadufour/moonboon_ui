import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../theme/theme_colors.dart';
import '../home_devices/shared.dart' show DeviceKind;
import '../home_devices/v1_frosted_pair_page.dart' show CompactDeviceCard;
import 'app_widgets.dart';
import 'plan.dart';

export 'app_widgets.dart';

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
                              style: AppText.titleMedium.copyWith(color: c.textTertiary),
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
                child: Text('Devices', style: AppText.titleMedium.copyWith(color: c.textTertiary)),
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

// ── Building blocks shared by the versions (app widgets, Figma copy) ────────

class StatPills extends StatelessWidget {
  final NapPlan plan;
  const StatPills({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final napped = plan.timeNapped;
    final h = napped ~/ 60, m = napped % 60;
    // As MyDayOverviewCards: equal shares until a card needs more.
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(flex: 1),
        1: FixedColumnWidth(AppSpacing.sm),
        2: IntrinsicColumnWidth(flex: 1),
        3: FixedColumnWidth(AppSpacing.sm),
        4: IntrinsicColumnWidth(flex: 1),
      },
      children: [
        TableRow(
          children: [
            OverviewCard(value: h > 0 ? '${h}h ${m}m' : '${m}m', label: 'Time napped'),
            const SizedBox.shrink(),
            OverviewCard(value: '${NapPlan.nightWakings}', label: 'Night wakings'),
            const SizedBox.shrink(),
            OverviewCard(value: '${plan.napCount}', label: 'Naps'),
          ],
        ),
      ],
    );
  }
}

/// A My day row for a predicted nap or bedtime: dashed, "in …" pill.
Widget predictedRow(NapPlan plan, {required String icon, required String label, required String detail, required Mins at, VoidCallback? onTap}) =>
    MyDayRowShell(
      icon: icon,
      label: label,
      detail: detail,
      isPlaceholder: true,
      trailing: MyDayPill(at > plan.now ? 'in ${short(at - plan.now)}' : 'Now'),
      onTap: onTap,
    );

/// The lifecycle card for the nap in focus, shared by every version: the
/// auto-track suggestion card with its header, × and button pair.
/// [e1] follows Exploration 1, where the card is the "Smart nap suggestion"
/// and its moment-of answers are Confirm / Adjust.
/// Returns null when there's nothing to act on (an upcoming nap).
Widget? lifecycleCard(BuildContext context, NapPlan plan, {bool e1 = false}) {
  final s = plan.focus;
  if (s == null) return null;
  final n = plan.now;
  switch (plan.phaseOf(s)) {
    case Phase.upcoming:
      if (!e1) return null;
      return MyDaySuggestionCard(
        title: 'Smart nap suggestion',
        detail: '(${hhmm(s.predStart)} · ${dur(s.predLength)})',
        trailing: MyDayPill('in ${short(s.predStart - n)}'),
        onDismiss: () => plan.skip(s),
      );
    case Phase.window:
      if (e1) {
        return MyDaySuggestionCard(
          title: 'Smart nap suggestion',
          detail: '(${hhmm(s.predStart)} · ${dur(s.predLength)})',
          trailing: const MyDayPill('Now'),
          onDismiss: () => plan.skip(s),
          primary: ('Confirm', () => plan.startNap(s)),
          secondary: ('Adjust', () => showAdjustSheet(context, plan, s)),
        );
      }
      return MyDaySuggestionCard(
        title: 'Nap window now · ${hhmm(s.windowStart)} – ${hhmm(s.windowEnd)}',
        detail: '(around ${hhmm(s.predStart)} · ${dur(s.predLength)})',
        trailing: const MyDayPill('Now'),
        onDismiss: () => plan.skip(s),
        primary: ('Start nap', () => plan.startNap(s)),
        secondary: ('Not yet', () => plan.notYet(s)),
      );
    case Phase.running:
      return MyDaySuggestionCard(
        title: 'Napping now',
        detail: 'since ${hhmm(s.start!)} · likely until ${hhmm(r5(s.start! + s.predLength))}',
        trailing: const MyDayPill('Now'),
        onOpen: () => showRunningNapSheet(context, plan, s),
      );
    case Phase.autoRunning:
      return MyDaySuggestionCard(
        title: 'Auto tracking with monitor',
        detail: '(${hhmm(s.start!)} · ${dur(math.max(n - s.start!, 1))})',
        trailing: const MyDayPill('Now'),
        onDismiss: () => plan.skip(s),
      );
    case Phase.askConfirm:
      return MyDaySuggestionCard(
        title: 'Did ${NapPlan.baby} nap around ${hhmm(s.predStart)}?',
        detail: '(${hhmm(s.predStart)} – ${hhmm(s.predEnd)} · ${dur(s.predLength)})',
        trailing: const MyDayPill('Not tracked'),
        onDismiss: () => plan.skip(s),
        primary: ('Confirm', () => plan.confirm(s)),
        secondary: ('Adjust', () => showAdjustSheet(context, plan, s)),
      );
    case Phase.autoReview:
      return MyDaySuggestionCard(
        title: 'Auto tracked with monitor',
        detail: '(${hhmm(s.start!)} · ${dur(s.end! - s.start!)})',
        trailing: MyDayPill.elapsed(n - s.end!),
        onDismiss: () => plan.skip(s),
        primary: ('Confirm', () => plan.confirm(s)),
        secondary: ('Adjust', () => showAdjustSheet(context, plan, s)),
      );
    case Phase.done:
    case Phase.skipped:
      return null;
  }
}

/// My day rows for what's been slept today, newest first, as the app draws
/// them: label, how long it lasted, how long ago it ended.
List<Widget> sleptRows(NapPlan plan, {int? limit, bool withTimes = false}) {
  final list = plan.slept.where((s) => s.end <= plan.now || s.kind == 'Night sleep').toList();
  return [
    for (final s in limit == null ? list : list.take(limit))
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: MyDayRowShell(
          icon: s.kind == 'Nap' ? kPillow : kMoon,
          label: s.kind,
          detail: withTimes && s.kind == 'Nap' ? '${hhmm(s.start)} – ${hhmm(s.end)} · ${dur(s.length)}' : dur(s.length),
          trailing: MyDayPill.elapsed(plan.now - s.end),
        ),
      ),
  ];
}

Widget _sheet(BuildContext ctx, List<Widget> children) {
  final c = ctx.color;
  return Padding(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(color: c.surfacePrimary, borderRadius: BorderRadius.circular(36)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.borderNormal, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    ),
  );
}

Future<T?> _show<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
  context: context,
  backgroundColor: Colors.transparent,
  barrierColor: ThemeColors.dark.surfaceSecondary.withValues(alpha: 0.38),
  builder: builder,
);

/// Stand-in for the nap tracking view: the running nap and its end.
Future<void> showRunningNapSheet(BuildContext context, NapPlan plan, NapSlot s) => _show(
  context,
  (ctx) => _sheet(ctx, [
    Image.asset(kPillow, height: 56),
    const SizedBox(height: 12),
    Text('Napping', textAlign: TextAlign.center, style: AppText.headlineMedium.copyWith(color: ctx.color.textPrimary)),
    const SizedBox(height: 6),
    Text(
      'since ${hhmm(s.start!)} · ${short(plan.now - s.start!)}',
      textAlign: TextAlign.center,
      style: AppText.bodySmall.copyWith(color: ctx.color.textTertiary),
    ),
    const SizedBox(height: 24),
    SmallButton(
      label: '${NapPlan.baby} woke up',
      height: 52,
      onTap: () {
        plan.wokeUpNow(s);
        Navigator.of(ctx).pop();
      },
    ),
  ]),
);

/// Stand-in for NapReviewSheet, pre-filled with the predicted times.
Future<void> showAdjustSheet(BuildContext context, NapPlan plan, NapSlot s) {
  var start = s.start ?? s.predStart;
  var end = s.end ?? s.predEnd;
  return _show(
    context,
    (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        final c = ctx.color;
        Widget stepper(String label, Mins v, ValueChanged<Mins> on) => Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(color: c.surfaceSecondary, borderRadius: AppRadius.pillAll),
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: AppText.labelMedium.copyWith(color: c.textSecondary))),
              IconButton(icon: Icon(Icons.remove_rounded, color: c.textTertiary), onPressed: () => set(() => on(v - 5))),
              SizedBox(width: 56, child: Text(hhmm(v), textAlign: TextAlign.center, style: AppText.titleMedium.copyWith(color: c.textPrimary))),
              IconButton(icon: Icon(Icons.add_rounded, color: c.textTertiary), onPressed: () => set(() => on(v + 5))),
            ],
          ),
        );
        return _sheet(ctx, [
          Image.asset(kPillow, height: 56),
          const SizedBox(height: 12),
          Text('Nap', textAlign: TextAlign.center, style: AppText.headlineMedium.copyWith(color: c.textPrimary)),
          const SizedBox(height: 6),
          Text(dur((end - start).clamp(0, 600)), textAlign: TextAlign.center, style: AppText.bodySmall.copyWith(color: c.textTertiary)),
          const SizedBox(height: 20),
          stepper('Fell asleep', start, (v) => start = v),
          const SizedBox(height: AppSpacing.sm),
          stepper('Woke up', end, (v) => end = v),
          const SizedBox(height: 24),
          SmallButton(
            label: 'Save',
            height: 52,
            onTap: () {
              plan.confirm(s, start: start, end: end);
              Navigator.of(ctx).pop();
            },
          ),
        ]);
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
