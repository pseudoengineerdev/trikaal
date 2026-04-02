import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../shared/network/json_api_helpers.dart';
import 'models/dasha_models.dart';

class DashaApiException implements Exception {
  const DashaApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    return 'DashaApiException(statusCode: $statusCode, message: $message)';
  }
}

class DashaApiClient {
  DashaApiClient({String? baseUrl, http.Client? httpClient})
      : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;

  Future<DashaComputeResponse> computeDasha(DashaComputeRequest request) async {
    final uri = Uri.parse('$_baseUrl/v1/dasha/compute');
    final body = await postJson(
      client: _httpClient,
      uri: uri,
      payload: request.toJson(),
      exceptionBuilder: (message, statusCode) => DashaApiException(
        message,
        statusCode: statusCode,
      ),
    );
    return DashaComputeResponse.fromJson(body);
  }

  void dispose() {
    _httpClient.close();
  }
}
