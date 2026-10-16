import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:efteqad/core/localization/domain_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/makhdom_profile_patch.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/trusted_mutations.dart';
import 'makhdom_age_selector.dart';
import 'makhdom_servant_class_selector.dart';

class AddEditMakhdomDialog extends StatefulWidget {
  final MakhdomModel? initialMakhdom;
  final List<KhademModel> khodamList;
  final FirestoreService? firestoreService;

  const AddEditMakhdomDialog({
    super.key,
    this.firestoreService,
    this.initialMakhdom,
    required this.khodamList,
  });

  @override
  State<AddEditMakhdomDialog> createState() => _AddEditMakhdomDialogState();
}

class _AddEditMakhdomDialogState extends State<AddEditMakhdomDialog> {
  final _formKey = GlobalKey<FormState>();
  late final FirestoreService _firestoreService;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _fatherPhoneController;
  late TextEditingController _motherPhoneController;
  late TextEditingController _addressController;
  late TextEditingController _areaController;
  late TextEditingController _schoolController;
  late TextEditingController _secondaryTypeController;
  late TextEditingController _secondaryCustomController;
  bool _secondaryEdited = false;
  bool get _supportsCustomSecondary => !const [
    'general',
    'technical',
    'services',
    'commercial',
  ].contains(_secondaryTypeController.text);
  DateTime? _trackingStartDate;
  bool _trackingEdited = false;
  late TextEditingController _locationController;
  late TextEditingController _photoController;
  late TextEditingController _notesController;

  DateTime? _birthDate;
  bool _isBrethren = false;
  String? _selectedKhademId;
  String? _selectedKhademName;
  String? _selectedClassId;
  String? _selectedClassName;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  final String _createOperationId = newOperationId('profile');
  String? _createdId;
  bool _submissionStarted = false;
  String? _submittedUid;
  bool _profileSaved = false;
  MakhdomProfilePatch? _submittedPatch;
  MakhdomModel? _submittedMakhdom;
  String? _submittedKhademId;
  String? _submittedKhademName;

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr.locationPermissionDenied),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr.locationPermissionPermanentlyDenied),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: context.tr.openSettings,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _locationController.text =
          'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.locationFetchedSuccess),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  int? _calculateAge(DateTime bDate) {
    final now = DateTime.now();
    int a = now.year - bDate.year;
    if (now.month < bDate.month ||
        (now.month == bDate.month && now.day < bDate.day)) {
      a--;
    }
    return a >= 0 ? a : null;
  }

  int _defaultAgeForGrade(String? grade) {
    if (grade != null && grade.startsWith('grade_')) {
      final order = int.tryParse(grade.replaceFirst('grade_', ''));
      if (order != null) {
        return 5 + order;
      }
    }
    switch (grade) {
      case AppConstants.grade1st:
        return 15;
      case AppConstants.grade2nd:
        return 16;
      case AppConstants.grade3rd:
        return 17;
      default:
        return 15;
    }
  }

  int get _currentEffectiveAge {
    if (_birthDate != null) {
      return _calculateAge(_birthDate!) ??
          _defaultAgeForGrade(widget.initialMakhdom?.grade);
    }
    return _defaultAgeForGrade(widget.initialMakhdom?.grade);
  }

  @override
  void initState() {
    super.initState();
    _firestoreService = widget.firestoreService ?? FirestoreService();
    final m = widget.initialMakhdom;
    _nameController = TextEditingController(text: m?.fullName ?? '');
    _phoneController = TextEditingController(text: m?.phone ?? '');
    _birthDate = m?.birthDate;
    _fatherPhoneController = TextEditingController(text: m?.fatherPhone ?? '');
    _motherPhoneController = TextEditingController(text: m?.motherPhone ?? '');
    _addressController = TextEditingController(text: m?.address ?? '');
    _areaController = TextEditingController(text: m?.area ?? '');
    _schoolController = TextEditingController(text: m?.school ?? '');
    _secondaryCustomController = TextEditingController(
      text: m?.secondaryTypeCustomLabel ?? '',
    );
    _trackingStartDate = m?.trackingStartDate;
    final secondaryCode = const DomainLabels(
      Locale('ar'),
    ).secondaryTypeCode(m?.secondaryType ?? 'general');
    _secondaryTypeController = TextEditingController(
      text: secondaryCode.isEmpty ? 'general' : secondaryCode,
    );
    _locationController = TextEditingController(text: m?.homeLocationUrl ?? '');
    _photoController = TextEditingController(text: m?.photoUrl ?? '');
    _notesController = TextEditingController(text: m?.notes ?? '');

    _isBrethren = m?.isBrethrenOfLord ?? false;
    _selectedKhademId = m?.assignedKhademId;
    _selectedKhademName = m?.assignedKhademName;
    _selectedClassId = m?.classId;
    _selectedClassName = m?.className;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _fatherPhoneController.dispose();
    _motherPhoneController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _schoolController.dispose();
    _secondaryTypeController.dispose();
    _secondaryCustomController.dispose();
    _locationController.dispose();
    _photoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isLoading ||
        _isLoadingLocation ||
        (!_submissionStarted && !_formKey.currentState!.validate())) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      if (!_submissionStarted) {
        _submittedKhademId = _selectedKhademId;
        _submittedKhademName = _selectedKhademName;
        _submittedUid = _firestoreService.captureMutationIdentity();
        _submissionStarted = true;
      }
      _isLoading = true;
    });
    try {
      _firestoreService.checkMutationIdentity(_submittedUid);
      final isEdit =
          widget.initialMakhdom != null && widget.initialMakhdom!.id.isNotEmpty;

      if (isEdit) {
        final patch = _submittedPatch ??= MakhdomProfilePatch(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          birthDate: _birthDate,
          clearBirthDate:
              _birthDate == null && widget.initialMakhdom?.birthDate != null,
          fatherPhone: _fatherPhoneController.text.trim(),
          motherPhone: _motherPhoneController.text.trim(),
          address: _addressController.text.trim(),
          area: _areaController.text.trim(),
          school: _schoolController.text.trim(),
          secondaryType: _secondaryTypeController.text,
          secondaryTypeCustomLabel: _secondaryEdited
              ? (_supportsCustomSecondary
                    ? _secondaryCustomController.text.trim()
                    : null)
              : widget.initialMakhdom?.secondaryTypeCustomLabel,
          clearSecondaryTypeCustomLabel:
              _secondaryEdited &&
              (!_supportsCustomSecondary ||
                  _secondaryCustomController.text.trim().isEmpty),
          trackingStartDate: _trackingEdited ? _trackingStartDate : null,
          clearTrackingStartDate: _trackingEdited && _trackingStartDate == null,
          grade: widget.initialMakhdom?.grade ?? AppConstants.grade1st,
          homeLocationUrl: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          clearHomeLocationUrl:
              _locationController.text.trim().isEmpty &&
              widget.initialMakhdom?.homeLocationUrl != null,
          isBrethrenOfLord: _isBrethren,
          photoUrl: _photoController.text.trim().isNotEmpty
              ? _photoController.text.trim()
              : null,
          clearPhotoUrl:
              _photoController.text.trim().isEmpty &&
              widget.initialMakhdom?.photoUrl != null,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          clearNotes:
              _notesController.text.trim().isEmpty &&
              widget.initialMakhdom?.notes != null,
          classId: _selectedClassId,
          clearClassId: _selectedClassId == null &&
              widget.initialMakhdom?.classId != null,
          className: _selectedClassName,
          clearClassName: _selectedClassName == null &&
              widget.initialMakhdom?.className != null,
        );

        if (!_profileSaved) {
          await _firestoreService.updateMakhdomPatch(
            widget.initialMakhdom!.id,
            patch,
            expectedUid: _submittedUid,
            operationId: _createOperationId,
          );
          _firestoreService.checkMutationIdentity(_submittedUid);
          _profileSaved = true;
        }

        // إذا تغير تعيين الخادم، يتم تحديث الإسناد بشكل مستقل وذرّي
        if (_submittedKhademId != widget.initialMakhdom?.assignedKhademId) {
          if (_submittedKhademId != null && _submittedKhademId!.isNotEmpty) {
            await _firestoreService.assignMakhdomeenToKhadem(
              khademId: _submittedKhademId!,
              khademName: _submittedKhademName ?? '',
              makhdomeenIds: [widget.initialMakhdom!.id],
              expectedAssignments: {
                widget.initialMakhdom!.id:
                    widget.initialMakhdom?.assignedKhademId,
              },
              expectedUid: _submittedUid,
              operationId: '${_createOperationId}_assign',
            );
          } else {
            await _firestoreService.unassignMakhdom(
              widget.initialMakhdom!.id,
              expectedKhademId: widget.initialMakhdom?.assignedKhademId,
              expectedUid: _submittedUid,
              operationId: '${_createOperationId}_unassign',
            );
          }
        }
      } else {
        final makhdom = _submittedMakhdom ??= MakhdomModel(
          id: '',
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          birthDate: _birthDate,
          fatherPhone: _fatherPhoneController.text.trim(),
          motherPhone: _motherPhoneController.text.trim(),
          address: _addressController.text.trim(),
          area: _areaController.text.trim(),
          school: _schoolController.text.trim(),
          secondaryType: _secondaryTypeController.text,
          secondaryTypeCustomLabel: _supportsCustomSecondary
              ? _secondaryCustomController.text.trim()
              : null,
          trackingStartDate: _trackingStartDate,
          grade: widget.initialMakhdom?.grade ?? AppConstants.grade1st,
          homeLocationUrl: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          isBrethrenOfLord: _isBrethren,
          photoUrl: _photoController.text.trim().isNotEmpty
              ? _photoController.text.trim()
              : null,
          assignedKhademId: _submittedKhademId,
          assignedKhademName: _submittedKhademName,
          classId: _selectedClassId,
          className: _selectedClassName,
          serviceId: widget.initialMakhdom?.serviceId ?? 'thanawy',
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          visitCount: 0,
          lastVisitDate: null,
          createdAt: DateTime.now(),
        );

        _createdId ??= await _firestoreService.addMakhdom(
          makhdom,
          expectedUid: _submittedUid,
          operationId: _createOperationId,
        );
        _firestoreService.checkMutationIdentity(_submittedUid);
        if (_submittedKhademId != null) {
          await _firestoreService.assignMakhdomeenToKhadem(
            khademId: _submittedKhademId!,
            khademName: _submittedKhademName ?? '',
            makhdomeenIds: [_createdId!],
            expectedAssignments: {_createdId!: null},
            expectedUid: _submittedUid,
            operationId: '${_createOperationId}_assign',
          );
        }
      }

      _firestoreService.checkMutationIdentity(_submittedUid);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.makhdomSavedSuccess),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(top: 14.h, bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: AppColors.primaryLight),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Divider(
              color: isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit =
        widget.initialMakhdom != null && widget.initialMakhdom!.id.isNotEmpty;

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580.w,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: isEdit
                          ? AppColors.accentBlue.withValues(alpha: 0.12)
                          : AppColors.primaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      isEdit
                          ? Icons.person_outline_rounded
                          : Icons.person_add_alt_1_rounded,
                      color: isEdit
                          ? AppColors.accentBlue
                          : AppColors.primaryLight,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit
                              ? context.tr.editMakhdomTitle
                              : context.tr.addMakhdomTitle,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          isEdit
                              ? context.tr.messageUpdateRecordAndPersonalDetails
                              : context.tr.messageInsertNewMakhdomToCareRegistry,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 22.sp),
                    color: isDark ? Colors.white54 : Colors.black45,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Form fields in a smooth scrollable view
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                      // Section 1: البيانات الشخصية والاتصال
                      _buildSectionHeader(
                        context,
                        icon: Icons.person_pin_outlined,
                        title: context.tr.personalAndContactSec,
                      ),

                      // 1. الاسم رباعي
                      TextFormField(
                        enabled: !_submissionStarted,
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: context.tr.fullNameRequiredLabel,
                          prefixIcon: Icon(
                            Icons.person_rounded,
                            size: 20.sp,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.tr.fullNameValidation
                            : null,
                      ),
                      SizedBox(height: 10.h),

                      // 2. رقم تليفون المخدوم
                      TextFormField(
                        enabled: !_submissionStarted,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: context.tr.makhdomPhoneLabel,
                          prefixIcon: Icon(
                            Icons.phone_rounded,
                            size: 20.sp,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.tr.phoneRequired
                            : null,
                      ),
                      SizedBox(height: 10.h),

                      // السن وتاريخ الميلاد
                      MakhdomAgeSelector(
                        birthDate: _birthDate,
                        currentEffectiveAge: _currentEffectiveAge,
                        isDark: isDark,
                        isEditing: isEdit,
                        defaultGrade: widget.initialMakhdom?.grade ?? AppConstants.grade1st,
                        disabled: _submissionStarted,
                        onBirthDateChanged: (val) => setState(() => _birthDate = val),
                      ),
                      SizedBox(height: 10.h),

                      // 3 & 4. تليفون الأب والأم
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              enabled: !_submissionStarted,
                              controller: _fatherPhoneController,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                labelText: context.tr.fatherPhoneInputLabel,
                                prefixIcon: Icon(
                                  Icons.phone_android_rounded,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: TextFormField(
                              enabled: !_submissionStarted,
                              controller: _motherPhoneController,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                labelText: context.tr.motherPhoneInputLabel,
                                prefixIcon: Icon(
                                  Icons.phone_android_rounded,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Section 2: السكن والتعليم
                      _buildSectionHeader(
                        context,
                        icon: Icons.location_on_outlined,
                        title: context.tr.residenceAndSchoolSec,
                      ),

                      // 5 & 6. المنطقة والعنوان
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              enabled: !_submissionStarted,
                              controller: _areaController,
                              decoration: InputDecoration(
                                labelText: context.tr.residentialAreaLabel,
                                prefixIcon: Icon(
                                  Icons.location_city_rounded,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: TextFormField(
                              enabled: !_submissionStarted,
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: context.tr.detailedAddressLabel,
                                prefixIcon: Icon(
                                  Icons.home_rounded,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      // 7. المدرسة
                      TextFormField(
                        enabled: !_submissionStarted,
                        controller: _schoolController,
                        decoration: InputDecoration(
                          labelText: context.tr.schoolNameInputLabel,
                          prefixIcon: Icon(
                            Icons.school_rounded,
                            size: 20.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // 8. نوع الثانوية
                      () {
                        const standardTypes = [
                          'general',
                          'technical',
                          'services',
                          'commercial',
                          'other',
                        ];
                        final currentVal = _secondaryTypeController.text;
                        final effectiveVal = currentVal.isNotEmpty
                            ? currentVal
                            : 'general';
                        final allTypes = standardTypes.contains(effectiveVal)
                            ? standardTypes
                            : [effectiveVal, ...standardTypes];

                        return DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: effectiveVal,
                          decoration: InputDecoration(
                            labelText: context.tr.secondaryTypeInputLabel,
                            prefixIcon: Icon(
                              Icons.category_rounded,
                              size: 20.sp,
                            ),
                          ),
                          items: allTypes.map((t) {
                            return DropdownMenuItem<String>(
                              value: t,
                              child: Text(
                                DomainLabels(
                                  Localizations.localeOf(context),
                                ).secondaryTypeName(
                                  t,
                                  customLabel: t == currentVal
                                      ? _secondaryCustomController.text
                                      : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _submissionStarted
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() {
                                      _secondaryTypeController.text = val;
                                      _secondaryEdited = true;
                                    });
                                  }
                                },
                        );
                      }(),
                      SizedBox(height: 10.h),

                      if (_supportsCustomSecondary) ...[
                        TextFormField(
                          enabled: !_submissionStarted,
                          controller: _secondaryCustomController,
                          onChanged: (_) => _secondaryEdited = true,
                          decoration: InputDecoration(
                            labelText: context.tr.secondaryTypeCustomLabel,
                          ),
                        ),
                        SizedBox(height: 10.h),
                      ],
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _trackingStartDate == null
                              ? context.tr.trackingOriginUnknown
                              : context.tr.trackingStartLabel(
                                  AppFormatters(
                                    Localizations.localeOf(context),
                                  ).formatDate(_trackingStartDate!),
                                ),
                          style: TextStyle(fontSize: 13.sp),
                        ),
                        onTap: _submissionStarted
                            ? null
                            : () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _trackingStartDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null && mounted) {
                                  setState(() {
                                    _trackingStartDate = date;
                                    _trackingEdited = true;
                                  });
                                }
                              },
                        trailing: _trackingStartDate == null
                            ? Icon(Icons.date_range, size: 20.sp)
                            : IconButton(
                                onPressed: _submissionStarted
                                    ? null
                                    : () => setState(() {
                                        _trackingStartDate = null;
                                        _trackingEdited = true;
                                      }),
                                icon: Icon(Icons.clear, size: 20.sp),
                              ),
                      ),
                      SizedBox(height: 10.h),

                      // 9. لوكيشن البيت
                      TextFormField(
                        enabled: !_submissionStarted,
                        controller: _locationController,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: context.tr.googleMapsUrlLabel,
                          prefixIcon: Icon(Icons.map_rounded, size: 20.sp),
                          suffixIcon: _isLoadingLocation
                              ? Padding(
                                  padding: EdgeInsets.all(12.r),
                                  child: SizedBox(
                                    width: 16.w,
                                    height: 16.h,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(Icons.my_location, size: 20.sp),
                                  color: AppColors.primaryLight,
                                  tooltip: context.tr.useCurrentLocation,
                                  onPressed: _submissionStarted
                                      ? null
                                      : _getCurrentLocation,
                                ),
                        ),
                      ),

                      // Section 3: الخدمة والرعاية
                      _buildSectionHeader(
                        context,
                        icon: Icons.supervised_user_circle_outlined,
                        title: context.tr.serviceAndCareSec,
                      ),

                      // الخادم المسؤول والفصل الدراسي وأخوة الرب
                      MakhdomServantClassSelector(
                        isDark: isDark,
                        disabled: _submissionStarted,
                        khodamList: widget.khodamList,
                        selectedKhademId: _selectedKhademId,
                        selectedKhademName: _selectedKhademName,
                        onKhademChanged: (id, name) {
                          setState(() {
                            _selectedKhademId = id;
                            _selectedKhademName = name;
                          });
                        },
                        firestoreService: _firestoreService,
                        serviceId: widget.initialMakhdom?.serviceId ?? 'thanawy',
                        gradeId: widget.initialMakhdom?.grade ?? AppConstants.grade1st,
                        selectedClassId: _selectedClassId,
                        onClassChanged: (id, name) {
                          setState(() {
                            _selectedClassId = id;
                            _selectedClassName = name;
                          });
                        },
                        isBrethren: _isBrethren,
                        onBrethrenChanged: (val) => setState(() => _isBrethren = val),
                      ),
                      SizedBox(height: 10.h),

                      // رابط الصورة
                      TextFormField(
                        enabled: !_submissionStarted,
                        controller: _photoController,
                        decoration: InputDecoration(
                          labelText: context.tr.photoUrlOptionalLabel,
                          prefixIcon: Icon(
                            Icons.image_outlined,
                            size: 20.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // ملاحظات
                      TextFormField(
                        enabled: !_submissionStarted,
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: context.tr.additionalNotesOptionalLabel,
                          prefixIcon: Icon(Icons.notes_rounded, size: 20.sp),
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              ),
            ),
              SizedBox(height: 14.h),

              if (_submissionStarted)
                Text(context.tr.messageFieldsAreLockedUntilConfirmationRetryTo),
              // Action buttons (Cancel & Save)
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        context.tr.cancel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50.h,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSave,
                        icon: _isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.check_circle_rounded, size: 20.sp),
                        label: Text(
                          _isLoading
                              ? context.tr.saving
                              : (isEdit
                                    ? context.tr.saveChanges
                                    : context.tr.save),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEdit
                              ? AppColors.accentBlue
                              : AppColors.primaryLight,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                        ),
                      ),
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
