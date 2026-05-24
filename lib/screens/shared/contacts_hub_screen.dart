import 'package:flutter/material.dart';

import '../widgets/centered_app_bar_title.dart';
import 'shared_contacts_screen.dart';
import '../../data/contacts_placeholders.dart';
import '../../data/api/api_client.dart';

class ContactsCategory {
  const ContactsCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.staffDepartment,
    required this.placeholderStaff,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String staffDepartment;
  final List<StaffMemberItem> placeholderStaff;
}

class ContactsHubScreen extends StatelessWidget {
  const ContactsHubScreen({super.key});

  static const _accent = Color(0xFF4A90E2);

  static final _categories = <ContactsCategory>[
    ContactsCategory(
      id: 'administration',
      title: 'Администрация',
      subtitle: 'Директор, заместители, приёмная',
      icon: Icons.apartment_outlined,
      staffDepartment: 'administration',
      placeholderStaff: ContactsPlaceholders.administration,
    ),
    ContactsCategory(
      id: 'teachers',
      title: 'Преподаватели',
      subtitle: 'Педагогический состав колледжа',
      icon: Icons.school_outlined,
      staffDepartment: 'teachers',
      placeholderStaff: ContactsPlaceholders.teachers,
    ),
    ContactsCategory(
      id: 'curators',
      title: 'Кураторы',
      subtitle: 'Кураторы учебных групп',
      icon: Icons.groups_outlined,
      staffDepartment: 'curators',
      placeholderStaff: ContactsPlaceholders.curators,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            title: const CenteredAppBarTitle(),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  'Контакты колледжа',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Выберите раздел, чтобы посмотреть сотрудников и связаться с ними.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
                ),
                const SizedBox(height: 20),
                ..._categories.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CategoryTile(
                        category: c,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SharedContactsScreen(
                                pageTitle: c.title,
                                staffDepartment: c.staffDepartment,
                                placeholderStaff: c.placeholderStaff,
                                showBackButton: true,
                                showInfoCard: false,
                              ),
                            ),
                          );
                        },
                      ),
                    )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onTap,
  });

  final ContactsCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ContactsHubScreen._accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  category.icon,
                  color: ContactsHubScreen._accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ContactsHubScreen._accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
