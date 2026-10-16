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

class WebMakhdomeenDataTable extends StatelessWidget {
  final List<MakhdomModel> list;
  final Map<String, AtRiskStudentInfo> atRiskMap;
  final AppFormatters formatters;
  final void Function(String phone) onMakeCall;
  final void Function(String phone) onOpenWhatsApp;
  final void Function(String? locationUrl) onOpenLocation;
  final void Function(String text, String label) onCopy;

  const WebMakhdomeenDataTable({
    super.key,
    required this.list,
    required this.atRiskMap,
    required this.formatters,
    required this.onMakeCall,
    required this.onOpenWhatsApp,
    required this.onOpenLocation,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WebCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          columnWidths: const {
            0: FixedColumnWidth(260),
            1: FixedColumnWidth(150),
            2: FixedColumnWidth(220),
            3: FixedColumnWidth(150),
            4: FixedColumnWidth(180),
            5: FixedColumnWidth(230),
          },
          border: TableBorder(
            horizontalInside: BorderSide(
              color: isDark
                  ? AppColors.cardBorderDark.withValues(alpha: 0.5)
                  : AppColors.cardBorderLight.withValues(alpha: 0.6),
            ),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF131D31)
                    : const Color(0xFFF8FAFC),
              ),
              children: [
                _buildHeaderCell('المخدوم'),
                _buildHeaderCell('المرحلة والمنطقة'),
                _buildHeaderCell('بيانات التواصل'),
                _buildHeaderCell('حالة الافتقاد'),
                _buildHeaderCell('آخر زيارة'),
                _buildHeaderCell('الإجراءات السريعة'),
              ],
            ),
            ...list.map((m) {
              final atRisk = atRiskMap[m.id];
              return TableRow(
                children: [
                  // 1. Student Name & Avatar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAvatar(m, radius: 18),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                m.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              if (atRisk != null) ...[
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'غياب متكرر (${formatters.formatNumber(atRisk.consecutiveAbsences)})',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                              if (m.isBrethrenOfLord) ...[
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.royalGold
                                        .withValues(alpha: 0.15),
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
                        ),
                      ],
                    ),
                  ),

                  // 2. Grade & Area
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DomainLabels(Localizations.localeOf(context))
                              .gradeName(m.grade),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (m.area.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            m.area,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 3. Contact & Phone
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: SelectableText(
                            m.phone,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          tooltip: 'نسخ الرقم',
                          onPressed: () => onCopy(m.phone, 'رقم الهاتف'),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.call_rounded,
                            size: 18,
                            color: Colors.blueAccent,
                          ),
                          tooltip: 'اتصال',
                          onPressed: () => onMakeCall(m.phone),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: Color(0xFF25D366),
                          ),
                          tooltip: 'واتساب',
                          onPressed: () => onOpenWhatsApp(m.phone),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),

                  // 4. Visit Status Badge
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: m.visitCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'تم الافتقاد (${formatters.formatNumber(m.visitCount)})',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: Color(0xFFF59E0B),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'لم يُفتقد بعد',
                                  style: TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  // 5. Last Visit Date
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: m.lastVisitDate != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatters.formatDate(m.lastVisitDate!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              if (m.lastVisitNotes != null &&
                                  m.lastVisitNotes!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  m.lastVisitNotes!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          )
                        : const Text(
                            '—',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                  ),

                  // 6. Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              RecordVisitSheet.show(context, makhdom: m),
                          icon: const Icon(Icons.add_task_rounded, size: 15),
                          label: const Text('سجل افتقاد'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.royalGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        IconButton.filledTonal(
                          icon: const Icon(
                            Icons.person_outline_rounded,
                            size: 17,
                          ),
                          tooltip: 'سجل وتفاصيل المخدوم',
                          onPressed: () =>
                              context.push(AppRoutes.makhdomHistory(m.id)),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (m.homeLocationUrl != null &&
                            m.homeLocationUrl!.isNotEmpty)
                          IconButton.filledTonal(
                            icon: const Icon(
                              Icons.location_on_outlined,
                              size: 17,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'موقع المنزل',
                            onPressed: () => onOpenLocation(m.homeLocationUrl),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildAvatar(MakhdomModel m, {double radius = 18}) {
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
