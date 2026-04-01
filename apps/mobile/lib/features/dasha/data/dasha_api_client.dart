import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
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
    _logRequest('POST', uri);
    final response = await _httpClient.post(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    _logResponse('POST', uri, response.statusCode);
    final body = _decode(response.body);
    _throwIfError(response.statusCode, body);
    return DashaComputeResponse.fromJson(body);
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
    throw const DashaApiException('Unexpected response format from server');
  }

  void _throwIfError(int statusCode, Map<String, dynamic> body) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    throw DashaApiException(
      (body['detail'] as String?) ?? 'Request failed',
      statusCode: statusCode,
    );
  }

  void _logRequest(String method, Uri uri) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[TRIKAAL_API] -> $method $uri');
  }

  void _logResponse(String method, Uri uri, int statusCode) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[TRIKAAL_API] <- $statusCode $method $uri');
  }
}
