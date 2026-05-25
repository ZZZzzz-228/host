import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String _selectedCategory = 'Все';

  static const _categories = [
    'Все', 'Веб-разработка', 'Программирование', 'Дизайн',
    'Аналитика', 'Мобильные приложения', 'Другое',
  ];

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

  Future<void> _showAddEditDialog({StudentPortfolioItem? item}) async {
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final descCtrl  = TextEditingController(text: item?.description ?? '');
    final urlCtrl   = TextEditingController(text: item?.projectUrl ?? '');
    final imgCtrl   = TextEditingController(text: item?.imageUrl ?? '');
    String category = item?.category.isNotEmpty == true ? item!.category : 'Веб-разработка';

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.folder_special_rounded, color: Color(0xFF4A90E2), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item == null ? 'Новый проект' : 'Редактировать',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField(titleCtrl, 'Название проекта *', Icons.title_rounded),
                const SizedBox(height: 10),
                _buildField(descCtrl, 'Описание', Icons.description_rounded, maxLines: 3),
                const SizedBox(height: 10),
                _buildField(urlCtrl, 'Ссылка на проект (GitHub, сайт…)', Icons.link_rounded),
                const SizedBox(height: 10),
                _buildField(imgCtrl, 'URL изображения (необязательно)', Icons.image_rounded),
                const SizedBox(height: 10),
                // Категория
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(
                    labelText: 'Категория',
                    prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFF4A90E2)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: _categories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setSt(() => category = v ?? category),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Отмена'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Сохранить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;
    if (titleCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите название проекта')),
        );
      }
      return;
    }

    try {
      if (item == null) {
        await _api.createStudentPortfolioItem(
          title: titleCtrl.text.trim(),
          description: descCtrl.text.trim(),
          projectUrl: urlCtrl.text.trim(),
          imageUrl: imgCtrl.text.trim(),
          category: category,
        );
      } else {
        await _api.updateStudentPortfolioItem(
          item.id,
          title: titleCtrl.text.trim(),
          description: descCtrl.text.trim(),
          projectUrl: urlCtrl.text.trim(),
          imageUrl: imgCtrl.text.trim(),
          category: category,
        );
      }
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4A90E2), size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Future<void> _confirmDelete(StudentPortfolioItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить проект?'),
        content: Text('«${item.title}» будет удалён безвозвратно.'),
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
    await _api.deleteStudentPortfolioItem(item.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return CareerUi.scaffold(
      title: 'Моё портфолио',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF4A90E2),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить проект'),
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
            final allItems = snapshot.data ?? const <StudentPortfolioItem>[];

            // Фильтрация по категории
            final items = _selectedCategory == 'Все'
                ? allItems
                : allItems.where((i) => i.category == _selectedCategory).toList();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Шапка-баннер
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A90E2), Color(0xFF64B5F6)],
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
                          child: const Icon(Icons.folder_open_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Моё портфолио',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                allItems.isEmpty
                                    ? 'Добавьте первый проект'
                                    : '${allItems.length} ${_pluralProjects(allItems.length)}',
                                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Фильтр по категориям
                if (allItems.isNotEmpty) SliverToBoxAdapter(
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final selected = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFF4A90E2) : const Color(0xFFF0F4F8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : Colors.black54,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Пустое состояние
                if (items.isEmpty) SliverFillRemaining(
                  child: _buildEmptyState(allItems.isEmpty),
                )
                else SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) => _PortfolioCard(
                        item: items[i],
                        onEdit: () => _showAddEditDialog(item: items[i]),
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

  Widget _buildEmptyState(bool fullyEmpty) {
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
              child: const Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF4A90E2)),
            ),
            const SizedBox(height: 18),
            Text(
              fullyEmpty ? 'Портфолио пустое' : 'Нет проектов в этой категории',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              fullyEmpty
                  ? 'Добавьте свои проекты, работы и достижения, чтобы работодатели могли их увидеть'
                  : 'Попробуйте выбрать другую категорию или добавьте новый проект',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            if (fullyEmpty) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _showAddEditDialog(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Добавить первый проект'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _pluralProjects(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'проект';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) return 'проекта';
    return 'проектов';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Карточка проекта портфолио
// ─────────────────────────────────────────────────────────────────────────────
class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final StudentPortfolioItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _catColors = <String, Color>{
    'Веб-разработка':       Color(0xFF4A90E2),
    'Программирование':     Color(0xFF7B61FF),
    'Дизайн':               Color(0xFFFF6B9D),
    'Аналитика':            Color(0xFF00C896),
    'Мобильные приложения': Color(0xFFFF9500),
    'Другое':               Color(0xFF8E8E93),
  };

  Color get _catColor => _catColors[item.category] ?? const Color(0xFF4A90E2);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Обложка проекта (если есть картинка)
          if (item.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                item.imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            )
          else
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: _catColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Категория + действия
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _catColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.category.isNotEmpty ? item.category : 'Проект',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _catColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: Colors.black45,
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.red.shade300,
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Название
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, height: 1.4, fontSize: 13.5),
                  ),
                ],

                // Теги
                if (item.tagsList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: item.tagsList.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                      ),
                    )).toList(),
                  ),
                ],

                // Кнопка перейти
                if (item.projectUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(item.projectUrl);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Открыть проект'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4A90E2),
                      side: const BorderSide(color: Color(0xFF4A90E2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
