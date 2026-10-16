import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// Desktop Hero branding panel for Web login split-screen view.
class WebAuthBrandingPanel extends StatelessWidget {
  const WebAuthBrandingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryNavy,
            AppColors.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.sacredGold.withValues(alpha: 0.45),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.sacredGold.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              AppConstants.appLogoPath,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),

          // App Name
          const Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Theological Verse
          Text(
            AppConstants.appTagline,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.sacredGold,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'منظومة المتابعة والافتقاد الذكية لخدمة التربية الكنسية، تتيح للخدام والأمناء رعاية المخدومين وإدارة الحضور بدقة واحترافية.',
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),

          const SizedBox(height: 36),

          // Highlights
          _buildFeatureBullet(
            icon: Icons.people_outline_rounded,
            title: 'رعاية وافتقاد المخدومين ومتابعة حالات الغياب',
          ),
          const SizedBox(height: 14),
          _buildFeatureBullet(
            icon: Icons.how_to_reg_outlined,
            title: 'تسجيل الحضور السريع والذكي في القداسات والخدمة',
          ),
          const SizedBox(height: 14),
          _buildFeatureBullet(
            icon: Icons.insights_outlined,
            title: 'إحصائيات وتقارير متقدمة وتصدير واستيراد ملفات الإكسل',
          ),

          const Spacer(),

          // Version badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'إصدار الويب ${AppConstants.appVersion}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.sacredGold, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
