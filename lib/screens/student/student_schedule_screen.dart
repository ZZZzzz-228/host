import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';
import '../../data/student/student_schedule_data.dart';
import '../widgets/centered_app_bar_title.dart';
import '../../widgets/haptic_refresh_indicator.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({
    super.key,
    this.initialGroupName,
    this.initialTabIndex = 0,
  });

  /// Группа, которую нужно показать сразу (из «Отделения» и т.п.).
  final String? initialGroupName;

  /// 0 — звонки, 1 — расписание групп.
  final int initialTabIndex;

  @override
  State<StudentScheduleScreen> createState() => StudentScheduleScreenState();
}

class StudentScheduleScreenState extends State<StudentScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int? _filterCourse;
  StudyGroupSchedule? _selectedGroup;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _initDefaultGroup();
  }

  @override
  void didUpdateWidget(StudentScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialGroupName != null &&
        widget.initialGroupName != oldWidget.initialGroupName) {
      selectGroup(widget.initialGroupName!);
      if (widget.initialTabIndex == 1) {
        _tabController.index = 1;
      }
    }
  }

  /// Вызывается с главного экрана при переходе из «Отделения».
  void selectGroup(String groupName) {
    final group = findGroupSchedule(groupName);
    if (group == null) return;
    setState(() {
      _selectedGroup = group;
      _filterCourse = null;
      _tabController.index = 1;
    });
  }

  Future<void> _initDefaultGroup() async {
    StudyGroupSchedule? preferred;

    final fromWidget = widget.initialGroupName?.trim();
    if (fromWidget != null && fromWidget.isNotEmpty) {
      preferred = findGroupSchedule(fromWidget);
    }

    if (preferred == null) {
      try {
        final profile = await AppSession.apiClient.fetchStudentProfile();
        final groupName = profile?.groupTitle.trim() ?? '';
        if (groupName.isNotEmpty) {
          preferred = findGroupSchedule(groupName);
        }
      } catch (_) {}
    }

    preferred ??= findGroupSchedule('ИСК1-22') ?? studentGroupSchedules.first;

    if (!mounted) return;
    setState(() {
      _selectedGroup = preferred;
      _filterCourse = null;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<StudyGroupSchedule> get _groupsForPicker {
    final list = filterGroups(course: _filterCourse);
    final sorted = List<StudyGroupSchedule>.from(list)
      ..sort((a, b) {
        final c = a.course.compareTo(b.course);
        if (c != 0) return c;
        return a.name.compareTo(b.name);
      });
    return sorted;
  }

  Future<void> _onRefresh() async {}

  Future<void> _showGroupPicker() async {
    final groups = _groupsForPicker;
    if (groups.isEmpty) return;

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Выберите группу',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: groups.length,
                    itemBuilder: (_, i) {
                      final g = groups[i];
                      final selected = _selectedGroup?.name == g.name;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: selected
                              ? const Color(0xFF4A90E2)
                              : Colors.grey.shade200,
                          child: Text(
                            '${g.course}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        title: Text(
                          g.name,
                          style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${g.course} курс · ${g.specialtyCode}',
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF4A90E2),
                              )
                            : null,
                        onTap: () => Navigator.pop(ctx, g.name),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedGroup = groups.firstWhere((g) => g.name == picked);
      });
    }
  }

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
    final pickerCount = _groupsForPicker.length;
    final totalCount = studentGroupSchedules.length;

    return HapticRefreshIndicator(
      color: const Color(0xFF4A90E2),
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Всего групп: $totalCount'
              '${_filterCourse != null ? ' · показано: $pickerCount' : ''}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  'Все курсы',
                  selected: _filterCourse == null,
                  onTap: () => setState(() => _filterCourse = null),
                ),
                ...studentCourses.map((c) {
                  final selected = _filterCourse == c;
                  return _buildFilterChip(
                    '$c курс',
                    selected: selected,
                    onTap: () {
                      setState(() {
                        _filterCourse = selected ? null : c;
                        _syncSelectedGroupAfterFilter();
                      });
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            Material(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _loading ? null : _showGroupPicker,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _loading
                            ? const Text('Загрузка…')
                            : Text(
                                group?.name ?? 'Выберите группу',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 28),
                    ],
                  ),
                ),
              ),
            ),
            if (group != null && !_loading) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${group.course} курс · ${group.specialtyCode}\n'
                  'Куратор: ${group.curatorName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                    height: 1.45,
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
            ] else if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  void _syncSelectedGroupAfterFilter() {
    final groups = _groupsForPicker;
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
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  lesson.room,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
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
