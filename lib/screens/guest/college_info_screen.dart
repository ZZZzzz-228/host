import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import 'about_college_headers.dart';

String _toAbsoluteUrl(String baseUrl, String value) {
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  if (value.startsWith('/')) {
    return '$base$value';
  }
  return '$base/$value';
}

Widget _imageFromPath(
    String baseUrl,
    String path, {
      required BoxFit fit,
      Widget? errorFallback,
    }) {
  final p = path.trim();
  if (p.isEmpty) {
    return errorFallback ?? const SizedBox.shrink();
  }
  if (p.startsWith('assets/')) {
    return Image.asset(
      p,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => errorFallback ?? const SizedBox.shrink(),
    );
  }
  return Image.network(
    _toAbsoluteUrl(baseUrl, p),
    fit: fit,
    errorBuilder: (context, error, stackTrace) => errorFallback ?? const SizedBox.shrink(),
  );
}

Color? _parseColorHexString(String value) {
  var hex = value.trim();
  if (hex.isEmpty) return null;
  if (hex.startsWith('0x') || hex.startsWith('0X')) {
    hex = hex.substring(2);
  }
  final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
  if (cleaned.length != 6 && cleaned.length != 8) return null;
  final full = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  final parsed = int.tryParse(full, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}

IconData _cmsMaterialIconByName(String iconName) {
  switch (iconName.trim()) {
    case 'school':
      return Icons.school;
    case 'star':
      return Icons.star;
    case 'people':
      return Icons.people;
    case 'public':
      return Icons.public;
    case 'business':
      return Icons.business;
    case 'engineering':
      return Icons.engineering;
    case 'science':
      return Icons.science;
    case 'computer':
      return Icons.computer;
    case 'menu_book':
      return Icons.menu_book;
    case 'rocket_launch':
      return Icons.rocket_launch;
    case 'emoji_events':
      return Icons.emoji_events;
    case 'flag':
      return Icons.flag;
    case 'verified':
      return Icons.verified;
    case 'auto_awesome':
      return Icons.auto_awesome;
    case 'workspace_premium':
      return Icons.workspace_premium;
    case 'apartment':
      return Icons.apartment;
    case 'home_work':
      return Icons.home_work;
    case 'sports_esports':
      return Icons.sports_esports;
    case 'fitness_center':
      return Icons.fitness_center;
    case 'restaurant':
      return Icons.restaurant;
    case 'local_library':
      return Icons.local_library;
    case 'lightbulb':
      return Icons.lightbulb;
    default:
      return Icons.info_outline;
  }
}

/// Экран «О колледже» — контент из CMS (pages.about-college).
class CollegeInfoScreen extends StatefulWidget {
  const CollegeInfoScreen({super.key});

  @override
  State<CollegeInfoScreen> createState() => _CollegeInfoScreenState();
}

class _CollegeInfoScreenState extends State<CollegeInfoScreen> {
  final ApiClient _api = AppSession.apiClient;
  late Future<PageContentItem?> _pageFuture;

  // Контроллер скролла + флаг для прозрачно-матовой «чёлки» как во «Все специальности».
  final ScrollController _scrollController = ScrollController();
  bool _showScrolledTitle = false;

  @override
  void initState() {
    super.initState();
    _pageFuture = _api.fetchPageBySlug('about-college');
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final show = _scrollController.offset > 10;
    if (show != _showScrolledTitle) {
      setState(() => _showScrolledTitle = show);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final f = _api.fetchPageBySlug('about-college');
    setState(() => _pageFuture = f);
    await f;
  }

  /// Собираем Scaffold с прозрачно-матовым SliverAppBar (как «Все специальности»).
  Widget _buildScaffold({required String title, required Widget body}) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: false,
              snap: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 74,
              flexibleSpace: AboutCollegePushedHeader(
                showScrolledTitle: _showScrolledTitle,
                onBack: () => Navigator.pop(context),
                scrolledTitle: title,
                alwaysShowTitle: true,
              ),
            ),
          ];
        },
        body: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = AppSession.apiClient.baseUrl;
    return FutureBuilder<PageContentItem?>(
      future: _pageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
          return _buildScaffold(
            title: 'О колледже',
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _buildScaffold(
            title: 'О колледже',
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Не удалось загрузить страницу: ${snapshot.error}'),
              ),
            ),
          );
        }

        final page = snapshot.data;
        if (page == null && snapshot.connectionState == ConnectionState.done) {
          return _buildScaffold(
            title: 'О колледже',
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Страница не найдена. Создайте в админке страницу со slug about-college.'),
              ),
            ),
          );
        }
        final appBarTitle = (page?.title ?? '').trim();
        final cover = (page?.coverImageUrl ?? '').trim();
        final missionHeading = (page?.missionTitle ?? '').trim();
        final aboutHeading = (page?.aboutTitle ?? '').trim();
        final lead = (page?.lead ?? '').trim();
        final body = (page?.body ?? '').trim();
        final statsHeading = (page?.statsHeading ?? '').trim();
        final advantagesHeading = (page?.advantagesHeading ?? '').trim();
        final achievementsHeading = (page?.achievementsHeading ?? '').trim();
        final infrastructureHeading = (page?.infrastructureHeading ?? '').trim();
        final infrastructureText = (page?.infrastructureText ?? '').trim();
        final stats = (page?.stats ?? const <PageStatCms>[])
            .where((s) =>
        s.iconName.trim().isNotEmpty &&
            s.value.trim().isNotEmpty &&
            s.label.trim().isNotEmpty)
            .toList(growable: false);
        final advantages = (page?.advantages ?? const <PageCmsCard>[])
            .where((c) =>
        c.iconName.trim().isNotEmpty &&
            c.title.trim().isNotEmpty &&
            c.text.trim().isNotEmpty)
            .toList(growable: false);
        final achievements = (page?.achievements ?? const <PageCmsCard>[])
            .where((c) =>
        c.iconName.trim().isNotEmpty &&
            c.title.trim().isNotEmpty &&
            c.text.trim().isNotEmpty)
            .toList(growable: false);

        return _buildScaffold(
          title: appBarTitle.isNotEmpty ? appBarTitle : 'О колледже',
          body: HapticRefreshIndicator(
            color: const Color(0xFF4A90E2),
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey[300]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _imageFromPath(
                        baseUrl,
                        cover.isNotEmpty ? cover : 'assets/images/college/college_building.jpg',
                        fit: BoxFit.cover,
                        errorFallback: const Center(child: Icon(Icons.image, size: 64, color: Colors.grey)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (missionHeading.isNotEmpty || lead.isNotEmpty) ...[
                    if (missionHeading.isNotEmpty)
                      Text(missionHeading, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (missionHeading.isNotEmpty) const SizedBox(height: 8),
                    if (lead.isNotEmpty)
                      Text(lead, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6)),
                    const SizedBox(height: 20),
                  ],
                  if (aboutHeading.isNotEmpty || body.isNotEmpty) ...[
                    if (aboutHeading.isNotEmpty)
                      Text(aboutHeading, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (aboutHeading.isNotEmpty) const SizedBox(height: 8),
                    if (body.isNotEmpty)
                      Text(body, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6)),
                    const SizedBox(height: 24),
                  ],
                  if (stats.isNotEmpty) ...[
                    Text(
                      statsHeading.isNotEmpty ? statsHeading : 'Колледж в цифрах',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildStatsFromCms(stats),
                    const SizedBox(height: 24),
                  ],
                  if (advantages.isNotEmpty) ...[
                    Text(
                      advantagesHeading.isNotEmpty ? advantagesHeading : 'Почему выбирают нас',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < advantages.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _AdvantageItem(
                        icon: _cmsMaterialIconByName(advantages[i].iconName),
                        title: advantages[i].title,
                        text: advantages[i].text,
                        color: _parseColorHexString(advantages[i].colorHex) ?? const Color(0xFF283593),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                  if (achievements.isNotEmpty) ...[
                    Text(
                      achievementsHeading.isNotEmpty ? achievementsHeading : 'Наши достижения',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < achievements.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _AchievementCard(
                        icon: _cmsMaterialIconByName(achievements[i].iconName),
                        title: achievements[i].title,
                        text: achievements[i].text,
                        color: _parseColorHexString(achievements[i].colorHex) ?? const Color(0xFFFFA726),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                  if (infrastructureText.isNotEmpty) ...[
                    Text(
                      infrastructureHeading.isNotEmpty ? infrastructureHeading : 'Инфраструктура',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      infrastructureText,
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _buildStatsFromCms(List<PageStatCms> stats) {
  final rows = <Widget>[];
  for (var i = 0; i < stats.length; i += 2) {
    final a = stats[i];
    final b = i + 1 < stats.length ? stats[i + 1] : null;
    final c1 = _parseColorHexString(a.colorHex) ?? const Color(0xFF4A90E2);
    rows.add(
      Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: _cmsMaterialIconByName(a.iconName),
              value: a.value,
              label: a.label,
              color: c1,
            ),
          ),
          if (b != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: _cmsMaterialIconByName(b.iconName),
                value: b.value,
                label: b.label,
                color: _parseColorHexString(b.colorHex) ?? const Color(0xFF4A90E2),
              ),
            ),
          ],
        ],
      ),
    );
    rows.add(const SizedBox(height: 10));
  }
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard({required this.icon, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700]), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _AdvantageItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  const _AdvantageItem({required this.icon, required this.title, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),
        ])),
      ]),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  const _AchievementCard({required this.icon, required this.title, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
        ])),
      ]),
    );
  }
}
