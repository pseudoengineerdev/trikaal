class SubscriptionPlansResponse {
  const SubscriptionPlansResponse({
    required this.version,
    required this.currency,
    required this.headline,
    required this.subheadline,
    required this.defaultPlanCode,
    required this.plans,
  });

  final String version;
  final String currency;
  final String headline;
  final String subheadline;
  final String defaultPlanCode;
  final List<SubscriptionPlan> plans;

  factory SubscriptionPlansResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlansResponse(
      version: json['version'] as String? ?? 'v1',
      currency: json['currency'] as String? ?? 'USD',
      headline: json['headline'] as String? ?? 'Choose your plan',
      subheadline: json['subheadline'] as String? ?? '',
      defaultPlanCode: json['default_plan_code'] as String? ?? 'monthly',
      plans: (json['plans'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionPlan.fromJson)
          .toList(growable: false),
    );
  }
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.code,
    required this.cycle,
    required this.title,
    required this.priceUsd,
    required this.periodLabel,
    required this.discountPercent,
    required this.discountLabel,
    required this.badge,
    required this.recommended,
  });

  final String code;
  final String cycle;
  final String title;
  final double priceUsd;
  final String periodLabel;
  final int discountPercent;
  final String? discountLabel;
  final String? badge;
  final bool recommended;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      code: json['code'] as String? ?? '',
      cycle: json['cycle'] as String? ?? '',
      title: json['title'] as String? ?? '',
      priceUsd: (json['price_usd'] as num?)?.toDouble() ?? 0,
      periodLabel: json['period_label'] as String? ?? '',
      discountPercent: json['discount_percent'] as int? ?? 0,
      discountLabel: json['discount_label'] as String?,
      badge: json['badge'] as String?,
      recommended: json['recommended'] as bool? ?? false,
    );
  }
}
