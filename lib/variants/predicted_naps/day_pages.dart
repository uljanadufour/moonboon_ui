import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/theme_colors.dart';
import 'plan.dart';
import 'shared.dart';

/// One block on the day visual: something slept, running, or predicted.
class DayBlock {
  final String id;
  final Mins start;
  final Mins end;
  final bool predicted;
  final bool bedtime;
  final NapSlot? slot;
  final Slept? slept;
  const DayBlock(this.id, this.start, this.end, {this.predicted = false, this.bedtime = false, this.slot, this.slept});
}

List<DayBlock> dayBlocks(NapPlan plan) {
  final n = plan.now;
  final out = <DayBlock>[];
  for (final s in plan.slept) {
    if (s.kind == 'Night sleep') {
      out.add(DayBlock('night', 0, s.end, slept: s));
    } else {
      out.add(DayBlock('slept-${s.start}', s.start, s.end, slept: s));
    }
  }
  for (final s in plan.slots) {
    switch (plan.phaseOf(s)) {
      case Phase.upcoming:
      case Phase.window:
      case Phase.askConfirm:
        out.add(DayBlock('slot-${s.index}', s.predStart, s.predEnd, predicted: true, slot: s));
      case Phase.running:
      case Phase.autoRunning:
        final likely = s.source == Source.monitor ? s.predEnd : s.start! + s.predLength;
        out.add(DayBlock('slot-${s.index}', s.start!, n, slot: s));
        if (likely > n) out.add(DayBlock('slot-${s.index}-rest', n, likely, predicted: true, slot: s));
      case Phase.autoReview:
        out.add(DayBlock('slot-${s.index}', s.start!, s.end!, slot: s));
      case Phase.done:
      case Phase.skipped:
        break;
    }
  }
  out.add(DayBlock('bed', plan.bedtime, 24 * 60, predicted: true, bedtime: true));
  return out;
}

enum Filter { none, slept, predicted }

/// The empty day behind the blocks: white on cream, a lifted brown in dark.
Color dayTrack(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? context.color.surfaceQuaternary : context.color.surfacePrimary;

/// E3 · Timeline ribbon and E4 · Napper-style day arc: same flow, different
/// picture of the day. Tap a block to see it; tap a legend chip to filter.
class DayViewPage extends StatefulWidget {
  final bool arc;
  final NapPlan? plan;
  const DayViewPage({super.key, required this.arc, this.plan});

  @override
  State<DayViewPage> createState() => _DayViewPageState();
}

class _DayViewPageState extends State<DayViewPage> {
  String? _selected;
  Filter _filter = Filter.none;

  @override
  Widget build(BuildContext context) {
    return NapsPlayground(
      plan: widget.plan,
      title: widget.arc ? 'E4 · Day arc' : 'E3 · Ribbon',
      sectionTitle: "${NapPlan.baby}'s day",
      builder: (context, plan) {
        final c = context.color;
        final blocks = dayBlocks(plan);
        if (_selected != null && !blocks.any((b) => b.id == _selected)) _selected = null;
        void select(String? id) => setState(() {
          _selected = id == _selected ? null : id;
          _filter = Filter.none;
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
              decoration: BoxDecoration(color: c.overlayLevel2, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.arc
                      ? DayArc(plan: plan, blocks: blocks, selected: _selected, onSelect: select)
                      : DayRibbon(plan: plan, blocks: blocks, selected: _selected, onSelect: select),
                  const SizedBox(height: 12),
                  Row(
                    spacing: 6,
                    children: [
                      _LegendChip(
                        label: 'Slept',
                        dashed: false,
                        on: _filter == Filter.slept,
                        onTap: () => setState(() {
                          _filter = _filter == Filter.slept ? Filter.none : Filter.slept;
                          _selected = null;
                        }),
                      ),
                      _LegendChip(
                        label: 'Predicted',
                        dashed: true,
                        on: _filter == Filter.predicted,
                        onTap: () => setState(() {
                          _filter = _filter == Filter.predicted ? Filter.none : Filter.predicted;
                          _selected = null;
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ..._below(context, plan, blocks),
          ],
        );
      },
    );
  }

  List<Widget> _below(BuildContext context, NapPlan plan, List<DayBlock> blocks) {
    final n = plan.now;
    Widget gap(Widget w) => Padding(padding: const EdgeInsets.only(bottom: 8), child: w);

    if (_filter == Filter.slept) return sleptRows(plan);
    if (_filter == Filter.predicted) return _predictedRows(plan, gap);

    if (_selected != null) {
      final b = blocks.firstWhere((b) => b.id == _selected);
      if (b.bedtime) {
        return [
          gap(EventRow(asset: kMoon, title: 'Bedtime', detail: 'around ${hhmm(b.start)}', trailing: 'in ${short(b.start - n)}', style: RowStyle.focus)),
        ];
      }
      if (b.slot != null && plan.phaseOf(b.slot!) == Phase.upcoming) {
        return [gap(_PredictedDetail(plan: plan, slot: b.slot!, onClose: () => setState(() => _selected = null)))];
      }
      if (b.slot != null) {
        final card = lifecycleCard(context, plan);
        if (card != null && plan.focus == b.slot) return [gap(card)];
      }
      if (b.slept != null) {
        final s = b.slept!;
        return [
          gap(EventRow(
            asset: s.kind == 'Nap' ? kPillow : kMoon,
            title: s.kind,
            detail: s.kind == 'Nap' ? '${hhmm(s.start)} – ${hhmm(s.end)} · ${dur(s.length)}' : '${hhmm(s.start)} – ${hhmm(s.end)} · ${dur(s.length)}',
            trailing: '${short(n - s.end)} ago',
            style: RowStyle.live,
          )),
        ];
      }
    }

    // Default: what needs you now (or the next nap), then today so far.
    final focus = plan.focus;
    final card = lifecycleCard(context, plan);
    final top = card ??
        (focus != null
            ? EventRow(
                asset: kPillow,
                title: 'Next nap',
                detail: '${focus.snoozes > 0 ? 'moved to' : 'around'} ${hhmm(focus.predStart)} · ${dur(focus.predLength)}',
                trailing: 'in ${short(focus.predStart - n)}',
                style: RowStyle.focus,
                onTap: () => setState(() => _selected = 'slot-${focus.index}'),
              )
            : plan.bedtime > n
                ? EventRow(asset: kMoon, title: 'Bedtime', detail: 'around ${hhmm(plan.bedtime)}', trailing: 'in ${short(plan.bedtime - n)}', style: RowStyle.focus)
                : null);
    return [if (top != null) gap(top), ...sleptRows(plan, limit: 2)];
  }

  List<Widget> _predictedRows(NapPlan plan, Widget Function(Widget) gap) {
    final n = plan.now;
    return [
      for (final s in plan.ahead)
        gap(EventRow(
          asset: kPillow,
          title: 'Nap',
          detail: 'around ${hhmm(s.predStart)} · ${dur(s.predLength)}',
          trailing: s.predStart > n ? 'in ${short(s.predStart - n)}' : 'Now',
          style: s == plan.focus ? RowStyle.focus : RowStyle.predicted,
          onTap: () => setState(() {
            _filter = Filter.none;
            _selected = 'slot-${s.index}';
          }),
        )),
      if (plan.bedtime > n)
        gap(EventRow(asset: kMoon, title: 'Bedtime', detail: 'around ${hhmm(plan.bedtime)}', trailing: 'in ${short(plan.bedtime - n)}', style: RowStyle.predicted)),
    ];
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final bool dashed;
  final bool on;
  final VoidCallback onTap;
  const _LegendChip({required this.label, required this.dashed, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    final swatch = Container(
      width: 12,
      height: 8,
      decoration: BoxDecoration(
        color: dashed ? c.overlayBrand : c.brandPrimary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: on ? c.surfaceTertiary : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: on ? c.surfaceTertiary : c.borderNormal),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            dashed ? DashedBorder(radius: 2, color: c.brandPrimary, child: swatch) : swatch,
            Text(label, style: t.labelSmall?.copyWith(color: on ? c.textOnCta : c.textTertiary)),
          ],
        ),
      ),
    );
  }
}

/// Tapped predicted nap: when, how sure, and a wind-down reminder.
class _PredictedDetail extends StatelessWidget {
  final NapPlan plan;
  final NapSlot slot;
  final VoidCallback onClose;
  const _PredictedDetail({required this.plan, required this.slot, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    final windDown = slot.windowStart - 10;
    Widget line(String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(a, style: t.bodySmall?.copyWith(color: c.textTertiary))),
          Text(b, style: t.labelMedium?.copyWith(color: c.textSecondary)),
        ],
      ),
    );
    return DashedBorder(
      radius: 22,
      color: c.brandPrimary,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 14),
        decoration: BoxDecoration(color: c.surfacePrimary, borderRadius: BorderRadius.circular(22)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Image.asset(kPillow, width: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Predicted nap · ${dur(slot.predLength)}', style: t.labelMedium?.copyWith(color: c.textSecondary)),
                ),
                Text('in ${short(slot.predStart - plan.now)}', style: t.labelSmall?.copyWith(color: c.textTertiary)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 18, color: c.textTertiary),
                  onPressed: onClose,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                children: [
                  line('Likely window', '${hhmm(slot.windowStart)} – ${hhmm(slot.windowEnd)}'),
                  if (windDown > plan.now) line('Start winding down', hhmm(windDown)),
                  const SizedBox(height: 10),
                  if (windDown > plan.now)
                    PillButton(
                      label: 'Remind me at ${hhmm(windDown)}',
                      onTap: () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text("We'll remind you at ${hhmm(windDown)}"))),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    "Based on ${NapPlan.baby}'s last 7 days. Times shift as you track.",
                    textAlign: TextAlign.center,
                    style: t.labelSmall?.copyWith(fontSize: 11, color: c.textQuaternary),
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

// ── E3: the ribbon ───────────────────────────────────────────────────────────

class DayRibbon extends StatelessWidget {
  final NapPlan plan;
  final List<DayBlock> blocks;
  final String? selected;
  final ValueChanged<String?> onSelect;
  const DayRibbon({super.key, required this.plan, required this.blocks, required this.selected, required this.onSelect});

  static const Mins from = 6 * 60, to = 20 * 60;

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        double x(Mins m) => ((m.clamp(from, to) - from) / (to - from)) * w;
        return GestureDetector(
          onTapUp: (d) {
            final m = from + (d.localPosition.dx / w) * (to - from);
            final hit = blocks.where((b) => b.start - 15 <= m && m <= b.end + 15 && b.end > from).toList();
            onSelect(hit.isEmpty ? null : hit.last.id.replaceAll('-rest', ''));
          },
          child: SizedBox(
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 16,
                  height: 24,
                  child: Container(decoration: BoxDecoration(color: dayTrack(context), borderRadius: BorderRadius.circular(6))),
                ),
                for (final b in blocks)
                  if (b.end > from && b.start < to)
                    Positioned(
                      left: x(b.start),
                      width: math.max(6, x(b.end) - x(b.start)),
                      top: 16,
                      height: 24,
                      child: _RibbonBlock(block: b, selected: selected != null && b.id.startsWith(selected!)),
                    ),
                Positioned(
                  left: x(plan.now) - 1,
                  top: 10,
                  width: 2,
                  height: 36,
                  child: Container(decoration: BoxDecoration(color: c.textPrimary, borderRadius: BorderRadius.circular(1))),
                ),
                Positioned(
                  left: x(plan.now) - 20,
                  width: 40,
                  top: -8,
                  child: Text('Now', textAlign: TextAlign.center, style: t.labelSmall?.copyWith(fontSize: 10, color: c.textPrimary)),
                ),
                for (final h in [6, 9, 12, 15, 18])
                  Positioned(
                    left: x(h * 60) - (h == 6 ? 0 : 8),
                    top: 44,
                    child: Text(h.toString().padLeft(2, '0'), style: t.labelSmall?.copyWith(fontSize: 10, color: c.textQuaternary)),
                  ),
                Positioned(right: 0, top: 42, child: Image.asset(kMoon, width: 16)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RibbonBlock extends StatelessWidget {
  final DayBlock block;
  final bool selected;
  const _RibbonBlock({required this.block, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final box = Container(
      decoration: BoxDecoration(
        color: block.predicted ? c.overlayBrand : c.brandPrimary,
        borderRadius: BorderRadius.circular(5),
        border: selected ? Border.all(color: c.textPrimary, width: 1.5) : null,
      ),
    );
    if (!block.predicted || selected) return box;
    return DashedBorder(radius: 5, color: c.brandPrimary, child: box);
  }
}

// ── E4: the Napper-style day arc ─────────────────────────────────────────────

class DayArc extends StatelessWidget {
  final NapPlan plan;
  final List<DayBlock> blocks;
  final String? selected;
  final ValueChanged<String?> onSelect;
  const DayArc({super.key, required this.plan, required this.blocks, required this.selected, required this.onSelect});

  static const double size = 250;
  static const double band = 18;
  static const double a0 = 3 * math.pi / 4, sweep = 3 * math.pi / 2;

  Mins get _from => NapPlan.wokeUp;
  Mins get _to => plan.bedtime;
  double _ang(Mins m) => a0 + ((m.clamp(_from, _to) - _from) / (_to - _from)) * sweep;

  (String, String, String) _centre() {
    final n = plan.now;
    final s = plan.focus;
    if (s == null) {
      return plan.bedtime > n
          ? ('Bedtime in', short(plan.bedtime - n), 'Around ${hhmm(plan.bedtime)}')
          : ('Good night', hhmm(plan.bedtime), 'Bedtime');
    }
    return switch (plan.phaseOf(s)) {
      Phase.upcoming => ('Next nap in', short(s.predStart - n), 'Around ${hhmm(s.predStart)}'),
      Phase.window => ('Nap window', 'Now', '${hhmm(s.windowStart)} – ${hhmm(s.windowEnd)}'),
      Phase.running => ('Napping', short(n - s.start!), 'Likely until ${hhmm(r5(s.start! + s.predLength))}'),
      Phase.autoRunning => ('Napping', short(n - s.start!), 'Tracked by monitor'),
      Phase.askConfirm => ('Did ${NapPlan.baby} nap?', hhmm(s.predStart), 'Confirm below'),
      Phase.autoReview => ('Monitor tracked', short(s.end! - s.start!), 'Confirm below'),
      _ => ('', '', ''),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    final (a, b, sub) = _centre();
    final r = size / 2;
    final h = r + r * math.sqrt1_2 + 40;
    return LayoutBuilder(
      builder: (context, box) {
        final cx = box.maxWidth / 2, cy = r + 16;
        Offset at(Mins m, double rad) => Offset(cx + rad * math.cos(_ang(m)), cy + rad * math.sin(_ang(m)));
        final focus = plan.focus;
        final labelled = focus == null ? null : blocks.where((b) => b.slot == focus).firstOrNull;
        final labelStart = focus?.start ?? focus?.predStart;
        final labelEnd = focus == null ? null : r5(focus.end ?? (focus.start != null ? focus.start! + focus.predLength : focus.predEnd));
        Widget timeLabel(Mins m, double rad) {
          final p = at(m, rad);
          return Positioned(
            left: p.dx - 20,
            top: p.dy - 8,
            width: 40,
            child: Text(hhmm(m), textAlign: TextAlign.center, style: t.labelSmall?.copyWith(fontSize: 10, color: c.textQuaternary)),
          );
        }

        return GestureDetector(
          onTapUp: (d) {
            final v = d.localPosition - Offset(cx, cy);
            if ((v.distance - (r - band / 2)).abs() > 26) return onSelect(null);
            var ang = math.atan2(v.dy, v.dx);
            while (ang < a0) {
              ang += 2 * math.pi;
            }
            final m = _from + ((ang - a0) / sweep) * (_to - _from);
            final hit = blocks.where((b) => !b.bedtime && b.start - 20 <= m && m <= b.end + 20 && b.end > _from).toList();
            onSelect(hit.isEmpty ? null : hit.last.id.replaceAll('-rest', ''));
          },
          child: SizedBox(
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ArcPainter(
                      centre: Offset(cx, cy),
                      radius: r,
                      band: band,
                      ang: _ang,
                      blocks: blocks.where((b) => !b.bedtime && b.end > _from).toList(),
                      selected: selected,
                      now: plan.now,
                      track: dayTrack(context),
                      halo: c.surfacePrimary,
                      slept: c.brandPrimary,
                      predictedFill: c.overlayBrand,
                      predictedLine: c.brandPrimary,
                      selectedLine: c.textPrimary,
                      nowDot: c.textPrimary,
                    ),
                  ),
                ),
                // Wake-up sun and bedtime moon at the ends.
                for (final (m, asset) in [(_from, kSun), (_to, kMoon)]) ...[
                  Positioned(
                    left: at(m, r - band / 2).dx - 13,
                    top: at(m, r - band / 2).dy - 13,
                    child: Image.asset(asset, width: 26),
                  ),
                  Positioned(
                    left: at(m, r - band / 2).dx - 20,
                    top: at(m, r - band / 2).dy + 16,
                    width: 40,
                    child: Text(hhmm(m), textAlign: TextAlign.center, style: t.labelSmall?.copyWith(fontSize: 10, color: c.textQuaternary)),
                  ),
                ],
                if (labelled != null && labelStart != null) timeLabel(labelStart, r + 20),
                if (labelled != null && labelEnd != null && labelEnd - (labelStart ?? 0) >= 45) timeLabel(labelEnd, r + 20),
                Positioned(
                  left: 0,
                  right: 0,
                  top: cy - 40,
                  child: Column(
                    children: [
                      Text(a, style: t.labelMedium?.copyWith(color: c.textTertiary)),
                      Text(b, style: t.headlineLarge?.copyWith(fontSize: 44, height: 1.1)),
                      Text(sub, style: t.labelSmall?.copyWith(color: c.textQuaternary)),
                    ],
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

class _ArcPainter extends CustomPainter {
  final Offset centre;
  final double radius, band;
  final double Function(Mins) ang;
  final List<DayBlock> blocks;
  final String? selected;
  final Mins now;
  final Color track, halo, slept, predictedFill, predictedLine, selectedLine, nowDot;

  _ArcPainter({
    required this.centre,
    required this.radius,
    required this.band,
    required this.ang,
    required this.blocks,
    required this.selected,
    required this.now,
    required this.track,
    required this.halo,
    required this.slept,
    required this.predictedFill,
    required this.predictedLine,
    required this.selectedLine,
    required this.nowDot,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mid = radius - band / 2;
    final rect = Rect.fromCircle(center: centre, radius: mid);
    // Track
    canvas.drawArc(
      rect,
      DayArc.a0,
      DayArc.sweep,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    for (final b in blocks) {
      final s = ang(b.start), e = ang(b.end);
      final sweep = math.max(e - s, 0.02);
      final isSel = selected != null && b.id.startsWith(selected!);
      if (b.predicted) {
        final sector = _sector(s, sweep, mid);
        canvas.drawPath(sector, Paint()..color = predictedFill);
        canvas.drawPath(
          isSel ? sector : dashPath(sector, 3, 3),
          Paint()
            ..color = isSel ? selectedLine : predictedLine
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSel ? 1.5 : 1,
        );
      } else {
        canvas.drawArc(
          rect,
          s,
          sweep,
          false,
          Paint()
            ..color = slept
            ..style = PaintingStyle.stroke
            ..strokeWidth = band
            ..strokeCap = StrokeCap.round,
        );
        if (isSel) canvas.drawPath(_sector(s, sweep, mid), Paint()..color = selectedLine..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }
    // Now
    final p = centre + Offset(math.cos(ang(now)), math.sin(ang(now))) * mid;
    canvas.drawCircle(p, 9, Paint()..color = halo);
    canvas.drawCircle(p, 6, Paint()..color = nowDot);
  }

  /// A band-wide arc segment with rounded ends, as a closed path.
  Path _sector(double start, double sweep, double mid) {
    final outer = Rect.fromCircle(center: centre, radius: mid + band / 2);
    final inner = Rect.fromCircle(center: centre, radius: mid - band / 2);
    final endC = centre + Offset(math.cos(start + sweep), math.sin(start + sweep)) * mid;
    final startC = centre + Offset(math.cos(start), math.sin(start)) * mid;
    return Path()
      ..arcTo(outer, start, sweep, true)
      ..arcTo(Rect.fromCircle(center: endC, radius: band / 2), start + sweep, math.pi, false)
      ..arcTo(inner, start + sweep, -sweep, false)
      ..arcTo(Rect.fromCircle(center: startC, radius: band / 2), start + math.pi, math.pi, false)
      ..close();
  }

  @override
  bool shouldRepaint(_ArcPainter old) => true;
}
