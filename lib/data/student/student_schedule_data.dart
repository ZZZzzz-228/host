import 'student_group_registry.dart';
import 'student_schedule_generator.dart';
import 'student_schedule_presets.dart';
import 'student_teacher_names.dart';

/// Расписание учебных групп (демо-данные; при появлении API — подменяются в экране).
class ScheduleLesson {
  const ScheduleLesson({
    required this.dayOfWeek,
    required this.lessonNumber,
    required this.subject,
    required this.teacher,
    required this.room,
  });

  /// 1 — понедельник … 6 — суббота
  final int dayOfWeek;
  final int lessonNumber;
  final String subject;
  final String teacher;
  final String room;
}

class StudyGroupSchedule {
  const StudyGroupSchedule({
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
  final List<ScheduleLesson> lessons;
}

const Map<int, String> lessonBellTimes = {
  1: '08:30–10:05',
  2: '10:15–11:50',
  3: '12:30–14:05',
  4: '14:15–15:50',
  5: '16:00–17:25',
  6: '17:55–19:20',
  7: '19:30–21:05',
};

const List<String> weekDayTitles = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
];

List<ScheduleLesson> _lessonsForGroup(GroupMeta meta) {
  final preset = presetForGroup(meta.name);
  if (preset != null) return preset;
  return generateScheduleForGroup(meta.name, meta.course);
}

StudyGroupSchedule _buildSchedule(GroupMeta meta) {
  return StudyGroupSchedule(
    name: meta.name,
    specialtyCode: meta.specialtyCode,
    course: meta.course,
    curatorName: expandTeacherName(meta.curatorName),
    lessons: _lessonsForGroup(meta),
  );
}

final List<StudyGroupSchedule> studentGroupSchedules =
    allCollegeGroups.map(_buildSchedule).toList(growable: false);

List<StudyGroupSchedule> filterGroups({
  int? course,
  String? specialtyCode,
}) {
  return studentGroupSchedules.where((g) {
    if (course != null && g.course != course) return false;
    if (specialtyCode != null &&
        specialtyCode.isNotEmpty &&
        g.specialtyCode != specialtyCode) {
      return false;
    }
    return true;
  }).toList(growable: false);
}

StudyGroupSchedule? findGroupSchedule(String name) {
  final key = name.trim().toLowerCase();
  for (final g in studentGroupSchedules) {
    if (g.name.toLowerCase() == key) return g;
  }
  const aliases = {
    'иск-3-22': 'ИСК1-22',
    'иск-2-22': 'ИСК1-22',
    'исп-2-22': 'ПК-10-25',
    'тоад-1-23': 'ТАД-10-25',
    'сса-2-22': 'С-65-24',
  };
  final alias = aliases[key];
  if (alias != null) {
    for (final g in studentGroupSchedules) {
      if (g.name == alias) return g;
    }
  }
  return null;
}

List<String> get studentSpecialtyCodes =>
    studentGroupSchedules.map((g) => g.specialtyCode).toSet().toList()..sort();

List<int> get studentCourses =>
    studentGroupSchedules.map((g) => g.course).toSet().toList()..sort();
