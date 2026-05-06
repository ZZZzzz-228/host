import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import 'career_ui.dart';

class StudentEventsScreen extends StatefulWidget {
  const StudentEventsScreen({super.key});

  @override
  State<StudentEventsScreen> createState() => _StudentEventsScreenState();
}

class _StudentEventsScreenState extends State<StudentEventsScreen> {
  final ApiClient _api = AppSession.apiClient;
  late Future<List<EventItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchEvents();
  }

  Future<void> _onRefresh() async {
    final next = _api.fetchEvents();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return CareerUi.scaffold(
      title: 'Мероприятия',
      body: HapticRefreshIndicator(
        color: const Color(0xFF4A90E2),
        onRefresh: _onRefresh,
        child: FutureBuilder<List<EventItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CareerUi.loading();
            }
            if (snapshot.hasError) {
              return CareerUi.error('Ошибка загрузки мероприятий: ${snapshot.error}');
            }
            final items = snapshot.data ?? const <EventItem>[];
            if (items.isEmpty) {
              return CareerUi.empty('Мероприятия пока не опубликованы');
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _EventCard(event: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final EventItem event;

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Дата уточняется';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$min';
  }

  Future<void> _openExternal(BuildContext context) async {
    final raw = event.externalUrl.trim();
    if (raw.isEmpty) return;
    final url = raw.contains('://') ? raw : 'https://$raw';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.coverUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                event.coverUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title.isEmpty ? 'Мероприятие' : event.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(event.startsAt),
                  style: const TextStyle(color: Colors.black54),
                ),
                if (event.location.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.location,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
                if (event.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(event.description),
                ],
                if (event.externalUrl.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => _openExternal(context),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Открыть ссылку'),
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
