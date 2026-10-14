import 'dart:typed_data';
import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/utils/platform_file_saver/platform_file_saver.dart';
import '../models/report_result.dart';
import '../models/report_type.dart';

class PdfReportService {
  /// توليد مصفوفة البايتات لملف PDF متكامل يدعم اللغة العربية وRTL
  static Future<Uint8List> generatePdfBytes(ReportResult report) async {
    final doc = pw.Document();

    // تحميل الخط العربي المعتمد (Cairo) للأوزان العادية والعريضة
    final regularFont = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    );

    // التحقق مما إذا كان التقرير هو بطاقة أداء خادم (لها تصميم خاص في صفحة واحدة)
    if (report.type == ReportType.servantPerformanceCard &&
        report.servantPerformance != null) {
      doc.addPage(
        _buildServantCardPage(
          report: report,
          theme: theme,
          regularFont: regularFont,
          boldFont: boldFont,
        ),
      );
    } else {
      // التقارير الجدولية العامة متعددة الصفحات
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(24),
          header: (context) => _buildReportHeader(report, context),
          footer: (context) => _buildReportFooter(context),
          build: (context) => [
            _buildKpiSummaryCards(report),
            pw.SizedBox(height: 12),
            _buildDataTable(report),
          ],
        ),
      );
    }

    return doc.save();
  }

  /// ترويسة التقرير الرسمية
  static pw.Widget _buildReportHeader(
    ReportResult report,
    pw.Context context,
  ) {
    final df = DateFormat('yyyy/MM/dd - hh:mm a');
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue900, width: 2),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // بيانات الكنيسة والتقرير
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'كنيسة الشهيد العظيم مارجرجس',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.blueGrey800,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  report.title,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  report.subtitle,
                  style: const pw.TextStyle(
                    fontSize: 9.5,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          // بيانات الاستخراج والتاريخ
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  report.dateRangeText,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.blue900,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'مستخرج التقرير: ${report.generatedBy}',
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                'تاريخ الطباعة: ${df.format(report.generatedAt)}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// كروت ملخص المؤشرات الإحصائية في رأس الصفحة
  static pw.Widget _buildKpiSummaryCards(ReportResult report) {
    if (report.summaryKpis.isEmpty) return pw.SizedBox.shrink();

    final kpiEntries = report.summaryKpis.entries.toList();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: kpiEntries.map((e) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                e.key,
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                e.value,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// جدول البيانات الرئيسي
  static pw.Widget _buildDataTable(ReportResult report) {
    if (report.rows.isEmpty) {
      return pw.Center(
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Text(
            'لا توجد سجلات تطابق الفلاتر المحددة في هذه الفترة',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
            ),
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
      columnWidths: _calculateColumnWidths(report.headers),
      children: [
        // صف الترويسة
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue900),
          children: report.headers.map((h) {
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 4,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                h,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            );
          }).toList(),
        ),

        // صفوف البيانات
        for (int r = 0; r < report.rows.length; r++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: r % 2 == 0 ? PdfColors.white : PdfColors.blueGrey50,
            ),
            children: [
              for (int c = 0; c < report.rows[r].length; c++)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 4,
                  ),
                  alignment: c == 0 || c == report.rows[r].length - 1
                      ? pw.Alignment.center
                      : pw.Alignment.centerRight,
                  child: pw.Text(
                    report.rows[r][c],
                    textAlign: c == 0 || c == report.rows[r].length - 1
                        ? pw.TextAlign.center
                        : pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: c == 1 ? pw.FontWeight.bold : pw.FontWeight.normal,
                      color: PdfColors.black,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// تذييل الصفحة مع الترقيم
  static pw.Widget _buildReportFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'تطبيق افتقاد - نظام الإدارة الرعوية',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// تصميم بطاقة أداء الخادم (صفحة واحدة ملخصة)
  static pw.Page _buildServantCardPage({
    required ReportResult report,
    required pw.ThemeData theme,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    final perf = report.servantPerformance!;
    final khadem = perf.khadem;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // الترويسة
            _buildReportHeader(report, context),

            // كارت معلومات الخادم
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue800,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        khadem.name,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'الهاتف: ${khadem.phone.isNotEmpty ? khadem.phone : "غير مسجل"} | البريد: ${khadem.email}',
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: PdfColors.blueGrey100,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.amber600,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'نسبة التغطية: ${perf.coverageRate.toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // شبكة المؤشرات الرقمية للخادم
            pw.Row(
              children: [
                _buildKpiBox('إجمالي المخدومين', '${perf.assignedMakhdomeenCount}'),
                pw.SizedBox(width: 8),
                _buildKpiBox(
                  'نسبة حضور أولاده',
                  '${perf.averageAttendanceRate.toStringAsFixed(1)}%',
                ),
                pw.SizedBox(width: 8),
                _buildKpiBox('زيارات منزلية', '${perf.homeVisitsCount}'),
                pw.SizedBox(width: 8),
                _buildKpiBox('مكالمات هاتفية', '${perf.phoneCallsCount}'),
                pw.SizedBox(width: 8),
                _buildKpiBox('إجمالي الافتقادات', '${perf.totalVisits}'),
              ],
            ),
            pw.SizedBox(height: 14),

            // عنوان جدول أولاد الخادم
            pw.Text(
              'كشف وموقف مخدومي الخادم:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 6),

            // جدول أولاد الخادم
            pw.Expanded(
              child: _buildDataTable(report),
            ),

            // قسم الحالات الحرجة / التنبيه
            if (perf.atRiskMakhdomeen.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.red300),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      '⚠️ تنبيه رعوي: ',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red900,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        'يوجد ${perf.atRiskMakhdomeen.length} مخدومين لم يتم افتقادهم لأكثر من 30 يوماً ويحتاجون تدخلاً عاجلاً.',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.red800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            pw.SizedBox(height: 8),
            _buildReportFooter(context),
          ],
        );
      },
    );
  }

  static pw.Widget _buildKpiBox(String title, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              title,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Map<int, pw.TableColumnWidth> _calculateColumnWidths(
    List<String> headers,
  ) {
    final map = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < headers.length; i++) {
      if (i == 0) {
        // م
        map[i] = const pw.FixedColumnWidth(22);
      } else if (headers[i].contains('اسم') || headers[i].contains('الاسم')) {
        map[i] = const pw.FlexColumnWidth(2.5);
      } else if (headers[i].contains('هاتف') || headers[i].contains('الهاتف')) {
        map[i] = const pw.FlexColumnWidth(1.6);
      } else if (headers[i].contains('عنوان') || headers[i].contains('العنوان')) {
        map[i] = const pw.FlexColumnWidth(2.2);
      } else if (headers[i].contains('ملاحظات')) {
        map[i] = const pw.FlexColumnWidth(2.0);
      } else {
        map[i] = const pw.FlexColumnWidth(1.2);
      }
    }
    return map;
  }

  // ==========================================
  // وظائف التصدير والمعاينة والمشاركة
  // ==========================================

  /// معاينة وطباعة التقرير مباشرة داخل التطبيق
  static Future<void> previewOrPrint(
    BuildContext context,
    ReportResult report,
  ) async {
    final pdfBytes = await generatePdfBytes(report);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '${report.title}_${DateFormat('yyyyMMdd').format(report.generatedAt)}.pdf',
    );
  }

  /// مشاركة ملف الـ PDF فورياً (عبر واتساب أو أي تطبيق)
  static Future<void> sharePdf(ReportResult report) async {
    final pdfBytes = await generatePdfBytes(report);
    final filename =
        '${report.title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(report.generatedAt)}.pdf';
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }

  /// تنزيل وحفظ ملف الـ PDF محلياً على الجهاز
  static Future<String?> savePdfToFile(ReportResult report) async {
    final pdfBytes = await generatePdfBytes(report);
    final filename =
        '${report.title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(report.generatedAt)}.pdf';
    return PlatformFileSaver.saveAndShareFile(
      bytes: pdfBytes,
      fileName: filename,
      openFile: true,
    );
  }
}
