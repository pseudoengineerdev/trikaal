import 'package:flutter/material.dart';

import '../../../app/models/custom_place_payload.dart';
import '../../../app/models/saved_birth_profile.dart';
import '../../../app/state/astrology_terms_state.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/state/terminology_mode_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/trikaal_app_bar.dart';
import '../../dasha/data/models/dasha_models.dart';
import '../data/models/compute_report_models.dart';
import '../data/models/place_search_models.dart';
import '../../shared/birth_input/birth_input_formatters.dart';
import '../../shared/widgets/terminology_toggle.dart';
import 'state/birth_chart_controller.dart';
import 'widgets/chart_result_card.dart';
import 'widgets/chart_state_widgets.dart';

class BirthInputPage extends StatefulWidget {
  const BirthInputPage({
    required this.birthInputState,
    required this.terminologyModeState,
    required this.astrologyTermsState,
    super.key,
  });

  final BirthInputState birthInputState;
  final TerminologyModeState terminologyModeState;
  final AstrologyTermsState astrologyTermsState;

  @override
  State<BirthInputPage> createState() => _BirthInputPageState();
}

class _BirthInputPageState extends State<BirthInputPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _placeController;
  late final VoidCallback _birthInputStateListener;
  final _controller = BirthChartController();
  final Map<String, ComputeReportResponse> _computedReportByProfileId =
      <String, ComputeReportResponse>{};
  final Map<String, DashaSummary?> _computedDashaByProfileId =
      <String, DashaSummary?>{};
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _dateController =
        TextEditingController(text: widget.birthInputState.dateOfBirth);
    _timeController =
        TextEditingController(text: widget.birthInputState.timeOfBirth);
    _placeController =
        TextEditingController(text: widget.birthInputState.placeOfBirth);
    _birthInputStateListener = _onBirthInputStateChanged;
    widget.birthInputState.addListener(_birthInputStateListener);
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.birthInputState.removeListener(_birthInputStateListener);
    _dateController.dispose();
    _timeController.dispose();
    _placeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BirthInputPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.birthInputState == widget.birthInputState) {
      return;
    }
    oldWidget.birthInputState.removeListener(_birthInputStateListener);
    widget.birthInputState.addListener(_birthInputStateListener);
    _onBirthInputStateChanged();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    await _computeForCurrentInput();
  }

  Future<void> _computeForCurrentInput() async {
    await _controller.submit(
      dateOfBirth: _dateController.text.trim(),
      timeOfBirth: _timeController.text.trim(),
      placeOfBirth: _placeController.text.trim(),
      customPlace: widget.birthInputState.customPlace,
    );
    if (_controller.result != null && _controller.error == null) {
      final resolvedPlace = _controller.result!.resolvedPlace;
      widget.birthInputState.setResolvedPlace(
        resolvedPlace.toCustomPlacePayload(),
        preserveActiveProfile: true,
      );
      _placeController.text = resolvedPlace.placeLabel;
      _placeController.selection = TextSelection.collapsed(
        offset: _placeController.text.length,
      );
      widget.birthInputState.markChartComputed(
        report: _controller.result,
        dashaSummary: _controller.dashaResult,
      );
      _cacheComputedForActiveProfile();
    } else {
      widget.birthInputState.clearComputedChart();
      _controller.clearComputedResult();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildTrikaalAppBar(context),
      body: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _controller,
          widget.birthInputState,
          widget.terminologyModeState,
          widget.astrologyTermsState,
        ]),
        builder: (BuildContext context, Widget? _) {
          return AstroPageBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 94),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Expanded(child: _AstroIntroCard()),
                        const SizedBox(width: 10),
                        TerminologyToggle(
                          mode: widget.terminologyModeState.mode,
                          onChanged: widget.terminologyModeState.setMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SavedProfilesCard(
                      profilesLoaded: widget.birthInputState.profilesLoaded,
                      profilesLoading: widget.birthInputState.profilesLoading,
                      profilesError: widget.birthInputState.profilesError,
                      profiles: widget.birthInputState.savedProfiles,
                      activeProfileId: widget.birthInputState.activeProfileId,
                      onSaveNew: _onSaveNewProfile,
                      onUseProfile: _onUseProfile,
                      onRenameProfile: _onRenameProfile,
                      onSetDefaultProfile: _onSetDefaultProfile,
                      onUpdateProfileFromCurrent: _onUpdateProfileFromCurrent,
                      onDeleteProfile: _onDeleteProfile,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: <Widget>[
                              TextFormField(
                                controller: _dateController,
                                readOnly: true,
                                enabled: !_controller.loading,
                                onTap: _pickDate,
                                decoration: const InputDecoration(
                                  labelText: 'Date of Birth',
                                  hintText: 'YYYY-MM-DD',
                                  suffixIcon:
                                      Icon(Icons.calendar_today_outlined),
                                ),
                                validator: BirthInputFormatters.validateDate,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _timeController,
                                readOnly: true,
                                enabled: !_controller.loading,
                                onTap: _pickTime,
                                decoration: const InputDecoration(
                                  labelText: 'Time of Birth',
                                  hintText: 'HH:MM',
                                  suffixIcon: Icon(Icons.schedule),
                                ),
                                validator: BirthInputFormatters.validateTime,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _placeController,
                                enabled: !_controller.loading,
                                decoration: const InputDecoration(
                                  labelText: 'Place of Birth',
                                  hintText: 'Mumbai',
                                  prefixIcon: Icon(Icons.public),
                                ),
                                onChanged: (String value) {
                                  widget.birthInputState
                                      .updatePlaceOfBirth(value.trim());
                                  _controller.onPlaceQueryChanged(value);
                                },
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Place is required';
                                  }
                                  return null;
                                },
                              ),
                              if (_controller
                                  .loadingPlaceSuggestions) ...<Widget>[
                                const SizedBox(height: 8),
                                const LinearProgressIndicator(minHeight: 2),
                              ],
                              if (_controller
                                  .placeSuggestions.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 8),
                                PlaceSuggestionList(
                                  suggestions: _controller.placeSuggestions,
                                  onTap: _onPlaceSelected,
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _controller.loading ? null : _submit,
                                  icon: _controller.loading
                                      ? SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                        )
                                      : const Icon(Icons.auto_awesome_rounded),
                                  label: Text(
                                    _controller.loading
                                        ? 'Computing...'
                                        : 'Compute Chart',
                                  ),
                                ),
                              ),
                              if (_controller.loading) ...<Widget>[
                                const SizedBox(height: 10),
                                const LoadingHint(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_controller.error != null) ...<Widget>[
                      const SizedBox(height: 12),
                      ErrorCard(
                        message: _controller.error!,
                        onRetry: _controller.loading ? null : _submit,
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_controller.result == null &&
                        !_controller.loading) ...<Widget>[
                      const EmptyResultHint(),
                    ] else if (_controller.result != null) ...<Widget>[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: ChartResultCard(
                            result: _controller.result!,
                            mode: widget.terminologyModeState.mode,
                            termsState: widget.astrologyTermsState,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onPlaceSelected(PlaceMatch place) {
    _placeController.text = place.placeLabel;
    _placeController.selection = TextSelection.collapsed(
      offset: _placeController.text.length,
    );
    if (place.isCustom) {
      widget.birthInputState.updatePlaceOfBirth(_placeController.text);
    } else {
      widget.birthInputState.setResolvedPlace(
        CustomPlacePayload(
          placeLabel: place.placeLabel,
          latitude: place.latitude,
          longitude: place.longitude,
          timezone: place.timezone,
          elevationM: place.elevationM,
        ),
      );
    }
    _controller.clearPlaceSuggestions();
  }

  void _onBirthInputStateChanged() {
    if (_isDisposed || !mounted) {
      return;
    }
    _syncController(_dateController, widget.birthInputState.dateOfBirth);
    _syncController(_timeController, widget.birthInputState.timeOfBirth);
    _syncController(_placeController, widget.birthInputState.placeOfBirth);
  }

  void _syncController(
    TextEditingController controller,
    String nextValue,
  ) {
    if (_isDisposed || !mounted) {
      return;
    }
    if (controller.text == nextValue) {
      return;
    }
    controller.text = nextValue;
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  Future<void> _onSaveNewProfile() async {
    if (!widget.birthInputState.canSaveCurrentAsProfile) {
      _showInfo(
        'Enter date, time, and place first. Then save this as a profile.',
      );
      return;
    }
    final profileName = await _showNameDialog(
      title: 'Save Profile',
      hintText: 'Profile name',
      initialValue: _suggestProfileName(),
      confirmLabel: 'Save',
    );
    if (profileName == null) {
      return;
    }

    final didSave =
        await widget.birthInputState.createProfile(name: profileName);
    if (!mounted) {
      return;
    }
    if (didSave) {
      _cacheComputedForActiveProfile();
      _showInfo('Profile saved.');
      return;
    }
    _showInfo(
        widget.birthInputState.profilesError ?? 'Could not save profile.');
  }

  Future<void> _onUseProfile(String profileId) async {
    widget.birthInputState.applyProfile(profileId);
    _controller.clearPlaceSuggestions();
    if (_restoreCachedProfileComputation(profileId)) {
      return;
    }
    _controller.clearComputedResult();
    await _computeForCurrentInput();
  }

  bool _restoreCachedProfileComputation(String profileId) {
    final cachedReport = _computedReportByProfileId[profileId];
    if (cachedReport == null) {
      return false;
    }
    final cachedDasha = _computedDashaByProfileId[profileId];
    _controller.applyComputedResult(
      report: cachedReport,
      dasha: cachedDasha,
    );
    widget.birthInputState.markChartComputed(
      report: cachedReport,
      dashaSummary: cachedDasha,
    );
    return true;
  }

  void _cacheComputedForActiveProfile() {
    final activeProfileId = widget.birthInputState.activeProfileId;
    final report = _controller.result;
    if (activeProfileId == null || report == null) {
      return;
    }
    _computedReportByProfileId[activeProfileId] = report;
    _computedDashaByProfileId[activeProfileId] = _controller.dashaResult;
  }

  Future<void> _onRenameProfile(SavedBirthProfile profile) async {
    final nextName = await _showNameDialog(
      title: 'Rename Profile',
      hintText: 'Profile name',
      initialValue: profile.name,
      confirmLabel: 'Rename',
    );
    if (nextName == null) {
      return;
    }

    final didRename = await widget.birthInputState.renameProfile(
      profileId: profile.id,
      name: nextName,
    );
    if (!mounted) {
      return;
    }
    if (didRename) {
      _showInfo('Profile renamed.');
      return;
    }
    _showInfo(
        widget.birthInputState.profilesError ?? 'Could not rename profile.');
  }

  Future<void> _onSetDefaultProfile(SavedBirthProfile profile) async {
    final didSet = await widget.birthInputState.setDefaultProfile(profile.id);
    if (!mounted) {
      return;
    }
    if (didSet) {
      _showInfo('Default profile updated.');
      return;
    }
    _showInfo('Could not update default profile.');
  }

  Future<void> _onUpdateProfileFromCurrent(SavedBirthProfile profile) async {
    if (!widget.birthInputState.canSaveCurrentAsProfile) {
      _showInfo('Enter date, time, and place before updating this profile.');
      return;
    }

    final didUpdate =
        await widget.birthInputState.updateProfileFromCurrent(profile.id);
    if (!mounted) {
      return;
    }
    if (didUpdate) {
      _cacheComputedForActiveProfile();
      _showInfo('Profile updated with current form values.');
      return;
    }
    _showInfo(
        widget.birthInputState.profilesError ?? 'Could not update profile.');
  }

  Future<void> _onDeleteProfile(SavedBirthProfile profile) async {
    final shouldDelete = await _showDeleteConfirmation(profile.name);
    if (!mounted || !shouldDelete) {
      return;
    }

    final previousActiveProfileId = widget.birthInputState.activeProfileId;
    final didDelete = await widget.birthInputState.deleteProfile(profile.id);
    if (!mounted) {
      return;
    }
    if (didDelete) {
      _computedReportByProfileId.remove(profile.id);
      _computedDashaByProfileId.remove(profile.id);
      if (previousActiveProfileId == profile.id) {
        final nextActiveProfileId = widget.birthInputState.activeProfileId;
        if (nextActiveProfileId == null) {
          _controller.clearComputedResult();
        } else if (!_restoreCachedProfileComputation(nextActiveProfileId)) {
          await _computeForCurrentInput();
        }
      }
      _showInfo('Profile deleted.');
      return;
    }
    _showInfo('Could not delete profile.');
  }

  Future<String?> _showNameDialog({
    required String title,
    required String hintText,
    required String initialValue,
    required String confirmLabel,
  }) async {
    if (!mounted || _isDisposed) {
      return null;
    }

    var draftValue = initialValue;
    final value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(title),
              content: TextFormField(
                initialValue: initialValue,
                autofocus: true,
                decoration: InputDecoration(hintText: hintText),
                textInputAction: TextInputAction.done,
                onChanged: (String value) {
                  setState(() {
                    draftValue = value;
                  });
                },
                onFieldSubmitted: (String value) {
                  final text = value.trim();
                  if (text.isNotEmpty) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(context).pop(text);
                  }
                },
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final text = draftValue.trim();
                    if (text.isEmpty) {
                      return;
                    }
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(context).pop(text);
                  },
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
      },
    );
    return value?.trim();
  }

  Future<bool> _showDeleteConfirmation(String profileName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Profile'),
          content: Text(
            'Delete "$profileName"? This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return shouldDelete ?? false;
  }

  String _suggestProfileName() {
    final place = _placeController.text.trim();
    final date = _dateController.text.trim();
    if (place.isNotEmpty && date.isNotEmpty) {
      return '$place • $date';
    }
    if (place.isNotEmpty) {
      return place;
    }
    if (date.isNotEmpty) {
      return 'Profile $date';
    }
    return 'My Profile';
  }

  void _showInfo(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    if (_controller.loading) {
      return;
    }
    final initialDate =
        BirthInputFormatters.parseDate(_dateController.text.trim()) ??
            DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selected == null) {
      return;
    }
    _dateController.text = BirthInputFormatters.formatDate(selected);
    widget.birthInputState.updateDateOfBirth(_dateController.text);
  }

  Future<void> _pickTime() async {
    if (_controller.loading) {
      return;
    }
    final initialTime =
        BirthInputFormatters.parseTime(_timeController.text.trim()) ??
            TimeOfDay.fromDateTime(DateTime.now());
    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (selected == null) {
      return;
    }
    _timeController.text = BirthInputFormatters.formatTime(selected);
    widget.birthInputState.updateTimeOfBirth(_timeController.text);
  }
}

class _AstroIntroCard extends StatelessWidget {
  const _AstroIntroCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.travel_explore_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Vedic Insight Workspace',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter birth details once, then explore chart, dasha, and guidance in one flow.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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

class _SavedProfilesCard extends StatelessWidget {
  const _SavedProfilesCard({
    required this.profilesLoaded,
    required this.profilesLoading,
    required this.profilesError,
    required this.profiles,
    required this.activeProfileId,
    required this.onSaveNew,
    required this.onUseProfile,
    required this.onRenameProfile,
    required this.onSetDefaultProfile,
    required this.onUpdateProfileFromCurrent,
    required this.onDeleteProfile,
  });

  final bool profilesLoaded;
  final bool profilesLoading;
  final String? profilesError;
  final List<SavedBirthProfile> profiles;
  final String? activeProfileId;
  final Future<void> Function() onSaveNew;
  final Future<void> Function(String profileId) onUseProfile;
  final Future<void> Function(SavedBirthProfile profile) onRenameProfile;
  final Future<void> Function(SavedBirthProfile profile) onSetDefaultProfile;
  final Future<void> Function(SavedBirthProfile profile)
      onUpdateProfileFromCurrent;
  final Future<void> Function(SavedBirthProfile profile) onDeleteProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.bookmark_outline_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Saved Profiles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    onSaveNew();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Save New'),
                ),
              ],
            ),
            if (profilesLoading && !profilesLoaded) ...<Widget>[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2),
            ],
            if (profilesError != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                profilesError!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (profilesLoaded && profiles.isEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Save your frequently used birth details once, then load them in one tap.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (profiles.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              for (final profile in profiles)
                _SavedProfileListTile(
                  profile: profile,
                  isActive: activeProfileId == profile.id,
                  onTap: () {
                    onUseProfile(profile.id);
                  },
                  onActionSelected: (action) async {
                    switch (action) {
                      case _ProfileAction.setDefault:
                        await onSetDefaultProfile(profile);
                      case _ProfileAction.updateFromCurrent:
                        await onUpdateProfileFromCurrent(profile);
                      case _ProfileAction.rename:
                        await onRenameProfile(profile);
                      case _ProfileAction.delete:
                        await onDeleteProfile(profile);
                    }
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SavedProfileListTile extends StatelessWidget {
  const _SavedProfileListTile({
    required this.profile,
    required this.isActive,
    required this.onTap,
    required this.onActionSelected,
  });

  final SavedBirthProfile profile;
  final bool isActive;
  final VoidCallback onTap;
  final Future<void> Function(_ProfileAction action) onActionSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          profile.isDefault ? Icons.star : Icons.person_outline,
          color:
              profile.isDefault ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                profile.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (isActive)
              Chip(
                label: const Text('Active'),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        subtitle: Text(
          '${profile.dateOfBirth} • ${profile.timeOfBirth}\n${profile.placeOfBirth}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<_ProfileAction>(
          tooltip: 'Profile actions',
          onSelected: (value) {
            onActionSelected(value);
          },
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<_ProfileAction>>[
              const PopupMenuItem<_ProfileAction>(
                value: _ProfileAction.setDefault,
                child: Text('Set as default'),
              ),
              const PopupMenuItem<_ProfileAction>(
                value: _ProfileAction.updateFromCurrent,
                child: Text('Update from current form'),
              ),
              const PopupMenuItem<_ProfileAction>(
                value: _ProfileAction.rename,
                child: Text('Rename'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<_ProfileAction>(
                value: _ProfileAction.delete,
                child: Text('Delete'),
              ),
            ];
          },
        ),
      ),
    );
  }
}

enum _ProfileAction {
  setDefault,
  updateFromCurrent,
  rename,
  delete,
}
