import 'package:flutter/material.dart';
import '../../data/group_schedule_data.dart';
import '../widgets/centered_app_bar_title.dart';
import '../../widgets/haptic_refresh_indicator.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF4A90E2);

  late TabController _tabController;
  String _selectedGroupId = GroupScheduleCatalog.all.first.id;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {}

  GroupSchedule get _selectedSchedule =>
      GroupScheduleCatalog.byId(_selectedGroupId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const CenteredAppBarTitle(),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _accent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _accent,
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
      color: _accent,
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
                color: _accent,
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
                color: _accent,
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
              color: _accent,
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
    final schedule = _selectedSchedule;

    return HapticRefreshIndicator(
      color: _accent,
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите группу',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            _buildGroupDropdown(),
            const SizedBox(height: 16),
            _buildGroupHeader(schedule),
            const SizedBox(height: 16),
            if (!schedule.hasLessons)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Расписание для группы ${schedule.title} появится позже.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              )
            else
              ...schedule.weekSchedule
                  .where((day) => day.lessons.isNotEmpty)
                  .map(_buildDaySection),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGroupId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _accent),
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          items: GroupScheduleCatalog.all
              .map(
                (g) => DropdownMenuItem<String>(
                  value: g.id,
                  child: Text('Гр. ${g.title}  ·  ${g.courseLabel}'),
                ),
              )
              .toList(growable: false),
          onChanged: (id) {
            if (id == null) return;
            setState(() => _selectedGroupId = id);
          },
        ),
      ),
    );
  }

  Widget _buildGroupHeader(GroupSchedule schedule) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Гр. ${schedule.title}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  schedule.courseLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.person_outline, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
                    children: [
                      const TextSpan(
                        text: 'Куратор: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: schedule.curatorName),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(GroupDaySchedule day) {
    final saturday = day.dayName == 'Суббота';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day.dayName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _accent,
            ),
          ),
          const SizedBox(height: 10),
          ...day.lessons.map(
            (lesson) => _buildLessonCard(
              lesson,
              saturday: saturday,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(GroupLessonEntry lesson, {required bool saturday}) {
    final time = GroupScheduleCatalog.periodTime(
      lesson.periodLabel,
      saturday: saturday,
    );

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
                  color: _accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${lesson.periodLabel.contains(':') ? '' : '${lesson.periodLabel} пара · '}$time',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'ауд. ${lesson.room}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
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
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
