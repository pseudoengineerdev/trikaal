import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import 'models/compute_chart_models.dart';
import 'models/place_search_models.dart';

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
    final response = await _httpClient.post(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    final body = _decode(response.body);
    _throwIfError(response.statusCode, body);
    return ComputeChartResponse.fromJson(body);
  }

  Future<PlaceSearchResponse> searchPlaces(String query) async {
    final uri = Uri.parse(
      '$_baseUrl/v1/places/search',
    ).replace(queryParameters: <String, String>{'query': query});
    final response = await _httpClient.get(uri);
    final body = _decode(response.body);
    _throwIfError(response.statusCode, body);
    return PlaceSearchResponse.fromJson(body);
  }

  void dispose() {
    _httpClient.close();
  }

  Map<String, dynamic> _decode(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const ChartApiException('Unexpected response format from server');
  }

  void _throwIfError(int statusCode, Map<String, dynamic> body) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    throw ChartApiException(
      (body['detail'] as String?) ?? 'Request failed',
      statusCode: statusCode,
    );
  }
}
