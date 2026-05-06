import 'package:flutter/material.dart';
import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import 'career_ui.dart';

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

  Future<void> _addResume() async {
    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новое резюме'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Название')),
            TextField(controller: summaryController, decoration: const InputDecoration(labelText: 'Кратко о себе')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сохранить')),
        ],
      ),
    );
    if (ok != true) return;
    await _api.createStudentResume(
      title: titleController.text.trim(),
      summary: summaryController.text.trim(),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return CareerUi.scaffold(
      title: 'Резюме',
      floatingActionButton: FloatingActionButton(
        onPressed: _addResume,
        child: const Icon(Icons.add),
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
            if (items.isEmpty) {
              return CareerUi.empty('Резюме пока нет');
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, color: Color(0xFF4A90E2)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (item.summary.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(item.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await _api.deleteStudentResume(item.id);
                          _reload();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
