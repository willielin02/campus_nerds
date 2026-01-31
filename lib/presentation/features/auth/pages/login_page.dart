import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../bloc/bloc.dart';
import '../widgets/onboarding_step_progress.dart';

/// Login page with Google/Apple sign-in
/// Matches FlutterFlow design exactly
///
/// When [allowGuest] is true (default): Initial login page, no back button, guest option available
/// When [allowGuest] is false: Must-login scenario, shows back button, no guest option
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.allowGuest = true,
  });

  final bool allowGuest;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isExpanded = false;

  void _handleGoogleSignIn() {
    context.read<AuthBloc>().add(const AuthSignInWithGoogle());
  }

  void _handleAppleSignIn() {
    context.read<AuthBloc>().add(const AuthSignInWithApple());
  }

  void _handleContinueAsGuest() {
    context.go(AppRoutes.home);
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go(AppRoutes.home);
        } else if (state.status == AuthStatus.needsSchoolVerification) {
          context.go(AppRoutes.schoolEmailVerification);
        } else if (state.status == AuthStatus.needsBasicInfo) {
          context.go(AppRoutes.basicInfo);
        } else if (state.status == AuthStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colors.error,
            ),
          );
          context.read<AuthBloc>().add(const AuthClearError());
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
                  // Header row: 64px height
                  Container(
                    width: double.infinity,
                    height: 64,
                    decoration: const BoxDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Show back button only when allowGuest is FALSE
                        if (!widget.allowGuest)
                          IconButton(
                            iconSize: 64,
                            icon: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: colors.secondaryText,
                              size: 24,
                            ),
                            onPressed: () => context.pop(),
                          ),
                        // 64px spacer on right
                        const SizedBox(width: 64, height: 64),
                      ],
                    ),
                  ),
                  // Main content
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Main content column
                            Container(
                              decoration: const BoxDecoration(),
                              child: Column(
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
                                  const Padding(
                                    padding: EdgeInsets.only(top: 32),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 24,
                                      child: OnboardingStepProgress(
                                        currentStep: 1,
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
                                          'Step1 登入 / 註冊',
                                          style: textTheme.titleMedium?.copyWith(
                                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Google sign-in button
                                  Padding(
                                    padding: const EdgeInsets.only(top: 24),
                                    child: _buildGoogleButton(colors, textTheme),
                                  ),
                                  // "更多登入方式" toggle
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: _buildMoreOptionsToggle(colors, textTheme),
                                  ),
                                ],
                              ),
                            ),
                            // Expanded options: Apple button
                            if (_isExpanded)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: _buildAppleButton(colors, textTheme),
                              ),
                            // Expanded options: Guest button (only when allowGuest is true)
                            if (_isExpanded && widget.allowGuest)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: _buildGuestButton(colors, textTheme),
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
        ),
      ),
    );
  }

  Widget _buildGoogleButton(AppColorsTheme colors, TextTheme textTheme) {
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        return InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: state.isLoading ? null : _handleGoogleSignIn,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.secondaryBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.tertiary, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: state.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.google,
                          color: colors.primaryText,
                          size: 24,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '使用 Google 繼續',
                            style: textTheme.bodyLarge?.copyWith(
                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoreOptionsToggle(AppColorsTheme colors, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: _toggleExpanded,
          child: Container(
            decoration: BoxDecoration(
              color: colors.secondaryBackground,
            ),
            child: Row(
              children: [
                Text(
                  '更多登入方式',
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.primaryText,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppleButton(AppColorsTheme colors, TextTheme textTheme) {
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        return InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: state.isLoading ? null : _handleAppleSignIn,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.secondaryBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.tertiary, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.apple,
                    color: colors.primaryText,
                    size: 28,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '使用 Apple 繼續',
                      style: textTheme.bodyLarge?.copyWith(
                        fontFamily: GoogleFonts.notoSansTc().fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuestButton(AppColorsTheme colors, TextTheme textTheme) {
    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: _handleContinueAsGuest,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.tertiary, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_rounded,
                color: colors.primaryText,
                size: 28,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '以訪客身分繼續',
                  style: textTheme.bodyLarge?.copyWith(
                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
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
