import '../../charts/data/models/compute_report_models.dart';
import '../../home/presentation/astrology/rashi_insights.dart';

class SignTrioInsights {
  const SignTrioInsights({
    required this.sun,
    required this.moon,
    required this.rising,
  });

  final RashiInsight sun;
  final RashiInsight moon;
  final RashiInsight rising;

  factory SignTrioInsights.fromReport(ComputeReportResponse report) {
    final vedic = report.snapshot.vedic;
    return SignTrioInsights(
      sun: rashiInsightFor(vedic.sun.rashi),
      moon: rashiInsightFor(vedic.moon.rashi),
      rising: rashiInsightFor(vedic.lagna.rashi),
    );
  }
}
