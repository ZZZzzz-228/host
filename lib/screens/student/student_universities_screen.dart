import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import 'career_ui.dart';

class StudentUniversitiesScreen extends StatefulWidget {
  const StudentUniversitiesScreen({super.key});

  @override
  State<StudentUniversitiesScreen> createState() => _StudentUniversitiesScreenState();
}

class _StudentUniversitiesScreenState extends State<StudentUniversitiesScreen> {
  final ApiClient _api = AppSession.apiClient;
  late Future<List<UniversityItem>> _future;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _future = _api.fetchUniversities();
  }

  Future<void> _onRefresh() async {
    final next = _api.fetchUniversities();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return CareerUi.scaffold(
      title: 'Университеты',
      body: HapticRefreshIndicator(
        color: const Color(0xFF4A90E2),
        onRefresh: _onRefresh,
        child: FutureBuilder<List<UniversityItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CareerUi.loading();
            }
            if (snapshot.hasError) {
              return CareerUi.error('Ошибка: ${snapshot.error}');
            }
            final allItems = snapshot.data ?? const <UniversityItem>[];
            final items = _searchQuery.isEmpty
                ? allItems
                : allItems.where((u) =>
            u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                u.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                u.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

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
                        colors: [Color(0xFF3F6EB0), Color(0xFF4A90E2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.school_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Университеты',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Найдите подходящий ВУЗ для продолжения образования',
                                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Поиск
                        TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Поиск по названию или городу...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ],
                    ),
                  ),
                ),

                // Счётчик
                if (allItems.isNotEmpty) SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Text(
                      '${items.length} из ${allItems.length} университетов',
                      style: const TextStyle(color: Colors.black45, fontSize: 13),
                    ),
                  ),
                ),

                if (items.isEmpty) SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.school_outlined, size: 44, color: Color(0xFF4A90E2)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          allItems.isEmpty
                              ? 'Список университетов пуст'
                              : 'Ничего не найдено',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          allItems.isEmpty
                              ? 'Университеты ещё не добавлены администратором'
                              : 'Попробуйте изменить запрос поиска',
                          style: const TextStyle(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
                else SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) => _UniversityCard(uni: items[i]),
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
}

// ─── Карточка университета ───────────────────────────────────────────────────
class _UniversityCard extends StatelessWidget {
  const _UniversityCard({required this.uni});
  final UniversityItem uni;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          // Обложка
          if (uni.coverUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(
                uni.coverUrl,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Логотип + название
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (uni.logoUrl.isNotEmpty)
                      Container(
                        width: 52, height: 52,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            uni.logoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded, size: 28, color: Color(0xFF4A90E2)),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 52, height: 52,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school_rounded, size: 28, color: Color(0xFF4A90E2)),
                      ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uni.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3),
                          ),
                          if (uni.shortName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A90E2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                uni.shortName,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Город
                if (uni.city.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text(uni.city, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ],

                // Краткое описание
                if (uni.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    uni.description,
                    style: const TextStyle(color: Colors.black54, fontSize: 13.5, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Теги
                if (uni.tagsList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: uni.tagsList.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(tag, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                    )).toList(),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Кнопки действий
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (uni.url.isNotEmpty)
                      _ActionButton(
                        icon: Icons.language_rounded,
                        label: 'Сайт',
                        color: const Color(0xFF4A90E2),
                        onTap: () => _launch(uni.url),
                      ),
                    if (uni.admissionUrl.isNotEmpty)
                      _ActionButton(
                        icon: Icons.how_to_reg_rounded,
                        label: 'Приёмная комиссия',
                        color: const Color(0xFF4CAF50),
                        onTap: () => _launch(uni.admissionUrl),
                      ),
                    if (uni.vkUrl.isNotEmpty)
                      _ActionButton(
                        icon: Icons.people_rounded,
                        label: 'ВКонтакте',
                        color: const Color(0xFF2196F3),
                        onTap: () => _launch(uni.vkUrl),
                      ),
                    if (uni.telegramUrl.isNotEmpty)
                      _ActionButton(
                        icon: Icons.telegram,
                        label: 'Telegram',
                        color: const Color(0xFF0088CC),
                        onTap: () => _launch(uni.telegramUrl),
                      ),
                    if (uni.phone.isNotEmpty)
                      _ActionButton(
                        icon: Icons.phone_outlined,
                        label: uni.phone,
                        color: Colors.black54,
                        onTap: () => _launch('tel:${uni.phone}'),
                      ),
                  ],
                ),

                // Подробнее
                if (uni.fullText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showFullInfo(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Подробнее',
                          style: TextStyle(
                            color: Color(0xFF4A90E2),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF4A90E2)),
                      ],
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

  void _showFullInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            // Ручка
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(uni.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            if (uni.city.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(uni.city, style: const TextStyle(color: Colors.black54)),
            ],
            const SizedBox(height: 16),
            Text(
              uni.fullText,
              style: const TextStyle(fontSize: 14.5, height: 1.6, color: Colors.black87),
            ),
            if (uni.address.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF4A90E2)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(uni.address, style: const TextStyle(fontSize: 14))),
                ],
              ),
            ],
            if (uni.email.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 18, color: Color(0xFF4A90E2)),
                  const SizedBox(width: 8),
                  Text(uni.email, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
