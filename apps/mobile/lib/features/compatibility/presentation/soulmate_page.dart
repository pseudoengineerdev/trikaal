import 'package:flutter/material.dart';

import '../../../app/models/custom_place_payload.dart';
import '../../../app/navigation/app_dock_navigation.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/trikaal_app_bar.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../charts/data/models/compute_compatibility_models.dart';
import '../../charts/data/models/place_search_models.dart';
import '../../charts/presentation/widgets/chart_state_widgets.dart';
import '../../shared/birth_input/birth_input_formatters.dart';
import 'state/soulmate_controller.dart';

class SoulmatePage extends StatefulWidget {
  const SoulmatePage({
    required this.birthInputState,
    super.key,
  });

  final BirthInputState birthInputState;

  @override
  State<SoulmatePage> createState() => _SoulmatePageState();
}

enum _PrimaryRole {
  boy,
  girl,
}

class _SoulmatePageState extends State<SoulmatePage> {
  late final SoulmateController _controller;
  _PartnerProfileDraft? _partner;
  _PrimaryRole _primaryRole = _PrimaryRole.boy;

  @override
  void initState() {
    super.initState();
    _controller = SoulmateController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              final primaryReady = _isPrimaryReady();
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
                children: <Widget>[
                  _pageHeading(context),
                  const SizedBox(height: 12),
                  _personCard(
                    context: context,
                    title: 'Your Profile',
                    name: _primaryName(),
                    details:
                        '${widget.birthInputState.dateOfBirth} • ${widget.birthInputState.timeOfBirth}\n${widget.birthInputState.placeOfBirth}',
                    isReady: primaryReady,
                    actionLabel:
                        primaryReady ? null : 'Complete onboarding first',
                    onTap: primaryReady ? null : _goHome,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF5A189A),
                        border: Border.all(
                          color: const Color(0xFF9D4EDD).withValues(alpha: 0.9),
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFFFE7B3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _personCard(
                    context: context,
                    title: 'Partner Profile',
                    name: _partner?.name ?? 'Tap to add partner details',
                    details: _partner == null
                        ? 'Date, time, and place are required for compatibility.'
                        : '${_partner!.dateOfBirth} • ${_partner!.timeOfBirth}\n${_partner!.placeOfBirth}',
                    isReady: _partner != null && _partner!.isComplete,
                    actionLabel:
                        _partner == null ? 'Add partner' : 'Edit partner',
                    onTap: _openPartnerForm,
                  ),
                  const SizedBox(height: 12),
                  _roleToggle(context),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _canCompute ? _computeCompatibility : null,
                      icon: _controller.loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.favorite_outline_rounded),
                      label: Text(
                        _controller.loading
                            ? 'Computing compatibility...'
                            : 'Find Compatibility',
                      ),
                    ),
                  ),
                  if (_controller.error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    ErrorCard(
                      message: _controller.error!,
                      onRetry: _canCompute ? _computeCompatibility : null,
                    ),
                  ],
                  if (_controller.result != null) ...<Widget>[
                    const SizedBox(height: 16),
                    _compatibilitySummaryCard(
                      context,
                      _controller.result!.compatibility.summary,
                    ),
                    const SizedBox(height: 12),
                    _manglikCard(
                        context, _controller.result!.compatibility.manglik),
                    const SizedBox(height: 12),
                    _kutaBreakdownCard(
                      context,
                      _controller.result!.compatibility.ashtaKuta,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _pageHeading(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Your Soulmate',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Match two birth charts with Ashta-Kuta, Manglik, and D1/D9 checks.',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _personCard({
    required BuildContext context,
    required String title,
    required String name,
    required String details,
    required bool isReady,
    required String? actionLabel,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF240046).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF9D4EDD).withValues(alpha: 0.42),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFFFE7B3),
                      ),
                ),
                const Spacer(),
                Icon(
                  isReady ? Icons.verified_rounded : Icons.pending_outlined,
                  color: isReady
                      ? const Color(0xFF6DFFB3)
                      : const Color(0xFFC77DFF),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              details,
              style: const TextStyle(
                color: Color(0xFFD8C8F5),
                height: 1.3,
              ),
            ),
            if (actionLabel != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                actionLabel,
                style: const TextStyle(
                  color: Color(0xFFC77DFF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roleToggle(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF240046).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF9D4EDD).withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Compatibility Role Mapping',
            style: TextStyle(
              color: Color(0xFFFFE7B3),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: const Text('You = Boy'),
                selected: _primaryRole == _PrimaryRole.boy,
                onSelected: (selected) {
                  if (!selected) {
                    return;
                  }
                  setState(() {
                    _primaryRole = _PrimaryRole.boy;
                  });
                  _controller.clearComputedResult();
                },
              ),
              ChoiceChip(
                label: const Text('You = Girl'),
                selected: _primaryRole == _PrimaryRole.girl,
                onSelected: (selected) {
                  if (!selected) {
                    return;
                  }
                  setState(() {
                    _primaryRole = _PrimaryRole.girl;
                  });
                  _controller.clearComputedResult();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'This preserves traditional Ashta-Kuta directionality used by Vedic matching systems.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compatibilitySummaryCard(
    BuildContext context,
    CompatibilitySummary summary,
  ) {
    final percent = summary.gunaScoreMax <= 0
        ? 0
        : (summary.gunaScore / summary.gunaScoreMax * 100);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF240046).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF9D4EDD).withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Compatibility Snapshot',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFFFE7B3),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.gunaScore.toStringAsFixed(1)} / ${summary.gunaScoreMax.toStringAsFixed(0)} Guna',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percent.toStringAsFixed(1)}% • ${summary.overallBand}',
            style: const TextStyle(color: Color(0xFFD8C8F5)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _pill(summary.manglikAlignment),
              _pill(summary.nadiMatch ? 'Nadi Match' : 'Nadi Dosha'),
              _pill(summary.bhakootMatch ? 'Bhakoot Match' : 'Bhakoot Dosha'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _manglikCard(BuildContext context, CompatibilityManglik manglik) {
    final partnerRole =
        _primaryRole == _PrimaryRole.boy ? 'Partner (Girl)' : 'Partner (Boy)';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF240046).withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF9D4EDD).withValues(alpha: 0.36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Manglik Check',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFFFE7B3),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${manglik.score.toStringAsFixed(1)} / ${manglik.maxScore.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            manglik.verdict,
            style: const TextStyle(color: Color(0xFFD8C8F5)),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _manglikMiniTile(
                  label: _primaryRole == _PrimaryRole.boy
                      ? 'You (Boy)'
                      : 'You (Girl)',
                  person: _primaryRole == _PrimaryRole.boy
                      ? manglik.boy
                      : manglik.girl,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _manglikMiniTile(
                  label: partnerRole,
                  person: _primaryRole == _PrimaryRole.boy
                      ? manglik.girl
                      : manglik.boy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _manglikMiniTile({
    required String label,
    required CompatibilityManglikPerson person,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF3C096C),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD8C8F5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            person.isManglik ? 'Manglik' : 'Non-Manglik',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${person.triggerCount} trigger(s)',
            style: const TextStyle(color: Color(0xFFC77DFF), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _kutaBreakdownCard(
    BuildContext context,
    CompatibilityAshtaKuta ashtaKuta,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF240046).withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF9D4EDD).withValues(alpha: 0.36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Ashta-Kuta Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFFFE7B3),
                ),
          ),
          const SizedBox(height: 10),
          ...ashtaKuta.components.map((component) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          component.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${component.score.toStringAsFixed(1)} / ${component.maxScore.toStringAsFixed(0)}',
                        style: const TextStyle(color: Color(0xFFFFE7B3)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (component.percent / 100).clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: const Color(0xFF3C096C),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF5A189A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFFE7B3),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  bool _isPrimaryReady() {
    return widget.birthInputState.dateOfBirth.trim().isNotEmpty &&
        widget.birthInputState.timeOfBirth.trim().isNotEmpty &&
        widget.birthInputState.placeOfBirth.trim().isNotEmpty;
  }

  bool get _canCompute {
    final partnerReady = _partner != null && _partner!.isComplete;
    return !_controller.loading && _isPrimaryReady() && partnerReady;
  }

  String _primaryName() {
    final value = widget.birthInputState.firstName.trim();
    if (value.isEmpty) {
      return 'You';
    }
    return value;
  }

  Future<void> _openPartnerForm() async {
    final draft = await Navigator.of(context).push<_PartnerProfileDraft>(
      MaterialPageRoute<_PartnerProfileDraft>(
        builder: (BuildContext context) {
          return _PartnerFormPage(
            initialDraft: _partner,
            controller: _controller,
          );
        },
      ),
    );
    if (!mounted || draft == null) {
      return;
    }
    setState(() {
      _partner = draft;
    });
    _controller.clearComputedResult();
  }

  Future<void> _computeCompatibility() async {
    final partner = _partner;
    if (partner == null || !partner.isComplete || !_isPrimaryReady()) {
      return;
    }
    await _controller.compute(
      primary: CompatibilityPersonRequestPayload(
        dateOfBirth: widget.birthInputState.dateOfBirth.trim(),
        timeOfBirth: widget.birthInputState.timeOfBirth.trim(),
        placeOfBirth: widget.birthInputState.placeOfBirth.trim(),
        customPlace: widget.birthInputState.customPlace,
      ),
      partner: CompatibilityPersonRequestPayload(
        dateOfBirth: partner.dateOfBirth,
        timeOfBirth: partner.timeOfBirth,
        placeOfBirth: partner.placeOfBirth,
        customPlace: partner.customPlace,
      ),
      primaryRole: _primaryRole == _PrimaryRole.boy ? 'boy' : 'girl',
    );
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
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

class _PartnerFormPage extends StatefulWidget {
  const _PartnerFormPage({
    required this.initialDraft,
    required this.controller,
  });

  final _PartnerProfileDraft? initialDraft;
  final SoulmateController controller;

  @override
  State<_PartnerFormPage> createState() => _PartnerFormPageState();
}

class _PartnerFormPageState extends State<_PartnerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _placeController;
  CustomPlacePayload? _customPlace;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialDraft?.name ?? '');
    _dateController =
        TextEditingController(text: widget.initialDraft?.dateOfBirth ?? '');
    _timeController =
        TextEditingController(text: widget.initialDraft?.timeOfBirth ?? '');
    _placeController =
        TextEditingController(text: widget.initialDraft?.placeOfBirth ?? '');
    _customPlace = widget.initialDraft?.customPlace;
  }

  @override
  void dispose() {
    widget.controller.clearPartnerPlaceSuggestions();
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner Details')),
      body: AstroPageBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (BuildContext context, Widget? _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Enter partner birth details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We need exact date, time, and place to calculate Guna and Manglik match accurately.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Partner Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Partner name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: _pickDate,
                        validator: BirthInputFormatters.validateDate,
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          hintText: 'YYYY-MM-DD',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _timeController,
                        readOnly: true,
                        onTap: _pickTime,
                        validator: BirthInputFormatters.validateTime,
                        decoration: const InputDecoration(
                          labelText: 'Time of Birth',
                          hintText: 'HH:MM',
                          suffixIcon: Icon(Icons.schedule_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _placeController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Place is required';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Place of Birth',
                          hintText: 'Mumbai',
                          suffixIcon: Icon(Icons.public_rounded),
                        ),
                        onChanged: (String value) {
                          _customPlace = null;
                          widget.controller.onPartnerPlaceQueryChanged(value);
                          setState(() {});
                        },
                      ),
                      if (widget.controller
                          .loadingPartnerPlaceSuggestions) ...<Widget>[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(minHeight: 2),
                      ],
                      if (widget.controller.partnerPlaceSuggestions
                          .isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        PlaceSuggestionList(
                          suggestions:
                              widget.controller.partnerPlaceSuggestions,
                          onTap: _onPlaceSelected,
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _save,
                          child: const Text('Save Partner'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = BirthInputFormatters.parseDate(_dateController.text) ??
        DateTime(now.year - 25, 1, 1);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year),
      initialDate: initialDate,
    );
    if (picked == null || !mounted) {
      return;
    }
    final formatted = BirthInputFormatters.formatDate(picked);
    _dateController.text = formatted;
    _dateController.selection =
        TextSelection.collapsed(offset: formatted.length);
    setState(() {});
  }

  Future<void> _pickTime() async {
    final initialTime =
        BirthInputFormatters.parseTime(_timeController.text) ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null || !mounted) {
      return;
    }
    final formatted = BirthInputFormatters.formatTime(picked);
    _timeController.text = formatted;
    _timeController.selection =
        TextSelection.collapsed(offset: formatted.length);
    setState(() {});
  }

  void _onPlaceSelected(PlaceMatch place) {
    _placeController.text = place.placeLabel;
    _placeController.selection = TextSelection.collapsed(
      offset: _placeController.text.length,
    );
    if (place.isCustom) {
      _customPlace = null;
    } else {
      _customPlace = CustomPlacePayload(
        placeLabel: place.placeLabel,
        latitude: place.latitude,
        longitude: place.longitude,
        timezone: place.timezone,
        elevationM: place.elevationM,
      );
    }
    widget.controller.clearPartnerPlaceSuggestions();
    setState(() {});
  }

  void _save() {
    final state = _formKey.currentState;
    if (state == null || !state.validate()) {
      return;
    }
    final draft = _PartnerProfileDraft(
      name: _nameController.text.trim(),
      dateOfBirth: _dateController.text.trim(),
      timeOfBirth: _timeController.text.trim(),
      placeOfBirth: _placeController.text.trim(),
      customPlace: _customPlace,
    );
    Navigator.of(context).pop(draft);
  }
}

class _PartnerProfileDraft {
  const _PartnerProfileDraft({
    required this.name,
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    required this.customPlace,
  });

  final String name;
  final String dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;
  final CustomPlacePayload? customPlace;

  bool get isComplete {
    return name.trim().isNotEmpty &&
        dateOfBirth.trim().isNotEmpty &&
        timeOfBirth.trim().isNotEmpty &&
        placeOfBirth.trim().isNotEmpty;
  }
}
