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
};

const List<String> weekDayTitles = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
];

/// Группа ИСК-3-22 — по расписанию 1 семестра 2025–2026 (фото).
List<ScheduleLesson> _isk322Lessons() => const [
  ScheduleLesson(
    dayOfWeek: 1,
    lessonNumber: 3,
    subject: 'Разговоры о важном',
    teacher: 'Вахитов Р.Г.',
    room: 'ауд. 13.20',
  ),
  ScheduleLesson(
    dayOfWeek: 1,
    lessonNumber: 4,
    subject: 'Инжиниринг и техническая поддержка сопровождения ИС',
    teacher: 'Торосян С.Т.',
    room: 'ауд. 406',
  ),
  ScheduleLesson(
    dayOfWeek: 1,
    lessonNumber: 5,
    subject: 'Интеллектуальные системы и технологии',
    teacher: 'Катаева Е.М.',
    room: 'ауд. 504',
  ),
  ScheduleLesson(
    dayOfWeek: 2,
    lessonNumber: 2,
    subject: 'Управление базами данных и автоматизация',
    teacher: 'Вахитов Р.Г.',
    room: 'ауд. 410',
  ),
  ScheduleLesson(
    dayOfWeek: 2,
    lessonNumber: 3,
    subject: 'Психология общения',
    teacher: 'Чепенко С.А.',
    room: 'ауд. 207',
  ),
  ScheduleLesson(
    dayOfWeek: 2,
    lessonNumber: 4,
    subject: 'Тестирование информационных систем',
    teacher: 'Мустыгина Е.С.',
    room: 'ауд. 301',
  ),
  ScheduleLesson(
    dayOfWeek: 3,
    lessonNumber: 3,
    subject: 'Менеджмент в профессиональной деятельности',
    teacher: 'Жуковская Ю.В.',
    room: 'ауд. 504',
  ),
  ScheduleLesson(
    dayOfWeek: 3,
    lessonNumber: 5,
    subject: 'Физическая культура',
    teacher: 'Бахирева Н.А.',
    room: 'спортзал',
  ),
  ScheduleLesson(
    dayOfWeek: 4,
    lessonNumber: 2,
    subject: 'Иностранный язык в профессиональной деятельности',
    teacher: 'Горбачева А.К.',
    room: 'ауд. Л 609',
  ),
  ScheduleLesson(
    dayOfWeek: 4,
    lessonNumber: 4,
    subject: 'Деловое общение в профессиональной деятельности',
    teacher: 'Букалина Д.А.',
    room: 'ауд. 201',
  ),
  ScheduleLesson(
    dayOfWeek: 5,
    lessonNumber: 3,
    subject: 'Сертификация информационных систем',
    teacher: 'Мустыгина Е.С.',
    room: 'ауд. 405',
  ),
  ScheduleLesson(
    dayOfWeek: 5,
    lessonNumber: 4,
    subject: 'Интеллектуальные системы и технологии',
    teacher: 'Катаева Е.М.',
    room: 'ауд. 504',
  ),
  ScheduleLesson(
    dayOfWeek: 6,
    lessonNumber: 2,
    subject: 'Тестирование информационных систем',
    teacher: 'Мустыгина Е.С.',
    room: 'ауд. 301',
  ),
];

List<ScheduleLesson> _isp22Lessons() => const [
  ScheduleLesson(
    dayOfWeek: 1,
    lessonNumber: 1,
    subject: 'Архитектура аппаратных средств',
    teacher: 'Мамыкин С.Е.',
    room: 'ауд. 509',
  ),
  ScheduleLesson(
    dayOfWeek: 1,
    lessonNumber: 2,
    subject: 'Основы алгоритмизации и программирования',
    teacher: 'Гвоздиевская О.С.',
    room: 'ауд. 411',
  ),
  ScheduleLesson(
    dayOfWeek: 1,
    lessonNumber: 3,
    subject: 'Информационные системы и программирование',
    teacher: 'Мустыгина Е.С.',
    room: 'ауд. 410',
  ),
  ScheduleLesson(
    dayOfWeek: 3,
    lessonNumber: 2,
    subject: 'Базы данных',
    teacher: 'Вахитов Р.Г.',
    room: 'ауд. 410',
  ),
  ScheduleLesson(
    dayOfWeek: 4,
    lessonNumber: 4,
    subject: 'Физическая культура',
    teacher: 'Бахирева Н.А.',
    room: 'спортзал',
  ),
  ScheduleLesson(
    dayOfWeek: 5,
    lessonNumber: 3,
    subject: 'Иностранный язык в профессиональной деятельности',
    teacher: 'Горбачева А.К.',
    room: 'ауд. Л 609',
  ),
];

List<StudyGroupSchedule> studentGroupSchedules = [
  StudyGroupSchedule(
    name: 'ИСК-3-22',
    specialtyCode: 'ИСК',
    course: 3,
    curatorName: 'Вахитов Р.Г.',
    lessons: _isk322Lessons(),
  ),
  StudyGroupSchedule(
    name: 'ИСП-2-22',
    specialtyCode: 'ИСП',
    course: 2,
    curatorName: 'Мустыгина Е.С.',
    lessons: _isp22Lessons(),
  ),
  StudyGroupSchedule(
    name: 'ИСК-2-22',
    specialtyCode: 'ИСК',
    course: 2,
    curatorName: 'Катаева Е.М.',
    lessons: _isp22Lessons(),
  ),
  StudyGroupSchedule(
    name: 'ТОАД-1-23',
    specialtyCode: 'ТОАД',
    course: 1,
    curatorName: 'Торосян С.Т.',
    lessons: _isp22Lessons(),
  ),
  StudyGroupSchedule(
    name: 'ССА-2-22',
    specialtyCode: 'ССА',
    course: 2,
    curatorName: 'Жуковская Ю.В.',
    lessons: _isp22Lessons(),
  ),
];

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

List<String> get studentSpecialtyCodes =>
    studentGroupSchedules.map((g) => g.specialtyCode).toSet().toList()..sort();

List<int> get studentCourses =>
    studentGroupSchedules.map((g) => g.course).toSet().toList()..sort();
