import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
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
      setState(() => _isExpanded = true);
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
        // Navigation after verification (matching FlutterFlow logic):
        // - codeVerified: User needs to fill basic info → BasicInfo page
        // - completed: User already has basic info → Home page
        if (state.status == OnboardingStatus.codeVerified) {
          context.go(AppRoutes.basicInfo);
        } else if (state.status == OnboardingStatus.completed) {
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
                  // Header row (64px height) - matching FlutterFlow
                  Container(
                    width: double.infinity,
                    height: 64,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: colors.secondaryText,
                              size: 24,
                            ),
                            onPressed: () => context.pop(),
                          ),
                        ),
                        Container(width: 64, height: 64),
                      ],
                    ),
                  ),

                  // Main content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
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
        final buttonText = canSend
            ? '發送驗證碼'
            : '您可以在${state.cooldownSeconds}秒後重新發送驗證碼';

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
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

              // Send code button - matching FlutterFlow style
              Opacity(
                opacity: canSend ? 1.0 : 0.5,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: canSend ? _handleSendCode : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: colors.primaryBackground,
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
                padding: const EdgeInsets.only(top: 16),
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
