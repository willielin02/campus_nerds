import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/auth_state_notifier.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../common/widgets/app_alert_dialog.dart';
import '../../../common/widgets/app_confirm_dialog.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_event.dart';
import '../../../features/auth/widgets/onboarding_step_progress.dart';
import '../bloc/bloc.dart';

/// School email verification page (Step 2 of onboarding)
/// Matching FlutterFlow design exactly
class SchoolEmailVerificationPage extends StatefulWidget {
  const SchoolEmailVerificationPage({super.key});

  @override
  State<SchoolEmailVerificationPage> createState() =>
      _SchoolEmailVerificationPageState();
}

class _SchoolEmailVerificationPageState
    extends State<SchoolEmailVerificationPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _codeFocusNode = FocusNode();

  bool _isExpanded = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _emailFocusNode.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      context.read<OnboardingBloc>().add(OnboardingSendCode(email));
    }
  }

  void _handleVerifyCode() {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (email.isNotEmpty && code.isNotEmpty) {
      context.read<OnboardingBloc>().add(
            OnboardingVerifyCode(schoolEmail: email, code: code),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        // Update router notifier — redirects happen automatically via GoRouter
        if (state.status == OnboardingStatus.codeVerified) {
          // School verified, but still needs basic info
          AuthStateNotifier.instance.updateProfileStatus(
            needsBasicInfo: true,
            needsSchoolVerification: false,
          );
        } else if (state.status == OnboardingStatus.completed) {
          // Fully onboarded (school verified + basic info already existed)
          AuthStateNotifier.instance.updateProfileStatus(
            needsBasicInfo: false,
            needsSchoolVerification: false,
          );
        } else if (state.errorMessage != null) {
          if (state.errorMessage == 'email_already_bound') {
            showAppAlertDialog(
              context: context,
              title: '此信箱已被綁定',
              message: '此學校信箱已被其他帳號使用。若您之前的帳號遺失或有任何疑問，請寄信至 team@campusnerds.app 聯絡客服。',
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: colors.error,
              ),
            );
          }
          context.read<OnboardingBloc>().add(const OnboardingClearError());
        }
        // Update expanded state when code is sent
        if (state.isCodeSent && !_isExpanded) {
          setState(() => _isExpanded = true);
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
                  // Header with back button (matching FlutterFlow)
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
                              context.read<AuthBloc>().add(const AuthSignOut());
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
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: const SizedBox(
                              width: double.infinity,
                              height: 24,
                              child: OnboardingStepProgress(
                                currentStep: 2,
                                totalSteps: 3,
                              ),
                            ),
                          ),

                          // Title - matching FlutterFlow exactly
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Row(
                              children: [
                                Text(
                                  'Step2 驗證您的學校信箱',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontFamily:
                                        GoogleFonts.notoSansTc().fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Subtitle - matching FlutterFlow exactly
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '為了確保最好的活動品質',
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontFamily:
                                        GoogleFonts.notoSansTc().fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Email field section
                          _buildEmailSection(colors, textTheme),

                          // Code field section (shown when expanded)
                          if (_isExpanded) _buildCodeSection(colors, textTheme),
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

  Widget _buildEmailSection(AppColorsTheme colors, TextTheme textTheme) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final canSend = state.cooldownSeconds == 0 && !state.isLoading;
        final buttonText = state.cooldownSeconds > 0
            ? '您可以在${state.cooldownSeconds}秒後重新發送驗證碼'
            : '發送驗證碼';

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label - matching FlutterFlow
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  '學校信箱',
                  style: textTheme.labelLarge?.copyWith(
                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    color: colors.secondaryText,
                  ),
                ),
              ),

              // Text field
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: colors.primaryText,
                    style: textTheme.bodyLarge?.copyWith(
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                      color: colors.primaryText,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '請輸入學校信箱',
                      hintStyle: textTheme.bodyLarge?.copyWith(
                        fontFamily: GoogleFonts.notoSansTc().fontFamily,
                        color: colors.tertiary,
                      ),
                      filled: true,
                      fillColor: colors.secondaryBackground,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colors.secondaryText,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colors.primaryText,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colors.error,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colors.error,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Send code button - matching FlutterFlow FFButtonWidget style
              Center(
                child: Opacity(
                opacity: canSend ? 1.0 : 0.5,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton(
                    onPressed: canSend ? _handleSendCode : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: colors.primaryBackground,
                      foregroundColor: colors.primaryText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: textTheme.bodyLarge?.copyWith(
                        fontFamily: GoogleFonts.notoSansTc().fontFamily,
                      ),
                    ),
                  ),
                ),
              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCodeSection(AppColorsTheme colors, TextTheme textTheme) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              // Verification code field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label - matching FlutterFlow
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      '驗證碼',
                      style: textTheme.labelLarge?.copyWith(
                        fontFamily: GoogleFonts.notoSansTc().fontFamily,
                        color: colors.secondaryText,
                      ),
                    ),
                  ),

                  // Text field
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextFormField(
                        controller: _codeController,
                        focusNode: _codeFocusNode,
                        keyboardType: TextInputType.number,
                        cursorColor: colors.primaryText,
                        style: textTheme.bodyLarge?.copyWith(
                          fontFamily: GoogleFonts.notoSansTc().fontFamily,
                          color: colors.primaryText,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: '請輸入驗證碼',
                          hintStyle: textTheme.bodyLarge?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                            color: colors.tertiary,
                          ),
                          filled: true,
                          fillColor: colors.secondaryBackground,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: colors.secondaryText,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: colors.primaryText,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: colors.error,
                              width: 2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
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

              // Verify button - matching FlutterFlow
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _handleVerifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.alternate,
                      foregroundColor: colors.primaryText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.status == OnboardingStatus.codeVerifying
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            '驗證',
                            style: textTheme.labelLarge?.copyWith(
                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
