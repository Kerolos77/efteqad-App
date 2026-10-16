import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/report_result.dart';

class ReportExportActions extends StatelessWidget {
  final ReportResult result;
  final VoidCallback onExportPdf;
  final VoidCallback onExportExcel;
  final VoidCallback onPreviewOrPrint;
  final VoidCallback onShowShare;

  const ReportExportActions({
    super.key,
    required this.result,
    required this.onExportPdf,
    required this.onExportExcel,
    required this.onPreviewOrPrint,
    required this.onShowShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // زر تصدير PDF
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onExportPdf,
                icon: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  'تصدير PDF 📄',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),

            // زر تصدير Excel
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onExportExcel,
                icon: const Icon(
                  Icons.table_chart_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  'تصدير Excel 📊',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        Row(
          children: [
            // زر معاينة وطباعة مباشرة
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPreviewOrPrint,
                icon: const Icon(Icons.print_rounded),
                label: const Text('معاينة وطباعة مباشرة 🖨️'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 11.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),

            // زر مشاركة سريعة
            IconButton.filledTonal(
              tooltip: 'مشاركة التقرير عبر واتساب وغيره',
              icon: Icon(Icons.share_rounded, size: 20.sp),
              onPressed: onShowShare,
            ),
          ],
        ),
      ],
    );
  }
}
