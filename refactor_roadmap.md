# خريطة إعادة هيكلة المشروع (Refactor Roadmap)

خطة تفصيلية لمراجعة وتحديث ملفات المشروع خطوة بخطوة، بحيث تمثل كل مهمة مراجعة ملف واحد منفصل مع ضمان التجاوب عبر `flutter_screenutil`، ومعايير الكود النظيف، وبدون استخدام Enums.

---

## 1. طبقة الأساسيات (`lib/core/`) - مكتملة بنجاح ✅

### `lib/core/constants/`
- [x] `constants.dart`
- [x] `firestore_collections.dart`

### `lib/core/errors/`
- [x] `app_failure.dart`

### `lib/core/localization/`
- [x] `app_formatters.dart`
- [x] `app_localizations.dart`
- [x] `domain_labels.dart`
- [x] `excel_column_labels.dart`
- [x] `notification_text.dart`

### `lib/core/models/`
- [x] `attendance_session_model.dart`
- [x] `class_model.dart`
- [x] `excel_import_result.dart`
- [x] `khadem_model.dart`
- [x] `makhdom_model.dart`
- [x] `makhdom_profile_patch.dart`
- [x] `notification_model.dart`
- [x] `page_result.dart`
- [x] `service_model.dart`
- [x] `snapshot_list.dart`
- [x] `task_model.dart`
- [x] `visit_model.dart`

### `lib/core/theme/`
- [x] `app_colors.dart`
- [x] `app_theme.dart`

### `lib/core/utils/`
- [x] `calendar_dates.dart`
- [x] `color_generator.dart`
- [x] `platform_file_saver/platform_file_saver.dart`
- [x] `platform_file_saver/platform_file_saver_io.dart`
- [x] `platform_file_saver/platform_file_saver_stub.dart`
- [x] `platform_file_saver/platform_file_saver_web.dart`

### `lib/core/services/`
- [x] `app_version_service.dart`
- [x] `attendance_analytics_service.dart`
- [x] `attendance_roster_repository.dart`
- [x] `auth_service.dart`
- [x] `device_registration_service.dart`
- [x] `excel_service.dart`
- [x] `firestore_service.dart`
- [x] `import_coordinator.dart`
- [x] `notification_service.dart`
- [x] `privileged_operations_service.dart`
- [x] `shorebird_updater_service.dart`
- [x] `trusted_mutations.dart`
- [x] `visit_draft_store.dart`

### `lib/core/repositories/`
- [x] `account_repository.dart`
- [x] `attendance_repository.dart`
- [x] `attendance_roster_repository.dart`
- [x] `auth_repository.dart`
- [x] `makhdom_repository.dart`
- [x] `notification_repository.dart`
- [x] `profile_repository.dart`
- [x] `visit_repository.dart`

### `lib/core/responsive/`
- [x] `responsive.dart`
- [x] `responsive_breakpoints.dart`
- [x] `responsive_layout.dart`

### `lib/core/router/`
- [x] `app_router.dart`
- [x] `app_routes.dart`
- [x] `notification_intent_coordinator.dart`
- [x] `router_refresh_notifier.dart`
- [x] `router_services.dart`
- [x] `route_access_service.dart`
- [x] `route_resource_loader.dart`
- [x] `widgets/protected_resource_page.dart`

### `lib/core/session/` & `lib/core/settings/`
- [x] `session/session_cubit.dart`
- [x] `session/session_state.dart`
- [x] `settings/settings_cubit.dart`
- [x] `settings/settings_repository.dart`

### `lib/core/widgets/`
- [x] `async_content.dart`
- [x] `paged_content.dart`
- [x] `query_content.dart`
- [x] `web/web_card.dart`
- [x] `web/web_page_header.dart`
- [x] `web/web_scaffold.dart`
- [x] `web/web_widgets.dart`

---

## 2. طبقة الميزات (`lib/features/`)

### `lib/features/auth/`
- [x] `presentation/widgets/auth_branding_header.dart`
- [x] `presentation/widgets/google_sign_in_button.dart`
- [x] `presentation/widgets/admin_sign_in_button.dart`
- [x] `presentation/widgets/admin_login_bottom_sheet.dart`
- [x] `presentation/widgets/auth_widgets.dart`
- [x] `presentation/screens/login_screen.dart`
- [x] `presentation/widgets/pending_status_card.dart`
- [x] `presentation/widgets/pending_profile_form.dart`
- [x] `presentation/widgets/pending_servant_avatar.dart`
- [x] `presentation/screens/pending_assignment_screen.dart`
- [x] `presentation/widgets/web_auth_branding_panel.dart`
- [x] `presentation/widgets/web_auth_mobile_header.dart`
- [x] `presentation/widgets/web_admin_login_form.dart`
- [x] `presentation/web/login_web_screen.dart`
- [x] `presentation/widgets/web_pending_status_header.dart`
- [x] `presentation/widgets/web_pending_profile_form.dart`
- [x] `presentation/widgets/web_pending_actions.dart`
- [x] `presentation/web/pending_assignment_web_screen.dart`

### `lib/features/common/`
- [x] `presentation/screens/notifications_screen.dart`
- [x] `presentation/screens/route_error_screen.dart`
- [x] `presentation/screens/splash_screen.dart`
- [x] `widgets/app_drawer.dart`
- [x] `widgets/app_drawer_header.dart`
- [x] `widgets/app_drawer_tile.dart`
- [x] `widgets/app_update_dialog.dart`
- [x] `widgets/version_pill.dart`
- [x] `widgets/mobile_splash_content.dart`
- [x] `widgets/notification_card.dart`
- [x] `widgets/notification_list.dart`
- [x] `widgets/notifications_sheet.dart`
- [x] `widgets/record_visit_sheet.dart`
- [x] `widgets/splash_progress_indicator.dart`
- [x] `widgets/splash_title.dart`
- [x] `widgets/splash_verse_pill.dart`
- [x] `widgets/visit_date_picker_tile.dart`
- [x] `widgets/visit_draft_banner.dart`
- [x] `widgets/visit_type_selector.dart`
- [x] `widgets/web_splash_content.dart`
- [x] `widgets/common_widgets.dart`

### `lib/features/khadem/`
- [x] `presentation/widgets/khadem_avatar_card.dart`
- [x] `presentation/widgets/khadem_assigned_count_card.dart`
- [x] `presentation/widgets/khadem_profile_form.dart`
- [x] `presentation/screens/khadem_profile_screen.dart`
- [x] `presentation/widgets/analytics_stat_card.dart`
- [x] `presentation/widgets/visitation_impact_card.dart`
- [x] `presentation/widgets/absence_alerts_section.dart`
- [x] `presentation/widgets/behavioral_segmentation_section.dart`
- [x] `presentation/widgets/my_analytics_tab.dart`
- [x] `presentation/widgets/servant_hero_card.dart`
- [x] `presentation/widgets/at_risk_alert_banner.dart`
- [x] `presentation/widgets/makhdomeen_filter_bar.dart`
- [x] `presentation/widgets/my_makhdomeen_tab.dart`
- [x] `presentation/screens/khadem_home_screen.dart`
- [x] `presentation/widgets/web_makhdom_card.dart`
- [x] `presentation/widgets/web_makhdomeen_controls_bar.dart`
- [x] `presentation/widgets/web_makhdomeen_data_table.dart`
- [x] `presentation/widgets/web_makhdomeen_metrics_bar.dart`
- [x] `presentation/web/my_makhdomeen_web_screen.dart`
- [x] `presentation/widgets/web_absence_alerts_section.dart`
- [x] `presentation/widgets/web_analytics_charts_section.dart`
- [x] `presentation/widgets/web_analytics_kpi_bar.dart`
- [x] `presentation/widgets/web_analytics_roster_section.dart`
- [x] `presentation/web/my_analytics_web_screen.dart`
- [x] `presentation/widgets/khadem_widgets.dart`

### `lib/features/attendance/`
- [x] `application/attendance_access.dart`
- [x] `application/attendance_cubit.dart`
- [x] `application/attendance_action_handler.dart`
- [x] `application/attendance_grade_helper.dart`
- [x] `application/attendance_roster_loader.dart`
- [x] `presentation/widgets/attendance_active_sessions_section.dart`
- [x] `presentation/widgets/attendance_app_bar_actions.dart`
- [x] `presentation/widgets/attendance_app_bar_title.dart`
- [x] `presentation/widgets/attendance_bottom_bar.dart`
- [x] `presentation/widgets/attendance_date_selector_bar.dart`
- [x] `presentation/widgets/attendance_empty_history_card.dart`
- [x] `presentation/widgets/attendance_empty_view.dart`
- [x] `presentation/widgets/attendance_excuse_dialog.dart`
- [x] `presentation/widgets/attendance_finalize_dialog.dart`
- [x] `presentation/widgets/attendance_history_section.dart`
- [x] `presentation/widgets/attendance_history_tile.dart`
- [x] `presentation/widgets/attendance_hub_header.dart`
- [x] `presentation/widgets/attendance_reopen_dialog.dart`
- [x] `presentation/widgets/attendance_roster_card.dart`
- [x] `presentation/widgets/attendance_roster_content.dart`
- [x] `presentation/widgets/attendance_roster_list_view.dart`
- [x] `presentation/widgets/attendance_search_and_filters.dart`
- [x] `presentation/widgets/attendance_session_card.dart`
- [x] `presentation/widgets/attendance_status_badge.dart`
- [x] `presentation/widgets/attendance_status_banners.dart`
- [x] `presentation/widgets/attendance_top_summary_bar.dart`
- [x] `presentation/screens/attendance_hub_tab.dart`
- [x] `presentation/screens/attendance_screen.dart`
- [x] `presentation/widgets/attendance_widgets.dart`

### `lib/features/tasks/`
- [x] `presentation/widgets/add_task_header.dart`
- [x] `presentation/widgets/delete_task_dialog.dart`
- [x] `presentation/widgets/task_action_buttons.dart`
- [x] `presentation/widgets/task_card.dart`
- [x] `presentation/widgets/task_details_card.dart`
- [x] `presentation/widgets/task_due_date_picker.dart`
- [x] `presentation/widgets/tasks_empty_view.dart`
- [x] `presentation/widgets/tasks_filter_bar.dart`
- [x] `presentation/widgets/web_task_badge.dart`
- [x] `presentation/widgets/web_task_card.dart`
- [x] `presentation/widgets/web_task_details_dialog.dart`
- [x] `presentation/widgets/web_tasks_controls_bar.dart`
- [x] `presentation/widgets/web_tasks_data_table.dart`
- [x] `presentation/widgets/web_tasks_empty_state.dart`
- [x] `presentation/widgets/web_tasks_grid_view.dart`
- [x] `presentation/widgets/web_tasks_kanban_view.dart`
- [x] `presentation/widgets/web_tasks_kpi_bar.dart`
- [x] `presentation/screens/task_details_screen.dart`
- [x] `presentation/web/my_tasks_web_screen.dart`
- [x] `presentation/widgets/add_task_dialog.dart`
- [x] `presentation/widgets/tasks_tab.dart`
- [x] `presentation/widgets/tasks_widgets.dart`

### `lib/features/reports/`
- [x] `models/report_filter_data.dart`
- [x] `models/report_result.dart`
- [x] `models/report_type.dart`
- [x] `models/servant_performance_data.dart`
- [x] `presentation/widgets/report_category_selector.dart`
- [x] `presentation/widgets/report_criteria_filters.dart`
- [x] `presentation/widgets/report_date_filter_section.dart`
- [x] `presentation/widgets/report_export_actions.dart`
- [x] `presentation/widgets/report_filter_panel.dart`
- [x] `presentation/widgets/report_result_preview_card.dart`
- [x] `presentation/widgets/report_share_sheet.dart`
- [x] `presentation/widgets/report_type_card.dart`
- [x] `presentation/widgets/reports_widgets.dart`
- [x] `presentation/screens/reports_screen.dart`
- [x] `services/excel_report_service.dart`
- [x] `services/pdf_report_service.dart`
- [x] `services/reports_data_service.dart`

### `lib/features/admin/`
- [x] `application/makhdom_history_service.dart`
- [x] `models/history_analysis.dart`
- [x] `presentation/screens/admin_main_screen.dart`
- [x] `presentation/screens/analytics_tab.dart`
- [x] `presentation/screens/grade_admin_screen.dart`
- [x] `presentation/screens/khodam_tab.dart`
- [x] `presentation/screens/makhdom_history_screen.dart`
- [x] `presentation/widgets/add_edit_makhdom_dialog.dart`
- [x] `presentation/widgets/assign_makhdomeen_modal.dart`
- [x] `presentation/widgets/excel_actions_sheet.dart`
- [x] `presentation/widgets/grade_makhdomeen_tab.dart`
- [x] `presentation/widgets/history_filters.dart`
- [x] `presentation/widgets/history_header.dart`
- [x] `presentation/widgets/history_kpis.dart`
- [x] `presentation/widgets/history_timeline.dart`
- [x] `presentation/widgets/makhdom_card.dart`
- [x] `presentation/widgets/manage_classes_dialog.dart`
- [x] `presentation/widgets/service_setup_dialog.dart`
- [x] `presentation/widgets/stage_people_tab.dart`

### `lib/features/settings/`
- [x] `presentation/screens/settings_screen.dart`

---

## 3. الجذور وإعدادات التطبيق
- [x] `lib/main.dart`
- [x] `lib/firebase_options.dart`
