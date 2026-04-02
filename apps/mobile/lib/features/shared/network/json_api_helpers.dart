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
  required ApiExceptionBuilder exceptionBuilder,
}) {
  final dynamic decoded;
  try {
    decoded = jsonDecode(responseBody);
  } catch (_) {
    throw exceptionBuilder('Unexpected response format from server', null);
  }

  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  throw exceptionBuilder('Unexpected response format from server', null);
}

void _throwIfError(
  int statusCode,
  Map<String, dynamic> body, {
  required ApiExceptionBuilder exceptionBuilder,
}) {
  if (statusCode >= 200 && statusCode < 300) {
    return;
  }
  throw exceptionBuilder(
    (body['detail'] as String?) ?? 'Request failed',
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
