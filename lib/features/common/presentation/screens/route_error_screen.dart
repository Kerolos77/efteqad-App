import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';

enum RouteErrorType { forbidden, notFound, general }

class RouteErrorScreen extends StatelessWidget {
  final RouteErrorType type;
  final String? message;
  final VoidCallback? onRetry;

  const RouteErrorScreen({
    super.key,
    this.type = RouteErrorType.notFound,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    final String title;
    final String description;
    final IconData icon;

    switch (type) {
      case RouteErrorType.forbidden:
        title = context.tr.messageAccessDenied;
        description =
            message ?? (context.tr.messageYouDoNotHavePermissionToAccess);
        icon = Icons.lock_outline_rounded;
        break;
      case RouteErrorType.notFound:
        title = context.tr.messagePageNotFound;
        description =
            message ?? (context.tr.messageThePageYouAreLookingForDoes);
        icon = Icons.search_off_rounded;
        break;
      case RouteErrorType.general:
        title = context.tr.messageAnErrorOccurred;
        description = message ?? (tr.dataUnavailable);
        icon = Icons.error_outline_rounded;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  color: AppColors.sacredGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48.r, color: AppColors.sacredGold),
              ),
              SizedBox(height: 24.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                description,
                style: TextStyle(fontSize: 15.sp, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12.w,
                runSpacing: 8.h,
                children: [
                  if (onRetry != null) ...[
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: Icon(Icons.refresh_rounded, size: 18.r),
                      label: Text(
                        context.tr.messageRetry,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                    SizedBox(width: 16.w),
                  ],
                  FilledButton.icon(
                    onPressed: () {
                      context.go(AppRoutes.bootstrapPath);
                    },
                    icon: Icon(Icons.home_rounded, size: 18.r),
                    label: Text(
                      context.tr.messageGoHome,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
