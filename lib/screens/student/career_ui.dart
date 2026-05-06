import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/centered_app_bar_title.dart';

class CareerUi {
  static Widget scaffold({
    required String title,
    required Widget body,
    bool showBackButton = true,
    Widget? floatingActionButton,
  }) {
    return _CareerScaffold(
      title: title,
      body: body,
      showBackButton: showBackButton,
      floatingActionButton: floatingActionButton,
    );
  }

  static Widget loading() => Container(
        color: const Color(0xFFF7FAFD),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );

  static Widget empty(String text) => Container(
        color: const Color(0xFFF7FAFD),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ],
        ),
      );

  static Widget error(String text) => Container(
        color: const Color(0xFFF7FAFD),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(text, style: const TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      );
}

class _CareerScaffold extends StatefulWidget {
  const _CareerScaffold({
    required this.title,
    required this.body,
    required this.showBackButton,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final bool showBackButton;
  final Widget? floatingActionButton;

  @override
  State<_CareerScaffold> createState() => _CareerScaffoldState();
}

class _CareerScaffoldState extends State<_CareerScaffold> {
  final ScrollController _scrollController = ScrollController();
  bool _showHeaderTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 10;
    if (shouldShow != _showHeaderTitle) {
      setState(() => _showHeaderTitle = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      floatingActionButton: widget.floatingActionButton,
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
              flexibleSpace: _CareerFrostedHeader(
                showCenterTitle: _showHeaderTitle,
                title: widget.title,
                showBackButton: widget.showBackButton,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
          ];
        },
        body: widget.body,
      ),
    );
  }
}

class _CareerFrostedHeader extends StatelessWidget {
  const _CareerFrostedHeader({
    required this.showCenterTitle,
    required this.title,
    required this.showBackButton,
    required this.onBack,
  });

  final bool showCenterTitle;
  final String title;
  final bool showBackButton;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: showCenterTitle ? 1 : 0,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: Colors.white.withOpacity(0.72)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (showBackButton)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: onBack,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: showCenterTitle ? 0 : 1,
                        child: const CenteredAppBarTitle(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.center,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: showCenterTitle ? 1 : 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    offset: showCenterTitle ? Offset.zero : const Offset(0, -0.15),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
