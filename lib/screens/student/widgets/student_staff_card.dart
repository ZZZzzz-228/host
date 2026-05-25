import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/api/api_client.dart';
import '../../../data/session/app_session.dart';

class StudentStaffCard extends StatelessWidget {
  const StudentStaffCard({
    super.key,
    required this.member,
    this.gradientColors,
  });

  final StaffMemberItem member;
  final List<Color>? gradientColors;

  String _toAbsoluteUrl(String value) {
    if (value.isEmpty) return value;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final rawBase = AppSession.apiClient.baseUrl;
    final trimmedBase =
        rawBase.endsWith('/') ? rawBase.substring(0, rawBase.length - 1) : rawBase;
    String origin = trimmedBase;
    try {
      final uri = Uri.parse(trimmedBase);
      if (uri.hasScheme && uri.host.isNotEmpty) {
        origin = uri.hasPort
            ? '${uri.scheme}://${uri.host}:${uri.port}'
            : '${uri.scheme}://${uri.host}';
      }
    } catch (_) {}
    if (value.startsWith('/api/')) return '$origin$value';
    if (value.startsWith('/')) return '$origin/api/public$value';
    return '$origin/api/public/$value';
  }

  Color? _parseColorHex(String value) {
    final hex = value.trim();
    if (hex.isEmpty) return null;
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    if (cleaned.length != 6) return null;
    try {
      return Color(int.parse('0xFF$cleaned'));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColor = _parseColorHex(member.colorHex);
    final colors = gradientColors ??
        (customColor != null
            ? [customColor, customColor.withOpacity(0.84)]
            : [const Color(0xFF4A90E2), const Color(0xFF64B5F6)]);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(child: _buildPhoto(member.photoUrl)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Text(
                  member.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  member.positionTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colors[0]),
                ),
                if (member.email.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ContactRow(
                    icon: Icons.email,
                    text: member.email,
                    color: colors[0],
                    onTap: () => launchUrl(
                      Uri.parse('mailto:${member.email}'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
                if (member.phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ContactRow(
                    icon: Icons.phone,
                    text: member.phone,
                    color: colors[0],
                    onTap: () {
                      final clean =
                          member.phone.replaceAll(RegExp(r'[^\d+]'), '');
                      launchUrl(
                        Uri.parse('tel:$clean'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ],
                if (member.officeHours.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    member.officeHours,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(String photoUrl) {
    final fallback = Image.asset(
      'assets/images/application_logo/icon42.png',
      fit: BoxFit.cover,
    );
    if (photoUrl.trim().isEmpty) return fallback;
    return Image.network(
      _toAbsoluteUrl(photoUrl.trim()),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}
