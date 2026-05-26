import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import 'career_ui.dart';
import 'widgets/student_staff_card.dart';

class StudentCareerContactsScreen extends StatefulWidget {
  const StudentCareerContactsScreen({super.key});

  @override
  State<StudentCareerContactsScreen> createState() =>
      _StudentCareerContactsScreenState();
}

class _StudentCareerContactsScreenState extends State<StudentCareerContactsScreen> {
  final ApiClient _api = AppSession.apiClient;

  bool _loading = true;
  String? _error;
  List<CareerContactPerson> _people = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.fetchCareerCenterPeople();
      if (!mounted) return;
      setState(() {
        _people = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _people.isEmpty) {
      return CareerUi.scaffold(title: 'Контакты', body: CareerUi.loading());
    }
    if (_error != null && _people.isEmpty) {
      return CareerUi.scaffold(
        title: 'Контакты',
        body: CareerUi.error('Не удалось загрузить контакты.\nПотяните вниз, чтобы обновить.'),
      );
    }

    return CareerUi.scaffold(
      title: 'Контакты',
      body: HapticRefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Сотрудники Центра карьеры. Список обновляется из админки «Контакты Центр карьеры».',
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.35),
              ),
            ),
            const SizedBox(height: 16),
            if (_people.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: const Text(
                  'Пока никого не добавили. Зайдите в админку → Карьерный центр → «Контакты Центр карьеры» → Добавить.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                ),
              )
            else
              ..._people.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: StudentStaffCard(
                    member: p.toStaffCard(),
                    gradientColors: const [
                      Color(0xFF4A90E2),
                      Color(0xFF64B5F6),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
