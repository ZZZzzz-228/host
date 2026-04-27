import 'package:flutter/foundation.dart';

/// Базовый URL для всех HTTP-запросов к бэкенду на Beget.
///
/// На хостинге Beget API живёт под /api/public/, поэтому в baseUrl сразу
/// включаем этот префикс. Все вызовы api_client.dart должны быть
/// БЕЗ префикса /public — например _get('/auth/login'), _get('/news').
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) {
    return fromEnv;
  }
  return 'http://kucersta.beget.tech/api/public';
}
