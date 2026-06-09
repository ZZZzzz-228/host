import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';
import '../../data/student/student_college_data.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import 'student_group_schedule_screen.dart';
import 'student_main_scope.dart';

class StudentDepartmentsScreen extends StatefulWidget {
  const StudentDepartmentsScreen({super.key});

  @override
  State<StudentDepartmentsScreen> createState() => _StudentDepartmentsScreenState();
}

class _StudentDepartmentsScreenState extends State<StudentDepartmentsScreen> {
  final ApiClient _api = AppSession.apiClient;
  List<_DepartmentView> _departments = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final remote = await _api.fetchCollegeDepartments();
    if (!mounted) return;
    setState(() {
      _departments = remote.isNotEmpty
          ? remote.map(_DepartmentView.fromApi).toList(growable: false)
          : studentCollegeDepartments
          .map(_DepartmentView.fromLocal)
          .toList(growable: false);
      _loading = false;
    });
  }

  void _openGroupSchedule(BuildContext context, String groupName) {
    final scope = StudentMainScope.maybeOf(context);
    if (scope != null) {
      Navigator.pop(context);
      scope.openGroupSchedule(groupName);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentGroupScheduleScreen(groupName: groupName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отделения'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : HapticRefreshIndicator(
        color: const Color(0xFF4A90E2),
        onRefresh: _loadDepartments,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _departments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final d = _departments[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  initiallyExpanded: index == 0,
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Text(
                    d.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '${d.groups.length} ${_groupsLabel(d.groups.length)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.person,
                          size: 20,
                          color: Color(0xFF4A90E2),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${d.headPosition}: ${d.headName}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (d.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        d.description,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                    if (d.groups.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Учебные группы',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...d.groups.map(
                            (group) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () => _openGroupSchedule(
                                context,
                                group.name,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month,
                                      size: 20,
                                      color: Color(0xFF1565C0),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            group.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1565C0),
                                            ),
                                          ),
                                          if (group.subtitle.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              group.subtitle,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Нажмите на группу — откроется подробное расписание',
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _groupsLabel(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'группа';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'группы';
    }
    return 'групп';
  }
}

class _DepartmentView {
  const _DepartmentView({
    required this.code,
    required this.title,
    required this.headName,
    required this.headPosition,
    required this.description,
    required this.groups,
  });

  final String code;
  final String title;
  final String headName;
  final String headPosition;
  final String description;
  final List<_GroupView> groups;

  factory _DepartmentView.fromLocal(CollegeDepartment d) {
    return _DepartmentView(
      code: d.code,
      title: d.title,
      headName: d.headName,
      headPosition: d.headPosition,
      description: d.description,
      groups: d.groups.map((name) => _GroupView(name: name)).toList(growable: false),
    );
  }

  factory _DepartmentView.fromApi(CollegeDepartmentApiItem d) {
    return _DepartmentView(
      code: d.code,
      title: d.title.isNotEmpty ? d.title : 'Отделение №${d.code}',
      headName: d.headName,
      headPosition: d.headPosition.isNotEmpty
          ? d.headPosition
          : 'Заведующий отделением',
      description: d.description,
      groups: d.groups.map(_GroupView.fromApi).toList(growable: false),
    );
  }
}

class _GroupView {
  const _GroupView({
    required this.name,
    this.course = 0,
    this.specialtyCode = '',
    this.studentsCount = 0,
    this.curatorName = '',
  });

  final String name;
  final int course;
  final String specialtyCode;
  final int studentsCount;
  final String curatorName;

  factory _GroupView.fromApi(DepartmentGroupItem g) {
    return _GroupView(
      name: g.name,
      course: g.studyYear,
      specialtyCode: g.specialtyCode,
      studentsCount: g.studentsCount,
      curatorName: g.curatorName,
    );
  }

  String get subtitle {
    final parts = <String>[];
    if (course > 0) parts.add('$course курс');
    if (specialtyCode.isNotEmpty) parts.add(specialtyCode);
    if (studentsCount > 0) parts.add('$studentsCount студ.');
    if (curatorName.isNotEmpty) parts.add(curatorName);
    return parts.join(' · ');
  }
}
