import 'package:flutter/material.dart';

import '../../../app/models/compatibility_partner_profile.dart';
import '../../../app/models/custom_place_payload.dart';
import '../../../app/models/person_gender.dart';
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

enum SoulmateEntryPoint {
  soulmate,
  mangalDosh,
}

const List<int> _defaultManglikTriggerHouses = <int>[1, 2, 4, 7, 8, 12];

class SoulmatePage extends StatefulWidget {
  const SoulmatePage({
    required this.birthInputState,
    this.entryPoint = SoulmateEntryPoint.soulmate,
    this.startWithPartnerForm = false,
    super.key,
  });

  final BirthInputState birthInputState;
  final SoulmateEntryPoint entryPoint;
  final bool startWithPartnerForm;

  @override
  State<SoulmatePage> createState() => _SoulmatePageState();
}

class _SoulmatePageState extends State<SoulmatePage> {
  late final SoulmateController _controller;
  CompatibilityPartnerProfile? _partner;
  bool _autoComputeAttempted = false;
  bool _autoPartnerFormAttempted = false;

  @override
  void initState() {
    super.initState();
    _controller = SoulmateController();
    _partner = widget.birthInputState.compatibilityPartnerProfile;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.startWithPartnerForm &&
          !_autoPartnerFormAttempted &&
          (_partner == null || !_partner!.isComplete)) {
        _autoPartnerFormAttempted = true;
        _openPartnerForm();
      }
      if (widget.entryPoint == SoulmateEntryPoint.mangalDosh &&
          !_autoComputeAttempted &&
          _canCompute) {
        _autoComputeAttempted = true;
        _computeCompatibility();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UniversalDockScaffold(
      appBar: buildTrikaalAppBar(context),
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
                    gender: _formatGenderLabel(widget.birthInputState.gender),
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
                    gender: _partner == null
                        ? 'Not set'
                        : _formatGenderLabel(_partner!.gender),
                    details: _partner == null
                        ? 'Date, time, and place are required for compatibility.'
                        : '${_partner!.dateOfBirth} • ${_partner!.timeOfBirth}\n${_partner!.placeOfBirth}',
                    isReady: _partner != null && _partner!.isComplete,
                    actionLabel:
                        _partner == null ? 'Add partner' : 'Edit partner',
                    onTap: _openPartnerForm,
                  ),
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
                            : _computeActionLabel(),
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
                    if (widget.entryPoint ==
                        SoulmateEntryPoint.mangalDosh) ...<Widget>[
                      _mangalDoshSummaryCard(context, _controller.result!),
                      const SizedBox(height: 12),
                      _mangalDoshLogicCard(context, _controller.result!),
                    ] else ...<Widget>[
                      _compatibilitySummaryCard(
                        context,
                        _controller.result!.compatibility.summary,
                      ),
                      const SizedBox(height: 12),
                      _kutaBreakdownCard(
                        context,
                        _controller.result!.compatibility.ashtaKuta,
                      ),
                    ],
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
          widget.entryPoint == SoulmateEntryPoint.mangalDosh
              ? 'Mangal Dosh'
              : 'Your Soulmate',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          widget.entryPoint == SoulmateEntryPoint.mangalDosh
              ? 'Using your saved partner profile, we evaluate Manglik alignment from both charts.'
              : 'Match two birth charts with Ashta-Kuta and detailed guna insights.',
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
    required String gender,
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
            const SizedBox(height: 2),
            Text(
              'Gender: $gender',
              style: const TextStyle(
                color: Color(0xFFCFB8F7),
                fontSize: 13,
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

  Widget _mangalDoshSummaryCard(
    BuildContext context,
    ComputeCompatibilityResponse response,
  ) {
    final manglik = response.compatibility.manglik;
    final (primary, partner) = _manglikPeopleForResponse(response);
    final isBalanced = manglik.pairAlignment.trim().toLowerCase() == 'balanced';
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
            'Mangal Dosh Result',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFFFE7B3),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${manglik.score.toStringAsFixed(1)} / ${manglik.maxScore.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            manglik.verdict,
            style: const TextStyle(
              color: Color(0xFFD8C8F5),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _pill(isBalanced ? 'Balanced' : 'Unbalanced'),
              _pill(
                'You: ${primary.isManglik ? 'Manglik' : 'Non-Manglik'}',
              ),
              _pill(
                'Partner: ${partner.isManglik ? 'Manglik' : 'Non-Manglik'}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mangalDoshLogicCard(
    BuildContext context,
    ComputeCompatibilityResponse response,
  ) {
    final manglik = response.compatibility.manglik;
    final (primary, partner) = _manglikPeopleForResponse(response);
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
            'Mangal Dosh Logic',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFFFE7B3),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            manglik.method.isEmpty
                ? 'Rule: Mars in houses 1, 2, 4, 7, 8, 12 from Lagna, Moon, and Venus.'
                : 'Rule: ${_humanizeManglikMethod(manglik.method)}',
            style: const TextStyle(
              color: Color(0xFFD8C8F5),
              height: 1.3,
            ),
          ),
          if (manglik.ruleProfileId.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Rule profile: ${manglik.ruleProfileId}',
              style: const TextStyle(
                color: Color(0xFFC77DFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _mangalReferenceBlock(
            title: 'Your Profile',
            person: primary,
          ),
          const SizedBox(height: 10),
          _mangalReferenceBlock(
            title: 'Partner Profile',
            person: partner,
          ),
        ],
      ),
    );
  }

  Widget _mangalReferenceBlock({
    required String title,
    required CompatibilityManglikPerson person,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF3C096C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9D4EDD).withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFE7B3),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            person.isManglik
                ? 'Manglik'
                : (person.cancelledReferences.isNotEmpty
                    ? 'Non-Manglik (Nullified)'
                    : 'Non-Manglik'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ...<String>['lagna', 'moon', 'venus'].map((String referenceKey) {
            final reference = _resolveReferenceEvidence(person, referenceKey);
            final isActiveTrigger = reference.effectiveTriggered;
            final isNullified = reference.cancelled;
            final stateLabel = isActiveTrigger
                ? '✓ trigger'
                : (isNullified ? '~ nullified' : '✗ no trigger');
            final stateColor = isActiveTrigger
                ? const Color(0xFF6DFFB3)
                : (isNullified
                    ? const Color(0xFFFFD27D)
                    : const Color(0xFFD8C8F5));
            final stateWeight = isActiveTrigger || isNullified
                ? FontWeight.w700
                : FontWeight.w500;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${reference.referenceLabel}: H${reference.marsHouse} $stateLabel',
                style: TextStyle(
                  color: stateColor,
                  fontSize: 12,
                  fontWeight: stateWeight,
                ),
              ),
            );
          }),
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
    final visual = _bandVisual(summary.overallBand);
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF3C096C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF9D4EDD).withValues(alpha: 0.42),
              ),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  visual.$1,
                  style: const TextStyle(fontSize: 23),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    visual.$2,
                    style: const TextStyle(
                      color: Color(0xFFFFE7B3),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Text(
                  '🕊️',
                  style: TextStyle(fontSize: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _pill(summary.overallBand),
              _pill(summary.nadiMatch ? 'Nadi Match' : 'Nadi Dosha'),
              _pill(summary.bhakootMatch ? 'Bhakoot Match' : 'Bhakoot Dosha'),
            ],
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 740),
              child: Table(
                border: TableBorder.all(
                  color: const Color(0xFF9D4EDD).withValues(alpha: 0.26),
                  borderRadius: BorderRadius.circular(12),
                ),
                columnWidths: const <int, TableColumnWidth>{
                  0: FlexColumnWidth(1.4),
                  1: FlexColumnWidth(0.65),
                  2: FlexColumnWidth(0.7),
                  3: FlexColumnWidth(1.1),
                  4: FlexColumnWidth(1.1),
                  5: FlexColumnWidth(1.25),
                },
                children: <TableRow>[
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFF5A189A)),
                    children: <Widget>[
                      _tableHeaderCell('Guna'),
                      _tableHeaderCell('Max'),
                      _tableHeaderCell('Obt'),
                      _tableHeaderCell('Boy'),
                      _tableHeaderCell('Girl'),
                      _tableHeaderCell('Area of Life'),
                    ],
                  ),
                  ...ashtaKuta.components.map((component) {
                    return TableRow(
                      decoration: BoxDecoration(
                        color: const Color(0xFF240046).withValues(alpha: 0.9),
                      ),
                      children: <Widget>[
                        _tableCell(component.label, isBold: true),
                        _tableCell(component.maxScore.toStringAsFixed(0),
                            centered: true),
                        _tableCell(component.score.toStringAsFixed(1),
                            centered: true),
                        _tableCell(
                          component.boyValue.isEmpty ? '-' : component.boyValue,
                        ),
                        _tableCell(
                          component.girlValue.isEmpty
                              ? '-'
                              : component.girlValue,
                        ),
                        _tableCell(
                          component.areaOfLife.isEmpty
                              ? '-'
                              : component.areaOfLife,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ashtaKuta.components.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.22,
            ),
            itemBuilder: (BuildContext context, int index) {
              final component = ashtaKuta.components[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3C096C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF9D4EDD).withValues(alpha: 0.32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${component.label} Details',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFFE7B3),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () =>
                              _showKutaExplanationSheet(context, component),
                          child: const Padding(
                            padding: EdgeInsets.all(3),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFFFFE7B3),
                              size: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${component.score.toStringAsFixed(1)} / ${component.maxScore.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Boy: ${component.boyValue.isEmpty ? '-' : component.boyValue}',
                      style: const TextStyle(
                        color: Color(0xFFD8C8F5),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Girl: ${component.girlValue.isEmpty ? '-' : component.girlValue}',
                      style: const TextStyle(
                        color: Color(0xFFD8C8F5),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      component.areaOfLife.isEmpty
                          ? 'Area: -'
                          : 'Area: ${component.areaOfLife}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFC77DFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _tableCell(
    String text, {
    bool isBold = false,
    bool centered = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Text(
        text,
        textAlign: centered ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Future<void> _showKutaExplanationSheet(
    BuildContext context,
    CompatibilityKutaComponent component,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF240046),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${component.label} Kuta',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFFFFE7B3),
                            ),
                      ),
                    ),
                    Text(
                      '${component.score.toStringAsFixed(1)}/${component.maxScore.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  component.description.isEmpty
                      ? 'This kuta score contributes to overall Ashta-Kuta matching quality.'
                      : component.description,
                  style: const TextStyle(
                    color: Color(0xFFD8C8F5),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Boy: ${component.boyValue.isEmpty ? '-' : component.boyValue}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Girl: ${component.girlValue.isEmpty ? '-' : component.girlValue}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Area of Life: ${component.areaOfLife.isEmpty ? '-' : component.areaOfLife}',
                  style: const TextStyle(color: Color(0xFFC77DFF)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  (String, String) _bandVisual(String band) {
    final value = band.trim().toLowerCase();
    if (value == 'excellent') {
      return ('🕊️💞🕊️', 'Harmony is exceptionally strong for this match.');
    }
    if (value == 'very good') {
      return ('💖🕊️', 'Strong compatibility with good long-term potential.');
    }
    if (value == 'middling') {
      return ('🤍🕊️', 'Moderate compatibility that needs conscious effort.');
    }
    return ('🕊️', 'Sensitive match. Alignment work is important.');
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

  String _computeActionLabel() {
    if (widget.entryPoint == SoulmateEntryPoint.mangalDosh) {
      return 'Check Mangal Dosh';
    }
    return 'Find Compatibility';
  }

  (CompatibilityManglikPerson, CompatibilityManglikPerson)
      _manglikPeopleForResponse(ComputeCompatibilityResponse response) {
    final isPrimaryBoy = response.roles.primary.trim().toLowerCase() == 'boy';
    if (isPrimaryBoy) {
      return (
        response.compatibility.manglik.boy,
        response.compatibility.manglik.girl
      );
    }
    return (
      response.compatibility.manglik.girl,
      response.compatibility.manglik.boy
    );
  }

  CompatibilityManglikReferenceEvidence _resolveReferenceEvidence(
    CompatibilityManglikPerson person,
    String referenceKey,
  ) {
    final existing = person.referenceEvidence[referenceKey];
    if (existing != null) {
      return existing;
    }
    final marsHouse = switch (referenceKey) {
      'lagna' => person.marsHouseFromLagna,
      'moon' => person.marsHouseFromMoon,
      'venus' => person.marsHouseFromVenus,
      _ => 0,
    };
    final triggerHouses = person.triggerHouses.isEmpty
        ? _defaultManglikTriggerHouses
        : person.triggerHouses;
    final label = switch (referenceKey) {
      'lagna' => 'Lagna',
      'moon' => 'Moon',
      'venus' => 'Venus',
      _ => referenceKey,
    };
    final triggered = triggerHouses.contains(marsHouse);
    return CompatibilityManglikReferenceEvidence(
      referenceKey: referenceKey,
      referenceLabel: label,
      marsHouse: marsHouse,
      triggered: triggered,
      effectiveTriggered: triggered,
      cancelled: false,
      ruleHouses: triggerHouses,
      reason: triggered
          ? 'Mars in house $marsHouse from $label triggers the rule.'
          : 'Mars in house $marsHouse from $label does not trigger the rule.',
    );
  }

  String _humanizeManglikMethod(String method) {
    if (method == 'mars_in_1_2_4_7_8_12_from_lagna_moon_venus') {
      return 'Mars in houses 1, 2, 4, 7, 8, 12 from Lagna, Moon, and Venus.';
    }
    return method.replaceAll('_', ' ');
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

  String _formatGenderLabel(PersonGender gender) {
    return switch (gender) {
      PersonGender.male => 'Male',
      PersonGender.female => 'Female',
      PersonGender.unspecified => 'Not set',
    };
  }

  String _derivePrimaryRole({
    required PersonGender primaryGender,
    required PersonGender partnerGender,
  }) {
    if (primaryGender == PersonGender.male &&
        partnerGender == PersonGender.female) {
      return 'boy';
    }
    if (primaryGender == PersonGender.female &&
        partnerGender == PersonGender.male) {
      return 'girl';
    }
    if (primaryGender == PersonGender.female) {
      return 'girl';
    }
    return 'boy';
  }

  Future<void> _openPartnerForm() async {
    final draft = await Navigator.of(context).push<CompatibilityPartnerProfile>(
      MaterialPageRoute<CompatibilityPartnerProfile>(
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
    widget.birthInputState.setCompatibilityPartnerProfile(draft);
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
      primaryRole: _derivePrimaryRole(
        primaryGender: widget.birthInputState.gender,
        partnerGender: partner.gender,
      ),
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

  final CompatibilityPartnerProfile? initialDraft;
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
  PersonGender _gender = PersonGender.unspecified;
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
    _gender = widget.initialDraft?.gender ?? PersonGender.unspecified;
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
                      DropdownButtonFormField<PersonGender>(
                        initialValue: _gender == PersonGender.unspecified
                            ? null
                            : _gender,
                        decoration: const InputDecoration(
                          labelText: 'Partner Gender',
                          hintText: 'Select gender',
                          prefixIcon: Icon(Icons.wc_rounded),
                        ),
                        items: const <DropdownMenuItem<PersonGender>>[
                          DropdownMenuItem<PersonGender>(
                            value: PersonGender.male,
                            child: Text('Male'),
                          ),
                          DropdownMenuItem<PersonGender>(
                            value: PersonGender.female,
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: (PersonGender? value) {
                          if (value == null) {
                            return;
                          }
                          _gender = value;
                          setState(() {});
                        },
                        validator: (PersonGender? value) {
                          if (value == null ||
                              value == PersonGender.unspecified) {
                            return 'Partner gender is required';
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
    final draft = CompatibilityPartnerProfile(
      name: _nameController.text.trim(),
      gender: _gender,
      dateOfBirth: _dateController.text.trim(),
      timeOfBirth: _timeController.text.trim(),
      placeOfBirth: _placeController.text.trim(),
      customPlace: _customPlace,
    );
    Navigator.of(context).pop(draft);
  }
}
