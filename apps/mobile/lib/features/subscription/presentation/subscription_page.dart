import 'package:flutter/material.dart';

import '../../../app/navigation/app_dock_navigation.dart';
import '../../../app/state/birth_input_state.dart';
import '../../../app/widgets/astro_page_background.dart';
import '../../../app/widgets/universal_dock_scaffold.dart';
import '../../charts/data/chart_api_client.dart';
import '../../subscription/data/models/subscription_models.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({
    required this.birthInputState,
    super.key,
  });

  final BirthInputState birthInputState;

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late final ChartApiClient _apiClient;
  late final Future<SubscriptionPlansResponse> _plansFuture;
  String? _selectedPlanCode;

  @override
  void initState() {
    super.initState();
    _apiClient = ChartApiClient();
    _plansFuture = _apiClient.fetchSubscriptionPlans();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UniversalDockScaffold(
      appBar: AppBar(title: const Text('Premium')),
      activeItem: AppDockItem.premium,
      onItemSelected: (AppDockItem item) => _handleDockItemTap(context, item),
      body: AstroPageBackground(
        child: SafeArea(
          child: FutureBuilder<SubscriptionPlansResponse>(
            future: _plansFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to load plans right now. Please try again.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final plans = snapshot.data!;
              if (plans.plans.isEmpty) {
                return const Center(
                  child: Text('No plans available right now.'),
                );
              }
              _selectedPlanCode ??= plans.defaultPlanCode;
              final selected = plans.plans.firstWhere(
                (plan) => plan.code == _selectedPlanCode,
                orElse: () => plans.plans.first,
              );
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plans.headline,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plans.subheadline,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: plans.plans.map((plan) {
                        final isSelected = plan.code == _selectedPlanCode;
                        return ChoiceChip(
                          label: Text(plan.title),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedPlanCode = plan.code);
                          },
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: 16),
                    _PlanCard(
                      plan: selected,
                      currency: plans.currency,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Checkout wiring for ${selected.title} will be added in payments phase.',
                                ),
                              ),
                            );
                        },
                        child: Text('Continue with ${selected.title}'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Pricing is shared via backend contract so mobile and web stay in sync.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
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
      activeItem: AppDockItem.premium,
      birthInputState: widget.birthInputState,
      homeBehavior: DockHomeBehavior.popToRoot,
      chartsBehavior: DockChartsBehavior.pushFeatures,
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.currency,
  });

  final SubscriptionPlan plan;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
        color: colorScheme.surface.withValues(alpha: 0.86),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 8),
              if (plan.badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                  ),
                  child: Text(
                    plan.badge!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '\$${plan.priceUsd.toStringAsFixed(plan.priceUsd.truncateToDouble() == plan.priceUsd ? 0 : 2)} / ${plan.periodLabel}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            currency,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (plan.discountPercent > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.secondaryContainer.withValues(alpha: 0.38),
              ),
              child: Text(
                plan.discountLabel ?? 'Save ${plan.discountPercent}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
