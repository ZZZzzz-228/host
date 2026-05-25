class CollegeDepartment {
  const CollegeDepartment({
    required this.code,
    required this.title,
    required this.headName,
    required this.headPosition,
    this.description = '',
  });

  final String code;
  final String title;
  final String headName;
  final String headPosition;
  final String description;
}

class ExtraClub {
  const ExtraClub({
    required this.title,
    required this.leader,
    required this.schedule,
    required this.room,
    this.description = '',
  });

  final String title;
  final String leader;
  final String schedule;
  final String room;
  final String description;
}

const String studentCollegeAboutTitle =
    'Аэрокосмический колледж СибГУ им. академика М.Ф. Решетнёва';

const String studentCollegeAboutText =
    'Сибирский государственный университет науки и технологий имени академика М.Ф. Решетнёва, '
    'аэрокосмический колледж — учебное заведение среднего профессионального образования, '
    'готовящее специалистов для авиационной, IT и инженерной отраслей.';

const List<CollegeDepartment> studentCollegeDepartments = [
  CollegeDepartment(
    code: 'ИСП',
    title: 'Отделение информационных систем и программирования',
    headName: 'Мустыгина Е.С.',
    headPosition: 'Заведующий отделением',
    description: 'Подготовка программистов, разработчиков и администраторов ИС.',
  ),
  CollegeDepartment(
    code: 'ИСК',
    title: 'Отделение интеллектуальных систем и компьютерных технологий',
    headName: 'Катаева Е.М.',
    headPosition: 'Заведующий отделением',
    description: 'Интеллектуальные системы, тестирование и сопровождение ПО.',
  ),
  CollegeDepartment(
    code: 'ТОАД',
    title: 'Отделение технического обслуживания авиационных двигателей',
    headName: 'Торосян С.Т.',
    headPosition: 'Заведующий отделением',
    description: 'Специалисты по ТО и ремонту авиационной техники.',
  ),
  CollegeDepartment(
    code: 'ССА',
    title: 'Отделение сервиса и сервисного обслуживания',
    headName: 'Жуковская Ю.В.',
    headPosition: 'Заведующий отделением',
  ),
  CollegeDepartment(
    code: 'ИБТС',
    title: 'Отделение информационной безопасности телекоммуникационных систем',
    headName: 'Чепенко С.А.',
    headPosition: 'Заведующий отделением',
  ),
  CollegeDepartment(
    code: 'ММР',
    title: 'Отделение мехатроники и мобильной робототехники',
    headName: 'Мамыкин С.Е.',
    headPosition: 'Заведующий отделением',
  ),
  CollegeDepartment(
    code: 'СЭГ',
    title: 'Отделение сварочного производства',
    headName: 'Букалина Д.А.',
    headPosition: 'Заведующий отделением',
  ),
  CollegeDepartment(
    code: 'ЭБУ',
    title: 'Отделение экономики и бухгалтерского учёта',
    headName: 'Горбачева А.К.',
    headPosition: 'Заведующий отделением',
  ),
];

const List<ExtraClub> studentExtraClubs = [
  ExtraClub(
    title: 'Клуб «Патриот»',
    leader: 'Вахитов Р.Г.',
    schedule: 'Среда, 15:00',
    room: 'ауд. 13.20',
    description: 'Военно-патриотическое воспитание, подготовка к службе в ВС РФ.',
  ),
  ExtraClub(
    title: 'Киберспорт',
    leader: 'Мамыкин С.Е.',
    schedule: 'Вторник, 16:30',
    room: 'компьютерный класс 509',
    description: 'Турниры и тренировки по киберспортивным дисциплинам.',
  ),
  ExtraClub(
    title: 'Театральная студия',
    leader: 'Бахирева Н.А.',
    schedule: 'Четверг, 14:00',
    room: 'актовый зал',
  ),
  ExtraClub(
    title: 'Робототехника',
    leader: 'Торосян С.Т.',
    schedule: 'Пятница, 15:30',
    room: 'лаборатория 406',
    description: 'Сборка и программирование мобильных роботов.',
  ),
  ExtraClub(
    title: 'Волонтёрский центр',
    leader: 'Жуковская Ю.В.',
    schedule: 'По расписанию мероприятий',
    room: 'каб. 201',
  ),
];
