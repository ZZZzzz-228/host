import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';
import 'about_college_media.dart';
import 'about_college_models.dart';
import 'about_college_headers.dart';

// ════════════════════════════════════════════════════════════════════════════
// ЛЕНТА «STORIES» — ВЕРТИКАЛЬНОЕ ПРОЛИСТЫВАНИЕ ИСТОРИЙ
// Внутри одной истории — горизонтальное пролистывание фотографий.
// Заголовок показываем здесь, на обложке — это и есть «открытое» состояние.
// ════════════════════════════════════════════════════════════════════════════
class StoryViewerScreen extends StatefulWidget {
  final int initialIndex;
  final List<StoryData> stories;
  const StoryViewerScreen({super.key, required this.initialIndex, required this.stories});
  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late int _currentIndex;
  late PageController _pageController;
  late int _photoIndex;
  late PageController _photoController;
  Timer? _timer;
  double _progress = 0.0;
  bool _isPaused = false;

  static const Duration _slideDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _photoIndex = 0;
    _photoController = PageController();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  List<String> _photosOf(StoryData s) {
    final list = s.imagePaths.where((u) => u.isNotEmpty).toList(growable: false);
    if (list.isNotEmpty) return list;
    return [s.imagePath];
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _isPaused = false;
    final tickStep = 50.0 / _slideDuration.inMilliseconds;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_isPaused) return;
      setState(() {
        _progress += tickStep;
        if (_progress >= 1.0) {
          _progress = 0.0;
          _onSlideComplete();
        }
      });
    });
  }

  void _onSlideComplete() {
    final story = widget.stories[_currentIndex];
    final photos = _photosOf(story);
    if (_photoIndex < photos.length - 1) {
      setState(() {
        _photoIndex++;
        _photoController.animateToPage(
          _photoIndex,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    } else {
      _nextStory();
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _photoIndex = 0;
        _pageController.animateToPage(_currentIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      });
      _photoController.dispose();
      _photoController = PageController();
      _startTimer();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_photoIndex > 0) {
      setState(() {
        _photoIndex--;
        _photoController.animateToPage(
          _photoIndex,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
      _startTimer();
      return;
    }
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _photoIndex = 0;
        _pageController.animateToPage(_currentIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      });
      _photoController.dispose();
      _photoController = PageController();
      _startTimer();
    }
  }

  void _onTapForward() {
    final story = widget.stories[_currentIndex];
    final photos = _photosOf(story);
    if (_photoIndex < photos.length - 1) {
      setState(() {
        _photoIndex++;
        _photoController.animateToPage(_photoIndex, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      });
      _startTimer();
    } else {
      _nextStory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final photos = _photosOf(story);
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final w = MediaQuery.of(context).size.width;
          final h = MediaQuery.of(context).size.height;
          if (details.globalPosition.dy > h * 0.75) return;
          if (details.globalPosition.dx < w / 2) {
            _previousStory();
          } else {
            _onTapForward();
          }
        },
        onLongPressStart: (_) {
          setState(() => _isPaused = true);
          _timer?.cancel();
        },
        onLongPressEnd: (_) {
          setState(() => _isPaused = false);
          _startTimer();
        },
        child: Stack(children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.stories.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final s = widget.stories[index];
              return _buildStoryContent(s, index == _currentIndex ? _photoIndex : 0);
            },
          ),
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: List.generate(photos.length, (i) {
                    double v;
                    if (i < _photoIndex) {
                      v = 1.0;
                    } else if (i == _photoIndex) {
                      v = _progress;
                    } else {
                      v = 0.0;
                    }
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 3,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(3)),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: v,
                            child: Container(height: 3, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3))),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                ),
              ),
            ]),
          ),
          Positioned(
            bottom: 40, left: 16, right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: ElevatedButton(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventsFeedScreen(
                          stories: widget.stories,
                          initialIndex: _currentIndex,
                        ),
                      ),
                    ).then((_) => _startTimer());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Подробнее', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStoryContent(StoryData story, int photoIndex) {
    final baseUrl = AppSession.apiClient.baseUrl;
    final photos = _photosOf(story);
    return Stack(fit: StackFit.expand, children: [
      // Фон чёрный — на нём будут видны «полосы» сверху/снизу или по бокам,
      // когда соотношение сторон фото не совпадает с экраном.
      Container(color: Colors.black),
      // Сами фотки — пролистываются внутри одной истории.
      // BoxFit.contain — фото показывается ЦЕЛИКОМ, без растяжения и обрезки.
      PageView.builder(
        controller: _photoController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: photos.length,
        onPageChanged: (i) => setState(() => _photoIndex = i),
        itemBuilder: (context, i) => Center(
          child: aboutCollegeImageFromPath(
            baseUrl,
            photos[i],
            fit: BoxFit.contain,
            errorFallback: Container(color: Colors.black),
          ),
        ),
      ),
      // Тёмный градиент для читаемости заголовка
      IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.45), Colors.transparent, Colors.black.withOpacity(0.40)],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
      // Заголовок — показываем здесь, в открытом просмотре истории
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 90, 16, 100),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              story.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// «ПОДРОБНЕЕ» — лента с заголовком, текстом и BENTO-сеткой фотографий
// Без верхнего фото-обложки. Сетка фотографий — сразу под заголовком.
// ════════════════════════════════════════════════════════════════════════════
class EventsFeedScreen extends StatefulWidget {
  const EventsFeedScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  final List<StoryData> stories;
  final int initialIndex;

  @override
  State<EventsFeedScreen> createState() => _EventsFeedScreenState();
}

class _EventsFeedScreenState extends State<EventsFeedScreen> {
  late final ScrollController _scrollController;
  late int _selectedIndex;
  bool _showScrolledTitle = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxExt = _scrollController.position.maxScrollExtent;
      final targetOffset = (_selectedIndex * 340.0).clamp(0.0, maxExt);
      _scrollController.jumpTo(targetOffset);
    });
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 10;
    if (shouldShow != _showScrolledTitle) {
      setState(() => _showScrolledTitle = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _photosOf(StoryData s) {
    final list = s.imagePaths.where((u) => u.isNotEmpty).toList(growable: false);
    if (list.isNotEmpty) return list;
    return [s.imagePath];
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = AppSession.apiClient.baseUrl;
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true, floating: false, snap: false,
              elevation: 0, scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 74,
              flexibleSpace: AboutCollegePushedHeader(
                showScrolledTitle: _showScrolledTitle,
                onBack: () => Navigator.pop(context),
                scrolledTitle: 'Мероприятия',
              ),
            ),
          ];
        },
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: widget.stories.length,
          itemBuilder: (context, index) {
            final story = widget.stories[index];
            final isSelected = index == _selectedIndex;
            final photos = _photosOf(story);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF4A90E2) : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _selectedIndex = index),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Шапка карточки: заголовок + бэйдж со счётчиком фото
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              story.title,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.3),
                            ),
                          ),
                          if (photos.length > 1) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.collections, size: 14, color: Colors.black54),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${photos.length} фото',
                                    style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Bento-сетка из всех фото — сразу под заголовком
                      _BentoPhotoGrid(
                        baseUrl: baseUrl,
                        photos: photos,
                        onTap: (startIndex) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => _PhotoLightbox(
                                baseUrl: baseUrl,
                                photos: photos,
                                initialIndex: startIndex,
                              ),
                            ),
                          );
                        },
                      ),
                      // Текст показываем только когда раскрыто
                      if (isSelected) ...[
                        const SizedBox(height: 14),
                        Text(
                          story.content,
                          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Нажмите, чтобы открыть',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BENTO-GRID для фотографий
// ════════════════════════════════════════════════════════════════════════════
class _BentoPhotoGrid extends StatelessWidget {
  const _BentoPhotoGrid({
    required this.baseUrl,
    required this.photos,
    required this.onTap,
  });

  final String baseUrl;
  final List<String> photos;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    final n = photos.length;
    if (n == 0) return const SizedBox.shrink();

    if (n == 1) {
      return _tile(0, height: 220, radius: 14);
    }
    if (n == 2) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(child: _tile(0, height: 200, radius: 14, marginRight: 6)),
            Expanded(child: _tile(1, height: 200, radius: 14, marginLeft: 6)),
          ],
        ),
      );
    }
    if (n == 3) {
      return SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(flex: 2, child: _tile(0, height: 220, radius: 14, marginRight: 6)),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: _tile(1, height: 107, radius: 14, marginLeft: 6, marginBottom: 3)),
                  Expanded(child: _tile(2, height: 107, radius: 14, marginLeft: 6, marginTop: 3)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (n == 4) {
      return SizedBox(
        height: 260,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _tile(0, height: 127, radius: 14, marginRight: 3, marginBottom: 3)),
                  Expanded(child: _tile(1, height: 127, radius: 14, marginLeft: 3, marginBottom: 3)),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _tile(2, height: 127, radius: 14, marginRight: 3, marginTop: 3)),
                  Expanded(child: _tile(3, height: 127, radius: 14, marginLeft: 3, marginTop: 3)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // 5+: одна большая сверху + 4 в сетке снизу
    return Column(
      children: [
        _tile(0, height: 200, radius: 14),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: Row(
            children: List.generate(4, (i) {
              final idx = i + 1;
              final isLastVisible = i == 3;
              final extra = n - 5;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 4, right: i == 3 ? 0 : 4),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _tile(idx, height: 100, radius: 12),
                      if (isLastVisible && extra > 0)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () => onTap(idx),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '+$extra',
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _tile(int index, {
    required double height,
    required double radius,
    double marginLeft = 0,
    double marginRight = 0,
    double marginTop = 0,
    double marginBottom = 0,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        margin: EdgeInsets.only(left: marginLeft, right: marginRight, top: marginTop, bottom: marginBottom),
        height: height,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), color: Colors.grey.shade100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: aboutCollegeImageFromPath(
            baseUrl,
            photos[index],
            fit: BoxFit.cover,
            errorFallback: Container(color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// LIGHTBOX — открыть фото на весь экран, листать свайпами
// ════════════════════════════════════════════════════════════════════════════
class _PhotoLightbox extends StatefulWidget {
  const _PhotoLightbox({
    required this.baseUrl,
    required this.photos,
    required this.initialIndex,
  });

  final String baseUrl;
  final List<String> photos;
  final int initialIndex;

  @override
  State<_PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<_PhotoLightbox> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: aboutCollegeImageFromPath(
                      widget.baseUrl,
                      widget.photos[i],
                      fit: BoxFit.contain,
                      errorFallback: Container(color: Colors.black),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8, right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
            if (widget.photos.length > 1)
              Positioned(
                top: 16, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_index + 1} / ${widget.photos.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
