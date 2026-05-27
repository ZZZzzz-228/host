import 'package:flutter/material.dart';

import '../../data/student/student_college_data.dart';
import '../../widgets/haptic_refresh_indicator.dart';

class StudentClubsScreen extends StatelessWidget {
  const StudentClubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доп. кружки'),
        centerTitle: true,
      ),
      body: HapticRefreshIndicator(
        color: const Color(0xFF4A90E2),
        onRefresh: () async {},
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: studentExtraClubs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final club = studentExtraClubs[index];
            final primary = club.isPrimary;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primary ? const Color(0xFFE3F2FD) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primary
                      ? const Color(0xFF4A90E2)
                      : Colors.grey.shade300,
                  width: primary ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (primary)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Главная организация',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    club.title,
                    style: TextStyle(
                      fontSize: primary ? 17 : 16,
                      fontWeight: FontWeight.bold,
                      color: primary
                          ? const Color(0xFF1565C0)
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _clubRow(
                    Icons.person_outline,
                    'Руководитель: ${club.leader}',
                  ),
                  _clubRow(Icons.schedule, club.schedule),
                  _clubRow(Icons.room, club.room),
                  if (club.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      club.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _clubRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4A90E2)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
