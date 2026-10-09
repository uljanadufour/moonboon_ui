import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/device_radius.dart';
import '../../common/modal_sheet.dart';
import '../../mock/mock_monitor_cubit.dart';
import '../../mock/mock_motor_cubit.dart';
import '../../pairing/motor_type.dart';
import '../../pairing/pair_device_modal.dart';
import '../../setup_flow/monitor_provisioning_page.dart';
import '../../theme/theme_colors.dart';

/// The two device families home always shows, owned or not.
enum DeviceKind { monitor, bouncer }

/// Which devices the mock account owns. Switchable from the prototype bar so
/// every variant can be felt in all four states.
enum Ownership {
  none('No devices'),
  monitor('Monitor'),
  bouncer('Bouncer'),
  both('Both');

  final String label;
  const Ownership(this.label);

  bool owns(DeviceKind kind) => switch (this) {
    Ownership.none => false,
    Ownership.both => true,
    Ownership.monitor => kind == DeviceKind.monitor,
    Ownership.bouncer => kind == DeviceKind.bouncer,
  };

  Ownership adding(DeviceKind kind) {
    final monitor = owns(DeviceKind.monitor) || kind == DeviceKind.monitor;
    final bouncer = owns(DeviceKind.bouncer) || kind == DeviceKind.bouncer;
    if (monitor && bouncer) return Ownership.both;
    if (monitor) return Ownership.monitor;
    if (bouncer) return Ownership.bouncer;
    return Ownership.none;
  }
}

/// Mock copy and artwork per device, so variants never invent their own.
extension DeviceKindMock on DeviceKind {
  String get name => switch (this) {
    DeviceKind.monitor => 'Baby monitor',
    DeviceKind.bouncer => 'Cradle bouncer',
  };

  /// Status line for an owned device.
  String get ownedStatus => switch (this) {
    DeviceKind.monitor => 'Live · 21°C',
    DeviceKind.bouncer => 'Connected',
  };

  /// The production card artwork (copied from moonboon_app new home).
  String get packshot => switch (this) {
    DeviceKind.monitor => 'assets/images/babymonitor_packshot_full.png',
    DeviceKind.bouncer => 'assets/images/motor_premium_lifestyle.png',
  };

  /// Warm in-context photo for larger cards.
  String get photo => switch (this) {
    DeviceKind.monitor => 'assets/images/streaming_bg.png',
    DeviceKind.bouncer => 'assets/images/motor_premium_lifestyle.png',
  };

  /// One calm line on what the device does, for unowned cards that pitch it.
  String get promise => switch (this) {
    DeviceKind.monitor => 'See Vera sleep, from anywhere',
    DeviceKind.bouncer => 'Gentle bouncing that soothes her to sleep',
  };
}

/// Blurs [child] and lays a soft veil over it — the "not yours yet" treatment.
class Frosted extends StatelessWidget {
  final Widget child;
  final double sigma;
  final double veil;

  const Frosted({
    super.key,
    required this.child,
    this.sigma = 9,
    this.veil = 0.35,
  });

  // Clamp, not decal: decal fades a blurred full-bleed photo to transparent
  // at its edges, which reads as pale bands down the card sides.

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: sigma,
            sigmaY: sigma,
            tileMode: TileMode.clamp,
          ),
          // Slightly enlarged so the blur samples the photo's interior
          // rather than smearing its edge pixels into bands.
          child: ClipRect(
            child: Transform.scale(scale: 1.15, child: child),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: context.color.surfacePrimary.withValues(alpha: veil),
            ),
          ),
        ),
      ],
    );
  }
}

/// Light text colour for labels set on photography, in either theme.
Color onPhoto([double alpha = 1]) =>
    ThemeColors.light.surfacePrimary.withValues(alpha: alpha);

/// Darkens the corner labels sit in on top of a photo.
class PhotoScrim extends StatelessWidget {
  final Alignment begin;
  final Alignment end;

  const PhotoScrim({
    super.key,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final scrim = ThemeColors.dark.surfaceSecondary.withValues(alpha: 0.55);
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: [scrim, scrim.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Mock new home around a variant's devices section: prototype state bar, the
/// app bar, the section itself, My Day underneath and the Track button.
///
/// Tapping an unowned device opens its real setup sheet; closing the sheet
/// counts as having added it, so the variant animates into its owned state.
class HomeDevicesPlayground extends StatefulWidget {
  final String title;

  final Widget Function(
    BuildContext context,
    Ownership ownership,
    void Function(DeviceKind kind) onTap,
  )
  sectionBuilder;

  /// Whether the variant draws its own "Devices" heading.
  final bool showHeading;

  final Ownership initial;

  const HomeDevicesPlayground({
    super.key,
    required this.title,
    required this.sectionBuilder,
    this.showHeading = true,
    this.initial = Ownership.none,
  });

  @override
  State<HomeDevicesPlayground> createState() => _HomeDevicesPlaygroundState();
}

class _HomeDevicesPlaygroundState extends State<HomeDevicesPlayground> {
  late Ownership _ownership = widget.initial;

  Future<void> _onTap(DeviceKind kind) async {
    if (_ownership.owns(kind)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Opens ${kind.name.toLowerCase()}'),
            duration: const Duration(seconds: 1),
          ),
        );
      return;
    }
    await openSetupFlow(context, kind);
    if (!mounted) return;
    setState(() => _ownership = _ownership.adding(kind));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: c.surfaceSecondary,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StateBar(
                    title: widget.title,
                    value: _ownership,
                    onChanged: (v) => setState(() => _ownership = v),
                  ),
                  const _MockAppBar(),
                  const SizedBox(height: 16),
                  if (widget.showHeading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
                      child: Text(
                        'Devices',
                        style: t.titleMedium?.copyWith(color: c.textTertiary),
                      ),
                    ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: widget.sectionBuilder(context, _ownership, _onTap),
                  ),
                  const SizedBox(height: 32),
                  const _MockMyDay(),
                ],
              ),
            ),
            const Positioned(right: 20, bottom: 36, child: _MockTrackFab()),
          ],
        ),
      ),
    );
  }
}

/// Opens the real setup sheet for [kind] from the moonboon_ui flows.
Future<void> openSetupFlow(BuildContext context, DeviceKind kind) {
  final br = DeviceRadius.instance.bottomSheetRadius;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: ThemeColors.dark.surfaceSecondary.withValues(alpha: 0.38),
    builder: (ctx) {
      final maxHeight = MediaQuery.of(ctx).size.height - 60;
      final Widget body = switch (kind) {
        DeviceKind.monitor => BlocProvider(
          create: (_) => MockMonitorCubit()..checkCurrentUser(),
          child: const MonitorProvisioningPage(),
        ),
        DeviceKind.bouncer => BlocProvider(
          create: (_) => MockMotorCubit(),
          child: const PairDeviceModal(motorType: MotorType.premium),
        ),
      };
      return Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(32),
              topRight: const Radius.circular(32),
              bottomLeft: Radius.circular(br),
              bottomRight: Radius.circular(br),
            ),
            color: getModalSheetBackgroundColor(ctx, ModalSheetBackground.white),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: body,
          ),
        ),
      );
    },
  );
}

// ── Prototype chrome ──────────────────────────────────────────────────────────

class _StateBar extends StatelessWidget {
  final String title;
  final Ownership value;
  final ValueChanged<Ownership> onChanged;

  const _StateBar({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: c.textTertiary, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 6,
                children: [
                  for (final o in Ownership.values)
                    GestureDetector(
                      onTap: () => onChanged(o),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: o == value
                              ? c.textTertiary
                              : c.overlayLevel1,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          o.label,
                          style: t.labelSmall?.copyWith(
                            color: o == value ? c.textInverse : c.textTertiary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(title, style: t.labelSmall?.copyWith(color: c.textInactive)),
        ],
      ),
    );
  }
}

// ── Mock surroundings ─────────────────────────────────────────────────────────

class _MockAppBar extends StatelessWidget {
  const _MockAppBar();

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 24, 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceTertiary,
              shape: BoxShape.circle,
            ),
            child: Text(
              'V',
              style: t.titleLarge?.copyWith(color: c.textInverse),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vera', style: t.headlineSmall?.copyWith(fontSize: 28)),
                Text(
                  '7 months',
                  style: t.bodySmall?.copyWith(color: c.textQuaternary),
                ),
              ],
            ),
          ),
          Icon(Icons.notifications_none_rounded, color: c.textTertiary),
        ],
      ),
    );
  }
}

class _MockMyDay extends StatelessWidget {
  const _MockMyDay();

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    const rows = [
      ('Nap', '09:40 – 11:05', '1h 25m'),
      ('Bottle', '11:20', '150 ml'),
      ('Nap', '13:30 – 14:10', '40m'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'My day',
              style: t.titleMedium?.copyWith(color: c.textTertiary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: c.surfacePrimary,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                for (final (label, time, value) in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: t.labelLarge?.copyWith(
                                  color: c.textTertiary,
                                ),
                              ),
                              Text(
                                time,
                                style: t.bodySmall?.copyWith(
                                  color: c.textQuaternary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          value,
                          style: t.labelMedium?.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockTrackFab extends StatelessWidget {
  const _MockTrackFab();

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: c.brandPrimary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(Icons.add, color: c.textInverse, size: 20),
          Text('Track', style: t.labelLarge?.copyWith(color: c.textInverse)),
        ],
      ),
    );
  }
}
