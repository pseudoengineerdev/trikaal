import '../../../dasha/data/models/dasha_models.dart';
import 'compute_chart_models.dart';

class ComputeReportResponse {
  const ComputeReportResponse({
    required this.chart,
    required this.dasha,
  });

  final ComputeChartResponse chart;
  final DashaSummary dasha;

  factory ComputeReportResponse.fromJson(Map<String, dynamic> json) {
    final profile = _asMap(json['profile']);
    final normalizedInput = _asMap(json['normalized_input']);
    final resolvedPlace =
        ResolvedPlace.fromJson(_asMap(json['resolved_place']));
    final snapshot = _asMap(json['snapshot']);

    return ComputeReportResponse(
      chart: ComputeChartResponse(
        profile: profile,
        normalizedInput: normalizedInput,
        resolvedPlace: resolvedPlace,
        snapshot: snapshot,
      ),
      dasha: DashaSummary.fromJson(_asMap(json['dasha'])),
    );
  }
}

Map<String, dynamic> _asMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}
