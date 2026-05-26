import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import 'career_ui.dart';
import 'student_resume_wizard_screen.dart';

class StudentResumeScreen extends StatefulWidget {
  const StudentResumeScreen({super.key});

  @override
  State<StudentResumeScreen> createState() => _StudentResumeScreenState();
}

class _StudentResumeScreenState extends State<StudentResumeScreen> {
  final ApiClient _api = AppSession.apiClient;
  late Future<List<StudentResumeItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchStudentResumes();
  }

  void _reload() {
    setState(() {
      _future = _api.fetchStudentResumes();
    });
  }

  Future<void> _onRefresh() async {
    final next = _api.fetchStudentResumes();
    setState(() => _future = next);
    await next;
  }

  Future<void> _openWizard({StudentResumeItem? item}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentResumeWizardScreen(
          resumeId: item?.id,
        ),
      ),
    );
    if (result == true) _reload();
  }

  Future<void> _confirmDelete(StudentResumeItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить резюме?'),
        content: Text('Резюме «${item.title}» будет удалено безвозвратно.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.deleteStudentResume(item.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CareerUi.scaffold(
      title: 'Мои резюме',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openWizard(),
        backgroundColor: const Color(0xFF4A90E2),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Создать резюме'),
      ),
      body: HapticRefreshIndicator(
        color: const Color(0xFF4A90E2),
        onRefresh: _onRefresh,
        child: FutureBuilder<List<StudentResumeItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CareerUi.loading();
            }
            if (snapshot.hasError) {
              return CareerUi.error('Ошибка: ${snapshot.error}');
            }
            final items = snapshot.data ?? const <StudentResumeItem>[];

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Шапка
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A90E2), Color(0xFF5BA4E8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.description_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Создание резюме',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                items.isEmpty
                                    ? 'Создайте своё первое резюме'
                                    : '${items.length} ${_pluralResumes(items.length)}',
                                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (items.isEmpty) SliverFillRemaining(
                  child: _buildEmptyState(),
                )
                else SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) => _ResumeCard(
                        item: items[i],
                        onEdit: () => _openWizard(item: items[i]),
                        onDelete: () => _confirmDelete(items[i]),
                      ),
                      childCount: items.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.description_rounded, size: 48, color: Color(0xFF4A90E2)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Резюме ещё нет',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Создайте профессиональное резюме за несколько минут. Выберите специальность — и мы зададим нужные вопросы',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openWizard(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Создать резюме', style: TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  String _pluralResumes(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'резюме';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) return 'резюме';
    return 'резюме';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Карточка резюме в списке
// ─────────────────────────────────────────────────────────────────────────────
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final StudentResumeItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: item.isPublished ? const Color(0xFF4CAF50) : const Color(0xFF4A90E2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.description_rounded, color: Color(0xFF4A90E2), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.summary.isNotEmpty)
                            Text(
                              item.summary,
                              style: const TextStyle(color: Colors.black54, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.isPublished
                                ? const Color(0xFF4CAF50).withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.isPublished ? 'Опубликовано' : 'Черновик',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: item.isPublished ? const Color(0xFF4CAF50) : Colors.black45,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Детали
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    if (item.city.isNotEmpty)
                      _InfoChip(icon: Icons.location_on_outlined, text: item.city),
                    if (item.desiredSalary != null && item.desiredSalary! > 0)
                      _InfoChip(icon: Icons.payments_outlined, text: '${item.desiredSalary} руб.'),
                    if (item.specialtyTitle.isNotEmpty)
                      _InfoChip(icon: Icons.school_outlined, text: item.specialtyTitle),
                  ],
                ),

                const Divider(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Редактировать'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4A90E2),
                          side: const BorderSide(color: Color(0xFF4A90E2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red.shade300,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width - 64;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW > 120 ? maxW : 120),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black45),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
