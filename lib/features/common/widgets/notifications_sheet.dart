import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/router_services.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/session/session_cubit.dart';
import 'notification_list.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final services = RouterServices.maybeOf(context);
    final userId =
        (services?.session ?? context.read<SessionCubit>()).state.userId;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: (services?.firestore ?? FirestoreService())
          .watchUnreadNotificationCount(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return IconButton(
            icon: Icon(Icons.error_outline_rounded, size: 24.r),
            tooltip: AppFailure.fromException(
              snapshot.error!,
            ).localizedMessage(context.tr),
            onPressed: () => NotificationsSheet.show(context),
          );
        }
        if (!snapshot.hasData) {
          return SizedBox(
            width: 48.r,
            height: 48.r,
            child: Center(
              child: SizedBox(
                width: 16.r,
                height: 16.r,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final unreadCount = snapshot.data!;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, size: 24.r),
              tooltip: context.tr.messageNotifications,
              onPressed: () => NotificationsSheet.show(context),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: const BoxDecoration(
                    color: AppColors.errorColor,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16.r,
                    minHeight: 16.r,
                  ),
                  child: Text(
                    unreadCount > 9
                        ? '9+'
                        : AppFormatters(
                            Localizations.localeOf(context),
                          ).formatNumber(unreadCount),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    final services = RouterServices.maybeOf(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => services == null
          ? const NotificationsSheet()
          : RouterServices(
              firestore: services.firestore,
              session: services.session,
              child: const NotificationsSheet(),
            ),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  int _revision = 0;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final services = RouterServices.maybeOf(context);
    final userId =
        (services?.session ?? context.read<SessionCubit>()).state.userId;
    final firestoreService = services?.firestore ?? FirestoreService();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
            width: 44.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(20.w, 8.h, 20.w, 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primaryLight,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      context.tr.messageNotificationsCenter616,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    if (userId != null) {
                      try {
                        await firestoreService.markAllNotificationsAsRead(
                          userId,
                        );
                        if (mounted) setState(() => _revision++);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppFailure.fromException(
                                  e,
                                ).localizedMessage(context.tr),
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text(
                    context.tr.messageMarkAllRead,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notifications Stream
          Expanded(
            child: NotificationList(
              key: ValueKey(_revision),
              onNotificationTapped: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
