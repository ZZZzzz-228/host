import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/api/api_client.dart';
import '../../data/cache/guest_staff_cache.dart';
import '../../data/session/app_session.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import '../widgets/centered_app_bar_title.dart';

/// Единый экран контактов — используется И в гостевой, И в студенческой части
/// приложения. Все данные тянутся с сервера:
///   • контакты (телефоны/почта/сайт)  → fetchContacts()
///   • сотрудники (фото + ФИО + ...)   → fetchStaff()
///
/// Это «один источник истины»: правишь карточку в админке (vk_pending → нет,
/// в /admin/contacts.php и /admin/staff.php) — меняется и для гостя, и для студента.
class SharedContactsScreen extends StatefulWidget {
  const SharedContactsScreen({super.key});

  @override
  State<SharedContactsScreen> createState() => _SharedContactsScreenState();
}

class _SharedContactsScreenState extends State<SharedContactsScreen> {
  final ScrollController _scrollController = ScrollController();
  final ApiClient _apiClient = AppSession.apiClient;
  bool _showHeaderTitle = false;

  // Контакты (телефоны/email/сайт)
  bool _contactsLoading = true;
  List<ContactItem> _contacts = [];
  String? _contactsError;

  // Сотрудники
  bool _staffInitialLoading = true;
  List<StaffMemberItem> _staffList = [];
  bool _staffFromCacheOnly = false;
  String? _staffError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadEverything();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 10;
    if (shouldShow != _showHeaderTitle) {
      setState(() => _showHeaderTitle = shouldShow);
    }
  }

  Future<void> _loadEverything() async {
    await Future.wait([_loadContacts(), _loadStaff()]);
  }

  Future<void> _loadContacts() async {
    try {
      final list = await _apiClient.fetchContacts();
      if (!mounted) return;
      setState(() {
        _contacts = list;
        _contactsLoading = false;
        _contactsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contactsLoading = false;
        _contactsError = e.toString();
      });
    }
  }

  Future<void> _loadStaff() async {
    final cached = await GuestStaffCache.read();
    if (!mounted) return;
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _staffList = cached;
        _staffInitialLoading = false;
        _staffFromCacheOnly = false;
        _staffError = null;
      });
    }
    try {
      final fresh = await _apiClient.fetchStaff();
      await GuestStaffCache.save(fresh);
      if (!mounted) return;
      setState(() {
        _staffList = fresh;
        _staffInitialLoading = false;
        _staffFromCacheOnly = false;
        _staffError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _staffInitialLoading = false;
        if (_staffList.isEmpty) {
          _staffError = e.toString();
          _staffFromCacheOnly = false;
        } else {
          _staffError = null;
          _staffFromCacheOnly = true;
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadEverything();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ────────── helpers ──────────
  IconData _iconForType(String type) {
    switch (type) {
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'website':
        return Icons.language;
      case 'address':
        return Icons.location_on;
      default:
        return Icons.info_outline;
    }
  }

  Color? _parseColorHex(String value) {
    final hex = value.trim();
    if (hex.isEmpty) return null;
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    if (cleaned.length != 6) return null;
    try {
      return Color(int.parse('0xFF$cleaned'));
    } catch (_) {
      return null;
    }
  }

  String _toAbsoluteUrl(String value) {
    if (value.isEmpty) return value;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final rawBase = _apiClient.baseUrl;
    final trimmedBase = rawBase.endsWith('/')
        ? rawBase.substring(0, rawBase.length - 1)
        : rawBase;
    String origin = trimmedBase;
    try {
      final uri = Uri.parse(trimmedBase);
      if (uri.hasScheme && uri.host.isNotEmpty) {
        origin = uri.hasPort
            ? '${uri.scheme}://${uri.host}:${uri.port}'
            : '${uri.scheme}://${uri.host}';
      }
    } catch (_) {}
    if (value.startsWith('/api/')) return '$origin$value';
    if (value.startsWith('/')) return '$origin/api/public$value';
    return '$origin/api/public/$value';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: false,
              snap: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 74,
              flexibleSpace: _FrostedContactsHeader(showCenterTitle: _showHeaderTitle),
            ),
          ];
        },
        body: HapticRefreshIndicator(
          color: const Color(0xFF4A90E2),
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildStaffSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ────────── главная информационная карточка ──────────
  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'ЦЕНТР КАРЬЕРЫ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Сибирский государственный университет науки и технологий имени академика М.Ф. Решетнёва, аэрокосмический колледж',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),

          // ── Динамические контакты с сервера ──
          if (_contactsLoading && _contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            )
          else if (_contactsError != null && _contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Не удалось загрузить контакты. Потяните вниз, чтобы обновить.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            )
          else if (_contacts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Контакты пока не настроены в админке.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              )
            else
              Wrap(
                spacing: 18,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _contacts
                    .map((c) => _buildContactItem(
                  _iconForType(c.type),
                  c.value,
                  const Color(0xFF4A90E2),
                ))
                    .toList(growable: false),
              ),

          const SizedBox(height: 24),
          // Иконки внизу — общая инфа (часы / студенты / поддержка)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _InfoStat(icon: Icons.access_time, label: '08:00-17:00'),
              _InfoStat(icon: Icons.people, label: '500+ студентов'),
              _InfoStat(icon: Icons.chat_bubble_outline, label: 'Онлайн поддержка'),
            ],
          ),
        ],
      ),
    );
  }

  // ────────── сотрудники ──────────
  Widget _buildStaffSection() {
    if (_staffInitialLoading && _staffList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_staffError != null && _staffList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Ошибка загрузки сотрудников: $_staffError'),
      );
    }
    if (_staffList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Список сотрудников пока пуст. Подключитесь к интернету один раз, чтобы подтянуть данные.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_staffFromCacheOnly)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, size: 20, color: Colors.amber.shade900),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Нет сети — показаны сохранённые карточки. Фото подгрузятся при следующем подключении.',
                        style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ...List.generate(_staffList.length, (index) {
          final staff = _staffList[index];
          final customColor = _parseColorHex(staff.colorHex);
          final gradientColors = customColor != null
              ? [customColor, customColor.withOpacity(0.84)]
              : [const Color(0xFF4A90E2), const Color(0xFF64B5F6)];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildStaffCard(
              name: staff.fullName,
              position: staff.positionTitle,
              email: staff.email,
              phone: staff.phone,
              hours: staff.officeHours,
              photoUrl: staff.photoUrl,
              gradientColors: gradientColors,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStaffCard({
    required String name,
    required String position,
    required String email,
    required String phone,
    required String hours,
    required String photoUrl,
    required List<Color> gradientColors,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(child: _buildStaffPhoto(photoUrl)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  position,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: gradientColors[0]),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse('mailto:$email');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email, size: 16, color: gradientColors[0]),
                        const SizedBox(width: 8),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            color: gradientColors[0],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
                      final uri = Uri.parse('tel:$cleanPhone');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, size: 16, color: gradientColors[0]),
                        const SizedBox(width: 8),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: gradientColors[0],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (hours.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    hours,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffPhoto(String photoUrl) {
    final fallback = Image.asset(
      'assets/images/application_logo/icon42.png',
      fit: BoxFit.cover,
    );
    if (photoUrl.trim().isEmpty) return fallback;
    final absolute = _toAbsoluteUrl(photoUrl.trim());
    return Image.network(
      absolute,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _buildContactItem(IconData icon, String text, Color color) {
    return GestureDetector(
      onTap: () async {
        Uri? uri;
        if (icon == Icons.phone) {
          final cleanPhone = text.replaceAll(RegExp(r'[^\d+]'), '');
          uri = Uri.parse('tel:$cleanPhone');
        } else if (icon == Icons.email) {
          uri = Uri.parse('mailto:$text');
        } else if (icon == Icons.language) {
          final url = text.contains('://') ? text : 'https://$text';
          uri = Uri.parse(url);
        }
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

// Маленький виджет нижнего ряда инфо-плашек
class _InfoStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.black87),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Frosted-шапка для контактов: при скролле появляется матовый фон + «Контакты»
// ─────────────────────────────────────────────────────────────────────────────
class _FrostedContactsHeader extends StatelessWidget {
  final bool showCenterTitle;
  const _FrostedContactsHeader({required this.showCenterTitle});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: showCenterTitle ? 1 : 0,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: Colors.white.withOpacity(0.72)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: showCenterTitle ? 0 : 1,
                  child: const CenteredAppBarTitle(),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.center,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: showCenterTitle ? 1 : 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    offset: showCenterTitle ? Offset.zero : const Offset(0, -0.15),
                    child: const Text(
                      'Контакты',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
