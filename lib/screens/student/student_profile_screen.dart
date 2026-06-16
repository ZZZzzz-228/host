import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../data/api/api_base_url.dart';
import '../../data/session/app_session.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import '../guest/guest_main_screen.dart';
import '../widgets/centered_app_bar_title.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String _groupName = '';
  String _statusText = 'Активен';
  String _lastLoginText = '—';
  String _createdAtText = '—';
  List<_CabinetNotification> _notifications = const [];

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<String> _ensureToken() async {
    if ((AppSession.apiClient.token ?? '').isEmpty) {
      try {
        await AppSession.apiClient.fetchStudentProfile();
      } catch (_) {}
    }
    final token = AppSession.apiClient.token ?? '';
    if (token.isEmpty) {
      throw Exception('Сессия не найдена');
    }
    return token;
  }

  String _cabinetBaseUrl() {
    final baseUrl = resolveApiBaseUrl();
    return baseUrl.replaceFirst(RegExp(r'/index\.php$'), '/student_cabinet.php');
  }

  Uri _cabinetUri(String action, String token) {
    return Uri.parse(
      '${_cabinetBaseUrl()}?action=$action&access_token=${Uri.encodeQueryComponent(token)}',
    );
  }

  Map<String, String> _headers(String token, {bool jsonBody = false}) {
    return <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Auth-Token': token,
      if (jsonBody) 'Content-Type': 'application/json',
    };
  }

  Future<void> _reloadAll() async {
    setState(() => _loading = true);

    try {
      final token = await _ensureToken();

      final responses = await Future.wait([
        http.get(_cabinetUri('profile', token), headers: _headers(token)),
        http.get(_cabinetUri('notifications', token), headers: _headers(token)),
      ]);

      final profileJson =
          jsonDecode(responses[0].body) as Map<String, dynamic>? ?? {};
      final notificationsJson =
          jsonDecode(responses[1].body) as Map<String, dynamic>? ?? {};

      if (responses[0].statusCode < 200 || responses[0].statusCode >= 300) {
        throw Exception(
          (profileJson['error'] ?? profileJson['message'] ?? 'Не удалось загрузить профиль')
              .toString(),
        );
      }

      final profile = _CabinetProfile.fromJson(
        (profileJson['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

      final notificationsRaw = notificationsJson['data'];
      final notifications = notificationsRaw is List
          ? notificationsRaw
          .whereType<Map>()
          .map((e) => _CabinetNotification.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false)
          : const <_CabinetNotification>[];

      _fullNameController.text = profile.fullName;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
      _bioController.text = profile.bio;

      if (!mounted) return;
      setState(() {
        _groupName = profile.groupName;
        _statusText = profile.isActive ? 'Активен' : 'Заблокирован';
        _createdAtText = _formatDate(profile.createdAt);
        _lastLoginText = _formatDate(profile.lastLogin);
        _notifications = notifications;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final bio = _bioController.text.trim();

    if (fullName.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните ФИО и email')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final token = await _ensureToken();
      final response = await http.put(
        _cabinetUri('profile', token),
        headers: _headers(token, jsonBody: true),
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'bio': bio,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          (body['error'] ?? body['message'] ?? 'Не удалось сохранить профиль').toString(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль сохранён')),
      );
      await _reloadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showNotificationsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.notifications_outlined, color: Color(0xFF4A90E2)),
                    SizedBox(width: 10),
                    Text(
                      'Уведомления',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_notifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Новых уведомлений нет',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _notifications[index];
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5ECF6)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A90E2).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: const Color(0xFF4A90E2),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.message,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.createdAt.isEmpty ? '—' : item.createdAt,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day.$month.$year $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName =
    _fullNameController.text.trim().isEmpty ? 'Студент' : _fullNameController.text.trim();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const CenteredAppBarTitle(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: _showNotificationsSheet,
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF4A90E2),
                  ),
                ),
                if (_notifications.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 18,
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          _notifications.length > 9 ? '9+' : '${_notifications.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: HapticRefreshIndicator(
        color: const Color(0xFF4A90E2),
        onRefresh: _reloadAll,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(
                  Icons.person,
                  size: 52,
                  color: Color(0xFF4A90E2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _groupName.isEmpty ? 'Группа не назначена' : _groupName,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoCard(
                children: [
                  _buildReadOnlyRow('Статус', _statusText),
                  const SizedBox(height: 12),
                  _buildReadOnlyRow('Дата регистрации', _createdAtText),
                  const SizedBox(height: 12),
                  _buildReadOnlyRow('Последний вход', _lastLoginText),
                ],
              ),
              const SizedBox(height: 14),
              _buildInputCard(
                label: 'ФИО',
                controller: _fullNameController,
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),
              _buildInputCard(
                label: 'Email',
                controller: _emailController,
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildInputCard(
                label: 'Телефон',
                controller: _phoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyCard(
                label: 'Группа',
                value: _groupName.isEmpty ? 'Не назначена' : _groupName,
                icon: Icons.groups_2_outlined,
              ),
              const SizedBox(height: 12),
              _buildInputCard(
                label: 'О себе',
                controller: _bioController,
                icon: Icons.description_outlined,
                maxLines: 5,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Сохранение...' : 'Сохранить'),
                ),
              ),
              const SizedBox(height: 12),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF4A90E2)),
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildReadOnlyCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4A90E2)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppSession.apiClient.logout();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GuestMainScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'Выйти',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CabinetProfile {
  const _CabinetProfile({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.bio,
    required this.groupName,
    required this.createdAt,
    required this.lastLogin,
    required this.isActive,
  });

  final String fullName;
  final String email;
  final String phone;
  final String bio;
  final String groupName;
  final String createdAt;
  final String lastLogin;
  final bool isActive;

  factory _CabinetProfile.fromJson(Map<String, dynamic> json) {
    return _CabinetProfile(
      fullName: (json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      groupName: (json['group_name'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      lastLogin: (json['last_login'] ?? '').toString(),
      isActive: (json['is_active'] as num?)?.toInt() != 0,
    );
  }
}

class _CabinetNotification {
  const _CabinetNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final String createdAt;

  IconData get icon {
    switch (type) {
      case 'schedule':
        return Icons.schedule_rounded;
      case 'news':
        return Icons.newspaper_rounded;
      case 'contacts':
        return Icons.perm_contact_calendar_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  factory _CabinetNotification.fromJson(Map<String, dynamic> json) {
    return _CabinetNotification(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}
