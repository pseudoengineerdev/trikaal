import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef ApiExceptionBuilder = Exception Function(
    String message, int? statusCode);

Future<Map<String, dynamic>> getJson({
  required http.Client client,
  required Uri uri,
  required ApiExceptionBuilder exceptionBuilder,
}) async {
  _logRequest('GET', uri);
  final response = await client.get(uri);
  _logResponse('GET', uri, response.statusCode);
  final body = _decodeJsonObject(
    statusCode: response.statusCode,
    response.body,
    exceptionBuilder: exceptionBuilder,
  );
  _throwIfError(
    response.statusCode,
    body,
    exceptionBuilder: exceptionBuilder,
  );
  return body;
}

Future<Map<String, dynamic>> postJson({
  required http.Client client,
  required Uri uri,
  required Map<String, dynamic> payload,
  required ApiExceptionBuilder exceptionBuilder,
}) async {
  _logRequest('POST', uri);
  final response = await client.post(
    uri,
    headers: const <String, String>{'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );
  _logResponse('POST', uri, response.statusCode);
  final body = _decodeJsonObject(
    statusCode: response.statusCode,
    response.body,
    exceptionBuilder: exceptionBuilder,
  );
  _throwIfError(
    response.statusCode,
    body,
    exceptionBuilder: exceptionBuilder,
  );
  return body;
}

Map<String, dynamic> _decodeJsonObject(
  String responseBody, {
  required int statusCode,
  required ApiExceptionBuilder exceptionBuilder,
}) {
  if (responseBody.trim().isEmpty) {
    throw exceptionBuilder(
      'Server returned an empty response (HTTP $statusCode).',
      statusCode,
    );
  }

  final dynamic decoded;
  try {
    decoded = jsonDecode(responseBody);
  } catch (_) {
    final preview = responseBody.length <= 220
        ? responseBody
        : '${responseBody.substring(0, 220)}...';
    final concise =
        preview.replaceAll('\n', ' ').replaceAll('\r', ' ').replaceAll('\t', ' ');
    throw exceptionBuilder(
      'Non-JSON response from server (HTTP $statusCode): $concise',
      statusCode,
    );
  }

  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  throw exceptionBuilder(
    'Unexpected response format from server (HTTP $statusCode).',
    statusCode,
  );
}

void _throwIfError(
  int statusCode,
  Map<String, dynamic> body, {
  required ApiExceptionBuilder exceptionBuilder,
}) {
  if (statusCode >= 200 && statusCode < 300) {
    return;
  }

  if (statusCode == 404) {
    final detail = body['detail'] as String?;
    final detailText = detail?.trim().toLowerCase();
    if (detailText == null || detailText == 'not found') {
      throw exceptionBuilder(
        'Endpoint not found on API. Please restart API with the latest backend build.',
        statusCode,
      );
    }
    throw exceptionBuilder(
      detail ?? 'Endpoint not found on API.',
      statusCode,
    );
  }

  throw exceptionBuilder(
    (body['detail'] as String?) ?? 'Request failed with status $statusCode.',
    statusCode,
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
