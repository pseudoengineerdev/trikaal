import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';

class AstrologyTermsState extends ChangeNotifier {
  AstrologyTermsState({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  String version = 'local-fallback';
  Map<String, Map<String, String>> rashi = <String, Map<String, String>>{};
  Map<String, Map<String, String>> nakshatra = <String, Map<String, String>>{};
  Map<String, Map<String, String>> graha = <String, Map<String, String>>{};
  bool loaded = false;
  String? error;

  Future<void> load() async {
    final uri =
        Uri.parse('${AppConfig.apiBaseUrl}/v1/metadata/astrology-terms');
    try {
      final response = await _httpClient.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        error = 'Unable to load terms contract';
        notifyListeners();
        return;
      }
      final payload = _decode(response.body);
      version = (payload['version'] as String?) ?? 'unknown';
      rashi = _readCategory(payload['rashi']);
      nakshatra = _readCategory(payload['nakshatra']);
      graha = _readCategory(payload['graha']);
      loaded = true;
      error = null;
      notifyListeners();
    } catch (_) {
      error = 'Unable to load terms contract';
      notifyListeners();
    }
  }

  String? lookup({
    required String category,
    required String key,
    required String field,
  }) {
    final source = switch (category) {
      'rashi' => rashi,
      'nakshatra' => nakshatra,
      'graha' => graha,
      _ => <String, Map<String, String>>{},
    };
    return source[key]?[field];
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  Map<String, dynamic> _decode(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  Map<String, Map<String, String>> _readCategory(Object? raw) {
    if (raw is! Map) {
      return <String, Map<String, String>>{};
    }
    final result = <String, Map<String, String>>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is Map) {
        result[entry.key.toString()] = value.map(
          (dynamic key, dynamic value) => MapEntry(
            key.toString(),
            value.toString(),
          ),
        );
      }
    }
    return result;
  }
}
