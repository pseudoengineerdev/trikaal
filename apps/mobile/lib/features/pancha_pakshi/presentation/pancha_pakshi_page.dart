import 'package:flutter/material.dart';

import '../../../app/navigation/app_dock_navigation.dart';
import '../../../app/models/custom_place_payload.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/trikaal_app_bar.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../charts/data/models/place_search_models.dart';
import '../../charts/presentation/widgets/chart_state_widgets.dart';
import '../data/models/pancha_pakshi_models.dart';
import 'state/pancha_pakshi_controller.dart';

class PanchaPakshiPage extends StatefulWidget {
  const PanchaPakshiPage({
    required this.birthInputState,
    super.key,
  });

  final BirthInputState birthInputState;

  @override
  State<PanchaPakshiPage> createState() => _PanchaPakshiPageState();
}

class _PanchaPakshiPageState extends State<PanchaPakshiPage> {
  late final PanchaPakshiController _controller;
  late final TextEditingController _runtimePlaceController;
  String? _lastInputSignature;
  String? _runtimePlaceQuery;
  String? _runtimePlaceDisplayLabel;
  CustomPlacePayload? _runtimeCustomPlace;
  String? _locationStatusMessage;

  @override
  void initState() {
    super.initState();
    _controller = PanchaPakshiController();
    _runtimePlaceController = TextEditingController();
    _locationStatusMessage = 'Using birth location for live activity windows.';
    widget.birthInputState.addListener(_handleBirthInputChange);
    _load();
  }

  @override
  void dispose() {
    widget.birthInputState.removeListener(_handleBirthInputChange);
    _runtimePlaceController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _load() {
    final input = _readBirthInputSnapshot();
    if (input == null) {
      _lastInputSignature = null;
      return;
    }
    _lastInputSignature = _buildInputSignature(
      dateOfBirth: input.dateOfBirth,
      timeOfBirth: input.timeOfBirth,
      placeOfBirth: input.placeOfBirth,
    );
    _loadPanchaPakshi(input);
  }

  void _handleBirthInputChange() {
    final input = _readBirthInputSnapshot();
    if (input == null) {
      if (_lastInputSignature != null) {
        _lastInputSignature = null;
        setState(() {});
      }
      return;
    }
    final inputSignature = _buildInputSignature(
      dateOfBirth: input.dateOfBirth,
      timeOfBirth: input.timeOfBirth,
      placeOfBirth: input.placeOfBirth,
    );
    if (inputSignature == _lastInputSignature) {
      return;
    }
    _lastInputSignature = inputSignature;
    _loadPanchaPakshi(input);
  }

  _BirthInputSnapshot? _readBirthInputSnapshot() {
    final dateOfBirth = widget.birthInputState.dateOfBirth.trim();
    final timeOfBirth = widget.birthInputState.timeOfBirth.trim();
    final placeOfBirth = widget.birthInputState.placeOfBirth.trim();
    if (dateOfBirth.isEmpty || timeOfBirth.isEmpty || placeOfBirth.isEmpty) {
      return null;
    }
    return _BirthInputSnapshot(
      dateOfBirth: dateOfBirth,
      timeOfBirth: timeOfBirth,
      placeOfBirth: placeOfBirth,
    );
  }

  void _loadPanchaPakshi(_BirthInputSnapshot input) {
    _controller.load(
      dateOfBirth: input.dateOfBirth,
      timeOfBirth: input.timeOfBirth,
      placeOfBirth: input.placeOfBirth,
      customPlace: widget.birthInputState.customPlace,
      runtimePlaceOfObservation: _runtimePlaceQuery,
      runtimeCustomPlace: _runtimeCustomPlace,
    );
  }

  void _onRuntimePlaceQueryChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _runtimePlaceQuery = null;
        _runtimePlaceDisplayLabel = null;
        _runtimeCustomPlace = null;
        _locationStatusMessage =
            'Using birth location for live activity windows.';
      });
      _controller.clearPlaceSuggestions();
      _load();
      return;
    }
    _controller.onRuntimePlaceQueryChanged(trimmed);
  }

  void _onRuntimePlaceSelected(PlaceMatch place) {
    _runtimePlaceController.text = place.placeLabel;
    _runtimePlaceController.selection = TextSelection.collapsed(
      offset: _runtimePlaceController.text.length,
    );
    setState(() {
      _runtimePlaceQuery = place.placeLabel;
      _runtimePlaceDisplayLabel = place.placeLabel;
      _runtimeCustomPlace = CustomPlacePayload(
        placeLabel: place.placeLabel,
        latitude: place.latitude,
        longitude: place.longitude,
        timezone: place.timezone,
        elevationM: place.elevationM,
      );
      _locationStatusMessage =
          'Using ${place.placeLabel} for live activity windows.';
    });
    _controller.clearPlaceSuggestions();
    _load();
  }

  void _useBirthLocationRuntime() {
    _runtimePlaceController.clear();
    setState(() {
      _runtimePlaceQuery = null;
      _runtimePlaceDisplayLabel = null;
      _runtimeCustomPlace = null;
      _locationStatusMessage =
          'Using birth location for live activity windows.';
    });
    _controller.clearPlaceSuggestions();
    _load();
  }

  String _buildInputSignature({
    required String dateOfBirth,
    required String timeOfBirth,
    required String placeOfBirth,
  }) {
    final customPlace = widget.birthInputState.customPlace;
    final customHash = customPlace == null
        ? ''
        : '${customPlace.latitude.toStringAsFixed(6)}|'
            '${customPlace.longitude.toStringAsFixed(6)}|'
            '${customPlace.timezone}|${customPlace.elevationM.toStringAsFixed(1)}';
    return '$dateOfBirth|$timeOfBirth|$placeOfBirth|$customHash';
  }

  @override
  Widget build(BuildContext context) {
    return UniversalDockScaffold(
      appBar: buildTrikaalAppBar(
        context,
        onPremiumTap: () => _handleDockItemTap(context, AppDockItem.premium),
      ),
      activeItem: AppDockItem.charts,
      onItemSelected: (AppDockItem item) => _handleDockItemTap(context, item),
      body: AstroPageBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? _) {
              final hasBirthInput =
                  widget.birthInputState.dateOfBirth.trim().isNotEmpty &&
                      widget.birthInputState.timeOfBirth.trim().isNotEmpty &&
                      widget.birthInputState.placeOfBirth.trim().isNotEmpty;

              if (!hasBirthInput) {
                return _StateMessage(
                  title: 'Birth details needed',
                  body:
                      'Complete onboarding first so we can calculate your Pancha Pakshi.',
                  actionLabel: 'Go to Home',
                  onAction: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                );
              }

              if (_controller.loading && _controller.result == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_controller.error != null && _controller.result == null) {
                return _StateMessage(
                  title: 'Unable to load Pancha Pakshi',
                  body: _controller.error!,
                  actionLabel: 'Retry',
                  onAction: _load,
                );
              }

              final result = _controller.result;
              if (result == null) {
                return _StateMessage(
                  title: 'No Pancha Pakshi data yet',
                  body: 'Tap retry to fetch your live Pakshi window.',
                  actionLabel: 'Retry',
                  onAction: _load,
                );
              }
              final payload = result.panchaPakshi;
              final usingCurrentReference = _runtimeCustomPlace != null &&
                  payload.runtime.referencePlaceLabel.trim().toLowerCase() ==
                      _runtimeCustomPlace!.placeLabel.trim().toLowerCase();
              return RefreshIndicator(
                onRefresh: _controller.refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
                  children: <Widget>[
                    _BirthPakshiCard(payload: payload),
                    const SizedBox(height: 12),
                    _RealtimeLocationCard(
                      usingCurrentLocation: usingCurrentReference,
                      placeController: _runtimePlaceController,
                      loadingSuggestions: _controller.loadingPlaceSuggestions,
                      suggestions: _controller.placeSuggestions,
                      currentLocationLabel: _runtimePlaceDisplayLabel,
                      statusMessage: _locationStatusMessage,
                      onPlaceQueryChanged: _onRuntimePlaceQueryChanged,
                      onPlaceSelected: _onRuntimePlaceSelected,
                      onUseBirthLocation: _useBirthLocationRuntime,
                    ),
                    const SizedBox(height: 12),
                    _ActiveWindowCard(
                      payload: payload,
                      secondsRemaining: _controller.secondsRemaining,
                      refreshing: _controller.refreshing,
                    ),
                    const SizedBox(height: 12),
                    ...payload.timeline.map((window) {
                      final isActive =
                          window.majorIndex == payload.active.majorIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MajorWindowCard(
                          window: window,
                          runtime: payload.runtime,
                          isActive: isActive,
                          activeMajorIndex: payload.active.majorIndex,
                          activeSubActivity: payload.active.subActivity,
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleDockItemTap(BuildContext context, AppDockItem item) {
    handleAppDockSelection(
      context: context,
      tappedItem: item,
      activeItem: AppDockItem.charts,
      birthInputState: widget.birthInputState,
      homeBehavior: DockHomeBehavior.popToRoot,
      chartsBehavior: DockChartsBehavior.popOne,
    );
  }
}

class _BirthInputSnapshot {
  const _BirthInputSnapshot({
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
  });

  final String dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealtimeLocationCard extends StatelessWidget {
  const _RealtimeLocationCard({
    required this.usingCurrentLocation,
    required this.placeController,
    required this.loadingSuggestions,
    required this.suggestions,
    required this.currentLocationLabel,
    required this.statusMessage,
    required this.onPlaceQueryChanged,
    required this.onPlaceSelected,
    required this.onUseBirthLocation,
  });

  final bool usingCurrentLocation;
  final TextEditingController placeController;
  final bool loadingSuggestions;
  final List<PlaceMatch> suggestions;
  final String? currentLocationLabel;
  final String? statusMessage;
  final ValueChanged<String> onPlaceQueryChanged;
  final ValueChanged<PlaceMatch> onPlaceSelected;
  final VoidCallback onUseBirthLocation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Realtime Location Mode',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              usingCurrentLocation
                  ? 'Using current location for live activity windows.'
                  : 'Using birth location for live activity windows.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: placeController,
              decoration: const InputDecoration(
                labelText: 'Current City (optional)',
                hintText: 'Detroit',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              onChanged: onPlaceQueryChanged,
            ),
            if (loadingSuggestions) ...<Widget>[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2),
            ],
            if (suggestions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              PlaceSuggestionList(
                suggestions: suggestions,
                onTap: onPlaceSelected,
              ),
            ],
            if (currentLocationLabel != null) ...<Widget>[
              const SizedBox(height: 6),
              _InfoPill(label: currentLocationLabel!),
            ],
            if (statusMessage != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                statusMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onUseBirthLocation,
              icon: const Icon(Icons.home_outlined, size: 16),
              label: const Text('Use birth location'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BirthPakshiCard extends StatelessWidget {
  const _BirthPakshiCard({required this.payload});

  final PanchaPakshiPayload payload;

  @override
  Widget build(BuildContext context) {
    final bannerAsset = _pakshiBannerAsset(payload.birth.pakshi);
    if (bannerAsset == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(
          'Birth Pakshi: ${_withBirdEmoji(payload.birth.pakshi)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 2.35,
        child: Image.asset(
          bannerAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}

class _ActiveWindowCard extends StatelessWidget {
  const _ActiveWindowCard({
    required this.payload,
    required this.secondsRemaining,
    required this.refreshing,
  });

  final PanchaPakshiPayload payload;
  final int secondsRemaining;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final active = payload.active;
    final sub = active.subActivity;
    final runtime = payload.runtime;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Active Right Now',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (refreshing)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${_withBirdEmoji(active.mainBird)} · ${_withActivityEmoji(active.mainActivity)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sub Activity: ${_withBirdEmoji(sub.bird)} · ${_withActivityEmoji(sub.activity)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _InfoPill(label: runtime.phase.toUpperCase()),
                _InfoPill(label: runtime.weekday),
                _InfoPill(label: runtime.paksha),
                _InfoPill(label: 'Relation: ${sub.relation}'),
                _InfoPill(label: 'Effect: ${sub.effect}'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Next transition in ${_formatCountdown(secondsRemaining)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Until ${_formatUntil(runtime.nextTransitionLocalIso)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MajorWindowCard extends StatelessWidget {
  const _MajorWindowCard({
    required this.window,
    required this.runtime,
    required this.isActive,
    required this.activeMajorIndex,
    required this.activeSubActivity,
  });

  final PanchaPakshiMajorWindow window;
  final PanchaPakshiRuntime runtime;
  final bool isActive;
  final int activeMajorIndex;
  final PanchaPakshiSubWindow activeSubActivity;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primaryContainer;
    final resolvedPhase = _resolveWindowPhase(window: window, runtime: runtime);
    final resolvedPaksha =
        _resolveWindowPaksha(window: window, runtime: runtime);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)
              : Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.5),
        ),
        color: isActive ? activeColor.withValues(alpha: 0.18) : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent),
          ),
          collapsedShape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          title: Text(
            '${_withBirdEmoji(window.mainBird)} · '
            '${_withActivityEmoji(window.mainActivity)} · '
            '${_phaseEmoji(resolvedPhase)} · ${_pakshaEmoji(resolvedPaksha)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${_formatTimeOnly(window.startLocalIso)} - ${_formatTimeOnly(window.endLocalIso)}'
            ' · ${_formatDurationMinutes(window.durationMinutes)}',
          ),
          initiallyExpanded: isActive,
          children: window.subTimeline.map((sub) {
            final isCurrentSub = window.majorIndex == activeMajorIndex &&
                sub.startLocalIso == activeSubActivity.startLocalIso &&
                sub.endLocalIso == activeSubActivity.endLocalIso;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(
                        alpha: 0.45,
                      ),
                  border: Border.all(
                    color: isCurrentSub
                        ? Theme.of(context).colorScheme.primary.withValues(
                              alpha: 0.85,
                            )
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${_withBirdEmoji(sub.bird)} · ${_withActivityEmoji(sub.activity)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${_formatTimeOnly(sub.startLocalIso)} - ${_formatTimeOnly(sub.endLocalIso)}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  sub.effect,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _effectPlusIndicator(sub.effect, sub.rating),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: _effectColor(sub.effect),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Relation: ${sub.relation}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (isCurrentSub) const _AnimatedHourglass(),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _AnimatedHourglass extends StatefulWidget {
  const _AnimatedHourglass();

  @override
  State<_AnimatedHourglass> createState() => _AnimatedHourglassState();
}

class _AnimatedHourglassState extends State<_AnimatedHourglass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (BuildContext context, Widget? child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: const Padding(
        padding: EdgeInsets.only(left: 10),
        child: Text(
          '⏳',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.35),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _formatCountdown(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  final secs = safe % 60;
  if (safe < 60) {
    return '$secs secs';
  }
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} mins';
  }
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} mins';
}

String _formatUntil(String iso) {
  final parsed = _parseIsoLocalParts(iso);
  if (parsed != null) {
    final readableTime = _formatTime24WithAmPm(parsed.$2);
    final readableDate = _formatReadableDate(parsed.$1);
    return '$readableTime · $readableDate';
  }
  return iso;
}

String _formatTimeOnly(String iso) {
  final parsed = _parseIsoLocalParts(iso);
  if (parsed != null) {
    return _formatTime24WithAmPm(parsed.$2);
  }
  return iso;
}

(String, String)? _parseIsoLocalParts(String iso) {
  final match =
      RegExp(r'^(\d{4}-\d{2}-\d{2})[T ](\d{2}):(\d{2})(?::\d{2})?').firstMatch(
    iso.trim(),
  );
  if (match == null) {
    return null;
  }
  final datePart = match.group(1);
  final hour = match.group(2);
  final minute = match.group(3);
  if (datePart == null || hour == null || minute == null) {
    return null;
  }
  return (datePart, '$hour:$minute');
}

String _formatTime24WithAmPm(String time24) {
  final pieces = time24.split(':');
  if (pieces.length != 2) {
    return time24;
  }
  final hour24 = int.tryParse(pieces[0]);
  final minute = pieces[1];
  if (hour24 == null) {
    return time24;
  }
  final isPm = hour24 >= 12;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final paddedHour = hour12.toString().padLeft(2, '0');
  return '$paddedHour:$minute ${isPm ? 'PM' : 'AM'}';
}

String _formatReadableDate(String isoDate) {
  final parts = isoDate.split('-');
  if (parts.length != 3) {
    return isoDate;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null || month < 1 || month > 12) {
    return isoDate;
  }
  const monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${monthNames[month - 1]} $day, $year';
}

String _withBirdEmoji(String bird) {
  final normalized = bird.trim().toLowerCase();
  const birdEmojis = <String, String>{
    'vulture': '🦅',
    'owl': '🦉',
    'crow': '🐦‍⬛',
    'cock': '🐓',
    'peacock': '🦚',
  };
  final emoji = birdEmojis[normalized];
  if (emoji == null) {
    return bird;
  }
  return '$emoji $bird';
}

String? _pakshiBannerAsset(String bird) {
  switch (bird.trim().toLowerCase()) {
    case 'vulture':
      return 'assets/feature_cards/pakshi_vulture_banner.png';
    case 'peacock':
      return 'assets/feature_cards/pakshi_peacock_banner.png';
    case 'crow':
      return 'assets/feature_cards/pakshi_crow_banner.png';
    case 'owl':
      return 'assets/feature_cards/pakshi_owl_banner.png';
    case 'cock':
    case 'rooster':
      return 'assets/feature_cards/pakshi_cock_banner.png';
    default:
      return null;
  }
}

String _withActivityEmoji(String activity) {
  final normalized = activity.trim().toLowerCase();
  const activityEmojis = <String, String>{
    'ruling': '👑',
    'eating': '🍲',
    'walking': '🐾',
    'sleeping': '💤',
    'dying': '🪦',
  };
  final emoji = activityEmojis[normalized];
  if (emoji == null) {
    return activity;
  }
  return '$emoji $activity';
}

String _phaseEmoji(String phase) {
  final normalized = phase.trim().toLowerCase();
  if (normalized == 'day') {
    return '☀️';
  }
  if (normalized == 'night') {
    return '🌙';
  }
  return phase;
}

String _pakshaEmoji(String paksha) {
  final normalized = paksha.trim().toLowerCase();
  if (normalized == 'krishna') {
    return '🌚';
  }
  if (normalized == 'shukla') {
    return '🌝';
  }
  return paksha;
}

String _resolveWindowPhase({
  required PanchaPakshiMajorWindow window,
  required PanchaPakshiRuntime runtime,
}) {
  final raw = window.phase.trim().toLowerCase();
  if (raw == 'day' || raw == 'night') {
    return raw;
  }

  // Backward-compat fallback for payloads that don't include per-window phase.
  // First 5 windows belong to current runtime phase, next 5 to alternate phase.
  final runtimePhase = runtime.phase.trim().toLowerCase();
  if (window.majorIndex <= 5) {
    return runtimePhase == 'night' ? 'night' : 'day';
  }
  return runtimePhase == 'night' ? 'day' : 'night';
}

String _resolveWindowPaksha({
  required PanchaPakshiMajorWindow window,
  required PanchaPakshiRuntime runtime,
}) {
  final raw = window.paksha.trim();
  if (raw.isNotEmpty) {
    return raw;
  }
  // Backward-compat fallback for payloads that don't include per-window paksha.
  return runtime.paksha;
}

String _formatDurationMinutes(double minutesValue) {
  final totalMinutes = minutesValue.round();
  if (totalMinutes < 60) {
    return '${totalMinutes}m';
  }
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (minutes == 0) {
    return '${hours}h';
  }
  return '${hours}h ${minutes}m';
}

String _effectPlusIndicator(String effect, int rating) {
  final count = _effectPlusCount(effect, rating);
  return List<String>.filled(count, '+').join();
}

int _effectPlusCount(String effect, int rating) {
  if (rating > 0) {
    return rating.clamp(1, 10);
  }
  final normalized = effect.trim().toLowerCase();
  if (normalized == 'very good') {
    return 8;
  }
  if (normalized == 'good') {
    return 6;
  }
  if (normalized == 'average') {
    return 4;
  }
  if (normalized == 'bad') {
    return 2;
  }
  if (normalized == 'very bad') {
    return 1;
  }
  return 3;
}

Color _effectColor(String effect) {
  final normalized = effect.trim().toLowerCase();
  if (normalized == 'very good' || normalized == 'good') {
    return const Color(0xFF3BD671);
  }
  if (normalized == 'average') {
    return const Color(0xFFF6C945);
  }
  return const Color(0xFFFF5B5B);
}
