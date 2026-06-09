import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';
import '../../data/student/student_schedule_data.dart';

/// Расписание одной группы (переход из «Отделения»).
class StudentGroupScheduleScreen extends StatefulWidget {
  const StudentGroupScheduleScreen({
    super.key,
    required this.groupName,
  });

  final String groupName;

  @override
  State<StudentGroupScheduleScreen> createState() => _StudentGroupScheduleScreenState();
}

class _StudentGroupScheduleScreenState extends State<StudentGroupScheduleScreen> {
  _ResolvedGroupSchedule? _group;
  bool _loading = true;
  bool _fromApi = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final remote = await AppSession.apiClient.fetchGroupSchedule(widget.groupName);
    if (!mounted) return;
    setState(() {
      if (remote != null) {
        _group = _ResolvedGroupSchedule.fromApi(remote, fallbackName: widget.groupName);
        _fromApi = true;
      } else {
        final local = findGroupSchedule(widget.groupName);
        _group = local == null ? null : _ResolvedGroupSchedule.fromLocal(local);
        _fromApi = false;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.groupName), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final group = _group;
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.groupName), centerTitle: true),
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${group.course > 0 ? '${group.course} курс · ' : ''}${group.specialtyCode}'.trim(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1565C0),
                      height: 1.45,
                    ),
                  ),
                  if (group.curatorName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Куратор: ${group.curatorName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _fromApi ? 'Источник: сайт' : 'Источник: локальные демо-данные',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (group.lessons.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('Для этой группы пока нет опубликованных пар.'),
                ),
              )
            else
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
      ),
    );
  }

  Widget _lessonCard(_ResolvedLesson lesson) {
    final time = lesson.timeLabel.isNotEmpty
        ? lesson.timeLabel
        : (lessonBellTimes[lesson.lessonNumber] ?? '${lesson.lessonNumber} лента');
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
                  '${lesson.lessonNumber} пара · $time',
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
          if (lesson.meta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              lesson.meta,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResolvedGroupSchedule {
  const _ResolvedGroupSchedule({
    required this.name,
    required this.specialtyCode,
    required this.course,
    required this.curatorName,
    required this.lessons,
  });

  final String name;
  final String specialtyCode;
  final int course;
  final String curatorName;
  final List<_ResolvedLesson> lessons;

  factory _ResolvedGroupSchedule.fromLocal(StudyGroupSchedule group) {
    return _ResolvedGroupSchedule(
      name: group.name,
      specialtyCode: group.specialtyCode,
      course: group.course,
      curatorName: group.curatorName,
      lessons: group.lessons
          .map(
            (lesson) => _ResolvedLesson(
          dayOfWeek: lesson.dayOfWeek,
          lessonNumber: lesson.lessonNumber,
          subject: lesson.subject,
          teacher: lesson.teacher,
          room: lesson.room,
        ),
      )
          .toList(growable: false),
    );
  }

  factory _ResolvedGroupSchedule.fromApi(
      GroupScheduleApiItem group, {
        required String fallbackName,
      }) {
    return _ResolvedGroupSchedule(
      name: group.groupName.isNotEmpty ? group.groupName : fallbackName,
      specialtyCode: group.specialtyCode,
      course: group.course,
      curatorName: group.curatorName,
      lessons: group.lessons
          .map(
            (lesson) => _ResolvedLesson(
          dayOfWeek: lesson.dayOfWeek,
          lessonNumber: lesson.lessonNumber,
          subject: lesson.subject.isNotEmpty
              ? lesson.subject
              : 'Дисциплина не указана',
          teacher: lesson.teacher.isNotEmpty
              ? lesson.teacher
              : 'Преподаватель не указан',
          room: lesson.room.isNotEmpty ? lesson.room : 'Аудитория уточняется',
          timeLabel: lesson.timeLabel,
          meta: _buildMeta(lesson),
        ),
      )
          .toList(growable: false),
    );
  }

  static String _buildMeta(GroupScheduleLessonItem lesson) {
    final parts = <String>[];
    if (lesson.lessonType.isNotEmpty) parts.add(lesson.lessonType);
    if (lesson.weekType.isNotEmpty && lesson.weekType != 'all') {
      parts.add('неделя: ${lesson.weekType}');
    }
    if (lesson.subgroup > 0) parts.add('подгруппа ${lesson.subgroup}');
    if (lesson.note.isNotEmpty) parts.add(lesson.note);
    return parts.join(' · ');
  }
}

class _ResolvedLesson {
  const _ResolvedLesson({
    required this.dayOfWeek,
    required this.lessonNumber,
    required this.subject,
    required this.teacher,
    required this.room,
    this.timeLabel = '',
    this.meta = '',
  });

  final int dayOfWeek;
  final int lessonNumber;
  final String subject;
  final String teacher;
  final String room;
  final String timeLabel;
  final String meta;
}
