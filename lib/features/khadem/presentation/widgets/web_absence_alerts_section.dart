import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../../core/widgets/web/web_widgets.dart';
import '../../../common/widgets/record_visit_sheet.dart';

class WebAbsenceAlertsSection extends StatelessWidget {
  final List<AtRiskStudentInfo> atRiskList;
  final AppFormatters formatters;
  final bool isDark;
  final void Function(String phone) onMakeCall;
  final void Function(String phone) onOpenWhatsApp;
  final VoidCallback onVisitRecorded;

  const WebAbsenceAlertsSection({
    super.key,
    required this.atRiskList,
    required this.formatters,
    required this.isDark,
    required this.onMakeCall,
    required this.onOpenWhatsApp,
    required this.onVisitRecorded,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (atRiskList.isEmpty
                          ? AppColors.successColor
                          : AppColors.errorColor)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  atRiskList.isEmpty
                      ? Icons.verified_user_rounded
                      : Icons.notifications_active_rounded,
                  color: atRiskList.isEmpty
                      ? AppColors.successColor
                      : AppColors.errorColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.tr.absenceAlertsHeader,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (atRiskList.isEmpty
                                    ? AppColors.successColor
                                    : AppColors.errorColor)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            formatters.formatNumber(atRiskList.length),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: atRiskList.isEmpty
                                  ? AppColors.successColor
                                  : AppColors.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr.absenceAlertsSubtitle,
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
          const SizedBox(height: 18),
          if (atRiskList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.successColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.successColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr.noAbsenceAlerts,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.successColor,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final int columns = width >= 1000 ? 3 : (width >= 600 ? 2 : 1);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 140,
                  ),
                  itemCount: atRiskList.length,
                  itemBuilder: (context, index) {
                    final info = atRiskList[index];
                    return _buildAtRiskStudentCard(context, info);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAtRiskStudentCard(
    BuildContext context,
    AtRiskStudentInfo info,
  ) {
    final m = info.makhdom;
    final color = info.isCritical ? AppColors.errorColor : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.6 : 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  m.fullName.isNotEmpty ? m.fullName[0] : context.tr.messageM,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    if (m.area.isNotEmpty)
                      Text(
                        m.area,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.tr.missedFridaysCount(info.consecutiveAbsences),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (m.phone.isNotEmpty) ...[
                IconButton.outlined(
                  tooltip: 'اتصال هاتفياً',
                  onPressed: () => onMakeCall(m.phone),
                  icon: const Icon(
                    Icons.phone_rounded,
                    size: 14,
                    color: AppColors.successColor,
                  ),
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: AppColors.successColor),
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(28, 28),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.outlined(
                  tooltip: 'مراسلة عبر واتساب',
                  onPressed: () => onOpenWhatsApp(m.phone),
                  icon: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    size: 14,
                    color: Colors.teal,
                  ),
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: Colors.teal),
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(28, 28),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                onPressed: () async {
                  await RecordVisitSheet.show(context, makhdom: m);
                  onVisitRecorded();
                },
                icon: const Icon(
                  Icons.edit_calendar_rounded,
                  size: 13,
                  color: Colors.white,
                ),
                label: const Text(
                  'تسجيل افتقاد',
                  style: TextStyle(fontSize: 11, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
