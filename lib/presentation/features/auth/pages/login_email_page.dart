import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../bloc/bloc.dart';
import '../widgets/onboarding_step_progress.dart';

/// Login with Email page
///
/// Allows users to sign in or register with email/password.
/// This is the primary auth entry point (Step 1 of onboarding).
class LoginEmailPage extends StatefulWidget {
  const LoginEmailPage({super.key});

  @override
  State<LoginEmailPage> createState() => _LoginEmailPageState();
}

class _LoginEmailPageState extends State<LoginEmailPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthSignInWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthCreateAccount(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        // Handle auth state changes
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
                    child: Form(
                      key: _formKey,
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

                          const SizedBox(height: 16),

                          // Email field
                          _buildEmailField(colors, textTheme),

                          const SizedBox(height: 16),

                          // Password field
                          _buildPasswordField(colors, textTheme),

                          const SizedBox(height: 24),

                          // Sign in button
                          _buildSignInButton(colors, textTheme),

                          const SizedBox(height: 8),

                          // Register button
                          _buildRegisterButton(colors, textTheme),

                          const SizedBox(height: 32),
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
    );
  }

  Widget _buildHeader(AppColorsTheme colors) {
    return SizedBox(
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: colors.secondaryText,
            ),
            onPressed: () => context.pop(),
          ),
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
          // Fallback if image not found
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

  Widget _buildEmailField(AppColorsTheme colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email', style: textTheme.bodyLarge),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: textTheme.bodyLarge,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colors.secondaryBackground,
            hintStyle: textTheme.bodyLarge?.copyWith(color: colors.tertiary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.tertiary, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.error, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '請輸入電子郵件';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return '請輸入有效的電子郵件';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField(AppColorsTheme colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('密碼', style: textTheme.bodyLarge),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          style: textTheme.bodyLarge,
          onFieldSubmitted: (_) => _handleSignIn(),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colors.secondaryBackground,
            hintStyle: textTheme.bodyLarge?.copyWith(color: colors.tertiary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.tertiary, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.error, width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '請輸入密碼';
            }
            if (value.length < 6) {
              return '密碼長度至少需要 6 個字元';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSignInButton(AppColorsTheme colors, TextTheme textTheme) {
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: state.isLoading ? null : _handleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.alternate,
              foregroundColor: colors.secondaryText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('登入', style: textTheme.labelLarge),
          ),
        );
      },
    );
  }

  Widget _buildRegisterButton(AppColorsTheme colors, TextTheme textTheme) {
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        return SizedBox(
          height: 48,
          child: TextButton(
            onPressed: state.isLoading ? null : _handleRegister,
            style: TextButton.styleFrom(
              foregroundColor: colors.primaryText,
            ),
            child: Text('註冊', style: textTheme.bodyLarge),
          ),
        );
      },
    );
  }
}
