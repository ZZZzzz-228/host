import 'package:flutter/material.dart';

import 'career_ui.dart';
import 'student_contacts_screen.dart';

class StudentCareerContactsScreen extends StatelessWidget {
  const StudentCareerContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CareerUi.scaffold(
      title: 'Контакты',
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Здесь будут отдельные карточки для раздела «Карьера».\n\n'
              'Контакты Центра карьеры (телефоны/почта/сотрудники) находятся на основной странице «Контакты».',
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.35),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentContactsScreen()),
                );
              },
              icon: const Icon(Icons.contacts_outlined),
              label: const Text('Открыть контакты Центра карьеры'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
