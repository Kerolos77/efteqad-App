import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/domain_labels.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../../core/utils/color_generator.dart';
import '../../../../core/widgets/web/web_widgets.dart';
import '../../../common/widgets/record_visit_sheet.dart';

class WebMakhdomCard extends StatelessWidget {
  final MakhdomModel makhdom;
  final AtRiskStudentInfo? atRisk;
  final AppFormatters formatters;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback? onOpenLocation;

  const WebMakhdomCard({
    super.key,
    required this.makhdom,
    required this.atRisk,
    required this.formatters,
    required this.onCall,
    required this.onWhatsApp,
    this.onOpenLocation,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      padding: const EdgeInsets.all(18),
      onTap: () => context.push(AppRoutes.makhdomHistory(makhdom.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(makhdom, radius: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            makhdom.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (makhdom.isBrethrenOfLord) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.royalGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'إخوة رب',
                              style: TextStyle(
                                color: AppColors.royalGold,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DomainLabels(Localizations.localeOf(context)).gradeName(makhdom.grade)}${makhdom.area.isNotEmpty ? ' • ${makhdom.area}' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (atRisk != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'غائب ${formatters.formatNumber(atRisk!.consecutiveAbsences)} مرات متتالية (افتقاد عاجل)',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'حالة الافتقاد',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      makhdom.visitCount > 0
                          ? 'تم (${formatters.formatNumber(makhdom.visitCount)} زيارات)'
                          : 'في الانتظار',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: makhdom.visitCount > 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'آخر افتقاد',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      makhdom.lastVisitDate != null
                          ? formatters.formatDate(makhdom.lastVisitDate!)
                          : 'لم يُسجل',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              IconButton.filledTonal(
                icon: const Icon(
                  Icons.call_rounded,
                  size: 18,
                  color: Colors.blueAccent,
                ),
                tooltip: 'اتصال',
                onPressed: onCall,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 18,
                  color: Color(0xFF25D366),
                ),
                tooltip: 'واتساب',
                onPressed: onWhatsApp,
                visualDensity: VisualDensity.compact,
              ),
              if (onOpenLocation != null) ...[
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  icon: const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'موقع المنزل',
                  onPressed: onOpenLocation,
                  visualDensity: VisualDensity.compact,
                ),
              ],
              const Spacer(),
              FilledButton.icon(
                onPressed: () => RecordVisitSheet.show(
                  context,
                  makhdom: makhdom,
                ),
                icon: const Icon(Icons.add_task_rounded, size: 16),
                label: const Text('سجل افتقاد'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.royalGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(MakhdomModel m, {double radius = 20}) {
    final hasPhoto = m.photoUrl != null && m.photoUrl!.isNotEmpty;
    final initials = m.fullName.trim().isNotEmpty
        ? m.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';

    if (hasPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: CachedNetworkImageProvider(m.photoUrl!),
      );
    }

    final avatarColor = ColorGenerator.getColorForId(m.fullName);
    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarColor.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: avatarColor,
          fontWeight: FontWeight.w900,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
