import 'dart:io';
import 'package:flutter/foundation.dart';

String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) {
    return fromEnv;
  }

  if (kIsWeb) {
    return 'https://aksibgu.gamer.gd';  // ← убрали пробел
  }

  if (Platform.isAndroid) {
    return 'https://aksibgu.gamer.gd';  // ← убрали пробел
  }

  if (Platform.isIOS) {
    return 'https://aksibgu.gamer.gd';  // ← убрали пробел
  }

  return 'https://aksibgu.gamer.gd';  // ← убрали пробел
}