import 'package:flutter/material.dart';

import '../../../app/navigation/app_dock_navigation.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/widgets/current_location_picker.dart';
import '../../../app/theme/trikaal_surface.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/trikaal_app_bar.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../charts/data/models/compute_report_models.dart';
import '../../feed/data/models/feed_post.dart';
import '../../feed/presentation/feed_page.dart';
import '../../feed/presentation/feed_post_detail_page.dart';
import '../../feed/presentation/state/feed_controller.dart';
import '../../feed/presentation/widgets/feed_post_card.dart';
import '../../feed/share/feed_sharing.dart';
import '../../home/presentation/astrology/rashi_insights.dart';
import '../../shared/astrology/sign_trio_insights.dart';

const List<String> _profileGrahaOrder = <String>[
  'lagna',
  'sun',
  'moon',
  'mangal',
  'budha',
  'guru',
  'shukra',
  'shani',
  'rahu',
  'ketu',
];

const Map<String, String> _grahaLabel = <String, String>{
  'lagna': 'ASCENDANT',
  'sun': 'SUN',
  'moon': 'MOON',
  'mangal': 'MARS',
  'budha': 'MERCURY',
  'guru': 'JUPITER',
  'shukra': 'VENUS',
  'shani': 'SATURN',
  'rahu': 'RAHU',
  'ketu': 'KETU',
};

const Map<String, String> _grahaGlyph = <String, String>{
  'lagna': '↑',
  'sun': '☉',
  'moon': '☽',
  'mangal': '♂',
  'budha': '☿',
  'guru': '♃',
  'shukra': '♀',
  'shani': '♄',
  'rahu': '☊',
  'ketu': '☋',
};

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.birthInputState,
    this.feedController,
    super.key,
  });

  final BirthInputState birthInputState;

  /// Injectable for tests; the page creates and owns one by default.
  final FeedController? feedController;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _activeTabIndex = 0;
  late final FeedController _feedController;

  BirthInputState get birthInputState => widget.birthInputState;

  bool get _ownsFeedController => widget.feedController == null;

  @override
  void initState() {
    super.initState();
    _feedController = widget.feedController ?? FeedController();
    _feedController.interactions.load();
  }

  @override
  void dispose() {
    if (_ownsFeedController) {
      _feedController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = birthInputState.computedReport;
    if (report == null) {
      return UniversalDockScaffold(
        activeItem: AppDockItem.profile,
        onItemSelected: (AppDockItem item) => _handleDockItemTap(context, item),
        appBar: buildTrikaalAppBar(
          context,
          onCurrentLocationTap: () => showCurrentLocationPickerSheet(
            context: context,
            birthInputState: birthInputState,
          ),
          currentLocationLabel: birthInputState.placeForCurrentObservations,
          onPremiumTap: () => _handleDockItemTap(context, AppDockItem.premium),
        ),
        body: const AstroPageBackground(
          child: Center(
            child: Text('Profile is available after chart computation.'),
          ),
        ),
      );
    }

    final displayName = birthInputState.firstName.trim().isEmpty
        ? 'You'
        : birthInputState.firstName.trim();
    final handle =
        '@${displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';
    final trio = SignTrioInsights.fromReport(report);
    final sun = trio.sun;
    final moon = trio.moon;
    final rising = trio.rising;

    return UniversalDockScaffold(
      activeItem: AppDockItem.profile,
      onItemSelected: (AppDockItem item) => _handleDockItemTap(context, item),
      appBar: buildTrikaalAppBar(
        context,
        onCurrentLocationTap: () => showCurrentLocationPickerSheet(
          context: context,
          birthInputState: birthInputState,
        ),
        currentLocationLabel: birthInputState.placeForCurrentObservations,
        onPremiumTap: () => _handleDockItemTap(context, AppDockItem.premium),
      ),
      body: AstroPageBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const CircleAvatar(
                      radius: 26,
                      child: Icon(Icons.person_rounded, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  displayName,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  handle,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '☉ ${sun.name}  ☽ ${moon.name}  ↑ ${rising.name}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _ProfileTabBar(
                activeIndex: _activeTabIndex,
                tabs: const <String>['Chart', 'Saved', 'Settings'],
                onTabSelected: (int index) {
                  setState(() {
                    _activeTabIndex = index;
                  });
                },
              ),
              Expanded(child: _buildActiveTab(context, report)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTab(BuildContext context, ComputeReportResponse report) {
    switch (_activeTabIndex) {
      case 1:
        return _buildSavedTab(context);
      case 2:
        return _buildSettingsTab(context);
      default:
        return _buildChartTab(context, report);
    }
  }

  Widget _buildSavedTab(BuildContext context) {
    return AnimatedBuilder(
      animation: _feedController,
      builder: (BuildContext context, Widget? child) {
        final interactions = _feedController.interactions;
        if (!interactions.loaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final savedPosts = interactions.savedPosts;
        if (savedPosts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Posts you save from the Feed will appear here.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const FeedPage(),
                        ),
                      );
                    },
                    child: const Text('Open Feed'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
          itemCount: savedPosts.length,
          itemBuilder: (BuildContext context, int index) {
            final post = savedPosts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FeedPostCard(
                post: post,
                isLiked: interactions.isLiked(post.id),
                likeCount: interactions.likeCountFor(post),
                isSaved: true,
                onToggleLike: () => interactions.toggleLike(post),
                onToggleSave: () => _unsavePost(post),
                onShare: () => shareFeedPostWithFeedback(context, post),
                onOpen: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return FeedPostDetailPage(
                          postId: post.id,
                          controller: _feedController,
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _unsavePost(FeedPost post) {
    _feedController.interactions.toggleSave(post);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Removed from your saved posts.')),
      );
  }

  Widget _buildSettingsTab(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.settings_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            const Text(
              'Settings are coming soon.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTab(BuildContext context, ComputeReportResponse report) {
    final chartRows = _buildChartRows(report.snapshot.grahaTable);
    final tableBorderColor =
        TrikaalSurface.border(Theme.of(context).colorScheme).color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Align(
        alignment: Alignment.topCenter,
        child: IntrinsicHeight(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: DecoratedBox(
              decoration: TrikaalSurface.decoration(
                colorScheme: Theme.of(context).colorScheme,
                radius: 18,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    width: 28,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, top: 14),
                        child: Text(
                          'S\nI\nG\nN\nS',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 11.2,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Table(
                        columnWidths: const <int, TableColumnWidth>{
                          0: FlexColumnWidth(1.05),
                          1: FlexColumnWidth(1.34),
                          2: FlexColumnWidth(0.34),
                        },
                        border: TableBorder(
                          verticalInside: BorderSide(
                              color: tableBorderColor, width: 0.8),
                        ),
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: chartRows.map((row) {
                          final signBottomBorder =
                              row.isLastRow || !row.isRashiGroupEnd
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: tableBorderColor,
                                      width: 0.8,
                                    );
                          final houseBottomBorder =
                              row.isLastRow || !row.isHouseGroupEnd
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: tableBorderColor,
                                      width: 0.8,
                                    );
                          return TableRow(
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: signBottomBorder,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    row.showRashi
                                        ? _rashiName(row.rashiCode)
                                        : '',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                color: const Color(0xFF10002B),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    '${_grahaGlyph[row.grahaKey] ?? '•'} ${_grahaLabel[row.grahaKey] ?? row.grahaKey.toUpperCase()}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 11.9,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.18,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: houseBottomBorder,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    row.showHouse ? '${row.house}' : '',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 13.3,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(growable: false),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10, bottom: 14),
                        child: Text(
                          'H\nO\nU\nS\nE\nS',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11.2,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleDockItemTap(BuildContext context, AppDockItem item) {
    handleAppDockSelection(
      context: context,
      tappedItem: item,
      activeItem: AppDockItem.profile,
      birthInputState: birthInputState,
      homeBehavior: DockHomeBehavior.popOne,
      chartsBehavior: DockChartsBehavior.pushFeatures,
    );
  }

  List<_ProfileChartRow> _buildChartRows(ReportGrahaTable table) {
    final entries = _profileGrahaOrder
        .map((String key) => table.entryByKey(key))
        .toList(growable: false)
      ..sort((a, b) {
        final byHouse = a.house.compareTo(b.house);
        if (byHouse != 0) {
          return byHouse;
        }
        final aOrder = _profileGrahaOrder.indexOf(a.key);
        final bOrder = _profileGrahaOrder.indexOf(b.key);
        return aOrder.compareTo(bOrder);
      });

    String? previousRashi;
    int? previousHouse;
    final rows = <_ProfileChartRow>[];
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      final nextEntry = index + 1 < entries.length ? entries[index + 1] : null;
      final showRashi = previousRashi != entry.rashi;
      final showHouse = previousHouse != entry.house;
      rows.add(
        _ProfileChartRow(
          rashiCode: entry.rashi,
          grahaKey: entry.key,
          house: entry.house,
          showRashi: showRashi,
          showHouse: showHouse,
          isRashiGroupEnd: nextEntry == null || nextEntry.rashi != entry.rashi,
          isHouseGroupEnd: nextEntry == null || nextEntry.house != entry.house,
          isLastRow: nextEntry == null,
        ),
      );
      previousRashi = entry.rashi;
      previousHouse = entry.house;
    }
    return rows;
  }

  String _rashiName(String rawCode) {
    return rashiInsightFor(rawCode).name;
  }
}

class _ProfileChartRow {
  const _ProfileChartRow({
    required this.rashiCode,
    required this.grahaKey,
    required this.house,
    required this.showRashi,
    required this.showHouse,
    required this.isRashiGroupEnd,
    required this.isHouseGroupEnd,
    required this.isLastRow,
  });

  final String rashiCode;
  final String grahaKey;
  final int house;
  final bool showRashi;
  final bool showHouse;
  final bool isRashiGroupEnd;
  final bool isHouseGroupEnd;
  final bool isLastRow;
}

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({
    required this.tabs,
    required this.activeIndex,
    required this.onTabSelected,
  });

  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.onSurface;
    final inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      // Transparent Material so tab ripples paint above the opaque
      // AstroPageBackground instead of on the Scaffold's material below it.
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          children: List<Widget>.generate(tabs.length, (index) {
            final isActive = index == activeIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onTabSelected(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                          color: isActive ? activeColor : inactiveColor,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      height: 1.8,
                      color: isActive
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
