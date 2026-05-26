import 'package:flutter/material.dart';

import '../../data/student/student_schedule_data.dart';

/// Расписание одной группы (переход из «Отделения»).
class StudentGroupScheduleScreen extends StatelessWidget {
  const StudentGroupScheduleScreen({
    super.key,
    required this.groupName,
  });

  final String groupName;

  @override
  Widget build(BuildContext context) {
    final group = findGroupSchedule(groupName);
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: Text(groupName), centerTitle: true),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Расписание для этой группы пока не добавлено.'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                ...dayLessons.map(_lessonCard),
                const SizedBox(height: 18),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _lessonCard(ScheduleLesson lesson) {
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
