import 'package:flutter/foundation.dart';

/// Minutes since midnight. Every time in this prototype is one of these.
typedef Mins = int;

String hhmm(Mins m) {
  final h = (m ~/ 60) % 24;
  final mm = m % 60;
  return '${h.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
}

/// Predictions are only ever shown to the nearest 5 minutes.
Mins r5(Mins m) => ((m + 2) ~/ 5) * 5;

/// "1h 15min", "30min" — the app's duration copy.
String dur(Mins m) {
  final h = m ~/ 60;
  final mm = m % 60;
  if (h == 0) return '${mm}min';
  if (mm == 0) return '${h}h';
  return '${h}h ${mm.toString().padLeft(2, '0')}min';
}

/// "1h 30m" — the compact countdown copy.
String short(Mins m) {
  final h = m ~/ 60;
  final mm = m % 60;
  if (h == 0) return '${mm}m';
  if (mm == 0) return '${h}h';
  return '${h}h ${mm}m';
}

enum Source { manual, monitor }

/// Where one predicted nap is in its life, at the simulated time.
enum Phase {
  /// Predicted, the window hasn't opened yet.
  upcoming,

  /// The likely window is open: Start nap / Not yet / × skip.
  window,

  /// Sleeping, started from the app.
  running,

  /// Sleeping, picked up by the monitor (auto-track owns the card).
  autoRunning,

  /// The predicted end passed and nothing was tracked: Confirm / Adjust / ×.
  askConfirm,

  /// The monitor tracked it; waiting for the parent's Confirm / Adjust.
  autoReview,

  /// Tracked and confirmed: a past event.
  done,

  /// Dismissed ("Skip this nap" / "She didn't nap").
  skipped,
}

/// A real past sleep shown on Home.
class Slept {
  final String kind; // 'Nap' | 'Night sleep'
  final Mins start;
  final Mins end; // may be < start for night sleep (crosses midnight)
  final Source? source;
  const Slept(this.kind, this.start, this.end, {this.source});
  Mins get length => end >= start ? end - start : end + 1440 - start;
}

/// One predicted nap and what the parent did with it.
class NapSlot {
  final int index;
  Mins predStart;
  Mins predLength;
  int snoozes = 0;
  bool skipped = false;
  Mins? start;
  Mins? end;
  Source source = Source.manual;
  bool confirmed = false;

  NapSlot(this.index, this.predStart, this.predLength);

  Mins get predEnd => predStart + predLength;
  Mins get windowStart => predStart - 10;
  Mins get windowEnd => predStart + 10;

  Phase phaseAt(Mins now) {
    if (skipped) return Phase.skipped;
    if (start != null) {
      if (end == null) {
        // The monitor ends its own naps at the predicted wake-up.
        if (source == Source.monitor && now >= predEnd) {
          end = predEnd;
        } else {
          return source == Source.monitor ? Phase.autoRunning : Phase.running;
        }
      }
      return confirmed ? Phase.done : Phase.autoReview;
    }
    if (now < windowStart) return Phase.upcoming;
    if (now < predEnd) return Phase.window;
    return Phase.askConfirm;
  }

  bool resolvedAt(Mins now) {
    final p = phaseAt(now);
    return p == Phase.done || p == Phase.skipped;
  }
}

/// Ella's day: the scenario, the simulated clock, and every action a parent
/// can take on a predicted nap. All four versions read from this one model,
/// so the same taps give the same plan whichever version you're in.
class NapPlan extends ChangeNotifier {
  static const String baby = 'Ella';
  static const String age = '8 months';

  /// Simulated moments worth jumping to.
  static const List<(Mins, String)> moments = [
    (11 * 60 + 40, 'Before'),
    (13 * 60 + 5, 'In window'),
    (13 * 60 + 25, 'Later'),
    (15 * 60, 'After'),
    (17 * 60 + 15, 'Evening'),
  ];

  static const Mins wokeUp = 6 * 60 + 40;
  static const int nightWakings = 3;

  /// Wake window before the next nap and before bed (8 months).
  static const Mins wakeWindow = 115;
  static const Mins bedWakeWindow = 130;

  Mins now;
  late List<NapSlot> slots;

  NapPlan({this.now = 11 * 60 + 40}) {
    _reset();
  }

  final List<Slept> past = const [
    Slept('Night sleep', 19 * 60 + 10, 6 * 60 + 40),
    Slept('Nap', 9 * 60 + 5, 10 * 60 + 10, source: Source.monitor),
  ];

  void _reset() {
    slots = [NapSlot(0, 13 * 60 + 10, 75), NapSlot(1, 16 * 60 + 20, 30)];
  }

  void reset() {
    now = moments.first.$1;
    _reset();
    notifyListeners();
  }

  void setNow(Mins m) {
    now = m;
    _replan();
    notifyListeners();
  }

  // ── Derived ────────────────────────────────────────────────────────────────

  Phase phaseOf(NapSlot s) => s.phaseAt(now);

  /// The nap the Home screen is talking about: the first one not yet done.
  NapSlot? get focus {
    for (final s in slots) {
      if (!s.resolvedAt(now)) return s;
    }
    return null;
  }

  /// Predicted naps still ahead (upcoming or in their window).
  List<NapSlot> get ahead => [
    for (final s in slots)
      if (const [Phase.upcoming, Phase.window].contains(phaseOf(s))) s,
  ];

  Mins get bedtime {
    final last = slots.lastWhere((s) => !s.skipped, orElse: () => slots.first);
    final end = last.end ?? (last.start != null ? last.start! + last.predLength : last.predEnd);
    final b = end + bedWakeWindow;
    return r5(b.clamp(18 * 60 + 15, 19 * 60 + 30));
  }

  /// Everything that has actually been slept today, newest first.
  List<Slept> get slept {
    final list = <Slept>[...past];
    for (final s in slots) {
      final p = phaseOf(s);
      if (p == Phase.done) list.add(Slept('Nap', s.start!, s.end!, source: s.source));
    }
    list.sort((a, b) => _endAbs(b).compareTo(_endAbs(a)));
    return list;
  }

  int _endAbs(Slept s) => s.kind == 'Night sleep' ? s.end : s.end;

  Mins get timeNapped => slept.where((s) => s.kind == 'Nap').fold(0, (a, s) => a + s.length);
  int get napCount => slept.where((s) => s.kind == 'Nap').length;

  /// Minutes since Ella last woke (for "awake 2h 55m").
  Mins get awakeFor {
    final ends = slept.map((s) => s.end).where((e) => e <= now);
    final last = ends.isEmpty ? wokeUp : ends.reduce((a, b) => a > b ? a : b);
    return now - last;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void startNap(NapSlot s, {Source source = Source.manual}) {
    s
      ..start = source == Source.monitor ? s.predStart : now
      ..source = source
      ..end = null
      ..confirmed = source == Source.manual;
    _replan();
    notifyListeners();
  }

  /// Ends a nap that was started from the app.
  void wokeUpNow(NapSlot s) {
    s
      ..end = now
      ..confirmed = true;
    _replan();
    notifyListeners();
  }

  /// "Not yet": push this nap about 30 minutes and shorten it a little.
  void notYet(NapSlot s) {
    s
      ..snoozes += 1
      ..predStart = (now + 35).clamp(s.predStart + 30, 24 * 60)
      ..predLength = (s.predLength - 15).clamp(30, 180);
    _replan();
    notifyListeners();
  }

  /// × / "Skip this nap" / "She didn't nap".
  void skip(NapSlot s) {
    s.skipped = true;
    _replan();
    notifyListeners();
  }

  /// Confirm the predicted (or auto-tracked) times as a real nap.
  void confirm(NapSlot s, {Mins? start, Mins? end}) {
    s
      ..start = start ?? s.start ?? s.predStart
      ..end = end ?? s.end ?? s.predEnd
      ..confirmed = true;
    _replan();
    notifyListeners();
  }

  /// Monitor detects the nap: the auto-track card takes over, no duplicate.
  void monitorDetects() {
    final s = focus;
    if (s == null) return;
    startNap(s, source: Source.monitor);
  }

  /// Re-predicts every later nap from what actually happened.
  void _replan() {
    for (var i = 1; i < slots.length; i++) {
      final prev = slots[i - 1];
      final next = slots[i];
      if (next.start != null) continue;
      if (prev.skipped) {
        next
          ..predStart = 10 * 60 + 10 + 5 * 60 + 20 // 15:30
          ..predLength = 45;
        continue;
      }
      final prevEnd = prev.end ?? (prev.start != null ? prev.start! + prev.predLength : prev.predEnd);
      next
        ..predStart = prevEnd + wakeWindow
        ..predLength = 30;
    }
  }
}
