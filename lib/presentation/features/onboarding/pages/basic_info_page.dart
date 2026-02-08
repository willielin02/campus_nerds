import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../features/auth/widgets/onboarding_step_progress.dart';
import '../bloc/bloc.dart';

/// Basic info page (Step 3 of onboarding)
///
/// Users enter nickname, select gender and birthday to complete registration.
/// UI matches FlutterFlow design exactly.
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
    '其他/ 不願透露',
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

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        DateTime tempDate = _selectedBirthday ?? DateTime(2000, 1, 1);
        return Container(
          height: 300,
          color: colors.secondaryBackground,
          child: Column(
            children: [
              // Header with Done button
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.secondaryBackground,
                  border: Border(
                    bottom: BorderSide(
                      color: colors.tertiary,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '取消',
                        style: GoogleFonts.notoSansTc(
                          color: colors.secondaryText,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() => _selectedBirthday = tempDate);
                        Navigator.pop(context);
                      },
                      child: Text(
                        '確定',
                        style: GoogleFonts.notoSansTc(
                          color: colors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Date picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  minimumDate: DateTime(1950, 1, 1),
                  maximumDate: DateTime.now().subtract(
                    const Duration(days: 365 * 16),
                  ), // Must be at least 16
                  onDateTimeChanged: (DateTime newDate) {
                    tempDate = newDate;
                  },
                ),
              ),
            ],
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

    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state.status == OnboardingStatus.completed) {
          // Onboarding complete, go to home
          context.go(AppRoutes.home);
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
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: colors.primaryBackground,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(colors),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        _buildLogo(),
                        const SizedBox(height: 32),
                        const SizedBox(
                          width: double.infinity,
                          height: 24,
                          child: OnboardingStepProgress(
                            currentStep: 3,
                            totalSteps: 3,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildTitle(textTheme),
                        const SizedBox(height: 8),
                        _buildSubtitle(textTheme, colors),
                        const SizedBox(height: 32),
                        _buildNicknameField(colors, textTheme),
                        const SizedBox(height: 24),
                        _buildGenderDropdown(colors, textTheme),
                        const SizedBox(height: 24),
                        _buildBirthdayField(colors, textTheme),
                        const SizedBox(height: 48),
                        _buildSubmitButton(colors, textTheme),
                        const SizedBox(height: 24),
                        _buildFooterNote(colors, textTheme),
                        const SizedBox(height: 32),
                      ],
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

  Widget _buildHeader(AppColorsTheme colors) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: colors.secondaryText,
            ),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitle(TextTheme textTheme) {
    return Row(
      children: [
        Text(
          'Step3 輸入您的基本資料',
          style: textTheme.titleMedium?.copyWith(
            fontFamily: GoogleFonts.notoSansTc().fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(TextTheme textTheme, AppColorsTheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '為了提供您更精準的活動分配',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.secondaryText,
            fontFamily: GoogleFonts.notoSansTc().fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildNicknameField(AppColorsTheme colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '暱稱',
          style: textTheme.bodyLarge?.copyWith(
            fontFamily: GoogleFonts.notoSansTc().fontFamily,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nicknameController,
          maxLength: 12,
          onChanged: (_) => setState(() {}),
          style: textTheme.bodyLarge?.copyWith(
            fontFamily: GoogleFonts.notoSansTc().fontFamily,
          ),
          decoration: InputDecoration(
            hintText: '請輸入暱稱 ( 至多 12 個字 )',
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colors.tertiary,
              fontFamily: GoogleFonts.notoSansTc().fontFamily,
            ),
            counterText: '', // Hide character counter
            filled: true,
            fillColor: colors.secondaryBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.tertiary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.tertiary, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.quaternary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown(AppColorsTheme colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '性別',
          style: textTheme.bodyLarge?.copyWith(
            fontFamily: GoogleFonts.notoSansTc().fontFamily,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.secondaryBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedGender != null ? colors.primary : colors.tertiary,
              width: 2,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              hint: Text(
                '請選擇性別',
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.tertiary,
                  fontFamily: GoogleFonts.notoSansTc().fontFamily,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color:
                    _selectedGender != null ? colors.primary : colors.tertiary,
              ),
              dropdownColor: colors.secondaryBackground,
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: GoogleFonts.notoSansTc().fontFamily,
              ),
              items: _genderOptions.map((String gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(
                    gender,
                    style: textTheme.bodyLarge?.copyWith(
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() => _selectedGender = newValue);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthdayField(AppColorsTheme colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '生日',
          style: textTheme.bodyLarge?.copyWith(
            fontFamily: GoogleFonts.notoSansTc().fontFamily,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _handleBirthdaySelect,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: colors.secondaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    _selectedBirthday != null ? colors.primary : colors.tertiary,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedBirthday != null
                      ? '${_selectedBirthday!.year}/${_selectedBirthday!.month.toString().padLeft(2, '0')}/${_selectedBirthday!.day.toString().padLeft(2, '0')}'
                      : '請選擇生日',
                  style: textTheme.bodyLarge?.copyWith(
                    color: _selectedBirthday != null
                        ? colors.primaryText
                        : colors.tertiary,
                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  color: _selectedBirthday != null
                      ? colors.primary
                      : colors.tertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AppColorsTheme colors, TextTheme textTheme) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _canSubmit && !state.isLoading ? _handleSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.alternate,
              foregroundColor: colors.secondaryText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: colors.tertiary,
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
                      fontSize: 18,
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFooterNote(AppColorsTheme colors, TextTheme textTheme) {
    return Text(
      'Campus Nerds 提醒您：基本資料提交後不可修改。若經查證不實，將取消使用者資格。',
      textAlign: TextAlign.center,
      style: textTheme.bodySmall?.copyWith(
        color: colors.secondaryText,
        fontFamily: GoogleFonts.notoSansTc().fontFamily,
      ),
    );
  }
}
