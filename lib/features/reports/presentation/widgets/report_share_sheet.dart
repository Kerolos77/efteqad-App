import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/report_result.dart';
import '../../services/excel_report_service.dart';
import '../../services/pdf_report_service.dart';

class ReportShareSheet extends StatelessWidget {
  final ReportResult result;

  const ReportShareSheet({super.key, required this.result});

  static Future<void> show(BuildContext context, ReportResult result) {
    return showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => ReportShareSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'مشاركة التقرير',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.red,
                size: 24.sp,
              ),
              title: const Text('مشاركة بصيغة PDF'),
              onTap: () {
                Navigator.pop(context);
                PdfReportService.sharePdf(result);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.table_chart_rounded,
                color: Colors.green,
                size: 24.sp,
              ),
              title: const Text('مشاركة بصيغة Excel'),
              onTap: () {
                Navigator.pop(context);
                ExcelReportService.shareExcel(result);
              },
            ),
          ],
        ),
      ),
    );
  }
}
