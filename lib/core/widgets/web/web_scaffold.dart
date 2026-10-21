import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';
import '../../../features/common/widgets/notifications_sheet.dart';
import '../../constants/constants.dart';
import '../../localization/app_localizations.dart';
import '../../responsive/responsive_breakpoints.dart';
import '../../session/session_cubit.dart';
import '../../settings/settings_cubit.dart';

/// Item definition for Web navigation destinations.
class WebNavDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? badge;

  const WebNavDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.badge,
  });
}

/// A comprehensive, responsive Web Scaffold providing:
/// - A persistent, stylish RTL sidebar on Desktop (>= 1024px)
/// - An adaptive top AppBar and Drawer on Mobile Browsers (< 1024px)
/// - User profile display, theme toggle, and logout actions
class WebScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<WebNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool maxWidthContained;
  final double maxWidth;

  const WebScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.maxWidthContained = true,
    this.maxWidth = 1440.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktopScreen;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isDesktop) {
      final currentDest =
          (selectedIndex >= 0 && selectedIndex < destinations.length)
              ? destinations[selectedIndex]
              : null;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        floatingActionButton: floatingActionButton,
        body: Row(
          children: [
            // Persistent Sidebar on the Right (RTL) or Left (LTR)
            _WebSidebar(
              destinations: destinations,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
            ),
            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  _WebHeader(
                    title: title,
                    subtitle: subtitle,
                    actions: actions,
                    currentDestination: currentDest,
                  ),
                  Expanded(
                    child: maxWidthContained
                        ? Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxWidth),
                              child: body,
                            ),
                          )
                        : body,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet Web Browser Layout
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        shape: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1B2D44) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        leading: Builder(
          builder: (ctx) => Center(
            child: InkWell(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Icon(
                  Icons.menu_rounded,
                  size: 20.r,
                  color: isDark ? Colors.white : AppColors.primaryNavy,
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.primaryNavy,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 2.h),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sacredGold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.android_rounded, color: AppColors.sacredGold),
            tooltip: 'تحميل تطبيق الأندرويد (APK)',
            onPressed: () async {
              final uri = Uri.parse(AppConstants.appDownloadPageUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          ...?actions,
          if (!(actions?.any((w) => w is NotificationBellButton) ?? false)) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: const NotificationBellButton(),
            ),
          ],
        ],
      ),
      drawer: Drawer(
        width: 285.w,
        child: _WebSidebar(
          destinations: destinations,
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            Navigator.of(context).pop(); // Close drawer
            onDestinationSelected(index);
          },
          isDrawerMode: true,
        ),
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

/// Web Top Navigation Header for Desktop View
class _WebHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final WebNavDestination? currentDestination;

  const _WebHeader({
    required this.title,
    this.subtitle,
    this.actions,
    this.currentDestination,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    String todayFormatted = '';
    try {
      todayFormatted =
          DateFormat('EEEE، d MMMM', locale).format(DateTime.now());
    } catch (_) {
      todayFormatted = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    final headerIcon = currentDestination?.selectedIcon ??
        currentDestination?.icon ??
        Icons.dashboard_rounded;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF091322) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1B2D44) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Page Icon Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.sacredGold.withValues(alpha: 0.16),
                        AppColors.primaryNavy.withValues(alpha: 0.4),
                      ]
                    : [
                        AppColors.primaryLight.withValues(alpha: 0.12),
                        AppColors.primaryLight.withValues(alpha: 0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isDark
                    ? AppColors.sacredGold.withValues(alpha: 0.3)
                    : AppColors.primaryLight.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                headerIcon,
                size: 20,
                color: isDark ? AppColors.sacredGold : AppColors.primaryLight,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title & Subtitle / Breadcrumb
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : AppColors.primaryNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.sacredGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Date Badge Pill
          if (todayFormatted.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: AppColors.sacredGold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    todayFormatted,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Download Android App APK Shortcut
          Tooltip(
            message: 'تحميل تطبيق الأندرويد (APK)',
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () async {
                  final uri = Uri.parse(AppConstants.appDownloadPageUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                hoverColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppColors.sacredGold.withValues(alpha: 0.3)
                          : AppColors.sacredGold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.android_rounded,
                        size: 15,
                        color: AppColors.sacredGold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'تطبيق الموبايل',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.grey[200]
                              : AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Additional Actions
          if (actions != null) ...actions!,
          // Notifications Bell Button
          if (!(actions?.any((w) => w is NotificationBellButton) ?? false)) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: const NotificationBellButton(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Web Sidebar Navigation Widget
class _WebSidebar extends StatelessWidget {
  final List<WebNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isDrawerMode;

  const _WebSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isDrawerMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      width: isDrawerMode ? 285.w : 272,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF091322) : Colors.white,
        border: isDrawerMode
            ? null
            : Border(
                left: isRtl
                    ? const BorderSide(color: Color(0xFF1B2D44), width: 1)
                    : BorderSide.none,
                right: !isRtl
                    ? const BorderSide(color: Color(0xFF1B2D44), width: 1)
                    : BorderSide.none,
              ),
        boxShadow: isDrawerMode
            ? null
            : (isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(2, 0),
                    ),
                  ]),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Branding Header
            _SidebarBrandHeader(isDrawerMode: isDrawerMode),

            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? const Color(0xFF1B2D44) : const Color(0xFFE2E8F0),
              indent: 14,
              endIndent: 14,
            ),

            // User Info Card
            _SidebarUserProfile(isDrawerMode: isDrawerMode),

            // Section Label
            Padding(
              padding: isDrawerMode
                  ? EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 4.h)
                  : const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Text(
                'القوائم الرئيسية',
                style: TextStyle(
                  fontSize: isDrawerMode ? 11.sp : 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
            ),

            // Navigation Destinations List
            Expanded(
              child: ListView.separated(
                padding: isDrawerMode
                    ? EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h)
                    : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                itemCount: destinations.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: isDrawerMode ? 4.h : 4),
                itemBuilder: (context, index) {
                  final dest = destinations[index];
                  final isSelected = selectedIndex == index;

                  return _WebNavItem(
                    destination: dest,
                    isSelected: isSelected,
                    onTap: () => onDestinationSelected(index),
                    isDrawerMode: isDrawerMode,
                  );
                },
              ),
            ),

            // Footer Actions: Theme Toggle & Logout
            _SidebarFooter(isDrawerMode: isDrawerMode),
          ],
        ),
      ),
    );
  }
}

/// Branding header inside Web Sidebar
class _SidebarBrandHeader extends StatelessWidget {
  final bool isDrawerMode;

  const _SidebarBrandHeader({this.isDrawerMode = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: isDrawerMode
          ? EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 14.h)
          : const EdgeInsets.fromLTRB(18, 20, 18, 14),
      child: Row(
        children: [
          // Elegant Logo Container with Sacred Gold rim & subtle glow
          Container(
            width: isDrawerMode ? 44.r : 44,
            height: isDrawerMode ? 44.r : 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isDrawerMode ? 12.r : 12),
              border: Border.all(
                color: AppColors.sacredGold.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.sacredGold.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              AppConstants.appLogoPath,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: isDrawerMode ? 12.w : 12),
          // App Title & Brand Tag
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: isDrawerMode ? 18.sp : 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.sacredGold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: AppColors.sacredGold.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'منظومة الافتقاد',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sacredGold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'v${AppConstants.appVersion}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// User profile presentation in Web Sidebar
class _SidebarUserProfile extends StatelessWidget {
  final bool isDrawerMode;

  const _SidebarUserProfile({this.isDrawerMode = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tr = context.tr;
    final sessionState = context.watch<SessionCubit>().state;
    final userProfile = sessionState.profile;

    if (userProfile == null) return const SizedBox.shrink();

    final roleLabel = sessionState.isStageAdmin
        ? 'أمين مرحلة'
        : sessionState.isGradeAdmin
            ? 'أمين سنة'
            : tr.servantRole;

    final roleIcon = sessionState.isStageAdmin
        ? Icons.shield_rounded
        : sessionState.isGradeAdmin
            ? Icons.workspace_premium_rounded
            : Icons.church_rounded;

    return Padding(
      padding: isDrawerMode
          ? EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 6.h)
          : const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Container(
        padding: isDrawerMode ? EdgeInsets.all(12.r) : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF132238),
                    Color(0xFF0E1A2C),
                  ]
                : const [
                    Color(0xFFF8FAFC),
                    Color(0xFFF1F5F9),
                  ],
          ),
          borderRadius: BorderRadius.circular(isDrawerMode ? 14.r : 14),
          border: Border.all(
            color: isDark
                ? AppColors.sacredGold.withValues(alpha: 0.22)
                : AppColors.cardBorderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // User Avatar with Status indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: isDrawerMode ? 40.r : 40,
                  height: isDrawerMode ? 40.r : 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryNavy,
                        AppColors.primaryLight,
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.sacredGold.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      userProfile.name.isNotEmpty ? userProfile.name[0] : 'خ',
                      style: TextStyle(
                        color: AppColors.sacredGold,
                        fontWeight: FontWeight.w800,
                        fontSize: isDrawerMode ? 16.sp : 16,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF132238) : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: isDrawerMode ? 11.w : 11),
            // User Name & Role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userProfile.name,
                    style: TextStyle(
                      fontSize: isDrawerMode ? 13.5.sp : 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.primaryNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        roleIcon,
                        size: isDrawerMode ? 12.r : 12,
                        color: AppColors.sacredGold,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: isDrawerMode ? 11.sp : 11,
                            color: AppColors.sacredGold,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A stylish navigation item for the Web Sidebar
class _WebNavItem extends StatefulWidget {
  final WebNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDrawerMode;

  const _WebNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
    this.isDrawerMode = false,
  });

  @override
  State<_WebNavItem> createState() => _WebNavItemState();
}

class _WebNavItemState extends State<_WebNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderRadius =
        BorderRadius.circular(widget.isDrawerMode ? 12.r : 12);

    final isSelected = widget.isSelected;
    final iconData = isSelected
        ? (widget.destination.selectedIcon ?? widget.destination.icon)
        : widget.destination.icon;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: borderRadius,
          hoverColor: Colors.transparent,
          splashColor: AppColors.primaryLight.withValues(alpha: 0.15),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: widget.isDrawerMode
                ? EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h)
                : const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: isDark
                          ? [
                              AppColors.primaryLight.withValues(alpha: 0.32),
                              AppColors.primaryNavy.withValues(alpha: 0.5),
                            ]
                          : [
                              AppColors.primaryLight.withValues(alpha: 0.14),
                              AppColors.primaryLight.withValues(alpha: 0.05),
                            ],
                    )
                  : (_isHovered
                      ? LinearGradient(
                          colors: isDark
                              ? [
                                  Colors.white.withValues(alpha: 0.06),
                                  Colors.white.withValues(alpha: 0.03),
                                ]
                              : [
                                  Colors.black.withValues(alpha: 0.04),
                                  Colors.black.withValues(alpha: 0.02),
                                ],
                        )
                      : null),
              borderRadius: borderRadius,
              border: Border.all(
                color: isSelected
                    ? (isDark
                        ? AppColors.primaryLight.withValues(alpha: 0.5)
                        : AppColors.primaryLight.withValues(alpha: 0.3))
                    : (_isHovered
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08))
                        : Colors.transparent),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Active indicator pill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isSelected ? 3.5 : 0,
                  height: isSelected ? (widget.isDrawerMode ? 20.h : 20) : 0,
                  decoration: BoxDecoration(
                    color: AppColors.sacredGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(
                  width: isSelected
                      ? (widget.isDrawerMode ? 8.w : 8)
                      : (widget.isDrawerMode ? 3.5.w : 3.5),
                ),
                // Icon Container
                Container(
                  width: widget.isDrawerMode ? 32.r : 32,
                  height: widget.isDrawerMode ? 32.r : 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? AppColors.sacredGold.withValues(alpha: 0.16)
                            : AppColors.primaryLight.withValues(alpha: 0.12))
                        : (_isHovered
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04))
                            : Colors.transparent),
                    borderRadius:
                        BorderRadius.circular(widget.isDrawerMode ? 8.r : 8),
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      size: widget.isDrawerMode ? 19.r : 19,
                      color: isSelected
                          ? (isDark
                              ? AppColors.sacredGold
                              : AppColors.primaryLight)
                          : (_isHovered
                              ? (isDark ? Colors.white : AppColors.primaryNavy)
                              : (isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600])),
                    ),
                  ),
                ),
                SizedBox(width: widget.isDrawerMode ? 11.w : 11),
                // Label
                Expanded(
                  child: Text(
                    widget.destination.label,
                    style: TextStyle(
                      fontSize: widget.isDrawerMode ? 13.5.sp : 13.5,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : (_isHovered
                              ? FontWeight.w700
                              : FontWeight.w600),
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.primaryNavy)
                          : (_isHovered
                              ? (isDark ? Colors.white : AppColors.primaryNavy)
                              : (isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700])),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Optional Badge
                if (widget.destination.badge != null)
                  Container(
                    padding: widget.isDrawerMode
                        ? EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h)
                        : const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.sacredGold
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(
                          widget.isDrawerMode ? 10.r : 10),
                    ),
                    child: Text(
                      widget.destination.badge!,
                      style: TextStyle(
                        fontSize: widget.isDrawerMode ? 10.5.sp : 10.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? AppColors.primaryNavy
                            : (isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sidebar Footer with Theme Switcher & Logout
class _SidebarFooter extends StatelessWidget {
  final bool isDrawerMode;

  const _SidebarFooter({this.isDrawerMode = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tr = context.tr;

    return Container(
      padding: isDrawerMode
          ? EdgeInsets.all(12.r)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1B2D44) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Download Android App Link
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () async {
                final uri = Uri.parse(AppConstants.appDownloadPageUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(10),
              hoverColor: AppColors.sacredGold.withValues(alpha: 0.08),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.sacredGold.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.android_rounded,
                      size: 16,
                      color: AppColors.sacredGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تحميل تطبيق الأندرويد (APK)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 13,
                      color: AppColors.sacredGold,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Theme Switcher & Logout Row
          Row(
            children: [
          // Theme Mode Toggle Button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () {
                final settings = context.read<SettingsCubit>();
                final current = settings.state.themeMode;
                settings.setThemeMode(
                  current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                );
              },
              borderRadius: BorderRadius.circular(10),
              hoverColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.sacredGold
                          : AppColors.primaryNavy,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isDark ? 'نهاري' : 'ليلي',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          // Logout Button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => _confirmSignOut(context),
              borderRadius: BorderRadius.circular(10),
              hoverColor: AppColors.errorColor.withValues(alpha: 0.12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.errorColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      size: 16,
                      color: AppColors.errorColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tr.signOut,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  ),
);
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final tr = context.tr;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.signOut),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr.signOut),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<SessionCubit>().signOut();
    }
  }
}
