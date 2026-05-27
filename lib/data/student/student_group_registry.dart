/// Реестр учебных групп колледжа (2 семестр 2025–2026).
class GroupMeta {
  const GroupMeta({
    required this.name,
    required this.departmentCode,
    required this.course,
    required this.curatorName,
  });

  final String name;
  /// Код отделения: 1, 2, 4, 5, 6, 7, 8 (как в структуре колледжа).
  final String departmentCode;
  final int course;
  final String curatorName;

  String get specialtyCode {
    final first = name.split('-').first;
    return first.replaceAll(RegExp(r'\d+$'), '');
  }
}

/// Порядок и привязка групп — по отделениям колледжа (заведующие на скрине админки).
const List<GroupMeta> allCollegeGroups = [
  // ── Отделение №1 (Курдойк Е.Д.) — ИСП и ИСК ──
  GroupMeta(name: 'ПК-10-25', departmentCode: '1', course: 1, curatorName: 'Селюн Е.В.'),
  GroupMeta(name: 'ИТ-17-25', departmentCode: '1', course: 1, curatorName: 'Фукс М.С.'),
  GroupMeta(name: 'БИАС-14-25', departmentCode: '1', course: 1, curatorName: 'Андриевская Н.М.'),
  GroupMeta(name: 'ИСК1-22', departmentCode: '1', course: 4, curatorName: 'Вахитов Р.Г.'),
  GroupMeta(name: 'ИСК3-22', departmentCode: '1', course: 4, curatorName: 'Катаева Е.М.'),

  // ── Отделение №2 (Малиновская Е.А.) — электротехника, экономика ──
  GroupMeta(name: 'ЭЛ-54-25', departmentCode: '2', course: 1, curatorName: 'Бочарова О.В.'),
  GroupMeta(name: 'ЭЛ-55-25', departmentCode: '2', course: 1, curatorName: 'Балсуновский П.А.'),
  GroupMeta(name: 'ЭЛ-56-25', departmentCode: '2', course: 1, curatorName: 'Жуковская Ю.В.'),
  GroupMeta(name: 'ЭЛ-51-24', departmentCode: '2', course: 2, curatorName: 'Малиновская Е.А.'),
  GroupMeta(name: 'ЭЛ-52-24', departmentCode: '2', course: 2, curatorName: 'Харламова Н.А.'),
  GroupMeta(name: 'ЭЛ-53-24', departmentCode: '2', course: 2, curatorName: 'Малиновская Е.А.'),
  GroupMeta(name: 'П-7-25', departmentCode: '2', course: 1, curatorName: 'Гвоздиевская О.С.'),
  GroupMeta(name: 'П-8-25', departmentCode: '2', course: 1, curatorName: 'Жданова О.И.'),
  GroupMeta(name: 'П-9-25', departmentCode: '2', course: 1, curatorName: 'Петрова А.А.'),

  // ── Отделение №4 (Бабенко М.Н.) — информационная безопасность ──
  GroupMeta(name: 'ИТС-18-25', departmentCode: '4', course: 1, curatorName: 'Бабенко М.Н.'),
  GroupMeta(name: 'БИАСС-15-25', departmentCode: '4', course: 1, curatorName: 'Притсепа'),

  // ── Отделение №5 (Кольга Е.В.) — мехатроника ──
  GroupMeta(name: 'МР-11-25', departmentCode: '5', course: 1, curatorName: 'Спириьянова А.В.'),
  GroupMeta(name: 'МР-12-25', departmentCode: '5', course: 1, curatorName: 'Лисник Т.В.'),
  GroupMeta(name: 'МР-8-24', departmentCode: '5', course: 2, curatorName: 'Боровикова Т.А.'),
  GroupMeta(name: 'МР-9-24', departmentCode: '5', course: 2, curatorName: 'Чепенко С.А.'),
  GroupMeta(name: 'МР-10-24', departmentCode: '5', course: 2, curatorName: 'Калашникова Е.В.'),

  // ── Отделение №6 (Гурьянов А.С.) — комплексная подготовка ──
  GroupMeta(name: 'К-84-24', departmentCode: '6', course: 2, curatorName: 'Карпан В.Н.'),
  GroupMeta(name: 'К-85-24', departmentCode: '6', course: 2, curatorName: 'Карпан В.Н.'),
  GroupMeta(name: 'К-83-23', departmentCode: '6', course: 3, curatorName: 'Гурьянов А.С.'),
  GroupMeta(name: 'С-65-24', departmentCode: '6', course: 2, curatorName: 'Жуковская Ю.В.'),

  // ── Отделение №7 (Моргунова В.В.) — ТОАД ──
  GroupMeta(name: 'ТАД-10-25', departmentCode: '7', course: 1, curatorName: 'Бирюков С.С.'),
  GroupMeta(name: 'ТАД-9-24', departmentCode: '7', course: 2, curatorName: 'Маханькова В.Н.'),
  GroupMeta(name: 'ТАД-5-22', departmentCode: '7', course: 4, curatorName: 'Аверина Т.И.'),
  GroupMeta(name: 'ТАД-6-22', departmentCode: '7', course: 4, curatorName: 'Сыпкова В.Г.'),

  // ── Отделение №8 (Букалина Д.А.) — сварка, машиностроение ──
  GroupMeta(name: 'ТМ-88-24', departmentCode: '8', course: 2, curatorName: 'Пусенкова Д.В.'),
  GroupMeta(name: 'ТМ-89-24', departmentCode: '8', course: 2, curatorName: 'Рядовская О.Д.'),
  GroupMeta(name: 'ТМ-90-24', departmentCode: '8', course: 2, curatorName: 'Козырева С.И.'),
  GroupMeta(name: 'ТМ-91-24', departmentCode: '8', course: 2, curatorName: 'Тахтобина Е.В.'),
  GroupMeta(name: 'ТМ-92-24', departmentCode: '8', course: 2, curatorName: 'Горбачева А.К.'),
  GroupMeta(name: 'ТМ-93-24', departmentCode: '8', course: 2, curatorName: 'Макарова А.С.'),
  GroupMeta(name: 'ТМ-94-24', departmentCode: '8', course: 2, curatorName: 'Рядовская О.Д.'),
  GroupMeta(name: 'ТМС-87-24', departmentCode: '8', course: 2, curatorName: 'Россихина М.И.'),
  GroupMeta(name: 'СЭГ-37-24', departmentCode: '8', course: 2, curatorName: 'Данилова Т.С.'),
  GroupMeta(name: 'СЭГ-38-24', departmentCode: '8', course: 2, curatorName: 'Бирюков С.С.'),
  GroupMeta(name: 'С-64-23', departmentCode: '8', course: 3, curatorName: 'Сыпкова В.Г.'),
];

List<String> groupsForDepartment(String departmentCode) {
  return allCollegeGroups
      .where((g) => g.departmentCode == departmentCode)
      .map((g) => g.name)
      .toList(growable: false);
}

GroupMeta? findGroupMeta(String name) {
  final key = name.trim();
  for (final g in allCollegeGroups) {
    if (g.name.toLowerCase() == key.toLowerCase()) return g;
  }
  return null;
}
