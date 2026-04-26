import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../shared/network/json_api_helpers.dart';
import 'models/compute_chart_models.dart';
import 'models/compute_report_models.dart';
import 'models/place_search_models.dart';
import '../../pancha_pakshi/data/models/pancha_pakshi_models.dart';
import '../../subscription/data/models/subscription_models.dart';

class ChartApiException implements Exception {
  const ChartApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    return 'ChartApiException(statusCode: $statusCode, message: $message)';
  }
}

class ChartApiClient {
  ChartApiClient({String? baseUrl, http.Client? httpClient})
      : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;

  Future<ComputeChartResponse> computeChart(ComputeChartRequest request) async {
    final uri = Uri.parse('$_baseUrl/v1/charts/compute');
    final body = await postJson(
      client: _httpClient,
      uri: uri,
      payload: request.toJson(),
      exceptionBuilder: (message, statusCode) => ChartApiException(
        message,
        statusCode: statusCode,
      ),
    );
    return ComputeChartResponse.fromJson(body);
  }

  Future<ComputeReportResponse> computeReport(
    ComputeChartRequest request,
  ) async {
    final uri = Uri.parse('$_baseUrl/v1/reports/compute');
    final body = await postJson(
      client: _httpClient,
      uri: uri,
      payload: request.toJson(),
      exceptionBuilder: (message, statusCode) => ChartApiException(
        message,
        statusCode: statusCode,
      ),
    );
    return ComputeReportResponse.fromJson(body);
  }

  Future<PlaceSearchResponse> searchPlaces(String query) async {
    final uri = Uri.parse(
      '$_baseUrl/v1/places/search',
    ).replace(queryParameters: <String, String>{'query': query});
    final body = await getJson(
      client: _httpClient,
      uri: uri,
      exceptionBuilder: (message, statusCode) => ChartApiException(
        message,
        statusCode: statusCode,
      ),
    );
    return PlaceSearchResponse.fromJson(body);
  }

  Future<SubscriptionPlansResponse> fetchSubscriptionPlans() async {
    final uri = Uri.parse('$_baseUrl/v1/billing/plans');
    final body = await getJson(
      client: _httpClient,
      uri: uri,
      exceptionBuilder: (message, statusCode) => ChartApiException(
        message,
        statusCode: statusCode,
      ),
    );
    return SubscriptionPlansResponse.fromJson(body);
  }

  Future<PanchaPakshiResponse> computePanchaPakshi(
    PanchaPakshiRequest request,
  ) async {
    final uri = Uri.parse('$_baseUrl/v1/pancha-pakshi/compute');
    final body = await postJson(
      client: _httpClient,
      uri: uri,
      payload: request.toJson(),
      exceptionBuilder: (message, statusCode) => ChartApiException(
        message,
        statusCode: statusCode,
      ),
    );
    return PanchaPakshiResponse.fromJson(body);
  }

  void dispose() {
    _httpClient.close();
  }
}
