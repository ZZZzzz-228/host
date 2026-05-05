import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

/// Кэш списка сотрудников для гостевой страницы контактов (работа без сети после первой успешной загрузки).
class GuestStaffCache {
  GuestStaffCache._();

  static String _keyForScope(String scope) => 'guest_staff_list_v4_$scope';

  static Future<List<StaffMemberItem>?> read({String scope = 'all'}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyForScope(scope));
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return null;
    try {
      return decoded
          .whereType<Map>()
          .map((e) => StaffMemberItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(List<StaffMemberItem> staff, {String scope = 'all'}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(staff.map((e) => e.toJson()).toList());
    await prefs.setString(_keyForScope(scope), raw);
  }
}
