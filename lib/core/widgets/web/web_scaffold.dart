import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    if (isDesktop) {
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
            const VerticalDivider(width: 1, thickness: 1),
            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  _WebHeader(
                    title: title,
                    subtitle: subtitle,
                    actions: actions,
                  ),
                  const Divider(height: 1, thickness: 1),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
          ],
        ),
        actions: [
          ...?actions,
          const NotificationBellButton(),
        ],
      ),
      drawer: Drawer(
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

  const _WebHeader({
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      color: theme.cardColor,
      child: Row(
        children: [
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Actions
          if (actions != null) ...actions!,
          const SizedBox(width: 8),
          const NotificationBellButton(),
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
    final tr = context.tr;
    final sessionState = context.watch<SessionCubit>().state;
    final userProfile = sessionState.profile;

    final primaryColor = theme.colorScheme.primary;

    return Container(
      width: isDrawerMode ? 280 : 260,
      color: theme.cardColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Branding Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppConstants.primaryNavy,
                          AppConstants.primaryLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryLight.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.church_rounded,
                      color: AppConstants.sacredGold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'نسخة الويب المتجاوبة',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // User Info Tile
            if (userProfile != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.grey.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: primaryColor.withOpacity(0.15),
                        child: Text(
                          userProfile.name.isNotEmpty
                              ? userProfile.name[0]
                              : 'خ',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sessionState.isStageAdmin
                                  ? 'أمين مرحلة'
                                  : sessionState.isGradeAdmin
                                      ? 'أمين سنة'
                                      : tr.servantRole,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppConstants.sacredGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Navigation Destinations List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: destinations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final dest = destinations[index];
                  final isSelected = selectedIndex == index;

                  return _WebNavItem(
                    destination: dest,
                    isSelected: isSelected,
                    onTap: () => onDestinationSelected(index),
                  );
                },
              ),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // Footer Actions: Theme Toggle & Logout
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Theme Mode Button
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 20,
                    ),
                    tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                    onPressed: () {
                      final settings = context.read<SettingsCubit>();
                      final current = settings.state.themeMode;
                      settings.setThemeMode(
                        current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                      );
                    },
                  ),
                  const Spacer(),
                  // Logout Button
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppConstants.errorColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(
                      tr.signOut,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () async {
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
                                backgroundColor: AppConstants.errorColor,
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
                    },
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
class _WebNavItem extends StatelessWidget {
  final WebNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _WebNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: primaryColor.withOpacity(0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: primaryColor.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? (destination.selectedIcon ?? destination.icon)
                    : destination.icon,
                size: 20,
                color: isSelected ? primaryColor : theme.iconTheme.color?.withOpacity(0.7),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  destination.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? primaryColor
                        : theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                  ),
                ),
              ),
              if (destination.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppConstants.sacredGold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    destination.badge!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryNavy,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
