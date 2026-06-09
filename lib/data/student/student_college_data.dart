import 'student_group_registry.dart';

class CollegeDepartment {
  const CollegeDepartment({
    required this.code,
    required this.title,
    required this.headName,
    required this.headPosition,
    this.description = '',
    this.groups = const [],
  });

  final String code;
  final String title;
  final String headName;
  final String headPosition;
  final String description;
  final List<String> groups;
}

class ExtraClub {
  const ExtraClub({
    required this.title,
    required this.leader,
    required this.schedule,
    required this.room,
    this.description = '',
    this.isPrimary = false,
  });

  final String title;
  final String leader;
  final String schedule;
  final String room;
  final String description;
  final bool isPrimary;
}

const String studentCollegeAboutTitle =
    'Аэрокосмический колледж СибГУ им. академика М.Ф. Решетнёва';

const String studentCollegeAboutText =
    'Сибирский государственный университет науки и технологий имени академика М.Ф. Решетнёва, '
    'аэрокосмический колледж — учебное заведение среднего профессионального образования, '
    'готовящее специалистов для авиационной, IT и инженерной отраслей.';

/// Отделения в порядке структуры колледжа (по скрину заведующих).
List<CollegeDepartment> get studentCollegeDepartments => [
      CollegeDepartment(
        code: '1',
        title: 'Отделение №1',
        headName: 'Курдояк Елена Дмитриевна',
        headPosition: 'Заведующая отделением',
        description:
            'Информационные системы, программирование, интеллектуальные системы.',
        groups: groupsForDepartment('1'),
      ),
      CollegeDepartment(
        code: '2',
        title: 'Отделение №2',
        headName: 'Малиновская Елена Александровна',
        headPosition: 'Заведующая отделением',
        description: 'Электротехника, электроника, экономика и смежные специальности.',
        groups: groupsForDepartment('2'),
      ),
      CollegeDepartment(
        code: '4',
        title: 'Отделение №4',
        headName: 'Бабенко Максим Николаевич',
        headPosition: 'Заведующий отделением',
        description: 'Информационная безопасность телекоммуникационных систем.',
        groups: groupsForDepartment('4'),
      ),
      CollegeDepartment(
        code: '5',
        title: 'Отделение №5',
        headName: 'Кольга Екатерина Викторовна',
        headPosition: 'Заведующая отделением',
        description: 'Мехатроника и мобильная робототехника.',
        groups: groupsForDepartment('5'),
      ),
      CollegeDepartment(
        code: '6',
        title: 'Отделение №6',
        headName: 'Гурьянов Александр Сергеевич',
        headPosition: 'Заведующий отделением',
        description: 'Комплексная подготовка, специальное оборудование и системы.',
        groups: groupsForDepartment('6'),
      ),
      CollegeDepartment(
        code: '7',
        title: 'Отделение №7',
        headName: 'Моргунова Вита Викторовна',
        headPosition: 'Заведующая отделением',
        description: 'Техническое обслуживание авиационных двигателей.',
        groups: groupsForDepartment('7'),
      ),
      CollegeDepartment(
        code: '8',
        title: 'Отделение №8',
        headName: 'Букалина Дарья Анатольевна',
        headPosition: 'Заведующая отделением',
        description: 'Сварочное производство, технология машиностроения.',
        groups: groupsForDepartment('8'),
      ),
    ];

final List<ExtraClub> studentExtraClubs = [
  ExtraClub(
    title: 'Совет студентов колледжа',
    leader: 'Старцева Анастасия Сергеевна',
    schedule: 'По плану заседаний совета',
    room: 'каб. 201',
    description:
        'Представительство студентов, организация мероприятий и связь с администрацией колледжа.',
    isPrimary: true,
  ),
  ExtraClub(
    title: 'Клуб «Патриот»',
    leader: 'Вахитов Руслан Геннадьевич',
    schedule: 'Среда, 15:00',
    room: 'ауд. 13.20',
    description: 'Военно-патриотическое воспитание, подготовка к службе в ВС РФ.',
  ),
  ExtraClub(
    title: 'Киберспорт',
    leader: 'Мамыкин Сергей Евгеньевич',
    schedule: 'Вторник, 16:30',
    room: 'компьютерный класс 509',
    description: 'Турниры и тренировки по киберспортивным дисциплинам.',
  ),
  ExtraClub(
    title: 'Театральная студия',
    leader: 'Бахирева Наталья Александровна',
    schedule: 'Четверг, 14:00',
    room: 'актовый зал',
  ),
  ExtraClub(
    title: 'Робототехника',
    leader: 'Торосян Светлана Тиграновна',
    schedule: 'Пятница, 15:30',
    room: 'лаборатория 406',
    description: 'Сборка и программирование мобильных роботов.',
  ),
  ExtraClub(
    title: 'Волонтёрский центр',
    leader: 'Жуковская Юлия Владимировна',
    schedule: 'По расписанию мероприятий',
    room: 'каб. 201',
  ),
];
