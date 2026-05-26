import 'student_schedule_data.dart';
import 'student_teacher_names.dart';

/// Детерминированное «разнообразное» расписание для групп без отдельного пресета.
List<ScheduleLesson> generateScheduleForGroup(String groupName, int course) {
  final hash = groupName.hashCode;
  final subjects = _subjectsForCourse(course);
  final teachers = teacherFullNames.values.toList();
  final rooms = const [
    'ауд. 301',
    'ауд. 405',
    'ауд. 408',
    'ауд. 503',
    'ауд. 504',
    'ауд. 510',
    'ауд. С-5',
    'спортзал',
    'ауд. 214',
    'ауд. 406',
  ];

  final lessons = <ScheduleLesson>[];
  var slot = 0;
  for (var day = 1; day <= 6; day++) {
    final lessonsPerDay = day == 6 ? 3 : 4;
    for (var n = 1; n <= lessonsPerDay; n++) {
      if ((hash + slot) % 5 == 0) {
        slot++;
        continue;
      }
      final si = (hash + slot) % subjects.length;
      final ti = (hash + slot * 3) % teachers.length;
      final ri = (hash + slot * 7) % rooms.length;
      final lessonNum = n.clamp(1, 6);
      lessons.add(
        ScheduleLesson(
          dayOfWeek: day,
          lessonNumber: lessonNum,
          subject: subjects[si],
          teacher: teachers[ti],
          room: rooms[ri],
        ),
      );
      slot++;
    }
  }

  if (lessons.isEmpty) {
    lessons.add(
      ScheduleLesson(
        dayOfWeek: 1,
        lessonNumber: 1,
        subject: 'Разговоры о важном',
        teacher: expandTeacherName('Андриевская Н.М.'),
        room: 'ауд. 303',
      ),
    );
  }
  return lessons;
}

List<String> _subjectsForCourse(int course) {
  switch (course) {
    case 1:
      return const [
        'Математика',
        'Русский язык',
        'Физика',
        'Информатика',
        'История',
        'Иностранный язык',
        'Физическая культура',
        'Обществознание',
        'География',
        'Химия',
      ];
    case 2:
      return const [
        'Инженерная графика',
        'Техническая механика',
        'Иностранный язык в профессиональной деятельности',
        'Физическая культура',
        'Технология машиностроения',
        'Электротехника и электроника',
        'Метрология, стандартизация и сертификация',
        'Информационные технологии в профессиональной деятельности',
      ];
    case 3:
      return const [
        'Компьютерная графика',
        'Основы расчёта и конструирования сварных конструкций',
        'Основы экономики организации',
        'Технология и оборудование сварочных процессов',
        'Организационная структура промышленной организации',
        'Проектирование вооружения',
      ];
    default:
      return const [
        'Профессиональный модуль',
        'Практика',
        'Иностранный язык в профессиональной деятельности',
        'Физическая культура',
        'Менеджмент в профессиональной деятельности',
      ];
  }
}
