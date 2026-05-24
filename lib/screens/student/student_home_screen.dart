import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/api/api_client.dart';
import '../../data/cache/guest_stories_cache.dart';
import '../../data/session/app_session.dart';
import '../guest/about_college_media.dart';
import '../guest/about_college_models.dart';
import '../guest/guest_story_screens.dart';
import '../widgets/centered_app_bar_title.dart';
import '../../widgets/haptic_refresh_indicator.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final Set<int> _viewedStories = {};
  final _apiClient = AppSession.apiClient;

  late Future<List<NewsItem>> _newsFuture;
  List<StoryData> _storiesUi = const [];

  @override
  void initState() {
    super.initState();
    _newsFuture = _apiClient.fetchNews();
    unawaited(_loadStories());
  }

  Future<void> _loadStories() async {
    final cachedStories = await GuestStoriesCache.read();
    if (!mounted) return;
    if (cachedStories != null && cachedStories.isNotEmpty) {
      setState(() {
        _storiesUi = cachedStories.map(StoryData.fromApi).toList(growable: false);
      });
    }

    try {
      final cmsStories = await _apiClient.fetchStories();
      if (!mounted) return;
      setState(() {
        _storiesUi = cmsStories.map(StoryData.fromApi).toList(growable: false);
      });
      await GuestStoriesCache.save(cmsStories);
    } catch (_) {
      // Оставляем кэш или пустой список.
    }
  }

  void _markAsViewed(int index) {
    setState(() {
      _viewedStories.add(index);
    });
  }

  bool _isViewed(int index) => _viewedStories.contains(index);

  Future<void> _onRefresh() async {
    final news = _apiClient.fetchNews();
    if (!mounted) return;
    setState(() {
      _newsFuture = news;
    });
    await Future.wait<void>([news, _loadStories()]);
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = _apiClient.baseUrl;
    final sw = MediaQuery.of(context).size.width;
    final storyItemWidth = sw < 360 ? 100.0 : (sw > 600 ? 150.0 : 120.0);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const CenteredAppBarTitle(),
      ),
      body: HapticRefreshIndicator(
        color: const Color(0xFF4A90E2),
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: _storiesUi.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Мероприятия и истории появятся после публикации на сайте.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _storiesUi.length,
                        itemBuilder: (context, index) {
                          return _buildStoryItem(
                            context,
                            index,
                            _storiesUi[index],
                            storyItemWidth,
                            baseUrl,
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<List<NewsItem>>(
                future: _newsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Ошибка загрузки новостей: ${snapshot.error}'),
                    );
                  }

                  final news = snapshot.data ?? const <NewsItem>[];
                  if (news.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Новости пока отсутствуют'),
                    );
                  }

                  return Column(
                    children: news.take(6).map((item) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _buildNewsCard(item),
                      );
                    }).toList(growable: false),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryItem(
    BuildContext context,
    int index,
    StoryData story,
    double storyItemWidth,
    String baseUrl,
  ) {
    final bool isViewed = _isViewed(index);
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoryViewerScreen(
              initialIndex: index,
              stories: _storiesUi,
            ),
          ),
        );
        _markAsViewed(index);
      },
      child: Container(
        width: storyItemWidth,
        margin: const EdgeInsets.only(right: 12),
        child: Container(
          width: storyItemWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isViewed ? Colors.grey : story.color,
              width: 3,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: aboutCollegeImageFromPath(
              baseUrl,
              story.imagePath,
              fit: BoxFit.cover,
              errorFallback: Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsItem item) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _newsPlaceholder(),
                  )
                : _newsPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _newsPlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 64, color: Colors.grey),
      ),
    );
  }
}
