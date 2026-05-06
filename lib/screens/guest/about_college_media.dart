import 'package:flutter/material.dart';

String aboutCollegeAbsoluteUrl(String baseUrl, String value) {
  if (value.isEmpty) return value;
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  // baseUrl типично имеет вид `http://kucersta.beget.tech/api`.
  // Из него надо извлечь чистый хост (`http://kucersta.beget.tech`),
  // иначе для путей вида `/api/public/uploads/...` будет дублироваться `/api/api/...`.
  final trimmedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  final origin = _serverOrigin(trimmedBase);
  if (value.startsWith('/api/')) {
    return '$origin$value';
  }
  if (value.startsWith('/')) {
    return '$origin/api/public$value';
  }
  return '$origin/api/public/$value';
}

String _serverOrigin(String baseUrl) {
  try {
    final uri = Uri.parse(baseUrl);
    if (uri.hasScheme && uri.host.isNotEmpty) {
      return uri.hasPort
          ? '${uri.scheme}://${uri.host}:${uri.port}'
          : '${uri.scheme}://${uri.host}';
    }
  } catch (_) {}
  return baseUrl;
}

Widget aboutCollegeImageFromPath(
  String baseUrl,
  String path, {
  required BoxFit fit,
  Widget? errorFallback,
}) {
  final p = path.trim();
  if (p.isEmpty) {
    return errorFallback ?? const SizedBox.shrink();
  }
  if (p.startsWith('assets/')) {
    return Image.asset(
      p,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => errorFallback ?? const SizedBox.shrink(),
    );
  }
  return Image.network(
    aboutCollegeAbsoluteUrl(baseUrl, p),
    fit: fit,
    errorBuilder: (context, error, stackTrace) => errorFallback ?? const SizedBox.shrink(),
  );
}

Color? aboutCollegeParseColorHex(String value) {
  var hex = value.trim();
  if (hex.isEmpty) return null;
  if (hex.startsWith('0x') || hex.startsWith('0X')) {
    hex = hex.substring(2);
  }
  final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
  if (cleaned.length != 6 && cleaned.length != 8) return null;
  final full = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  final parsed = int.tryParse(full, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}
