/// Занятие в расписании группы.
class GroupLessonEntry {
  const GroupLessonEntry({
    required this.periodLabel,
    required this.room,
    required this.subject,
    required this.teacher,
  });

  final String periodLabel;
  final String room;
  final String subject;
  final String teacher;
}

/// Расписание на один день недели.
class GroupDaySchedule {
  const GroupDaySchedule({
    required this.dayName,
    required this.lessons,
  });

  final String dayName;
  final List<GroupLessonEntry> lessons;
}

class GroupSchedule {
  const GroupSchedule({
    required this.id,
    required this.title,
    required this.courseLabel,
    required this.curatorName,
    required this.weekSchedule,
  });

  final String id;
  final String title;
  final String courseLabel;
  final String curatorName;
  final List<GroupDaySchedule> weekSchedule;

  bool get hasLessons =>
      weekSchedule.any((day) => day.lessons.isNotEmpty);
}

/// Справочник расписаний по группам.
class GroupScheduleCatalog {
  GroupScheduleCatalog._();

  static const _isk322Week = <GroupDaySchedule>[
    GroupDaySchedule(
      dayName: 'Понедельник',
      lessons: [
        GroupLessonEntry(
          periodLabel: '1',
          room: '—',
          subject: 'Внеклассное мероприятие «Разговоры о важном»',
          teacher: 'Вахитов Р.Г.',
        ),
        GroupLessonEntry(
          periodLabel: '3',
          room: '401',
          subject: 'Интеллектуальные системы и технологии',
          teacher: 'Катаева Е.М.',
        ),
      ],
    ),
    GroupDaySchedule(
      dayName: 'Вторник',
      lessons: [
        GroupLessonEntry(
          periodLabel: '4',
          room: '406',
          subject: 'Управление и автоматизация баз данных',
          teacher: 'Вахитов Р.Г.',
        ),
        GroupLessonEntry(
          periodLabel: '5',
          room: '402',
          subject: 'Инженерно-техническая поддержка сопровождения ИС',
          teacher: 'Торосян С.Т.',
        ),
      ],
    ),
    GroupDaySchedule(
      dayName: 'Среда',
      lessons: [
        GroupLessonEntry(
          periodLabel: '4',
          room: '410',
          subject: 'Психология общения',
          teacher: 'Чепенко С.А.',
        ),
        GroupLessonEntry(
          periodLabel: '13:20',
          room: '207',
          subject: 'Иностранный язык в профессиональной деятельности',
          teacher: 'Горбачева А.К.',
        ),
      ],
    ),
    GroupDaySchedule(
      dayName: 'Четверг',
      lessons: [
        GroupLessonEntry(
          periodLabel: '5',
          room: 'Л 609',
          subject: 'Тестирование информационных систем',
          teacher: 'Мустыгина Е.С.',
        ),
        GroupLessonEntry(
          periodLabel: '6',
          room: '301',
          subject: 'Менеджмент в профессиональной деятельности',
          teacher: 'Жуковская Ю.В.',
        ),
      ],
    ),
    GroupDaySchedule(
      dayName: 'Пятница',
      lessons: [
        GroupLessonEntry(
          periodLabel: '5',
          room: '201',
          subject: 'Деловое общение в профессиональной деятельности',
          teacher: 'Букалина Д.А.',
        ),
        GroupLessonEntry(
          periodLabel: '6',
          room: '405',
          subject: 'Сертификация информационных систем',
          teacher: 'Мустыгина Е.С.',
        ),
        GroupLessonEntry(
          periodLabel: '6',
          room: '405/С-9',
          subject: 'Сертификация информационных систем (подгруппа)',
          teacher: 'Мустыгина Е.С.',
        ),
      ],
    ),
    GroupDaySchedule(
      dayName: 'Суббота',
      lessons: [
        GroupLessonEntry(
          periodLabel: '7',
          room: 'С/з',
          subject: 'Физическая культура',
          teacher: 'Бахирева Н.А.',
        ),
        GroupLessonEntry(
          periodLabel: '7',
          room: 'Л 610',
          subject: 'Сертификация информационных систем',
          teacher: 'Мустыгина Е.С.',
        ),
      ],
    ),
  ];

  static const _ispWeek = <GroupDaySchedule>[
    GroupDaySchedule(
      dayName: 'Понедельник',
      lessons: [
        GroupLessonEntry(
          periodLabel: '1',
          room: '509',
          subject: 'Архитектура аппаратных средств',
          teacher: 'Мамыкин С.Е.',
        ),
        GroupLessonEntry(
          periodLabel: '2',
          room: '411',
          subject: 'Основы алгоритмизации',
          teacher: 'Гвоздиевская О.С.',
        ),
        GroupLessonEntry(
          periodLabel: '3',
          room: '410',
          subject: 'Информационные системы и программирование',
          teacher: 'Мустыгина Е.С.',
        ),
      ],
    ),
  ];

  static final List<GroupSchedule> all = [
    const GroupSchedule(
      id: 'isk-3-22',
      title: 'ИСК-3-22',
      courseLabel: '3 курс',
      curatorName: 'Вахитов Р.Г.',
      weekSchedule: _isk322Week,
    ),
    const GroupSchedule(
      id: 'isk-3-21',
      title: 'ИСК-3-21',
      courseLabel: '3 курс',
      curatorName: 'Катаева Е.М.',
      weekSchedule: [],
    ),
    const GroupSchedule(
      id: 'isk-2-22',
      title: 'ИСК-2-22',
      courseLabel: '2 курс',
      curatorName: 'Торосян С.Т.',
      weekSchedule: [],
    ),
    const GroupSchedule(
      id: 'isp-2-21',
      title: 'ИСП-2-21',
      courseLabel: '2 курс',
      curatorName: 'Мамыкин С.Е.',
      weekSchedule: _ispWeek,
    ),
    const GroupSchedule(
      id: 'isp-3-22',
      title: 'ИСП-3-22',
      courseLabel: '3 курс',
      curatorName: 'Гвоздиевская О.С.',
      weekSchedule: [],
    ),
    const GroupSchedule(
      id: 'toad-3-22',
      title: 'ТОАД-3-22',
      courseLabel: '3 курс',
      curatorName: 'Смирнов А.В.',
      weekSchedule: [],
    ),
    const GroupSchedule(
      id: 'ssa-2-21',
      title: 'ССА-2-21',
      courseLabel: '2 курс',
      curatorName: 'Петрова Н.И.',
      weekSchedule: [],
    ),
    const GroupSchedule(
      id: 'ibts-3-22',
      title: 'ИБТС-3-22',
      courseLabel: '3 курс',
      curatorName: 'Сидоров К.Л.',
      weekSchedule: [],
    ),
    const GroupSchedule(
      id: 'mmr-2-22',
      title: 'ММР-2-22',
      courseLabel: '2 курс',
      curatorName: 'Козлова М.П.',
      weekSchedule: [],
    ),
    const GroupSchedule(
      id: 'seg-3-21',
      title: 'СЭГ-3-21',
      courseLabel: '3 курс',
      curatorName: 'Новиков Д.С.',
      weekSchedule: [],
    ),
    const GroupSchedule(
      id: 'ebu-2-22',
      title: 'ЭБУ-2-22',
      courseLabel: '2 курс',
      curatorName: 'Фёдорова Е.А.',
      weekSchedule: [],
    ),
  ];

  static GroupSchedule byId(String id) =>
      all.firstWhere((g) => g.id == id, orElse: () => all.first);

  static String periodTime(String periodLabel, {bool saturday = false}) {
    if (periodLabel == '13:20') return '13:20–14:05';
    switch (periodLabel) {
      case '1':
        return saturday ? '08:30–10:05' : '08:30–10:05';
      case '2':
        return saturday ? '10:15–11:50' : '10:15–11:50';
      case '3':
        return saturday ? '12:00–13:35' : '12:30–14:05';
      case '4':
        return saturday ? '13:45–15:20' : '14:15–15:50';
      case '5':
        return '16:00–17:25';
      case '6':
        return '17:55–19:20';
      case '7':
        return '19:30–21:00';
      default:
        return periodLabel.contains(':') ? periodLabel : '—';
    }
  }
}
