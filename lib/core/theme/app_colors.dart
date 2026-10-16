import 'package:flutter/material.dart';

/// نظام الألوان الموحد لتطبيق «الراعي»
class AppColors {
  AppColors._();

  // ألوان هوية «الراعي» - الكحلي الملكي العميق والذهبي النوراني المقدس
  static const Color sacredGold = Color(0xFFE2B542); // الذهبي النوراني المقدس
  static const Color royalGold = Color(0xFFC9A84C); // الذهبي الملكي الدافئ
  static const Color accentGold = Color(0xFFE2B542); // الذهبي الرئيسي لعناصر التمييز
  static const Color primaryColor = Color(0xFF0D1B2A); // الكحلي الملكي العميق
  static const Color primaryNavy = Color(0xFF132238); // كحلي أغمق للأسطح والبطاقات
  static const Color primaryLight = Color(0xFF1E3A8A); // أزرق ملكي كنسي متناسق
  static const Color accentIndigo = Color(0xFF4F46E5); // بنفسجي كنسي رقيق

  // ألوان شاشة البداية
  static const Color splashBgColor = Color(0xFF071931);

  // ألوان الخلفيات والأسطح (Light Mode)
  static const Color backgroundLight = Color(0xFFF8FAFC); // عاجي ناعم جداً
  static const Color surfaceLight = Colors.white;
  static const Color cardBorderLight = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0D1B2A);
  static const Color textMuted = Color(0xFF64748B);

  // ألوان الهوية الليلية (Dark Mode)
  static const Color backgroundDark = Color(0xFF070E17); // سواد كحلي فاخر
  static const Color surfaceDark = Color(0xFF0D1B2A); // كحلي ملكي عميق
  static const Color cardBorderDark = Color(0xFF1E334D); // حدود كحلية مائلة للذهبي
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color inputFillDark = Color(0xFF131D31);

  // ألوان الحالات والافتقاد
  static const Color successColor = Color(0xFF10B981); // Emerald للزيارات المكتملة
  static const Color warningColor = Color(0xFFF59E0B); // Amber للاهتمام
  static const Color errorColor = Color(0xFFEF4444); // Rose للمتأخرين
  static const Color infoColor = Color(0xFF0284C7); // Sky blue للاتصالات

  // أسماء بديلة لتوافق التخطيط الحديث (Aliases)
  static const Color cardLight = surfaceLight;
  static const Color cardDark = surfaceDark;
  static const Color borderLight = cardBorderLight;
  static const Color borderDark = cardBorderDark;
  static const Color textPrimary = textDark;
  static const Color textSecondary = textMuted;
  static const Color textSecondaryDark = textMutedDark;
  static const Color accentBlue = primaryLight;
}
