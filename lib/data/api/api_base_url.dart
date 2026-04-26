// Web-safe определение базового URL API.
// Раньше здесь был импорт `dart:io`, который ломает сборку под Web.
import 'package:flutter/foundation.dart';

/// Базовый URL для всех HTTP-запросов к бэкенду на Beget.
///
/// При желании можно переопределить через `--dart-define=API_BASE_URL=...`
/// при сборке (например, для локального dev-сервера).
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) {
    return fromEnv;
  }
  // Один и тот же URL для всех платформ — продакшн на Beget.
  return 'http://kucersta.beget.tech/api';
}
