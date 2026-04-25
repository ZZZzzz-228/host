import 'dart:io';

import 'package:flutter/foundation.dart';

String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) {
    return fromEnv;
  }

  if (kIsWeb) {
    return 'https://aksibgu.gamer.gd';
  }

  if (Platform.isAndroid) {
    return 'https://aksibgu.gamer.gd';
  }

  if (Platform.isIOS) {
    // Физический iPhone: IPv4 ПК в той же Wi‑Fi сети (см. ipconfig → «Беспроводная сеть»).
    return 'https://aksibgu.gamer.gd';
  }

  return 'https://aksibgu.gamer.gd';
}
