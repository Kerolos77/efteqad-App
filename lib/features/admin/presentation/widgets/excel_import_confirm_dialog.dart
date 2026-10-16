import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:efteqad/core/localization/app_formatters.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/excel_import_result.dart';

class ExcelImportConfirmDialog extends StatelessWidget {
  final String gradeLabel;
  final ExcelImportResult result;

  const ExcelImportConfirmDialog({
    super.key,
    required this.gradeLabel,
    required this.result,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String gradeLabel,
    required ExcelImportResult result,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ExcelImportConfirmDialog(
        gradeLabel: gradeLabel,
        result: result,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Text(context.tr.excelConfirmImportTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.messageTargetGrade(gradeLabel),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryLight,
              ),
            ),
            SizedBox(height: 8.h),
            Text(context.tr.excelConfirmImportPrompt(result.rows.length)),
            Builder(
              builder: (context) {
                final detectedClasses = <String>{};
                for (final r in result.rows) {
                  if (r.className != null && r.className!.trim().isNotEmpty) {
                    detectedClasses.add(r.className!.trim());
                  }
                }
                if (detectedClasses.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.diversity_3_rounded,
                          size: 16.sp,
                          color: AppColors.primaryLight,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'تم رصد ${detectedClasses.length} فصول بالملف: ${detectedClasses.join("، ")}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (result.hasErrors) ...[
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  context.tr.messageRowsExcluded(
                    AppFormatters(
                      Localizations.localeOf(context),
                    ).formatNumber(result.rowErrors.length),
                    result.rowErrors
                        .map((e) => "${e.rowIndex}: ${e.errorMessage}")
                        .join('\n'),
                  ),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (result.hasWarnings) ...[
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.warnings
                      .map(
                        (w) => Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: Text(
                            '• $w',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: AppColors.warningColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.successColor,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.tr.excelImportNowBtn),
        ),
      ],
    );
  }
}
