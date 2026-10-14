import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'common/device_radius.dart';
import 'common/firmware_update_sheet.dart';
import 'common/modal_sheet.dart';
import 'common/monitor_troubleshoot_page.dart';
import 'mock/mock_monitor_cubit.dart';
import 'mock_screens/baby_sleep_home_page.dart';
import 'mock_screens/mock_last_night_page.dart';
import 'mock_screens/mock_monitor_stream_page.dart';
import 'mock_screens/mock_nap_tracking_page.dart';
import 'setup_flow/bloc/setup_error_type.dart';
import 'setup_flow/monitor_provisioning_page.dart';
import 'theme/app_theme.dart';
import 'theme/theme_colors.dart';
import 'variants/home_devices/shared.dart';
import 'variants/home_devices/v1_frosted_pair_page.dart';
import 'variants/home_devices/v2_window_display_page.dart';
import 'variants/home_devices/v3_lead_follow_page.dart';
import 'variants/home_devices/v4_deck_page.dart';
import 'variants/home_devices/v5_nursery_shelf_page.dart';
import 'variants/predicted_naps/day_pages.dart';
import 'variants/predicted_naps/list_pages.dart';
import 'variants/predicted_naps/plan.dart';
import 'variants/predicted_naps/shared.dart' show appDark, NapsPlayground;
import 'variants/settings/v1_stacked_list_page.dart';
import 'variants/settings/v2_hero_actions_page.dart';
import 'variants/settings/v3_tile_dashboard_page.dart';
import 'variants/settings/v4_photo_cards_page.dart';
import 'variants/settings/v5_constellation_page.dart';
import 'variants/settings_flow/baby_form_page.dart';
import 'variants/settings_flow/flow_state.dart';
import 'variants/settings_flow/help_page.dart';
import 'variants/settings_flow/invite_flows.dart';
import 'variants/settings_flow/profile_page.dart';
import 'variants/settings_flow/settings_root_page.dart';
import 'variants/settings_refinement/ref_baby_page.dart';
import 'variants/settings_refinement/ref_family_page.dart';
import 'variants/settings_refinement/ref_overview_page.dart';
import 'variants/settings_refinement/ref_feedback_modal.dart';
import 'variants/settings_refinement/ref_profile_page.dart';

Widget _flowAs(Viewer viewer, FamilyScenario scenario) {
  FlowState.i.viewer = viewer;
  FlowState.i.scenario = scenario;
  return const SettingsRootPage();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DeviceRadius.instance.init();
  runApp(const MoonboonUIApp());
}

class MoonboonUIApp extends StatefulWidget {
  const MoonboonUIApp({super.key});
  @override
  State<MoonboonUIApp> createState() => _MoonboonUIAppState();
}

// Screenshot hook: `--dart-define=SHOT=v1 --dart-define=SHOT_DARK=true`
// boots straight into a settings variant in the given theme.
const String _shot = String.fromEnvironment('SHOT');
const bool _shotDark = bool.fromEnvironment('SHOT_DARK');

/// Predicted naps versions by id, for the launcher and the screenshot remote.
Widget predictedNapsVersion(String id, [NapPlan? plan]) => switch (id) {
  'e1' => E1NextNapPage(key: UniqueKey(), plan: plan),
  'e2' => E2ListPage(key: UniqueKey(), plan: plan),
  'e3' => DayViewPage(key: UniqueKey(), arc: false, plan: plan),
  _ => DayViewPage(key: UniqueKey(), arc: true, plan: plan),
};

/// Builds a plan at [hhmm] after replaying [actions] on the focus nap
/// (start, notyet, skip, confirm, woke, monitor). Each action is "verb@time".
NapPlan scriptedPlan(List<String> actions) {
  final plan = NapPlan();
  for (final a in actions) {
    final parts = a.split('@');
    if (parts.length == 2) {
      final t = int.parse(parts[1]);
      plan.setNow((t ~/ 100) * 60 + t % 100);
    }
    final s = plan.focus;
    switch (parts[0]) {
      case 'start' when s != null: plan.startNap(s);
      case 'notyet' when s != null: plan.notYet(s);
      case 'skip' when s != null: plan.skip(s);
      case 'confirm' when s != null: plan.confirm(s);
      case 'woke' when s != null: plan.wokeUpNow(s);
      case 'monitor': plan.monitorDetects();
      default: break;
    }
  }
  return plan;
}

/// Home devices variants by id, for the launcher and the screenshot remote.
Widget homeDevicesVariant(String id, Ownership initial) => switch (id) {
  'v1' => V1FrostedPairPage(key: UniqueKey(), initial: initial),
  'v2' => V2WindowDisplayPage(key: UniqueKey(), initial: initial),
  'v3' => V3LeadFollowPage(key: UniqueKey(), initial: initial),
  'v4' => V4DeckPage(key: UniqueKey(), initial: initial),
  _ => V5NurseryShelfPage(key: UniqueKey(), initial: initial),
};

class _MoonboonUIAppState extends State<MoonboonUIApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  Timer? _remote;
  String? _lastCommand;

  // Screenshot remote (debug only): write "hd <v1..v5> <none|monitor|bouncer|both>
  // <light|dark>" to the app's tmp/remote.txt and the app jumps there.
  @override
  void initState() {
    super.initState();
    appDark.value = _shotDark;
    assert(() {
      _remote = Timer.periodic(const Duration(milliseconds: 400), (_) => _poll());
      return true;
    }());
  }

  void _poll() {
    final file = File('${Directory.systemTemp.path}/remote.txt');
    if (!file.existsSync()) return;
    final command = file.readAsStringSync().trim();
    if (command == _lastCommand) return;
    _lastCommand = command;
    final parts = command.split(' ');
    if (parts.length >= 3 && parts[0] == 'pn') {
      appDark.value = parts[2] == 'dark';
      NapsPlayground.initialScroll = parts.contains('scroll') ? 330 : 0;
      final plan = scriptedPlan(parts.sublist(3));
      _navigatorKey.currentState?.pushAndRemoveUntil(
        PageRouteBuilder(pageBuilder: (_, _, _) => predictedNapsVersion(parts[1], plan)),
        (_) => false,
      );
      return;
    }
    if (parts.length < 4 || parts[0] != 'hd') return;
    appDark.value = parts[3] == 'dark';
    final ownership = Ownership.values.byName(parts[2]);
    _navigatorKey.currentState?.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => homeDevicesVariant(parts[1], ownership),
      ),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _remote?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: appDark,
    builder: (context, dark, _) => _build(context, dark),
  );

  Widget _build(BuildContext context, bool isDark) {
    final colors = isDark ? ThemeColors.darkVariantC : ThemeColors.light;
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Moonboon Monitor Setup',
      debugShowCheckedModeBanner: false,
      theme: buildThemeWithColors(colors, isDark ? Brightness.dark : Brightness.light),
      themeMode: ThemeMode.light,
      home: switch (_shot) {
        'v1' => const V1StackedListPage(),
        'v2' => const V2HeroActionsPage(),
        'v3' => const V3TileDashboardPage(),
        'v4' => const V4PhotoCardsPage(),
        'v5' => const V5ConstellationPage(),
        'flow' => const SettingsRootPage(),
        'flow-member' => _flowAs(Viewer.member, FamilyScenario.full),
        'flow-solo' => _flowAs(Viewer.owner, FamilyScenario.solo),
        'flow-empty' => _flowAs(Viewer.owner, FamilyScenario.empty),
        'flow-profile' => const ProfilePage(),
        'flow-baby' => BabyFormPage(mode: BabyFormMode.edit, baby: FlowState.i.baby!),
        'flow-add-baby' => const BabyFormPage(mode: BabyFormMode.create),
        'flow-request' => const RequestAccessPage(),
        'flow-help' => const HelpPage(),
        'ref' => const RefOverviewPage(),
        'ref-logout' => const RefOverviewPage(autoOpen: 'logout'),
        'ref-delete' => const RefOverviewPage(autoOpen: 'delete'),
        'ref-profile' => const RefProfilePage(),
        'ref-country' => const RefProfilePage(autoOpen: 'country'),
        'ref-family' => const RefFamilyPage(),
        'ref-member' => const RefFamilyPage(autoOpen: 'member'),
        'ref-remove' => const RefFamilyPage(autoOpen: 'remove'),
        'ref-invite' => const RefFamilyPage(autoOpen: 'invite'),
        'ref-baby' => const RefBabyPage(),
        'ref-feedback' => const _RefFeedbackShot(),
        _ => _LauncherPage(
            isDark: isDark,
            onToggleDark: () => appDark.value = !appDark.value,
          ),
      },
    );
  }
}

// ── Launcher ──────────────────────────────────────────────────────────────────

/// Screenshot helper: overview with the feedback sheet already open.
class _RefFeedbackShot extends StatefulWidget {
  const _RefFeedbackShot();

  @override
  State<_RefFeedbackShot> createState() => _RefFeedbackShotState();
}

class _RefFeedbackShotState extends State<_RefFeedbackShot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showRefFeedbackSheet(context);
    });
  }

  @override
  Widget build(BuildContext context) => const RefOverviewPage();
}

class _LauncherPage extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleDark;

  const _LauncherPage({required this.isDark, required this.onToggleDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.surfacePrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Moonboon',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Monitor Setup',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.color.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onToggleDark,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.color.textPrimary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        size: 20,
                        color: context.color.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ══════════════════════════════════════════════════════════════
              // PROTOTYPE — Predicted naps on Home
              // ══════════════════════════════════════════════════════════════
              _SectionLabel(label: 'Prototype · Predicted naps', accent: true),
              const SizedBox(height: 4),
              Text(
                'Ella, 8 months. Jump the clock and try Start nap, Not yet, ×, Confirm and Adjust at the top of each version.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.color.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              for (final (id, label, subtitle) in const [
                ('e1', 'E1 · Next nap card', 'Existing components: the suggestion card on top of today'),
                ('e2', 'E2 · Coming up list', 'Predicted naps and bedtime join the list, dashed'),
                ('e3', 'E3 · Timeline ribbon', "Ella's day as a 06–20 ribbon, tap blocks and chips"),
                ('e4', 'E4 · Day arc', 'Napper-style arc from wake-up to bedtime, countdown inside'),
              ]) ...[
                _FlowTile(
                  label: label,
                  subtitle: subtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => predictedNapsVersion(id)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 36),

              // ══════════════════════════════════════════════════════════════
              // PROTOTYPE — New home: always both device cards
              // ══════════════════════════════════════════════════════════════
              _SectionLabel(label: 'Prototype · New home device cards', accent: true),
              const SizedBox(height: 4),
              Text(
                'Both devices always shown; unowned ones frosted, tap to set up. Switch states at the top.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.color.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              for (final (id, label, subtitle) in const [
                ('v1', 'V1 · The Frosted Pair', 'Card grid — production 2-up cards, unowned frosted'),
                ('v2', 'V2 · The Window Display', 'Stacked — unowned as a tall blurred photo with a promise'),
                ('v3', 'V3 · Lead & Follow', 'Hero + companion — owned leads, unowned a narrow sliver'),
                ('v4', 'V4 · The Deck', 'Carousel — tall photo cards, unowned peeking off the edge'),
                ('v5', 'V5 · The Nursery Shelf', 'Spatial — both products in one scene, unowned out of focus'),
              ]) ...[
                _FlowTile(
                  label: label,
                  subtitle: subtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => homeDevicesVariant(id, Ownership.none),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 36),

              // ══════════════════════════════════════════════════════════════
              // PROTOTYPE — Revised Settings (CU-86cavd37q)
              // ══════════════════════════════════════════════════════════════
              _SectionLabel(label: 'Prototype · Revised Settings', accent: true),
              const SizedBox(height: 4),
              Text(
                'V2 picked — full flow deep dive, all mapped cases.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.color.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              _FlowTile(
                label: 'V2 Flow · Settings deep dive',
                subtitle: 'Root states, profile, baby, invite, members, help — all wired',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsRootPage()),
                ),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'V3 Refinement · Designer direction',
                subtitle: 'Figma refinement file — overview, profile, family orbit, baby, feedback',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RefOverviewPage()),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 4),
              Text(
                'CU-86cavd37q — 5 divergent directions for the coffee deck.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.color.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              _FlowTile(
                label: 'V1 · The Calm Index',
                subtitle: 'Stacked list — grouped sections, baby pinned on top',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const V1StackedListPage()),
                ),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'V2 · Family First',
                subtitle: 'Hero + actions — Vera as the emotional center',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const V2HeroActionsPage()),
                ),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'V3 · The Glance Board',
                subtitle: 'Dashboard tiles — live peek content, one-tap access',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const V3TileDashboardPage()),
                ),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'V4 · The Album',
                subtitle: 'Full-bleed imagery cards — Devices-page language',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const V4PhotoCardsPage()),
                ),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'V5 · The Constellation',
                subtitle: 'Spatial map — caregivers orbiting Vera on threads',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const V5ConstellationPage()),
                ),
              ),

              const SizedBox(height: 48),

              // ══════════════════════════════════════════════════════════════
              // MONITOR SETUP FLOW — Design → PR pipeline
              // ══════════════════════════════════════════════════════════════
              _SectionLabel(label: 'Monitor setup flow', accent: true),
              const SizedBox(height: 4),
              Text(
                'Checkmark = PR\'d into production. Tap to preview the design.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.color.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              _FlowTile(
                label: 'Charge device',
                subtitle: 'Radar pulse + USB-C cable animation, keyboard-aware collapse',
                onTap: () => _openStep(context, (c) => c.showChargeStep()),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'Searching for monitor',
                subtitle: 'Bluetooth scan with radar animation',
                onTap: () => _openStep(context, (c) => c.showSearchingStep()),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'Monitor found',
                subtitle: 'Name entry — tap Connect to continue',
                onTap: () => _openStep(context, (c) => c.showFoundStep()),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'WiFi networks',
                subtitle: 'Network list — tap a network to enter password',
                onTap: () => _openStep(context, (c) => c.showWifiListStep()),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'WiFi password',
                subtitle: 'Password input for selected network',
                onTap: () => _openStep(context, (c) => c.showWifiPasswordStep()),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'Provisioning',
                subtitle: 'Progress indicator — connecting, uploading, firmware check',
                onTap: () => _openStep(context, (c) => c.showProvisioningStep()),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'Noise detection',
                subtitle: 'Sensitivity level selector + AI filtering toggle',
                onTap: () => _openStep(context, (c) => c.showNoiseDetectionStep()),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'Streaming consent',
                subtitle: 'Allow audio streaming for remote monitoring',
                onTap: () => _openStep(context, (c) => c.showStreamingConsentStep()),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'Error state',
                subtitle: 'Something went wrong — retry + troubleshoot',
                onTap: () => _openMonitorFlow(context, simulateError: true),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'Troubleshoot guide',
                subtitle: 'Full-screen guide — charging, Bluetooth, WiFi, reset',
                onTap: () => openMonitorTroubleshootPage(context),
              ),

              const SizedBox(height: 16),

              _FlowTile(
                label: 'Full flow (end-to-end)',
                subtitle: 'Charge → Search → Found → WiFi → Provisioning → Consent → Done',
                onTap: () => _openMonitorFlow(context),
              ),

              const SizedBox(height: 48),

              // ══════════════════════════════════════════════════════════════
              // OTHER EXPLORATIONS
              // ══════════════════════════════════════════════════════════════
              _SectionLabel(label: 'Other explorations'),
              const SizedBox(height: 4),
              Text(
                'Concept demos and standalone screens. Not part of the setup flow PRs.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.color.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              _FlowTile(
                label: 'Sound monitoring consent',
                subtitle: 'Enable or disable sound monitoring (removed from prod)',
                onTap: () => _openStep(context, (c) => c.showConsentStep()),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'Welcome gift',
                subtitle: 'Moonboon Plus onboarding screen',
                onTap: () => _openStep(context, (c) => c.showWelcomeGiftStep()),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'Last night report',
                subtitle: 'Card + detail sheet — night bar, vertical timeline, insights',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MockLastNightPage()),
                ),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'Nap tracking (full screen)',
                subtitle: 'Live timer, collapse chevron, pause/save — auto-opens on start',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MockNapTrackingPage()),
                ),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'Baby sleep — Learning phase',
                subtitle: 'Track naps + feeds · live timer · timeline · insight cards',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BabySleepHomePage()),
                ),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'Monitor stream',
                subtitle: 'Telemetry cards, video feed, action buttons',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MockMonitorStreamPage()),
                ),
              ),
              const SizedBox(height: 12),
              _FlowTile(
                label: 'Firmware update',
                subtitle: 'Sheet — update now vs. continue without updating',
                onTap: () => showFirmwareUpdateSheet(
                  context,
                  onUpdate: () {},
                  onContinueWithout: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the full connected monitor provisioning flow.
  void _openMonitorFlow(BuildContext context, {bool simulateError = false}) {
    _openSetupSheet(
      context,
      child: (ctx) => BlocProvider(
        create: (_) {
          final cubit = MockMonitorCubit();
          if (simulateError) {
            cubit.simulateError(SetupErrorType.monitorNotFound);
          } else {
            cubit.checkCurrentUser();
          }
          return cubit;
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height - 60),
          child: const MonitorProvisioningPage(),
        ),
      ),
    );
  }

  /// Opens the monitor setup sheet with the cubit jumped to a specific step.
  void _openStep(BuildContext context, void Function(MockMonitorCubit) jumpTo) {
    _openSetupSheet(
      context,
      child: (ctx) => BlocProvider(
        create: (_) {
          final cubit = MockMonitorCubit();
          jumpTo(cubit);
          return cubit;
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height - 60),
          child: const MonitorProvisioningPage(),
        ),
      ),
    );
  }

  void _openSetupSheet(BuildContext context, {required Widget Function(BuildContext) child}) {
    final br = DeviceRadius.instance.bottomSheetRadius;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (ctx) {
        final keyboardUp = MediaQuery.of(ctx).viewInsets.bottom > 0;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            left: keyboardUp ? 0 : 6,
            right: keyboardUp ? 0 : 6,
            top: keyboardUp ? 0 : 6,
            bottom: keyboardUp ? 0 : 6,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: keyboardUp
                  ? const BorderRadius.vertical(top: Radius.circular(32))
                  : BorderRadius.only(
                      topLeft: const Radius.circular(32),
                      topRight: const Radius.circular(32),
                      bottomLeft: Radius.circular(br),
                      bottomRight: Radius.circular(br),
                    ),
              color: getModalSheetBackgroundColor(ctx, ModalSheetBackground.white),
            ),
            child: child(ctx),
          ),
        );
      },
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool accent;

  const _SectionLabel({required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: accent ? context.color.brandPrimary : context.color.textTertiary,
        letterSpacing: 1.2,
        fontWeight: accent ? FontWeight.w600 : null,
      ),
    );
  }
}

// ── Flow tile ─────────────────────────────────────────────────────────────────

class _FlowTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final bool done;

  const _FlowTile({
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: context.color.surfaceTertiary.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badge == 'TEST'
                                ? context.color.feedbackInfo.withValues(alpha: 0.15)
                                : context.color.brandPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            badge!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: badge == 'TEST'
                                  ? context.color.feedbackInfo
                                  : context.color.brandPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.color.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (done)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: context.color.feedbackSuccess,
                ),
              ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: context.color.textQuaternary,
            ),
          ],
        ),
      ),
    );
  }
}
