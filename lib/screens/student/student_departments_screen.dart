import 'package:flutter/material.dart';

import '../../data/student/student_college_data.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import 'student_group_schedule_screen.dart';

class StudentDepartmentsScreen extends StatelessWidget {
  const StudentDepartmentsScreen({super.key});

  void _openGroupSchedule(BuildContext context, String groupName) {
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
      body: HapticRefreshIndicator(
        color: const Color(0xFF4A90E2),
        onRefresh: () async {},
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: studentCollegeDepartments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final d = studentCollegeDepartments[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: index == 0,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Text(
                    d.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Код: ${d.code} · ${d.groups.length} ${_groupsLabel(d.groups.length)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: d.groups.map((groupName) {
                          return ActionChip(
                            label: Text(groupName),
                            backgroundColor: const Color(0xFFE3F2FD),
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1565C0),
                            ),
                            side: const BorderSide(color: Color(0xFF90CAF9)),
                            onPressed: () =>
                                _openGroupSchedule(context, groupName),
                          );
                        }).toList(growable: false),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Нажмите на группу, чтобы открыть расписание',
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
