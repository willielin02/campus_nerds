import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../bloc/bloc.dart';
import '../widgets/onboarding_step_progress.dart';

/// Login page with social auth (Google/Apple)
///
/// Allows users to sign in using Google or Apple accounts.
/// Also provides access to email login and guest mode.
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
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: colors.primaryBackground,
          body: SafeArea(
            child: Column(
              children: [
                // Header with back button
                _buildHeader(colors),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),

                        // Logo
                        _buildLogo(),

                        const SizedBox(height: 32),

                        // Progress indicator
                        const OnboardingStepProgress(
                          currentStep: 1,
                          totalSteps: 3,
                        ),

                        const SizedBox(height: 32),

                        // Title
                        _buildTitle(textTheme),

                        const SizedBox(height: 24),

                        // Google sign-in button
                        _buildGoogleButton(colors, textTheme),

                        const SizedBox(height: 16),

                        // More options toggle
                        _buildMoreOptionsToggle(colors, textTheme),

                        // Expanded options
                        if (_isExpanded) ...[
                          const SizedBox(height: 16),
                          _buildAppleButton(colors, textTheme),
                          const SizedBox(height: 16),
                          if (widget.allowGuest) _buildGuestButton(colors, textTheme),
                        ],

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!widget.allowGuest)
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: colors.secondaryText,
              ),
              onPressed: () => context.pop(),
            )
          else
            const SizedBox(width: 64),
          const SizedBox(width: 64),
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
          'Step1 登入 / 註冊',
          style: textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildGoogleButton(AppColorsTheme colors, TextTheme textTheme) {
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        return InkWell(
          onTap: state.isLoading ? null : _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.secondaryBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.tertiary, width: 2),
            ),
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
                      const FaIcon(FontAwesomeIcons.google, size: 24),
                      const SizedBox(width: 8),
                      Text('使用 Google 繼續', style: textTheme.bodyLarge),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildMoreOptionsToggle(AppColorsTheme colors, TextTheme textTheme) {
    return InkWell(
      onTap: _toggleExpanded,
      child: Container(
        color: colors.secondaryBackground,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('更多登入方式', style: textTheme.bodyMedium),
            const SizedBox(width: 4),
            Icon(
              _isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: colors.primaryText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleButton(AppColorsTheme colors, TextTheme textTheme) {
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        return InkWell(
          onTap: state.isLoading ? null : _handleAppleSignIn,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.secondaryBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.tertiary, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.apple, size: 28),
                const SizedBox(width: 8),
                Text('使用 Apple 繼續', style: textTheme.bodyLarge),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuestButton(AppColorsTheme colors, TextTheme textTheme) {
    return InkWell(
      onTap: _handleContinueAsGuest,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.tertiary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_rounded, color: colors.primaryText, size: 28),
            const SizedBox(width: 8),
            Text('以訪客身分繼續', style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
