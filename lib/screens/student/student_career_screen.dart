import 'package:flutter/material.dart';

import '../shared/shared_partners_screen.dart';
import 'student_contacts_screen.dart';
import 'student_events_screen.dart';
import 'student_portfolio_screen.dart';
import 'student_resume_screen.dart';
import 'student_vacancies_screen.dart';
import '../widgets/centered_app_bar_title.dart';

class StudentCareerScreen extends StatelessWidget {
  const StudentCareerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const CenteredAppBarTitle(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _CareerTile(
              title: 'Портфолио',
              icon: Icons.folder_open_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentPortfolioScreen()),
              ),
            ),
            _CareerTile(
              title: 'Вакансии',
              icon: Icons.work_outline,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentVacanciesScreen()),
              ),
            ),
            _CareerTile(
              title: 'Резюме',
              icon: Icons.description_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentResumeScreen()),
              ),
            ),
            _CareerTile(
              title: 'Партнеры',
              icon: Icons.handshake_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SharedPartnersScreen()),
              ),
            ),
            _CareerTile(
              title: 'Контакты',
              icon: Icons.contacts_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentContactsScreen()),
              ),
            ),
            _CareerTile(
              title: 'Мероприятия',
              icon: Icons.event_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentEventsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareerTile extends StatelessWidget {
  const _CareerTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: const Color(0xFF4A90E2)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
