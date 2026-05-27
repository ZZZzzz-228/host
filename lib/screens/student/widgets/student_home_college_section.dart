import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/api/api_client.dart';
import '../../../data/session/app_session.dart';
import '../../../data/student/student_college_data.dart';
import '../student_clubs_screen.dart';
import '../student_departments_screen.dart';

/// Блок «О колледже», отделения и кружки на главной вкладке студента.
class StudentHomeCollegeSection extends StatefulWidget {
  const StudentHomeCollegeSection({super.key});

  @override
  State<StudentHomeCollegeSection> createState() =>
      _StudentHomeCollegeSectionState();
}

class _StudentHomeCollegeSectionState extends State<StudentHomeCollegeSection> {
  final ApiClient _api = AppSession.apiClient;
  List<ContactItem> _contacts = [];
  bool _contactsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      var list = await _api.fetchContacts(category: 'college');
      if (list.isEmpty) {
        list = await _api.fetchContacts();
      }
      if (!mounted) return;
      setState(() {
        _contacts = list;
        _contactsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _contactsLoading = false);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'website':
        return Icons.language;
      case 'address':
        return Icons.location_on;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAboutCard(),
          const SizedBox(height: 16),
          _buildMenuTile(
            icon: Icons.apartment,
            title: 'Отделения',
            subtitle: 'Список отделений и заведующих',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StudentDepartmentsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: Icons.groups,
            title: 'Доп. кружки',
            subtitle: 'Совет студентов, патриот, робототехника',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentClubsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'О КОЛЛЕДЖЕ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            studentCollegeAboutTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            studentCollegeAboutText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          if (_contactsLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_contacts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _contacts
                  .map(
                    (c) => _buildContactChip(
                      _iconForType(c.type),
                      c.value,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoStat(icon: Icons.access_time, label: '08:00–17:00'),
              _InfoStat(icon: Icons.people, label: '500+ студентов'),
              _InfoStat(icon: Icons.school, label: '15 специальностей'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactChip(IconData icon, String text) {
    return GestureDetector(
      onTap: () async {
        Uri? uri;
        if (icon == Icons.phone) {
          final clean = text.replaceAll(RegExp(r'[^\d+]'), '');
          uri = Uri.parse('tel:$clean');
        } else if (icon == Icons.email) {
          uri = Uri.parse('mailto:$text');
        } else if (icon == Icons.language) {
          final url = text.contains('://') ? text : 'https://$text';
          uri = Uri.parse(url);
        }
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4A90E2)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4A90E2),
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF4A90E2)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  const _InfoStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.black87),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
