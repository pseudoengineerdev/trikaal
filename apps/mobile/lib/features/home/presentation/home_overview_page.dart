import 'package:flutter/material.dart';

import '../../../app/navigation/app_dock_navigation.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/state/terminology_mode_state.dart';
import '../../../app/widgets/current_location_picker.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/trikaal_app_bar.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../feed/presentation/feed_page.dart';
import '../../feed/presentation/state/feed_controller.dart';
import '../../shared/astrology/sign_trio_insights.dart';
import 'widgets/home_header_tabs.dart';

class HomeOverviewPage extends StatefulWidget {
  const HomeOverviewPage({
    required this.birthInputState,
    super.key,
  });

  final BirthInputState birthInputState;

  @override
  State<HomeOverviewPage> createState() => _HomeOverviewPageState();
}

class _HomeOverviewPageState extends State<HomeOverviewPage> {
  static const Duration _tabTransitionDuration = Duration(milliseconds: 280);

  final PageController _pageController = PageController();
  // The app-wide instance: this toggle is the only place the mode can be
  // changed, but every term-rendering screen observes the same state.
  final TerminologyModeState _terminologyModeState =
      TerminologyModeState.shared;
  // Owned here (not by the Feed tab's view) so likes and loaded pages
  // survive tab switches even if the view is rebuilt.
  final FeedController _feedController = FeedController();
  HomeTab _activeTab = HomeTab.today;

  @override
  void initState() {
    super.initState();
    _terminologyModeState.load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _feedController.dispose();
    super.dispose();
  }

  void _selectTab(HomeTab tab) {
    if (tab == _activeTab) {
      return;
    }
    setState(() => _activeTab = tab);
    _pageController.animateToPage(
      tab.index,
      duration: _tabTransitionDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePageChanged(int index) {
    final tab = HomeTab.values[index];
    if (tab == _activeTab) {
      return;
    }
    setState(() => _activeTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    return UniversalDockScaffold(
      appBar: buildTrikaalAppBar(
        context,
        onCurrentLocationTap: () => showCurrentLocationPickerSheet(
          context: context,
          birthInputState: widget.birthInputState,
        ),
        currentLocationLabel: widget.birthInputState.placeForCurrentObservations,
        onCalendarTap: () =>
            openHinduCalendar(context, widget.birthInputState),
        onPremiumTap: () => _handleDockItemTap(context, AppDockItem.premium),
        bottom: HomeHeaderTabs(
          activeTab: _activeTab,
          onTabSelected: _selectTab,
          terminologyListenable: _terminologyModeState,
          onTerminologyChanged: _terminologyModeState.setMode,
        ),
      ),
      activeItem: AppDockItem.home,
      onItemSelected: (AppDockItem item) => _handleDockItemTap(context, item),
      body: AstroPageBackground(
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            onPageChanged: _handlePageChanged,
            children: <Widget>[
              _TodayTab(birthInputState: widget.birthInputState),
              FeedView(
                controller: _feedController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDockItemTap(BuildContext context, AppDockItem item) {
    handleAppDockSelection(
      context: context,
      tappedItem: item,
      activeItem: AppDockItem.home,
      birthInputState: widget.birthInputState,
      homeBehavior: DockHomeBehavior.stay,
      chartsBehavior: DockChartsBehavior.pushFeatures,
    );
  }
}

class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.birthInputState});

  final BirthInputState birthInputState;

  @override
  Widget build(BuildContext context) {
    final report = birthInputState.computedReport;
    if (report == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.auto_awesome_rounded, size: 40),
              SizedBox(height: 10),
              Text(
                'We need your birth mix to build your personalized home.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final trio = SignTrioInsights.fromReport(report);
    final sun = trio.sun;
    final moon = trio.moon;
    final rising = trio.rising;
    final displayName = birthInputState.firstName.trim().isEmpty
        ? 'Your Profile'
        : birthInputState.firstName.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Welcome, $displayName',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 18),
          _HomeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Your Sign Trio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _SignPill(label: '☉ ${sun.name} ${sun.symbol}'),
                    _SignPill(label: '☽ ${moon.name} ${moon.symbol}'),
                    _SignPill(label: '↑ ${rising.name} ${rising.symbol}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the center profile button for your full "About You" section.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

class _SignPill extends StatelessWidget {
  const _SignPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(
              alpha: 0.32,
            ),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
