import 'package:flutter/material.dart';
import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import 'career_ui.dart';

class StudentPortfolioScreen extends StatefulWidget {
  const StudentPortfolioScreen({super.key});

  @override
  State<StudentPortfolioScreen> createState() => _StudentPortfolioScreenState();
}

class _StudentPortfolioScreenState extends State<StudentPortfolioScreen> {
  final ApiClient _api = AppSession.apiClient;
  late Future<List<StudentPortfolioItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchStudentPortfolio();
  }

  void _reload() {
    setState(() {
      _future = _api.fetchStudentPortfolio();
    });
  }

  Future<void> _onRefresh() async {
    final next = _api.fetchStudentPortfolio();
    setState(() => _future = next);
    await next;
  }

  Future<void> _addItem() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новый проект'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Название')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Описание')),
            TextField(controller: urlController, decoration: const InputDecoration(labelText: 'Ссылка')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сохранить')),
        ],
      ),
    );
    if (ok != true) return;
    await _api.createStudentPortfolioItem(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      projectUrl: urlController.text.trim(),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return CareerUi.scaffold(
      title: 'Портфолио',
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: HapticRefreshIndicator(
        color: const Color(0xFF4A90E2),
        onRefresh: _onRefresh,
        child: FutureBuilder<List<StudentPortfolioItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CareerUi.loading();
            }
            if (snapshot.hasError) {
              return CareerUi.error('Ошибка: ${snapshot.error}');
            }
            final items = snapshot.data ?? const <StudentPortfolioItem>[];
            if (items.isEmpty) {
              return CareerUi.empty('Портфолио пока пусто');
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
                      const Icon(Icons.folder_open, color: Color(0xFF4A90E2)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (item.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await _api.deleteStudentPortfolioItem(item.id);
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
