import 'dart:ui';

import 'package:flutter/material.dart';
import '../../data/api/api_client.dart';
import '../../data/cache/guest_staff_cache.dart';
import '../../data/session/app_session.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import '../widgets/centered_app_bar_title.dart';
import 'widgets/student_staff_card.dart';

/// Контакты студента: администрация и преподаватели.
///
/// ИСПРАВЛЕНО: все сотрудники хранятся с role='career_center',
/// поэтому загружаем всех и делим по ключевым словам в должности.
/// Убраны попытки загрузить несуществующие роли 'administration', 'teachers' и т.д.
class StudentContactsScreen extends StatefulWidget {
  const StudentContactsScreen({super.key});

  @override
  State<StudentContactsScreen> createState() => _StudentContactsScreenState();
}

class _StudentContactsScreenState extends State<StudentContactsScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = AppSession.apiClient;
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  bool _showHeaderTitle = false;

  bool _loading = true;
  List<StaffMemberItem> _administration = [];
  List<StaffMemberItem> _teachers = [];
  String? _error;
  bool _fromCache = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadStaff();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 10;
    if (shouldShow != _showHeaderTitle) {
      setState(() => _showHeaderTitle = shouldShow);
    }
  }

  List<StaffMemberItem> _dedupe(List<StaffMemberItem> source) {
    final seen = <String>{};
    final out = <StaffMemberItem>[];
    for (final s in source) {
      final key = s.email.isNotEmpty
          ? s.email.toLowerCase()
          : s.fullName.toLowerCase();
      if (seen.add(key)) out.add(s);
    }
    return out;
  }

  Future<void> _loadStaff() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Читаем кэш
    final cachedAdmin = await GuestStaffCache.read(scope: 'student_admin');
    final cachedTeachers = await GuestStaffCache.read(scope: 'student_teachers');
    if (!mounted) return;
    if ((cachedAdmin != null && cachedAdmin.isNotEmpty) ||
        (cachedTeachers != null && cachedTeachers.isNotEmpty)) {
      setState(() {
        _administration = cachedAdmin ?? const [];
        _teachers = cachedTeachers ?? const [];
        _loading = false;
      });
    }

    try {
      // ИСПРАВЛЕНО: загружаем всех сотрудников (все имеют role='career_center')
      // и делим по ключевым словам в должности
      final all = await _api.fetchStaff();
      final deduped = _dedupe(all);

      var admin = deduped
          .where((s) => _looksLikeAdministration(s.positionTitle))
          .toList(growable: false);
      var teachers = deduped
          .where((s) => !_looksLikeAdministration(s.positionTitle))
          .toList(growable: false);

      await GuestStaffCache.save(admin, scope: 'student_admin');
      await GuestStaffCache.save(teachers, scope: 'student_teachers');

      if (!mounted) return;
      setState(() {
        _administration = admin;
        _teachers = teachers;
        _loading = false;
        _fromCache = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_administration.isEmpty && _teachers.isEmpty) {
          _error = e.toString();
        } else {
          _fromCache = true;
        }
      });
    }
  }

  /// Определяет, относится ли сотрудник к администрации по ключевым словам в должности
  bool _looksLikeAdministration(String position) {
    final p = position.toLowerCase();
    return p.contains('директор') ||
        p.contains('заместител') ||
        p.contains('заведующ') ||
        p.contains('администрац') ||
        p.contains('приём') ||
        p.contains('диспетчер');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 74,
              flexibleSpace: _FrostedStudentContactsHeader(
                showCenterTitle: _showHeaderTitle,
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF4A90E2),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF4A90E2),
                tabs: const [
                  Tab(text: 'Администрация'),
                  Tab(text: 'Преподаватели'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildStaffTab(_administration),
            _buildStaffTab(_teachers),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffTab(List<StaffMemberItem> list) {
    return HapticRefreshIndicator(
      color: const Color(0xFF4A90E2),
      onRefresh: _loadStaff,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (_fromCache) _offlineBanner(),
          if (_loading && list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && list.isEmpty)
            Text('Ошибка загрузки: $_error')
          else if (list.isEmpty)
              const Text('Список пока пуст.')
            else
              ...list.map(
                    (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: StudentStaffCard(member: m),
                ),
              ),
        ],
      ),
    );
  }

  Widget _offlineBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.wifi_off, size: 20, color: Color(0xFFF57F17)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Нет сети — показаны сохранённые карточки.',
                  style: TextStyle(fontSize: 13, color: Color(0xFFF57F17)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrostedStudentContactsHeader extends StatelessWidget {
  const _FrostedStudentContactsHeader({required this.showCenterTitle});

  final bool showCenterTitle;

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