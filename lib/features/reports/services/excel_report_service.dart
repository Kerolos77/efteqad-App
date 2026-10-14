import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/platform_file_saver/platform_file_saver.dart';
import '../models/report_result.dart';

class ExcelReportService {
  /// توليد مصفوفة بايتات ملف Excel منسق بالكامل من اليمين لليسار
  static Uint8List generateExcelBytes(ReportResult report) {
    final excel = Excel.createExcel();
    final sheetName = 'التقرير';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');
    sheet.isRTL = true;

    // 1. عنوان التقرير الرئيسي
    final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(report.title);
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#1E3A8A'),
    );

    // 2. معلومات الاستخراج والفترة
    final subCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    subCell.value = TextCellValue(
      '${report.subtitle} | ${report.dateRangeText} | مستخرج التقرير: ${report.generatedBy} (${DateFormat('yyyy-MM-dd').format(report.generatedAt)})',
    );
    subCell.cellStyle = CellStyle(
      italic: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#4B5563'),
    );

    int currentRow = 3;

    // 3. قسم المؤشرات السريعة (KPIs)
    if (report.summaryKpis.isNotEmpty) {
      int colIndex = 0;
      for (var entry in report.summaryKpis.entries) {
        final labelCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: currentRow),
        );
        labelCell.value = TextCellValue(entry.key);
        labelCell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#F3F4F6'),
          horizontalAlign: HorizontalAlign.Center,
        );

        final valCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: currentRow + 1),
        );
        valCell.value = TextCellValue(entry.value);
        valCell.cellStyle = CellStyle(
          bold: true,
          fontSize: 12,
          fontColorHex: ExcelColor.fromHexString('#1E3A8A'),
          backgroundColorHex: ExcelColor.fromHexString('#F3F4F6'),
          horizontalAlign: HorizontalAlign.Center,
        );

        colIndex++;
      }
      currentRow += 3;
    }

    // 4. ترويسة أعمدة الجدول
    for (int col = 0; col < report.headers.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow),
      );
      cell.value = TextCellValue(report.headers[col].replaceAll('\n', ' '));
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }
    currentRow++;

    // 5. صفوف البيانات
    final darkRowBg = ExcelColor.fromHexString('#F8FAFC');
    final lightRowBg = ExcelColor.fromHexString('#FFFFFF');

    for (int r = 0; r < report.rows.length; r++) {
      final rowBg = (r % 2 == 0) ? lightRowBg : darkRowBg;
      for (int c = 0; c < report.rows[r].length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: currentRow),
        );
        final cellText = report.rows[r][c];

        // حفظ الهواتف والنصوص كنص صريح لتجنب مسح الصفر
        cell.value = TextCellValue(cellText);
        cell.cellStyle = CellStyle(
          backgroundColorHex: rowBg,
          horizontalAlign: (c == 0 || c == report.rows[r].length - 1)
              ? HorizontalAlign.Center
              : HorizontalAlign.Right,
        );
      }
      currentRow++;
    }

    return Uint8List.fromList(excel.encode() ?? []);
  }

  /// حفظ ملف الإكسيل محلياً على الجهاز
  static Future<String?> saveExcelToFile(ReportResult report) async {
    final bytes = generateExcelBytes(report);
    final filename =
        '${report.title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(report.generatedAt)}.xlsx';
    return PlatformFileSaver.saveAndShareFile(
      bytes: bytes,
      fileName: filename,
      openFile: true,
    );
  }

  /// مشاركة ملف الإكسيل مباشرة
  static Future<void> shareExcel(ReportResult report) async {
    final bytes = generateExcelBytes(report);
    final filename =
        '${report.title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(report.generatedAt)}.xlsx';

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: filename,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      text: report.title,
    );
  }
}
