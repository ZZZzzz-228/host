import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';
import '../../data/student/student_schedule_data.dart';
import '../widgets/centered_app_bar_title.dart';
import '../../widgets/haptic_refresh_indicator.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int? _filterCourse;
  String? _filterSpecialty;
  StudyGroupSchedule? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initDefaultGroup();
  }

  Future<void> _initDefaultGroup() async {
    StudyGroupSchedule? preferred;
    try {
      final profile = await AppSession.apiClient.fetchStudentProfile();
      final groupName = profile?.groupTitle.trim() ?? '';
      if (groupName.isNotEmpty) {
        preferred = studentGroupSchedules
            .where((g) => g.name.toLowerCase() == groupName.toLowerCase())
            .firstOrNull;
      }
    } catch (_) {}

    final group = preferred ??
        studentGroupSchedules.firstWhere(
          (g) => g.name == 'ИСК-3-22',
          orElse: () => studentGroupSchedules.first,
        );

    if (!mounted) return;
    setState(() {
      _selectedGroup = group;
      _filterCourse = group.course;
      _filterSpecialty = group.specialtyCode;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {}

  List<StudyGroupSchedule> get _filteredGroups =>
      filterGroups(course: _filterCourse, specialtyCode: _filterSpecialty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const CenteredAppBarTitle(),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4A90E2),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4A90E2),
          tabs: const [
            Tab(
              icon: Icon(Icons.access_time),
              text: 'Расписание звонков',
            ),
            Tab(
              icon: Icon(Icons.groups),
              text: 'Расписание групп',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBellSchedule(),
          _buildGroupSchedule(),
        ],
      ),
    );
  }

  Widget _buildBellSchedule() {
    return HapticRefreshIndicator(
      color: const Color(0xFF4A90E2),
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Расписание звонков',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 16),
            _buildScheduleItem('1', '1 Лента', '08:30 - 10:05'),
            _buildScheduleItem('2', '2 Лента', '10:15 - 11:50'),
            _buildScheduleItem('3', '3 Лента', '12:30 - 14:05'),
            _buildScheduleItem('4', '4 Лента', '14:15 - 15:50'),
            _buildScheduleItem('5', '5 Лента', '16:00 - 17:25'),
            _buildScheduleItem('6', '6 Лента', '17:55 - 19:20'),
            const SizedBox(height: 24),
            const Text(
              'Суббота',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 16),
            _buildScheduleItem('1', '1 Лента', '8:30 - 10:05'),
            _buildScheduleItem('2', '2 Лента', '10:15 - 11:50'),
            _buildScheduleItem('3', '3 Лента', '12:00 - 13:35'),
            _buildScheduleItem('4', '4 Лента', '13:45 - 15:20'),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(String number, String title, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF4A90E2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSchedule() {
    final group = _selectedGroup;
    final groups = _filteredGroups;

    return HapticRefreshIndicator(
      color: const Color(0xFF4A90E2),
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: studentCourses.map((c) {
                final selected = _filterCourse == c;
                return _buildFilterChip(
                  '$c курс',
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _filterCourse = selected ? null : c;
                      _syncSelectedGroup();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: studentSpecialtyCodes.map((code) {
                final selected = _filterSpecialty == code;
                return _buildFilterChip(
                  code,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _filterSpecialty = selected ? null : code;
                      _syncSelectedGroup();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: group != null && groups.any((g) => g.name == group.name)
                      ? group.name
                      : (groups.isNotEmpty ? groups.first.name : null),
                  hint: const Text('Выберите группу'),
                  items: groups
                      .map(
                        (g) => DropdownMenuItem(
                          value: g.name,
                          child: Text(g.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: groups.isEmpty
                      ? null
                      : (name) {
                          if (name == null) return;
                          setState(() {
                            _selectedGroup = groups.firstWhere(
                              (g) => g.name == name,
                            );
                          });
                        },
                ),
              ),
            ),
            if (group != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Куратор группы: ${group.curatorName}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(6, (dayIndex) {
                final day = dayIndex + 1;
                final dayLessons = group.lessons
                    .where((l) => l.dayOfWeek == day)
                    .toList()
                  ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
                if (dayLessons.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weekDayTitles[dayIndex],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...dayLessons.map(_buildLessonCard),
                    const SizedBox(height: 18),
                  ],
                );
              }),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  void _syncSelectedGroup() {
    final groups = _filteredGroups;
    if (groups.isEmpty) {
      _selectedGroup = null;
      return;
    }
    if (_selectedGroup == null ||
        !groups.any((g) => g.name == _selectedGroup!.name)) {
      _selectedGroup = groups.first;
    }
  }

  Widget _buildFilterChip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4A90E2) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildLessonCard(ScheduleLesson lesson) {
    final time =
        lessonBellTimes[lesson.lessonNumber] ?? '${lesson.lessonNumber} лента';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${lesson.lessonNumber} лента · $time',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                lesson.room,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lesson.subject,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lesson.teacher,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
