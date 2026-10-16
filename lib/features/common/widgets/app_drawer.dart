import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/service_model.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/router_services.dart';
import '../../../core/services/app_version_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/session/session_cubit.dart';
import '../../../core/utils/color_generator.dart';
import '../../../main.dart';
import '../../admin/presentation/widgets/service_setup_dialog.dart';
import 'app_drawer_header.dart';
import 'app_drawer_tile.dart';
import 'app_update_dialog.dart';

class AppDrawer extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback? onOpenExcel;

  const AppDrawer({super.key, required this.isAdmin, this.onOpenExcel});

  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.errorColor, size: 22.r),
            SizedBox(width: 8.w),
            Text(
              context.tr.signOutConfirmTitle,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ],
        ),
        content: Text(context.tr.signOutConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.tr.signOut,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final session =
          RouterServices.maybeOf(context)?.session ??
          context.read<SessionCubit>();
      try {
        await session.signOut();
        if (context.mounted) context.go(AppRoutes.loginPath);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.tr.dataUnavailable)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark;
        final session =
            RouterServices.maybeOf(context)?.session.state ??
            context.watch<SessionCubit>().state;
        final user = session.profile;
        final khademColor = ColorGenerator.getColorForId(
          user?.email ?? user?.id,
        );

        return Drawer(
          backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(28.r),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // الهيدر العصري
                AppDrawerHeader(
                  isAdmin: isAdmin,
                  user: user,
                  isDark: isDark,
                  khademColor: khademColor,
                ),
                SizedBox(height: 8.h),

                // قائمة الخيارات والتنقل
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    children: [
                      if (isAdmin) ...[
                        AppDrawerTile(
                          icon: Icons.dashboard_outlined,
                          title: context.tr.mainDashboard,
                          onTap: () {
                            final target = AppRoutes.landing(session);
                            Navigator.pop(context);
                            context.go(target);
                          },
                          isDark: isDark,
                        ),
                        if (session.isStageAdmin)
                          StreamBuilder<ServiceModel?>(
                            stream: (RouterServices.maybeOf(context)?.firestore ??
                                    FirestoreService())
                                .watchService(session.serviceId),
                            builder: (context, snap) {
                              final service = snap.data;
                              if (service == null) return const SizedBox.shrink();
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AppDrawerTile(
                                    icon: Icons.tune_rounded,
                                    title: 'تخصيص الخدمة والصفوف',
                                    color: AppColors.sacredGold,
                                    onTap: () {
                                      Navigator.pop(context);
                                      ServiceSetupDialog.show(
                                        context,
                                        service: service,
                                        firestoreService:
                                            RouterServices.maybeOf(context)
                                                    ?.firestore ??
                                                FirestoreService(),
                                      );
                                    },
                                    isDark: isDark,
                                  ),
                                  if (service.grades.isNotEmpty)
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent,
                                      ),
                                      child: ExpansionTile(
                                        tilePadding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 0,
                                        ),
                                        leading: Icon(
                                          Icons.school_outlined,
                                          size: 20.r,
                                        ),
                                        title: Text(
                                          'صفوف الخدمة (${service.grades.length})',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        children: service.grades.map((g) {
                                          return ListTile(
                                            dense: true,
                                            contentPadding:
                                                EdgeInsetsDirectional.only(
                                              start: 36.w,
                                              end: 16.w,
                                            ),
                                            leading: Icon(
                                              Icons.arrow_right_rounded,
                                              size: 20.r,
                                            ),
                                            title: Text(
                                              g.name,
                                              style: TextStyle(
                                                fontSize: 12.5.sp,
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              context.go(
                                                AppRoutes.gradeMakhdomeen(g.id),
                                              );
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        if (onOpenExcel != null)
                          AppDrawerTile(
                            icon: Icons.table_chart_outlined,
                            title: context.tr.excelTools,
                            onTap: () {
                              Navigator.pop(context);
                              onOpenExcel!();
                            },
                            isDark: isDark,
                          ),
                      ] else ...[
                        AppDrawerTile(
                          icon: Icons.people_alt_outlined,
                          title: context.tr.myGroupAndVisits,
                          onTap: () {
                            final target = AppRoutes.landing(session);
                            Navigator.pop(context);
                            context.go(target);
                          },
                          isDark: isDark,
                        ),
                        AppDrawerTile(
                          icon: Icons.person_outline_rounded,
                          title: context.tr.servantProfile,
                          onTap: () {
                            Navigator.pop(context);
                            context.push(AppRoutes.profilePath);
                          },
                          isDark: isDark,
                        ),
                      ],
                      AppDrawerTile(
                        icon: Icons.how_to_reg_outlined,
                        title: 'الحضور والغياب',
                        onTap: () {
                          final target = AppRoutes.attendanceHubFor(session);
                          Navigator.pop(context);
                          context.go(target);
                        },
                        isDark: isDark,
                      ),
                      AppDrawerTile(
                        icon: Icons.assessment_outlined,
                        title: 'مركز التقارير وتصدير البيانات',
                        color: AppColors.sacredGold,
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.reportsPath);
                        },
                        isDark: isDark,
                      ),

                      SizedBox(height: 6.h),
                      Divider(
                        color: isDark
                            ? AppColors.cardBorderDark
                            : AppColors.cardBorderLight,
                        indent: 8.w,
                        endIndent: 8.w,
                      ),
                      SizedBox(height: 6.h),

                      // زر التبديل السريع للمظهر (الداكن / الفاتح)
                      _buildThemeToggleTile(context, isDark),

                      // صفحة الإعدادات الشاملة
                      AppDrawerTile(
                        icon: Icons.settings_outlined,
                        title: context.tr.generalSettings,
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.settingsPath);
                        },
                        isDark: isDark,
                      ),

                      // التحقق من التحديثات وصفحة تحميل التطبيق
                      AppDrawerTile(
                        icon: Icons.system_update_rounded,
                        title: 'تحديث التطبيق / التحميل',
                        color: AppColors.sacredGold,
                        onTap: () async {
                          final rootNavigator = Navigator.of(
                            context,
                            rootNavigator: true,
                          );
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          Navigator.pop(context);
                          final info = await AppVersionService.shared
                              .checkVersion();
                          if (info.isUpdateAvailable() &&
                              rootNavigator.mounted) {
                            await AppUpdateDialog.show(
                              rootNavigator.context,
                              versionInfo: info,
                            );
                          } else {
                            await AppVersionService.shared.openDownloadPage(
                              info.downloadUrl,
                            );
                            messenger?.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'أنت على أحدث إصدار (v${AppConstants.appVersion}) — تم فتح صفحة التحميل',
                                ),
                                backgroundColor: AppColors.successColor,
                              ),
                            );
                          }
                        },
                        isDark: isDark,
                      ),

                      // تسجيل الخروج
                      AppDrawerTile(
                        icon: Icons.logout_rounded,
                        title: context.tr.signOut,
                        color: AppColors.errorColor,
                        onTap: () => _handleLogout(context),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // الفوتر
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 16.h,
                    horizontal: 20.w,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            size: 14.r,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            context.tr.shepherdVerseShort,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${context.tr.appName} ${context.tr.version(AppConstants.appVersion)}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeToggleTile(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        leading: Icon(
          isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          color: isDark ? Colors.amber : AppColors.primaryLight,
          size: 22.r,
        ),
        title: Text(
          isDark ? context.tr.darkMode : context.tr.lightMode,
          style: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        trailing: Switch(
          value: isDark,
          activeThumbColor: Colors.amber,
          onChanged: (val) {
            themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
          },
        ),
        dense: true,
      ),
    );
  }
}
