import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/api/api_client.dart';
import '../../data/session/app_session.dart';
import '../../widgets/haptic_refresh_indicator.dart';
import '../student/career_ui.dart';

class SharedPartnersScreen extends StatefulWidget {
  const SharedPartnersScreen({super.key});

  @override
  State<SharedPartnersScreen> createState() => _SharedPartnersScreenState();
}

class _SharedPartnersScreenState extends State<SharedPartnersScreen> {
  final ApiClient _api = AppSession.apiClient;
  late Future<List<PartnerItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchPartners();
  }

  Future<void> _onRefresh() async {
    final next = _api.fetchPartners();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CareerUi.appBar('Партнеры'),
      body: HapticRefreshIndicator(
        color: const Color(0xFF4A90E2),
        onRefresh: _onRefresh,
        child: FutureBuilder<List<PartnerItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CareerUi.loading();
            }
            if (snapshot.hasError) {
              return CareerUi.error('Ошибка загрузки партнеров: ${snapshot.error}');
            }
            final partners = snapshot.data ?? const <PartnerItem>[];
            if (partners.isEmpty) {
              return CareerUi.empty('Партнеры пока не опубликованы');
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: partners.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _PartnerCard(item: partners[i]),
            );
          },
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.item});

  final PartnerItem item;

  Future<void> _openWebsite(BuildContext context) async {
    final raw = item.websiteUrl.trim();
    if (raw.isEmpty) return;
    final url = raw.contains('://') ? raw : 'https://$raw';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть сайт партнера')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openWebsite(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.logoUrl.isNotEmpty
                  ? Image.network(
                      item.logoUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackLogo(),
                    )
                  : _fallbackLogo(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (item.websiteUrl.trim().isNotEmpty)
              const Icon(Icons.open_in_new, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _fallbackLogo() {
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFFE3F2FD),
      child: const Icon(Icons.business, color: Color(0xFF4A90E2)),
    );
  }
}
