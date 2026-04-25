import 'dart:io';
import 'package:flutter/foundation.dart';

String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) {
    return fromEnv;
  }

  if (kIsWeb) {
    return 'http://kucersta.beget.tech/api/public';  // ← убрали пробел
  }

  if (Platform.isAndroid) {
    return 'http://kucersta.beget.tech/api/public';  // ← убрали пробел
  }

  if (Platform.isIOS) {
    return 'http://kucersta.beget.tech/api/public';  // ← убрали пробел
  }

  return 'http://kucersta.beget.tech/api/public';  // ← убрали пробел
}