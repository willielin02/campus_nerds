import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/auth_state_notifier.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../common/widgets/app_confirm_dialog.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_event.dart';
import '../../../features/auth/widgets/onboarding_step_progress.dart';
import '../bloc/bloc.dart';

/// Basic info page (Step 3 of onboarding)
///
/// Users enter nickname, select gender and birthday to complete registration.
/// UI matches FlutterFlow BasicInfo0 design exactly.
class BasicInfoPage extends StatefulWidget {
  const BasicInfoPage({super.key});

  @override
  State<BasicInfoPage> createState() => _BasicInfoPageState();
}

class _BasicInfoPageState extends State<BasicInfoPage> {
  final _nicknameController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedBirthday;

  // Gender options matching FlutterFlow exactly
  static const List<String> _genderOptions = [
    '女性',
    '男性',
  ];

  bool get _canSubmit =>
      _nicknameController.text.trim().isNotEmpty &&
      _nicknameController.text.trim().length <= 12 &&
      _selectedGender != null &&
      _selectedBirthday != null;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  /// Convert display gender to database value
  String _genderToValue(String displayGender) {
    switch (displayGender) {
      case '女性':
        return 'female';
      case '男性':
        return 'male';
      case '其他/ 不願透露':
        return 'other';
      default:
        return 'other';
    }
  }

  Future<void> _handleBirthdaySelect() async {
    final colors = context.appColors;
    final now = AppClock.now();

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width,
          color: colors.secondaryBackground,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: DateTime(now.year - 18, now.month, now.day),
            minimumDate: DateTime(now.year - 100, now.month, now.day),
            maximumDate: DateTime(now.year - 18, now.month, now.day),
            backgroundColor: colors.secondaryBackground,
            onDateTimeChanged: (DateTime newDate) {
              setState(() => _selectedBirthday = newDate);
            },
          ),
        );
      },
    );
  }

  void _handleSubmit() {
    if (_canSubmit) {
      context.read<OnboardingBloc>().add(
            OnboardingUpdateBasicInfo(
              nickname: _nicknameController.text.trim(),
              gender: _genderToValue(_selectedGender!),
              birthday: _selectedBirthday!,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state.status == OnboardingStatus.completed) {
          AuthStateNotifier.instance.updateProfileStatus(
            needsBasicInfo: false,
            needsSchoolVerification: false,
          );
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colors.error,
            ),
          );
          context.read<OnboardingBloc>().add(const OnboardingClearError());
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          backgroundColor: colors.primaryBackground,
          body: SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: colors.primaryBackground,
              ),
              child: Column(
                children: [
                  // Header (64h)
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: colors.secondaryText,
                            size: 24,
                          ),
                          iconSize: 64,
                          padding: EdgeInsets.zero,
                          onPressed: () => showAppConfirmDialog(
                            context: context,
                            title: '確定要登出嗎？',
                            message: '登出後將返回登入頁面，您需要重新登入才能繼續。',
                            confirmText: '確定登出',
                            onConfirm: () {
                              context
                                  .read<AuthBloc>()
                                  .add(const AuthSignOut());
                            },
                          ),
                        ),
                        const SizedBox(width: 64, height: 64),
                      ],
                    ),
                  ),

                  // Main content
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                          // Logo
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32),
                            child: Image.asset(
                              'assets/images/Photoroom3.png',
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: Text(
                                      'Campus Nerds',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Progress indicator
                          const Padding(
                            padding: EdgeInsets.only(top: 32),
                            child: SizedBox(
                              width: double.infinity,
                              height: 24,
                              child: OnboardingStepProgress(
                                currentStep: 3,
                                totalSteps: 3,
                              ),
                            ),
                          ),

                          // Title
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Row(
                              children: [
                                Text(
                                  'Step3 輸入您的基本資料',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontFamily: fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Subtitle
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '為了提供您更精準的活動分配',
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontFamily: fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Nickname field
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: Text(
                                    '暱稱',
                                    style: textTheme.labelLarge?.copyWith(
                                      fontFamily: fontFamily,
                                      color: colors.secondaryText,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: TextFormField(
                                      controller: _nicknameController,
                                      maxLength: 12,
                                      cursorColor: colors.primaryText,
                                      onChanged: (_) => setState(() {}),
                                      style: textTheme.bodyLarge?.copyWith(
                                        fontFamily: fontFamily,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        hintText: '請輸入暱稱 ( 至多 12 個字 ) ',
                                        hintStyle:
                                            textTheme.bodyLarge?.copyWith(
                                          fontFamily: fontFamily,
                                          color: colors.primaryText,
                                        ),
                                        counterText: '',
                                        filled: true,
                                        fillColor: colors.secondaryBackground,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: colors.tertiary,
                                            width: 2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: colors.quaternary,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: colors.error,
                                            width: 2,
                                          ),
                                        ),
                                        focusedErrorBorder:
                                            OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: colors.error,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Gender + Birthday row (side by side)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              children: [
                                // Gender dropdown
                                Flexible(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(right: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 2),
                                          child: Text(
                                            '性別',
                                            style: textTheme.labelLarge
                                                ?.copyWith(
                                              fontFamily: fontFamily,
                                              color: colors.secondaryText,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 8),
                                          child: Container(
                                            width: double.infinity,
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: colors
                                                  .secondaryBackground,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: colors.tertiary,
                                                width: 2,
                                              ),
                                            ),
                                            child:
                                                DropdownButtonHideUnderline(
                                              child:
                                                  DropdownButton<String>(
                                                value: _selectedGender,
                                                hint: Text(
                                                  '請選擇性別',
                                                  style: textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                    fontFamily: fontFamily,
                                                  ),
                                                ),
                                                isExpanded: true,
                                                icon: Icon(
                                                  Icons
                                                      .keyboard_arrow_down_rounded,
                                                  color: colors
                                                      .secondaryText,
                                                  size: 32,
                                                ),
                                                dropdownColor: colors
                                                    .secondaryBackground,
                                                elevation: 2,
                                                style: textTheme.bodyLarge
                                                    ?.copyWith(
                                                  fontFamily: fontFamily,
                                                ),
                                                items: _genderOptions
                                                    .map((String gender) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: gender,
                                                    child: Text(
                                                      gender,
                                                      style: textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                        fontFamily:
                                                            fontFamily,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged:
                                                    (String? newValue) {
                                                  setState(() =>
                                                      _selectedGender =
                                                          newValue);
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Birthday picker
                                Flexible(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(left: 2),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 2),
                                          child: Text(
                                            '生日',
                                            style: textTheme.labelLarge
                                                ?.copyWith(
                                              fontFamily: fontFamily,
                                              color: colors.secondaryText,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 8),
                                          child: InkWell(
                                            splashColor:
                                                Colors.transparent,
                                            focusColor:
                                                Colors.transparent,
                                            hoverColor:
                                                Colors.transparent,
                                            highlightColor:
                                                Colors.transparent,
                                            onTap: _handleBirthdaySelect,
                                            child: Container(
                                              width: double.infinity,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: colors
                                                    .secondaryBackground,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8),
                                                border: Border.all(
                                                  color: colors.tertiary,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets
                                                            .only(
                                                            left: 10),
                                                    child: Text(
                                                      _selectedBirthday !=
                                                              null
                                                          ? '${_selectedBirthday!.year}/${_selectedBirthday!.month.toString().padLeft(2, '0')}/${_selectedBirthday!.day.toString().padLeft(2, '0')}'
                                                          : '請選擇生日',
                                                      style: textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                        fontFamily:
                                                            fontFamily,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Confirm button
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: _buildSubmitButton(colors, textTheme),
                          ),

                          // Footer note line 1
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Text(
                                  'Campus Nerds 提醒您：',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontFamily: fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Footer note line 2
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 16),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '基本資料提交後不可修改。若查證不實，將取消用戶資格。',
                                    style: textTheme.bodySmall?.copyWith(
                                      fontFamily: fontFamily,
                                    ),
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AppColorsTheme colors, TextTheme textTheme) {
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _canSubmit && !state.isLoading ? _handleSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.alternate,
              foregroundColor: colors.secondaryText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state.status == OnboardingStatus.basicInfoUpdating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    '確認',
                    style: textTheme.labelLarge?.copyWith(
                      fontFamily: fontFamily,
                      color: colors.secondaryText,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
