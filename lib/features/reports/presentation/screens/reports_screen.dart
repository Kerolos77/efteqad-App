import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../widgets/report_filter_panel.dart';
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

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firestore =
        RouterServices.maybeOf(context)?.firestore ?? FirestoreService();

    // استعلام قائمة الخدام لتمريرها في فلاتر التقارير
    final khodamStream = session.isGradeAdmin && session.grade != null
        ? firestore.getKhodamByGradeStream(session.grade!, serviceId: session.serviceId)
        : firestore.getKhodamStream(serviceId: session.serviceId);

    return Scaffold(
      backgroundColor: isDark ? AppConstants.primaryColor : AppConstants.backgroundLight,
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
        title: const Text(
          'مركز التقارير وتصدير البيانات',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
              .where((type) =>
                  _selectedCategory == null || type.category == _selectedCategory)
              .toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  children: [
                // 1. تصنيفات التقارير (Category Pills)
                _buildCategorySelector(isDark),
                const SizedBox(height: 14),

                // 2. قائمة اختيار نوع التقرير
                Text(
                  '1. اختر نوع التقرير:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...accessibleReports.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
                const SizedBox(height: 14),

                // 3. لوحة الفلاتر الديناميكية
                Text(
                  '2. تخصيص الفلاتر:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 18),

                // 4. زر استخراج ومعاينة البيانات
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _generateReport(session, khodam: khodam),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.analytics_rounded),
                  label: Text(
                    _isLoading ? 'جارٍ تجميع وحساب البيانات...' : 'استخراج ومعاينة نتائج التقرير',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppConstants.sacredGold : AppConstants.primaryLight,
                    foregroundColor: isDark ? Colors.black87 : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. بطاقة المعاينة وأزرار التصدير (PDF & Excel)
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_currentResult != null) ...[
                  _buildResultPreviewCard(isDark, _currentResult!),
                  const SizedBox(height: 16),
                  _buildExportButtons(_currentResult!),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
        },
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('جميع الأقسام'),
            selected: _selectedCategory == null,
            onSelected: (val) {
              if (val) setState(() => _selectedCategory = null);
            },
            selectedColor: isDark ? AppConstants.sacredGold : AppConstants.primaryLight,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.normal,
              color: _selectedCategory == null
                  ? (isDark ? Colors.black87 : Colors.white)
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          const SizedBox(width: 6),
          ...ReportCategory.values.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: ChoiceChip(
                avatar: Icon(cat.icon, size: 16),
                label: Text(cat.title),
                selected: isSelected,
                onSelected: (val) {
                  setState(() => _selectedCategory = val ? cat : null);
                },
                selectedColor: isDark ? AppConstants.sacredGold : AppConstants.primaryLight,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? (isDark ? Colors.black87 : Colors.white)
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultPreviewCard(bool isDark, ReportResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'تم حصر ${result.rowCount} سجل يطابق الفلاتر المحددة',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // شبكة الإحصائيات السريعة
          if (result.summaryKpis.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: result.summaryKpis.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.white60 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppConstants.sacredGold : AppConstants.primaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildExportButtons(ReportResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // زر تصدير PDF
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _exportPdf(result),
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                label: const Text(
                  'تصدير PDF 📄',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626), // أحمر أنيق للـ PDF
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // زر تصدير Excel
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _exportExcel(result),
                icon: const Icon(Icons.table_chart_rounded, color: Colors.white),
                label: const Text(
                  'تصدير Excel 📊',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A), // أخضر مميز للإكسيل
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            // زر معاينة وطباعة مباشرة
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => PdfReportService.previewOrPrint(context, result),
                icon: const Icon(Icons.print_rounded),
                label: const Text('معاينة وطباعة مباشرة 🖨️'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // زر مشاركة سريعة
            IconButton.filledTonal(
              tooltip: 'مشاركة التقرير عبر واتساب وغيره',
              icon: const Icon(Icons.share_rounded),
              onPressed: () => _showShareOptions(result),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _generateReport(SessionState session, {List<KhademModel>? khodam}) async {
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

  void _showShareOptions(ReportResult result) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'مشاركة التقرير',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                title: const Text('مشاركة بصيغة PDF'),
                onTap: () {
                  Navigator.pop(ctx);
                  PdfReportService.sharePdf(result);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_rounded, color: Colors.green),
                title: const Text('مشاركة بصيغة Excel'),
                onTap: () {
                  Navigator.pop(ctx);
                  ExcelReportService.shareExcel(result);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
