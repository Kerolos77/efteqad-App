import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/notification_intent_coordinator.dart';
import '../../../../core/router/router_services.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/widgets/paged_content.dart';
import 'notification_card.dart';

class NotificationList extends StatefulWidget {
  final VoidCallback? onNotificationTapped;

  const NotificationList({super.key, this.onNotificationTapped});
  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  final Set<String> _readIds = {};

  String _formatTime(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return context.tr.messageJustNow;
    } else if (diff.inMinutes < 60) {
      return context.tr.messageMAgo(
        AppFormatters(
          Localizations.localeOf(context),
        ).formatNumber(diff.inMinutes),
      );
    } else if (diff.inHours < 24) {
      return context.tr.messageHAgo(
        AppFormatters(
          Localizations.localeOf(context),
        ).formatNumber(diff.inHours),
      );
    } else if (diff.inDays < 7) {
      return context.tr.messageDAgo(
        AppFormatters(
          Localizations.localeOf(context),
        ).formatNumber(diff.inDays),
      );
    } else {
      return AppFormatters(
        Localizations.localeOf(context),
      ).formatDate(date, format: 'yyyy/MM/dd');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final services = RouterServices.maybeOf(context);
    final userId =
        (services?.session ?? context.read<SessionCubit>()).state.userId;
    final firestoreService = services?.firestore ?? FirestoreService();

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return PagedContent<NotificationModel>(
      queryKey: userId,
      fetch: (cursor) =>
          firestoreService.fetchNotificationPage(uid: userId, cursor: cursor),
      emptyWidget: Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(18.r),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_off_outlined,
                  size: 40.r,
                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                context.tr.messageNoNotificationsYet,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.sp,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                context.tr.messageTaskAssignmentsAndAlertsWillAppearHere,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
      builder: (context, notifications, more) {
        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemCount: notifications.length + (more != null ? 1 : 0),
          separatorBuilder: (_, __) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            if (index == notifications.length) return more!;
            final n = notifications[index];
            final isRead = n.isRead || _readIds.contains(n.id);

            return NotificationCard(
              notification: n,
              isRead: isRead,
              isDark: isDark,
              formattedTime: _formatTime(context, n.createdAt),
              onTap: () async {
                if (!isRead) {
                  try {
                    await firestoreService.markNotificationAsRead(n.id);
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
                    return;
                  }
                }
                if (!context.mounted) return;
                setState(() => _readIds.add(n.id));
                widget.onNotificationTapped?.call();

                final target = NotificationIntent.fromPayload({
                  'type': n.type,
                  ...n.data,
                }).toRoutePath();
                context.push(target ?? AppRoutes.notFoundPath);
              },
            );
          },
        );
      },
    );
  }
}
