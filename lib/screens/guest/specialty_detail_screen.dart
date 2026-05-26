import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/session/app_session.dart';
import 'about_college_media.dart';
import 'about_college_models.dart';

class SpecialtyDetailScreen extends StatelessWidget {
  final Specialty specialty;
  const SpecialtyDetailScreen({super.key, required this.specialty});

  Future<void> _onSubmitTap(BuildContext context) async {
    final urlStr = specialty.gosuslugiUrl.trim();

    if (urlStr.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ссылка для подачи документов пока не указана'),
          ),
        );
      }
      return;
    }

    try {
      final url = Uri.parse(urlStr);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть ссылку')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = AppSession.apiClient.baseUrl;
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 200, pinned: true, backgroundColor: specialty.color,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [specialty.color, specialty.color.withOpacity(0.72)],
                ),
              ),
              child: Stack(fit: StackFit.expand, children: [
                aboutCollegeImageFromPath(
                  baseUrl,
                  specialty.imagePath,
                  fit: BoxFit.cover,
                  errorFallback: const SizedBox(),
                ),
                Container(color: Colors.black.withOpacity(0.28)),
                Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(specialty.icon, color: Colors.white, size: 48),
                  ),
                ])),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: specialty.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(specialty.code, style: TextStyle(color: specialty.color, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            Text(specialty.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: specialty.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.workspace_premium, color: specialty.color, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Квалификация: ${specialty.qualification}',
                  style: TextStyle(fontSize: 13, color: specialty.color, fontWeight: FontWeight.w600),
                )),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(children: [
                Expanded(child: _buildInfoChip(Icons.schedule, 'Срок обучения', specialty.duration, specialty.color)),
                Container(width: 1, height: 48, color: Colors.grey.shade300),
                Expanded(child: _buildInfoChip(Icons.school, 'Форма', specialty.form, specialty.color)),
              ]),
            ),

            // ═════════ КРАСИВЫЙ БЛОК ПРИЁМА ═════════
            const SizedBox(height: 12),
            _buildAdmissionBlock(specialty),
            // ═══════════════════════════════════════════

            const SizedBox(height: 20),
            const Text('О специальности', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(specialty.description, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6)),
            const SizedBox(height: 20),
            _buildSpecialtyInfoBlock(Icons.work_outline, 'Кем работать', specialty.career, specialty.color),
            const SizedBox(height: 12),
            _buildSpecialtyInfoBlock(Icons.build_outlined, 'Ключевые навыки', specialty.skills, specialty.color),
            const SizedBox(height: 12),
            _buildSpecialtyInfoBlock(Icons.payments_outlined, 'Зарплата выпускников', specialty.salary, specialty.color),
            const SizedBox(height: 28),
            ValueListenableBuilder<Set<String>>(
              valueListenable: FavoriteSpecialtyStore.instance.favorites,
              builder: (context, favorites, _) {
                final isFav = favorites.contains(specialty.id);
                return Row(children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: IconButton(
                      onPressed: () => FavoriteSpecialtyStore.instance.toggle(specialty.id),
                      icon: Icon(
                        isFav ? Icons.star : Icons.star_border,
                        color: isFav ? const Color(0xFFFFD54F) : Colors.grey[600],
                      ),
                      tooltip: 'Хочу эту специальность',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _onSubmitTap(context),
                      icon: const Icon(Icons.description_outlined),
                      label: const Text(
                        'Подать документы',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: specialty.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ]),
        )),
      ]),
    );
  }

  /// Красивый блок "Условия приёма" в едином стиле с верхней карточкой:
  /// серый фон Colors.grey[50], тонкая граница, внутри — белые "плитки"
  /// с иконками в фирменном цвете специальности.
  Widget _buildAdmissionBlock(Specialty s) {
    final hasAnyInfo = s.base9 || s.base11 || s.hasBudget;
    if (!hasAnyInfo) return const SizedBox.shrink();

    final accent = s.color;
    const greenBudget = Color(0xFF2E7D32);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(children: [
            Icon(Icons.school_outlined, color: accent, size: 18),
            const SizedBox(width: 8),
            Text(
              'Условия приёма',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accent,
                letterSpacing: 0.2,
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // ── База 9 / База 11 — две плитки в ряд (как Срок/Форма выше) ──
          Row(
            children: [
              Expanded(
                child: _admissionTile(
                  icon: Icons.looks_one_rounded,
                  label: 'На базе',
                  value: '9 классов',
                  active: s.base9,
                  accent: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _admissionTile(
                  icon: Icons.looks_two_rounded,
                  label: 'На базе',
                  value: '11 классов',
                  active: s.base11,
                  accent: accent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Бюджет: плитка во всю ширину ──
          if (s.hasBudget)
            _budgetTile(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Есть бюджетные места',
              subtitle: s.budgetSeats > 0
                  ? 'Количество мест: ${s.budgetSeats}'
                  : 'Количество мест уточняется',
              color: greenBudget,
            )
          else
            _budgetTile(
              icon: Icons.payments_outlined,
              title: 'Только платное обучение',
              subtitle: 'Бюджетных мест не предусмотрено',
              color: Colors.orange.shade700,
            ),
        ],
      ),
    );
  }

  /// Плитка база 9 / база 11 — в стиле _buildInfoChip (белая + иконка фирменного цвета).
  Widget _admissionTile({
    required IconData icon,
    required String label,
    required String value,
    required bool active,
    required Color accent,
  }) {
    final fg = active ? accent : Colors.grey.shade400;
    final valueColor = active ? Colors.black87 : Colors.grey.shade500;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? accent.withOpacity(0.25) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!active) ...[
                Icon(Icons.do_not_disturb_alt_rounded, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    decoration: active ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Плитка "Есть бюджет / только платно" — белая, с цветной иконкой слева.
  Widget _budgetTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildSpecialtyInfoBlock(IconData icon, String title, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
          ])),
        ],
      ),
    );
  }
}
