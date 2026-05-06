import 'package:flutter/material.dart';

import '../shared/shared_contacts_screen.dart';

class StudentCareerContactsScreen extends StatelessWidget {
  const StudentCareerContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SharedContactsScreen(
      contactsCategory: 'career_center',
      staffDepartment: 'career_center',
      showBackButton: true,
    );
  }
}
