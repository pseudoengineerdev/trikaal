import 'package:flutter/material.dart';

import '../../../app/models/custom_place_payload.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../charts/data/models/place_search_models.dart';
import '../../charts/presentation/state/birth_chart_controller.dart';
import '../../charts/presentation/widgets/chart_state_widgets.dart';
import '../../shared/astrology/sign_trio_insights.dart';
import '../../shared/birth_input/birth_input_formatters.dart';

enum _OnboardingStep {
  firstName,
  birthMix,
  computing,
  aboutYou,
}

class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({
    required this.birthInputState,
    required this.onCompleted,
    super.key,
  });

  final BirthInputState birthInputState;
  final VoidCallback onCompleted;

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final _controller = BirthChartController();
  final _birthFormKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _placeController;
  _OnboardingStep _step = _OnboardingStep.firstName;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.birthInputState.firstName);
    _dateController =
        TextEditingController(text: widget.birthInputState.dateOfBirth);
    _timeController =
        TextEditingController(text: widget.birthInputState.timeOfBirth);
    _placeController =
        TextEditingController(text: widget.birthInputState.placeOfBirth);
    if (_nameController.text.trim().isNotEmpty) {
      _step = _OnboardingStep.birthMix;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _placeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trikaal Onboarding'),
        leading: _step == _OnboardingStep.firstName ||
                _step == _OnboardingStep.computing
            ? null
            : IconButton(
                onPressed: () {
                  if (_step == _OnboardingStep.aboutYou) {
                    setState(() {
                      _step = _OnboardingStep.birthMix;
                    });
                    return;
                  }
                  setState(() {
                    _step = _OnboardingStep.firstName;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
      ),
      body: AstroPageBackground(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: switch (_step) {
              _OnboardingStep.firstName => _buildFirstNameStep(context),
              _OnboardingStep.birthMix => _buildBirthMixStep(context),
              _OnboardingStep.computing => _buildComputingStep(context),
              _OnboardingStep.aboutYou => _buildAboutYouStep(context),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFirstNameStep(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('first_name_step'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Let\'s start with your first name',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll use this to personalize your astrology home.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'First Name',
              hintText: 'Sahil',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            onChanged: (String value) {
              widget.birthInputState
                  .updateFirstName(value, clearComputed: false);
              setState(() {});
            },
          ),
          const SizedBox(height: 10),
          Text(
            '✨ A personal name makes your insights feel yours from day one.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nameController.text.trim().isEmpty
                  ? null
                  : () {
                      widget.birthInputState.updateFirstName(
                        _nameController.text.trim(),
                        clearComputed: false,
                      );
                      setState(() {
                        _step = _OnboardingStep.birthMix;
                      });
                    },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthMixStep(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey<String>('birth_mix_step'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Form(
        key: _birthFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Add your zodiac mix',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Date, place, and time together unlock your full Vedic chart identity.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 6),
            _FieldHintLine(
              icon: Icons.wb_sunny_outlined,
              text:
                  'Unlocks your Sun sign, which reflects your core personality.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _placeController,
              validator: (String? value) {
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
                widget.birthInputState
                    .updatePlaceOfBirth(value.trim(), clearComputed: false);
                _controller.onPlaceQueryChanged(value);
                setState(() {});
              },
            ),
            const SizedBox(height: 6),
            _FieldHintLine(
              icon: Icons.brightness_2_outlined,
              text:
                  'Unlocks your Moon sign, your inner emotions and karmic memory.',
            ),
            if (_controller.loadingPlaceSuggestions) ...<Widget>[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2),
            ],
            if (_controller.placeSuggestions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              PlaceSuggestionList(
                suggestions: _controller.placeSuggestions,
                onTap: _onPlaceSelected,
              ),
            ],
            const SizedBox(height: 14),
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
            const SizedBox(height: 6),
            _FieldHintLine(
              icon: Icons.north_rounded,
              text:
                  'Unlocks your Rising sign, the first impression and outward style.',
            ),
            if (_controller.error != null) ...<Widget>[
              const SizedBox(height: 12),
              ErrorCard(
                message: _controller.error!,
                onRetry: _startComputation,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startComputation,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComputingStep(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('computing_step'),
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 18),
          Text(
            'Calculating your zodiac mix...',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We are computing your Sun, Moon, and Rising from your exact birth details.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutYouStep(BuildContext context) {
    final report = widget.birthInputState.computedReport;
    if (report == null) {
      return const SizedBox.shrink();
    }

    final trio = SignTrioInsights.fromReport(report);
    final sun = trio.sun;
    final moon = trio.moon;
    final rising = trio.rising;
    final name = widget.birthInputState.firstName.trim().isEmpty
        ? 'You'
        : widget.birthInputState.firstName.trim();

    return Padding(
      key: const ValueKey<String>('about_you_step'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'About $name',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your chart has been computed. Here is your first personalized snapshot.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          _AboutTile(
            icon: '☀️',
            headline: 'Sun in ${sun.name} ${sun.symbol}',
            title: 'Your core personality',
            body: sun.sunTrait,
          ),
          const SizedBox(height: 12),
          _AboutTile(
            icon: '🌙',
            headline: 'Moon in ${moon.name} ${moon.symbol}',
            title: 'Your emotional side',
            body: moon.moonTrait,
          ),
          const SizedBox(height: 12),
          _AboutTile(
            icon: '⬆️',
            headline: 'Rising in ${rising.name} ${rising.symbol}',
            title: 'How others see you',
            body: rising.risingTrait,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.birthInputState.completeOnboarding();
                widget.onCompleted();
              },
              child: const Text('Enter Astrology Mode'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startComputation() async {
    final form = _birthFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    widget.birthInputState.updateFirstName(
      _nameController.text.trim(),
      clearComputed: false,
    );
    widget.birthInputState.updateDateOfBirth(
      _dateController.text.trim(),
      clearComputed: false,
    );
    widget.birthInputState.updateTimeOfBirth(
      _timeController.text.trim(),
      clearComputed: false,
    );
    widget.birthInputState.updatePlaceOfBirth(
      _placeController.text.trim(),
      clearComputed: false,
    );

    setState(() {
      _step = _OnboardingStep.computing;
    });

    await _controller.submit(
      dateOfBirth: _dateController.text.trim(),
      timeOfBirth: _timeController.text.trim(),
      placeOfBirth: _placeController.text.trim(),
      customPlace: widget.birthInputState.customPlace,
    );
    if (!mounted) {
      return;
    }

    final report = _controller.result;
    if (report == null || _controller.error != null) {
      setState(() {
        _step = _OnboardingStep.birthMix;
      });
      return;
    }

    final resolvedPlace = report.resolvedPlace.toCustomPlacePayload();
    widget.birthInputState.setResolvedPlace(
      resolvedPlace,
      clearComputed: false,
    );
    _placeController.text = resolvedPlace.placeLabel;
    _placeController.selection = TextSelection.collapsed(
      offset: _placeController.text.length,
    );
    widget.birthInputState.markReportComputed(report);

    setState(() {
      _step = _OnboardingStep.aboutYou;
    });
  }

  void _onPlaceSelected(PlaceMatch place) {
    _placeController.text = place.placeLabel;
    _placeController.selection = TextSelection.collapsed(
      offset: _placeController.text.length,
    );
    if (place.isCustom) {
      widget.birthInputState
          .updatePlaceOfBirth(_placeController.text, clearComputed: false);
    } else {
      widget.birthInputState.setResolvedPlace(
        CustomPlacePayload(
          placeLabel: place.placeLabel,
          latitude: place.latitude,
          longitude: place.longitude,
          timezone: place.timezone,
          elevationM: place.elevationM,
        ),
        clearComputed: false,
      );
    }
    _controller.clearPlaceSuggestions();
    setState(() {});
  }

  Future<void> _pickDate() async {
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
    widget.birthInputState
        .updateDateOfBirth(_dateController.text, clearComputed: false);
    setState(() {});
  }

  Future<void> _pickTime() async {
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
    widget.birthInputState
        .updateTimeOfBirth(_timeController.text, clearComputed: false);
    setState(() {});
  }
}

class _FieldHintLine extends StatelessWidget {
  const _FieldHintLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.icon,
    required this.headline,
    required this.title,
    required this.body,
  });

  final String icon;
  final String headline;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              icon,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    headline,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
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
