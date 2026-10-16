import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/excel_column_labels.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/excel_import_result.dart';
import '../../../../core/services/excel_service.dart';
import '../../../../core/services/firestore_service.dart';
import 'excel_action_tile.dart';
import 'excel_import_confirm_dialog.dart';

class ExcelActionsSheet extends StatefulWidget {
  final List<MakhdomModel> currentMakhdomeen;
  final String grade;
  final FirestoreService? firestoreService;
  final Future<ExcelImportResult> Function(String grade)? picker;

  const ExcelActionsSheet({
    super.key,
    this.firestoreService,
    this.picker,
    required this.currentMakhdomeen,
    required this.grade,
  });

  @override
  State<ExcelActionsSheet> createState() => _ExcelActionsSheetState();
}

class _ExcelActionsSheetState extends State<ExcelActionsSheet> {
  late final FirestoreService _firestoreService =
      widget.firestoreService ?? FirestoreService();
  bool _isLoading = false;
  String? _statusText;

  String _getGradeLabel(String grade) {
    switch (grade) {
      case AppConstants.grade1st:
        return context.tr.grade1stName;
      case AppConstants.grade2nd:
        return context.tr.grade2ndName;
      case AppConstants.grade3rd:
        return context.tr.grade3rdName;
      default:
        return grade;
    }
  }

  Future<void> _handleDownloadTemplate() async {
    setState(() {
      _isLoading = true;
      _statusText = context.tr.messageGeneratingSharingTemplate;
    });

    try {
      final labels = ExcelColumnLabels(Localizations.localeOf(context));
      await ExcelService.generateAndShareTemplate(labels: labels);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUploadExcel() async {
    setState(() {
      _isLoading = true;
      _statusText = context.tr.messageReadingAndExtractingDataFromFile;
    });

    try {
      final result =
          await (widget.picker?.call(widget.grade) ??
              ExcelService.pickAndParseExcel(
                grade: widget.grade,
                labels: ExcelColumnLabels(Localizations.localeOf(context)),
              ));

      if (result.rows.isEmpty) {
        if (mounted) {
          if (result.hasErrors) {
            final errorSummary = result.rowErrors
                .take(3)
                .map((e) => '${e.rowIndex}: ${e.errorMessage}')
                .join('\n');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr.messageCouldNotImportAnyRowsDueTo(errorSummary),
                ),
                backgroundColor: AppColors.errorColor,
                duration: const Duration(seconds: 5),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr.excelEmptyOrCanceled)),
            );
          }
        }
        return;
      }

      // إظهار نافذة المعاينة والتأكيد مع تفاصيل السنة والأخطاء والتحذيرات
      if (!mounted) return;
      final gradeLabel = _getGradeLabel(widget.grade);

      final bool? confirm = await ExcelImportConfirmDialog.show(
        context,
        gradeLabel: gradeLabel,
        result: result,
      );

      if (confirm == true) {
        setState(() => _statusText = context.tr.messageSavingToFirebase);
        final outcome = await _firestoreService.importMakhdomeen(
          result.rows,
          onProgress: (done, total) {
            if (mounted) {
              setState(() {
                _statusText = context.tr.messageSavingToFirebase564(
                  AppFormatters(
                    Localizations.localeOf(context),
                  ).formatNumber(done),
                  AppFormatters(
                    Localizations.localeOf(context),
                  ).formatNumber(total),
                );
              });
            }
          },
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                [
                  context.tr.excelImportSuccessMsg(outcome.imported),
                  if (result.rowErrors.isNotEmpty)
                    '${AppFormatters(Localizations.localeOf(context)).formatNumber(result.rowErrors.length)} ${context.tr.messageLocalRowsExcluded}: ${result.rowErrors.map((e) => "${e.rowIndex}: ${e.errorMessage}").join(', ')}',
                  if (outcome.rejected.isNotEmpty)
                    '${AppFormatters(Localizations.localeOf(context)).formatNumber(outcome.rejected.length)} ${context.tr.messageServerRowsRejected}: ${outcome.rejected.map((r) => "${r['rowIndex']}: ${context.tr.dataUnavailable}").join(', ')}',
                ].join('; '),
              ),
              backgroundColor:
                  outcome.rejected.isEmpty && result.rowErrors.isEmpty
                  ? AppColors.successColor
                  : AppColors.warningColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExportAll() async {
    setState(() {
      _isLoading = true;
      _statusText = context.tr.messageExportingDataToExcel;
    });

    try {
      final labels = ExcelColumnLabels(Localizations.localeOf(context));
      await ExcelService.exportMakhdomeen(
        widget.currentMakhdomeen,
        labels: labels,
        title: context.tr.messageStudents726(_getGradeLabel(widget.grade)),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 12.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : AppColors.cardBorderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 18.h),

          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: FaIcon(
                  FontAwesomeIcons.fileExcel,
                  color: AppColors.successColor,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.tr.excelSheetTitle} (${_getGradeLabel(widget.grade)})',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      context.tr.messageBulkDataManagementAndSheetExports,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 12.h),
                  Text(
                    _statusText ?? (context.tr.messageProcessing),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else ...[
            ExcelActionTile(
              icon: Icons.download_for_offline_outlined,
              iconColor: AppColors.primaryLight,
              title: context.tr.excelDownloadTemplate,
              subtitle: context.tr.excelDownloadTemplateDesc,
              isDark: isDark,
              onTap: _handleDownloadTemplate,
            ),
            SizedBox(height: 10.h),

            ExcelActionTile(
              icon: Icons.upload_file_outlined,
              iconColor: AppColors.successColor,
              title: context.tr.excelImportMakhdomeen,
              subtitle:
                  '${context.tr.excelImportMakhdomeenDesc} (${_getGradeLabel(widget.grade)})',
              isDark: isDark,
              onTap: _handleUploadExcel,
            ),
            SizedBox(height: 10.h),

            ExcelActionTile(
              icon: Icons.share_outlined,
              iconColor: AppColors.accentGold,
              title:
                  '${context.tr.excelExportMakhdomeen} (${AppFormatters(Localizations.localeOf(context)).formatNumber(widget.currentMakhdomeen.length)})',
              subtitle: context.tr.excelExportMakhdomeenDesc,
              isDark: isDark,
              onTap: _handleExportAll,
            ),
          ],
        ],
      ),
    );
  }
}
