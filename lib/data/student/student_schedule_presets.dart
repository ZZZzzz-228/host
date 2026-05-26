import 'student_schedule_data.dart';
import 'student_teacher_names.dart';

typedef _L = ({
  int day,
  int lesson,
  String subject,
  String teacher,
  String room,
});

List<ScheduleLesson> _fromPreset(List<_L> rows) {
  return rows
      .map(
        (r) => ScheduleLesson(
          dayOfWeek: r.day,
          lessonNumber: r.lesson,
          subject: r.subject,
          teacher: expandTeacherName(r.teacher),
          room: r.room,
        ),
      )
      .toList(growable: false);
}

/// ИСК1-22 / ИСК3-22 — 4 курс, 2 семестр 2025–2026.
List<ScheduleLesson> presetIsk4Course() => _fromPreset([
  (day: 1, lesson: 3, subject: 'Разговоры о важном', teacher: 'Вахитов Р.Г.', room: 'ауд. 13.20'),
  (day: 1, lesson: 4, subject: 'Инжиниринг и техническая поддержка сопровождения ИС', teacher: 'Торосян С.Т.', room: 'ауд. 406'),
  (day: 1, lesson: 5, subject: 'Интеллектуальные системы и технологии', teacher: 'Катаева Е.М.', room: 'ауд. 504'),
  (day: 2, lesson: 2, subject: 'Управление базами данных и автоматизация', teacher: 'Вахитов Р.Г.', room: 'ауд. 410'),
  (day: 2, lesson: 3, subject: 'Психология общения', teacher: 'Чепенко С.А.', room: 'ауд. 207'),
  (day: 2, lesson: 4, subject: 'Тестирование информационных систем', teacher: 'Мустыгина Е.С.', room: 'ауд. 301'),
  (day: 3, lesson: 3, subject: 'Менеджмент в профессиональной деятельности', teacher: 'Жуковская Ю.В.', room: 'ауд. 504'),
  (day: 3, lesson: 5, subject: 'Физическая культура', teacher: 'Бахирева Н.А.', room: 'спортзал'),
  (day: 4, lesson: 2, subject: 'Иностранный язык в профессиональной деятельности', teacher: 'Горбачева А.К.', room: 'ауд. Л 609'),
  (day: 4, lesson: 4, subject: 'Деловое общение в профессиональной деятельности', teacher: 'Букалина Д.А.', room: 'ауд. 201'),
  (day: 5, lesson: 3, subject: 'Сертификация информационных систем', teacher: 'Мустыгина Е.С.', room: 'ауд. 405'),
  (day: 5, lesson: 4, subject: 'Интеллектуальные системы и технологии', teacher: 'Катаева Е.М.', room: 'ауд. 504'),
  (day: 6, lesson: 2, subject: 'Тестирование информационных систем', teacher: 'Мустыгина Е.С.', room: 'ауд. 301'),
]);

List<ScheduleLesson> presetIsk3CourseVariant() {
  final base = presetIsk4Course();
  return [
    ...base,
    const ScheduleLesson(
      dayOfWeek: 6,
      lessonNumber: 3,
      subject: 'Инжиниринг и техническая поддержка сопровождения ИС',
      teacher: 'Торосян Светлана Тиграновна',
      room: 'ауд. 406',
    ),
  ];
}

/// ТАД-5-22 — 4 курс.
List<ScheduleLesson> presetTad522() => _fromPreset([
  (day: 1, lesson: 3, subject: 'Разговоры о важном', teacher: 'Аверина Т.И.', room: 'ауд. 13.20'),
  (day: 1, lesson: 4, subject: 'Организационно-правовое обеспечение профессиональной деятельности', teacher: 'Сподина Ю.В.', room: 'ауд. 302'),
  (day: 1, lesson: 5, subject: 'Организационно-правовое обеспечение профессиональной деятельности', teacher: 'Сподина Ю.В.', room: 'ауд. 302'),
  (day: 1, lesson: 6, subject: 'Организационно-правовое обеспечение профессиональной деятельности', teacher: 'Сподина Ю.В.', room: 'ауд. 302'),
  (day: 2, lesson: 3, subject: 'Иностранный язык в профессиональной деятельности', teacher: 'Федосова Н.Р.', room: 'ауд. 208'),
  (day: 2, lesson: 4, subject: 'Ремонт авиационного двигателя, его компонентов и функциональных систем', teacher: 'Резник М.В.', room: 'ауд. 510'),
  (day: 2, lesson: 5, subject: 'Ремонт авиационного двигателя, его компонентов и функциональных систем', teacher: 'Резник М.В.', room: 'ауд. 510'),
  (day: 2, lesson: 6, subject: 'Ремонт авиационного двигателя, его компонентов и функциональных систем', teacher: 'Резник М.В.', room: 'ауд. 510'),
  (day: 3, lesson: 3, subject: 'Физическая культура', teacher: 'Боровикова Т.А.', room: 'спортзал'),
  (day: 3, lesson: 4, subject: 'Организационно-правовое обеспечение профессиональной деятельности', teacher: 'Сподина Ю.В.', room: 'ауд. 302'),
  (day: 3, lesson: 5, subject: 'Ремонт авиационного двигателя, его компонентов и функциональных систем', teacher: 'Резник М.В.', room: 'ауд. 302'),
  (day: 3, lesson: 6, subject: 'Ремонт авиационного двигателя, его компонентов и функциональных систем', teacher: 'Резник М.В.', room: 'ауд. 302'),
  (day: 4, lesson: 4, subject: 'Ремонт авиационного двигателя, его компонентов и функциональных систем', teacher: 'Резник М.В.', room: 'ауд. 510'),
  (day: 4, lesson: 5, subject: 'Ремонт авиационного двигателя, его компонентов и функциональных систем', teacher: 'Резник М.В.', room: 'ауд. 510'),
  (day: 4, lesson: 6, subject: 'Организационно-правовое обеспечение профессиональной деятельности', teacher: 'Сподина Ю.В.', room: 'ауд. 510'),
  (day: 5, lesson: 3, subject: 'Подготовка авиационного двигателя, его компонентов и функциональных систем к ремонту', teacher: 'Бирюков С.С.', room: 'ауд. 115'),
  (day: 5, lesson: 4, subject: 'Подготовка авиационного двигателя, его компонентов и функциональных систем к ремонту', teacher: 'Бирюков С.С.', room: 'ауд. 115'),
]);

/// ТАД-6-22 — 4 курс.
List<ScheduleLesson> presetTad622() => _fromPreset([
  (day: 1, lesson: 3, subject: 'Разговоры о важном', teacher: 'Сыпкова В.Г.', room: 'ауд. 17.00'),
  (day: 1, lesson: 5, subject: 'Физическая культура', teacher: 'Боровикова Т.А.', room: 'спортзал'),
  (day: 1, lesson: 6, subject: 'Ремонт авиационного двигателя, его компонентов и функциональных систем', teacher: 'Ковель И.П.', room: 'ауд. 315'),
  (day: 1, lesson: 7, subject: 'Ремонт авиационного двигателя, его компонентов и функциональных систем', teacher: 'Ковель И.П.', room: 'ауд. 315'),
  (day: 2, lesson: 4, subject: 'Иностранный язык в профессиональной деятельности', teacher: 'Федосова Н.Р.', room: 'ауд. 208'),
  (day: 2, lesson: 5, subject: 'Организационно-правовое обеспечение профессиональной деятельности', teacher: 'Сподина Ю.В.', room: 'ауд. 211'),
  (day: 2, lesson: 6, subject: 'Организационно-правовое обеспечение профессиональной деятельности', teacher: 'Сподина Ю.В.', room: 'ауд. 211'),
  (day: 2, lesson: 7, subject: 'Ремонт авиационного двигателя, его компонентов и функциональных систем', teacher: 'Сергеев И.Ф.', room: 'ауд. 211'),
  (day: 3, lesson: 5, subject: 'Организационно-правовое обеспечение профессиональной деятельности', teacher: 'Сподина Ю.В.', room: 'ауд. 212'),
  (day: 3, lesson: 6, subject: 'Ремонт авиационного двигателя, его компонентов и функциональных систем', teacher: 'Ковель И.П.', room: 'ауд. 212'),
  (day: 3, lesson: 7, subject: 'Ремонт авиационного двигателя, его компонентов и функциональных систем', teacher: 'Ковель И.П.', room: 'ауд. 212'),
  (day: 4, lesson: 4, subject: 'Организационно-правовое обеспечение профессиональной деятельности', teacher: 'Сподина Ю.В.', room: 'ауд. 505'),
  (day: 4, lesson: 5, subject: 'Организационно-правовое обеспечение профессиональной деятельности', teacher: 'Сподина Ю.В.', room: 'ауд. 505'),
  (day: 4, lesson: 6, subject: 'Ремонт авиационного двигателя, его компонентов и функциональных систем', teacher: 'Сергеев И.Ф.', room: 'ауд. 505'),
  (day: 4, lesson: 7, subject: 'Ремонт авиационного двигателя, его компонентов и функциональных систем', teacher: 'Сергеев И.Ф.', room: 'ауд. 505'),
  (day: 5, lesson: 1, subject: 'Подготовка авиационного двигателя, его компонентов и функциональных систем к ремонту', teacher: 'Бирюков С.С.', room: 'ауд. 115'),
  (day: 5, lesson: 2, subject: 'Подготовка авиационного двигателя, его компонентов и функциональных систем к ремонту', teacher: 'Бирюков С.С.', room: 'ауд. 115'),
]);

/// ПК-10-25 — 1 курс (фрагмент недели).
List<ScheduleLesson> presetPk1025() => _fromPreset([
  (day: 1, lesson: 1, subject: 'Разговоры о важном', teacher: 'Селюн Е.В.', room: 'ауд. 08.00'),
  (day: 1, lesson: 1, subject: 'Математика', teacher: 'Дубиненко Е.П.', room: 'ауд. С-5'),
  (day: 1, lesson: 2, subject: 'Математика', teacher: 'Дубиненко Е.П.', room: 'ауд. С-5'),
  (day: 1, lesson: 3, subject: 'Физика', teacher: 'Табаченко И.К.', room: 'ауд. 408'),
  (day: 2, lesson: 1, subject: 'История', teacher: 'Андриевская Н.М.', room: 'ауд. 303'),
  (day: 2, lesson: 2, subject: 'Физика', teacher: 'Табаченко И.К.', room: 'ауд. 408'),
  (day: 3, lesson: 1, subject: 'Иностранный язык', teacher: 'Горбачева А.К.', room: 'ауд. Л 609'),
  (day: 3, lesson: 2, subject: 'Литература', teacher: 'Сыпкова В.Г.', room: 'ауд. 203'),
  (day: 3, lesson: 3, subject: 'Русский язык', teacher: 'Сыпкова В.Г.', room: 'ауд. 203'),
  (day: 4, lesson: 1, subject: 'Информатика', teacher: 'Петрова А.А.', room: 'ауд. С-6'),
  (day: 4, lesson: 2, subject: 'Физическая культура', teacher: 'Окружная Н.В.', room: 'спортзал'),
  (day: 5, lesson: 1, subject: 'Информатика', teacher: 'Петрова А.А.', room: 'ауд. С-6'),
  (day: 6, lesson: 1, subject: 'Математика', teacher: 'Дубиненко Е.П.', room: 'ауд. 212'),
  (day: 6, lesson: 2, subject: 'Математика', teacher: 'Дубиненко Е.П.', room: 'ауд. 212'),
]);

/// К-84-24 — 2 курс.
List<ScheduleLesson> presetK8424() => _fromPreset([
  (day: 1, lesson: 1, subject: 'Разговоры о важном', teacher: 'Карпан В.Н.', room: 'ауд. 08.00'),
  (day: 1, lesson: 1, subject: 'Инженерная графика', teacher: 'Лисник Т.В., Федоренко Т.В.', room: 'ауд. 401/205'),
  (day: 1, lesson: 2, subject: 'Основы материаловедения и технологии обработки материалов', teacher: 'Рядовская О.Д.', room: 'ауд. 204'),
  (day: 2, lesson: 1, subject: 'Общая технология машиностроения', teacher: 'Шувалова М.А.', room: 'ауд. 508'),
  (day: 2, lesson: 2, subject: 'Техническая механика', teacher: 'Упорова А.Д.', room: 'ауд. 126'),
  (day: 3, lesson: 1, subject: 'Физическая культура', teacher: 'Окружная Н.В.', room: 'спортзал'),
  (day: 3, lesson: 2, subject: 'Конструирование специального оборудования и систем', teacher: 'Гурьянов А.С.', room: 'ауд. 126'),
  (day: 4, lesson: 1, subject: 'Термическая обработка материалов и упрочняющие технологии', teacher: 'Малиновская Е.А.', room: 'ауд. 207'),
  (day: 5, lesson: 1, subject: 'Подготовка производства специального оборудования и систем', teacher: 'Жуковская Ю.В.', room: 'ауд. 504'),
  (day: 6, lesson: 1, subject: 'Основы материаловедения и технологии обработки материалов', teacher: 'Рядовская О.Д.', room: 'ауд. 204'),
  (day: 6, lesson: 2, subject: 'Иностранный язык', teacher: 'Никулин А.С.', room: 'ауд. Л 415'),
]);

List<ScheduleLesson>? presetForGroup(String groupName) {
  switch (groupName) {
    case 'ИСК1-22':
      return presetIsk4Course();
    case 'ИСК3-22':
      return presetIsk3CourseVariant();
    case 'ТАД-5-22':
      return presetTad522();
    case 'ТАД-6-22':
      return presetTad622();
    case 'ПК-10-25':
      return presetPk1025();
    case 'К-84-24':
      return presetK8424();
    default:
      return null;
  }
}
