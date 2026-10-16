import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/router/router_services.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/session/session_state.dart';
import '../../../common/widgets/app_drawer.dart';
import '../../models/report_filter_data.dart';
import '../../models/report_result.dart';
import '../../models/report_type.dart';
import '../../services/excel_report_service.dart';
import '../../services/pdf_report_service.dart';
import '../../services/reports_data_service.dart';
import '../widgets/report_category_selector.dart';
import '../widgets/report_export_actions.dart';
import '../widgets/report_filter_panel.dart';
import '../widgets/report_result_preview_card.dart';
import '../widgets/report_share_sheet.dart';
import '../widgets/report_type_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportCategory? _selectedCategory;
  ReportType _selectedType = ReportType.visitationLog;
  late ReportFilterData _filters;
  final ReportsDataService _reportsDataService = ReportsDataService();

  bool _isLoading = false;
  ReportResult? _currentResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionCubit>().state;
    _filters = ReportFilterData(
      serviceId: session.serviceId,
      grade: session.isGradeAdmin ? session.grade : 'all',
      khademId: session.isServant ? session.userId : 'all',
    );
  }

  Future<void> _generateReport(
    SessionState session, {
    List<KhademModel>? khodam,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _reportsDataService.generateReport(
        type: _selectedType,
        filters: _filters,
        session: session,
        availableKhodam: khodam,
      );

      setState(() {
        _currentResult = res;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء تجميع التقرير: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPdf(ReportResult result) async {
    try {
      final savedPath = await PdfReportService.savePdfToFile(result);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ ملف الـ PDF بنجاح: ${savedPath ?? ""}'),
          action: (savedPath != null && savedPath.isNotEmpty)
              ? SnackBarAction(
                  label: 'فتح الملف',
                  onPressed: () => OpenFilex.open(savedPath),
                )
              : null,
          backgroundColor: Colors.green.shade800,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حفظ ملف الـ PDF: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  Future<void> _exportExcel(ReportResult result) async {
    try {
      final savedPath = await ExcelReportService.saveExcelToFile(result);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ ملف الـ Excel بنجاح: ${savedPath ?? ""}'),
          action: (savedPath != null && savedPath.isNotEmpty)
              ? SnackBarAction(
                  label: 'فتح الملف',
                  onPressed: () => OpenFilex.open(savedPath),
                )
              : null,
          backgroundColor: Colors.green.shade800,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حفظ ملف الـ Excel: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firestore =
        RouterServices.maybeOf(context)?.firestore ?? FirestoreService();

    // استعلام قائمة الخدام لتمريرها في فلاتر التقارير
    final khodamStream = session.isGradeAdmin && session.grade != null
        ? firestore.getKhodamByGradeStream(
            session.grade!,
            serviceId: session.serviceId,
          )
        : firestore.getKhodamStream(serviceId: session.serviceId);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.primaryColor : AppColors.backgroundLight,
      drawer: AppDrawer(isAdmin: session.isStageAdmin || session.isGradeAdmin),
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'رجوع',
                onPressed: () => Navigator.of(context).pop(),
              )
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  tooltip: 'القائمة الرئيسية',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        title: Text(
          'مركز التقارير وتصدير البيانات',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث واستخراج التقرير',
            onPressed: () => _generateReport(session),
          ),
        ],
      ),
      body: StreamBuilder<List<KhademModel>>(
        stream: khodamStream,
        builder: (context, snapshot) {
          final khodam = snapshot.data ?? [];

          // تصفية أنواع التقارير المتاحة للمستخدم حسب الرتبة والصلاحية
          final accessibleReports = ReportType.values
              .where((type) => type.isAccessibleBy(session))
              .where(
                (type) =>
                    _selectedCategory == null ||
                    type.category == _selectedCategory,
              )
              .toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  children: [
                    // 1. تصنيفات التقارير (Category Pills)
                    ReportCategorySelector(
                      selectedCategory: _selectedCategory,
                      isDark: isDark,
                      onCategorySelected: (cat) {
                        setState(() => _selectedCategory = cat);
                      },
                    ),
                    SizedBox(height: 14.h),

                    // 2. قائمة اختيار نوع التقرير
                    Text(
                      '1. اختر نوع التقرير:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ...accessibleReports.map((type) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: ReportTypeCard(
                          type: type,
                          isSelected: _selectedType == type,
                          onTap: () {
                            setState(() {
                              _selectedType = type;
                              _currentResult = null; // إعادة تعيين المعاينة
                            });
                          },
                        ),
                      );
                    }),
                    SizedBox(height: 14.h),

                    // 3. لوحة الفلاتر الديناميكية
                    Text(
                      '2. تخصيص الفلاتر:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ReportFilterPanel(
                      selectedType: _selectedType,
                      filters: _filters,
                      session: session,
                      availableKhodam: khodam,
                      onFiltersChanged: (newFilters) {
                        setState(() {
                          _filters = newFilters;
                          _currentResult = null;
                        });
                      },
                    ),
                    SizedBox(height: 18.h),

                    // 4. زر استخراج ومعاينة البيانات
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () =>
                              _generateReport(session, khodam: khodam),
                      icon: _isLoading
                          ? SizedBox(
                              width: 18.w,
                              height: 18.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.analytics_rounded, size: 20.sp),
                      label: Text(
                        _isLoading
                            ? 'جارٍ تجميع وحساب البيانات...'
                            : 'استخراج ومعاينة نتائج التقرير',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.sacredGold
                            : AppColors.primaryLight,
                        foregroundColor:
                            isDark ? Colors.black87 : Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // 5. بطاقة المعاينة وأزرار التصدير (PDF & Excel)
                    if (_errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_currentResult != null) ...[
                      ReportResultPreviewCard(
                        result: _currentResult!,
                        isDark: isDark,
                      ),
                      SizedBox(height: 16.h),
                      ReportExportActions(
                        result: _currentResult!,
                        onExportPdf: () => _exportPdf(_currentResult!),
                        onExportExcel: () => _exportExcel(_currentResult!),
                        onPreviewOrPrint: () =>
                            PdfReportService.previewOrPrint(
                              context,
                              _currentResult!,
                            ),
                        onShowShare: () =>
                            ReportShareSheet.show(context, _currentResult!),
                      ),
                    ],
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
