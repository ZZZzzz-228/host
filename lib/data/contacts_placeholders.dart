import 'api/api_client.dart';

/// Заглушки сотрудников, если в API раздел ещё пуст.
class ContactsPlaceholders {
  ContactsPlaceholders._();

  static final administration = <StaffMemberItem>[
    StaffMemberItem(
      id: -1,
      fullName: 'Иванов Иван Иванович',
      positionTitle: 'Директор колледжа',
      email: 'director@college.example',
      phone: '+7 (391) 000-00-01',
      officeHours: 'Пн–Пт, 08:00–17:00',
      photoUrl: '',
      colorHex: '1565C0',
    ),
    StaffMemberItem(
      id: -2,
      fullName: 'Петрова Анна Сергеевна',
      positionTitle: 'Заместитель директора',
      email: 'deputy@college.example',
      phone: '+7 (391) 000-00-02',
      officeHours: 'Пн–Пт, 09:00–16:00',
      photoUrl: '',
      colorHex: '2E7D32',
    ),
    StaffMemberItem(
      id: -3,
      fullName: 'Сидоров Пётр Николаевич',
      positionTitle: 'Секретарь приёмной',
      email: 'office@college.example',
      phone: '+7 (391) 000-00-03',
      officeHours: 'Пн–Пт, 08:00–17:00',
      photoUrl: '',
      colorHex: '6A1B9A',
    ),
  ];

  static final teachers = <StaffMemberItem>[
    StaffMemberItem(
      id: -10,
      fullName: 'Катаева Елена Михайловна',
      positionTitle: 'Преподаватель',
      email: 'kataeva@college.example',
      phone: '+7 (391) 000-10-01',
      officeHours: 'Каб. 401',
      photoUrl: '',
      colorHex: '4A90E2',
    ),
    StaffMemberItem(
      id: -11,
      fullName: 'Мустыгина Елена Сергеевна',
      positionTitle: 'Преподаватель',
      email: 'mustygina@college.example',
      phone: '+7 (391) 000-10-02',
      officeHours: 'Каб. 410',
      photoUrl: '',
      colorHex: 'E65100',
    ),
    StaffMemberItem(
      id: -12,
      fullName: 'Горбачева Анна Константиновна',
      positionTitle: 'Преподаватель',
      email: 'gorbacheva@college.example',
      phone: '+7 (391) 000-10-03',
      officeHours: 'Каб. 207',
      photoUrl: '',
      colorHex: '00838F',
    ),
  ];

  static final curators = <StaffMemberItem>[
    StaffMemberItem(
      id: -20,
      fullName: 'Вахитов Рустам Гаязович',
      positionTitle: 'Куратор группы ИСК-3-22',
      email: 'vakhitov@college.example',
      phone: '+7 (391) 000-20-01',
      officeHours: 'Каб. 406',
      photoUrl: '',
      colorHex: '4A90E2',
    ),
    StaffMemberItem(
      id: -21,
      fullName: 'Мамыкин Сергей Евгеньевич',
      positionTitle: 'Куратор группы ИСП-2-21',
      email: 'mamykin@college.example',
      phone: '+7 (391) 000-20-02',
      officeHours: 'Каб. 509',
      photoUrl: '',
      colorHex: '5C6BC0',
    ),
    StaffMemberItem(
      id: -22,
      fullName: 'Букалина Дарья Александровна',
      positionTitle: 'Куратор группы (уточняется)',
      email: 'bukalina@college.example',
      phone: '+7 (391) 000-20-03',
      officeHours: 'Каб. 201',
      photoUrl: '',
      colorHex: 'AD1457',
    ),
  ];
}
