import 'package:flutter/material.dart';
import 'student_contacts_screen.dart';
import 'student_schedule_screen.dart';
import 'student_home_screen.dart';
import 'student_career_screen.dart';
import 'student_profile_screen.dart';
import 'student_main_scope.dart';

class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({super.key});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _currentIndex = 2;
  final GlobalKey<StudentScheduleScreenState> _scheduleKey =
      GlobalKey<StudentScheduleScreenState>();
  String? _scheduleInitialGroup;

  void _openGroupSchedule(String groupName) {
    setState(() {
      _scheduleInitialGroup = groupName;
      _currentIndex = 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleKey.currentState?.selectGroup(groupName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StudentMainScope(
      openGroupSchedule: _openGroupSchedule,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const StudentContactsScreen(),
            StudentScheduleScreen(
              key: _scheduleKey,
              initialGroupName: _scheduleInitialGroup,
              initialTabIndex: _scheduleInitialGroup != null ? 1 : 0,
            ),
            const StudentHomeScreen(),
            const StudentCareerScreen(),
            const StudentProfileScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  activeIcon: 'assets/icons/student/contacts_active.png',
                  inactiveIcon: 'assets/icons/student/contacts.png',
                  label: 'Контакты',
                ),
                _buildNavItem(
                  index: 1,
                  activeIcon: 'assets/icons/student/schedule_active.png',
                  inactiveIcon: 'assets/icons/student/schedule.png',
                  label: 'Расписание',
                ),
                _buildNavItem(
                  index: 2,
                  activeIcon: 'assets/icons/student/home_active.png',
                  inactiveIcon: 'assets/icons/student/home.png',
                  label: 'О колледже',
                ),
                _buildNavItem(
                  index: 3,
                  activeIcon: 'assets/icons/student/vacancies_active.png',
                  inactiveIcon: 'assets/icons/student/vacancies.png',
                  label: 'Карьера',
                ),
                _buildNavItem(
                  index: 4,
                  activeIcon: 'assets/icons/student/profile_active.png',
                  inactiveIcon: 'assets/icons/student/profile.png',
                  label: 'Профиль',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String activeIcon,
    required String inactiveIcon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
          if (index != 1) {
            _scheduleInitialGroup = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4A90E2).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isSelected ? activeIcon : inactiveIcon,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.image,
                  size: 24,
                  color: isSelected ? const Color(0xFF4A90E2) : Colors.grey,
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF4A90E2) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
