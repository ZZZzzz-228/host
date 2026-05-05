import 'package:flutter/material.dart';

import '../widgets/centered_app_bar_title.dart';

class CareerUi {
  static PreferredSizeWidget appBar(String title) {
    return AppBar(
      centerTitle: true,
      title: const CenteredAppBarTitle(),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(28),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  static Widget loading() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );

  static Widget empty(String text) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(child: Text(text)),
        ],
      );

  static Widget error(String text) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [Text(text)],
      );
}
