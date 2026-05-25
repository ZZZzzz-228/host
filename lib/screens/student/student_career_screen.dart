import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared/shared_partners_screen.dart';
import 'student_career_contacts_screen.dart';
import 'student_events_screen.dart';
import 'student_portfolio_screen.dart';
import 'student_resume_screen.dart';
import 'student_universities_screen.dart';
import 'student_vacancies_screen.dart';
import 'career_ui.dart';

class StudentCareerScreen extends StatelessWidget {
  const StudentCareerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CareerUi.scaffold(
      title: 'Карьера',
      showBackButton: false,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // ── Шапка-баннер ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF64B5F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.work_history_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Карьера',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Раздел карьерного развития студента. Здесь публикуются актуальные возможности, советы и полезные материалы.',
                  style: TextStyle(color: Colors.white, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Разделы карьеры ───────────────────────────────────────────────
          _SectionCard(
            title: 'Разделы карьеры',
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.16,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _CareerTile(
                    title: 'Моё портфолио',
                    icon: Icons.folder_open_rounded,
                    subtitle: 'Проекты и достижения',
                    color: const Color(0xFF4A90E2),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentPortfolioScreen()),
                    ),
                  ),
                  _CareerTile(
                    title: 'Создание резюме',
                    icon: Icons.description_rounded,
                    subtitle: 'Подготовка резюме',
                    color: const Color(0xFF7B61FF),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentResumeScreen()),
                    ),
                  ),
                  _CareerTile(
                    title: 'Вакансии',
                    icon: Icons.work_outline_rounded,
                    subtitle: 'Открытые предложения',
                    color: const Color(0xFF4CAF50),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentVacanciesScreen()),
                    ),
                  ),
                  _CareerTile(
                    title: 'Университеты',
                    icon: Icons.school_rounded,
                    subtitle: 'ВУЗы для поступления',
                    color: const Color(0xFF3F6EB0),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentUniversitiesScreen()),
                    ),
                  ),
                  _CareerTile(
                    title: 'Партнёры',
                    icon: Icons.handshake_outlined,
                    subtitle: 'Компании и организации',
                    color: const Color(0xFFFF9500),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SharedPartnersScreen()),
                    ),
                  ),
                  _CareerTile(
                    title: 'Контакты',
                    icon: Icons.contacts_outlined,
                    subtitle: 'Карьерный центр',
                    color: const Color(0xFF00BCD4),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentCareerContactsScreen()),
                    ),
                  ),
                  _CareerTile(
                    title: 'Мероприятия',
                    icon: Icons.event_note_rounded,
                    subtitle: 'События и встречи',
                    color: const Color(0xFFE91E63),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentEventsScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Быстрые действия ──────────────────────────────────────────────
          _SectionCard(
            title: 'Быстрые действия',
            children: [
              _ActionTile(
                icon: Icons.mail_outline_rounded,
                title: 'Написать в карьерный центр',
                subtitle: 'Связаться по почте',
                onTap: () => _openExternal(context, 'mailto:kucersemen18@gmail.com'),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.phone_in_talk_outlined,
                title: 'Позвонить в приемную',
                subtitle: 'Открыть телефонный звонок',
                onTap: () => _openExternal(context, 'tel:+73912707700'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Полезные советы ───────────────────────────────────────────────
          const _SectionCard(
            title: 'Полезно сейчас',
            children: [
              _HintRow(
                icon: Icons.check_circle_outline_rounded,
                text: 'Обновляй профиль и резюме минимум раз в семестр.',
              ),
              SizedBox(height: 10),
              _HintRow(
                icon: Icons.check_circle_outline_rounded,
                text: 'Следи за мероприятиями и ярмарками вакансий.',
              ),
              SizedBox(height: 10),
              _HintRow(
                icon: Icons.check_circle_outline_rounded,
                text: 'Добавляй проекты и кейсы в портфолио с измеримыми результатами.',
              ),
              SizedBox(height: 10),
              _HintRow(
                icon: Icons.check_circle_outline_rounded,
                text: 'Рассмотри возможность продолжения образования в университетах-партнёрах.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openExternal(BuildContext context, String raw) async {
    final uri = Uri.parse(raw);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не удалось открыть действие')),
    );
  }
}

class _CareerTile extends StatelessWidget {
  const _CareerTile({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.onTap,
    this.color = const Color(0xFF4A90E2),
  });

  final String title;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7FAFD),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7FAFD),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF4A90E2)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4A90E2)),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
