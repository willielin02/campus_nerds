import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/auth_state_notifier.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../common/widgets/app_alert_dialog.dart';
import '../../../common/widgets/app_confirm_dialog.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_event.dart';
import '../../../features/auth/widgets/onboarding_step_progress.dart';
import '../bloc/bloc.dart';

/// School email verification page (Step 3 of onboarding)
/// Two tabs: email verification (OTP) and document upload
class SchoolEmailVerificationPage extends StatefulWidget {
  const SchoolEmailVerificationPage({super.key});

  @override
  State<SchoolEmailVerificationPage> createState() =>
      _SchoolEmailVerificationPageState();
}

class _SchoolEmailVerificationPageState
    extends State<SchoolEmailVerificationPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _codeFocusNode = FocusNode();

  // Tab 2 state
  String? _docImagePath;

  bool _isExpanded = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _codeController.dispose();
    _emailFocusNode.dispose();
    _codeFocusNode.dispose();
    _tabController.dispose();
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

  Future<void> _pickDocImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _docImagePath = result.files.single.path);
    }
  }

  void _handleStudentIdSubmit() {
    if (_docImagePath == null) return;
    context.read<OnboardingBloc>().add(
          OnboardingSubmitStudentId(_docImagePath!),
        );
  }

  void _showPendingReviewDialog(String? message) {
    final colors = context.appColors;
    final typo = context.appTypography;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: 579,
          decoration: BoxDecoration(
            color: colors.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.tertiary, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    '已提交驗證申請',
                    style: typo.heading.copyWith(fontFamily: fontFamily),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    message ??
                        '我們會在 1-2 個工作天內完成人工審核，届時將以推播通知告知您結果。',
                    style: typo.detail.copyWith(fontFamily: fontFamily),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.alternate,
                        foregroundColor: colors.primaryText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '我知道了',
                        style: typo.body.copyWith(fontFamily: fontFamily),
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

  void _showVerifiedDialog() {
    final colors = context.appColors;
    final typo = context.appTypography;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: 579,
          decoration: BoxDecoration(
            color: colors.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.tertiary, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    '學校驗證成功',
                    style: typo.heading.copyWith(fontFamily: fontFamily),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    '已確認您的學校身分，歡迎加入 Campus Nerds！',
                    style: typo.detail.copyWith(fontFamily: fontFamily),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        AuthStateNotifier.instance.updateProfileStatus(
                          needsBasicInfo: false,
                          needsSchoolVerification: false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.alternate,
                        foregroundColor: colors.primaryText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '開始使用',
                        style: typo.body.copyWith(fontFamily: fontFamily),
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;

    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state.status == OnboardingStatus.codeVerified) {
          AuthStateNotifier.instance.updateProfileStatus(
            needsBasicInfo: true,
            needsSchoolVerification: false,
          );
        } else if (state.status == OnboardingStatus.completed) {
          AuthStateNotifier.instance.updateProfileStatus(
            needsBasicInfo: false,
            needsSchoolVerification: false,
          );
        } else if (state.status == OnboardingStatus.studentIdVerified) {
          _showVerifiedDialog();
        } else if (state.status == OnboardingStatus.studentIdPendingReview) {
          _showPendingReviewDialog(state.pendingReviewMessage);
          setState(() => _docImagePath = null);
        } else if (state.errorMessage != null) {
          if (state.errorMessage == 'email_already_bound') {
            showAppAlertDialog(
              context: context,
              title: '此信箱已被綁定',
              message: '此學校信箱已被其他帳號使用。若您之前的帳號遺失或有任何疑問，請聯絡客服。',
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
                  // Header with back button
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          // Logo
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 48),
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
                                  'Step3 驗證您的學校身分',
                                  style: typo.pageTitle.copyWith(
                                    fontFamily:
                                        GoogleFonts.notoSansTc().fontFamily,
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
                                  '為了確保最好的活動品質',
                                  style: typo.body.copyWith(
                                    fontFamily:
                                        GoogleFonts.notoSansTc().fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // TabBar — matching Home/TicketHistory style
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Align(
                              alignment: Alignment.center,
                              child: TabBar(
                                controller: _tabController,
                                labelColor: colors.primaryText,
                                unselectedLabelColor: colors.tertiary,
                                labelStyle: typo.heading.copyWith(
                                  fontFamily:
                                      GoogleFonts.notoSansTc().fontFamily,
                                ),
                                unselectedLabelStyle: typo.body.copyWith(
                                  fontFamily:
                                      GoogleFonts.notoSansTc().fontFamily,
                                ),
                                indicatorColor: colors.secondaryText,
                                dividerColor: Colors.transparent,
                                tabs: const [
                                  Tab(text: '信箱驗證'),
                                  Tab(text: '上傳證件'),
                                ],
                              ),
                            ),
                          ),

                          // Tab content
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildEmailTab(colors, typo),
                                _buildDocumentTab(colors, typo),
                              ],
                            ),
                          ),
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

  /// Tab 1: Email verification (existing OTP flow)
  Widget _buildEmailTab(AppColorsTheme colors, AppTypography typo) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildEmailSection(colors, typo),
          _buildCodeSection(colors, typo),
          _buildHelpText(colors, typo),
        ],
      ),
    );
  }

  /// Tab 2: Document upload for AI-powered school verification
  Widget _buildDocumentTab(AppColorsTheme colors, AppTypography typo) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final isSubmitting =
            state.status == OnboardingStatus.studentIdSubmitting;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        '學生證照片',
                        style: typo.detail.copyWith(
                          fontFamily: GoogleFonts.notoSansTc().fontFamily,
                          fontWeight: FontWeight.w600,
                          color: colors.secondaryText,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _docImagePath != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_docImagePath!),
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (!isSubmitting)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _docImagePath = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: colors.primaryText
                                              .withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color:
                                              colors.secondaryBackground,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : InkWell(
                              onTap: isSubmitting ? null : _pickDocImage,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: double.infinity,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: colors.secondaryBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colors.tertiary,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: colors.secondaryText,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '選擇圖片',
                                      style: typo.caption.copyWith(
                                        fontFamily: GoogleFonts.notoSansTc()
                                            .fontFamily,
                                        color: colors.secondaryText,
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

              // Submit button
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        _docImagePath != null && !isSubmitting
                            ? _handleStudentIdSubmit
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.alternate,
                      disabledBackgroundColor: colors.tertiary,
                      foregroundColor: colors.primaryText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.secondaryBackground,
                            ),
                          )
                        : Text(
                            '提交驗證申請',
                            style: typo.body.copyWith(
                              fontFamily:
                                  GoogleFonts.notoSansTc().fontFamily,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),

              _buildHelpText(colors, typo),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpText(AppColorsTheme colors, AppTypography typo) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: typo.caption.copyWith(
              fontFamily: GoogleFonts.notoSansTc().fontFamily,
              color: colors.tertiaryText,
            ),
            children: [
              const TextSpan(text: '需要協助？'),
              TextSpan(
                text: '聯繫我們',
                style: typo.caption.copyWith(
                  fontFamily: GoogleFonts.notoSansTc().fontFamily,
                  color: colors.secondaryText,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    context.push(AppRoutes.supportTickets);
                  },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailSection(AppColorsTheme colors, AppTypography typo) {
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
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  '學校信箱',
                  style: typo.detail.copyWith(
                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    fontWeight: FontWeight.w600,
                    color: colors.secondaryText,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: colors.primaryText,
                    style: typo.detail.copyWith(
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                      color: colors.primaryText,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '請輸入學校信箱',
                      hintStyle: typo.detail.copyWith(
                        fontFamily: GoogleFonts.notoSansTc().fontFamily,
                        color: colors.tertiary,
                      ),
                      filled: true,
                      fillColor: colors.secondaryBackground,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colors.tertiary,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colors.quaternary,
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
              Center(
                child: Opacity(
                opacity: (state.isLoading && !state.isCodeSent) ? 1.0 : (canSend ? 1.0 : 0.5),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton(
                    onPressed: canSend ? _handleSendCode : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: colors.primaryBackground,
                      disabledBackgroundColor: colors.primaryBackground,
                      foregroundColor: colors.primaryText,
                      disabledForegroundColor: colors.primaryText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: (state.isLoading && !state.isCodeSent) ? 0 : 1,
                          child: Text(
                            buttonText,
                            style: typo.detail.copyWith(
                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                            ),
                          ),
                        ),
                        if (state.isLoading && !state.isCodeSent)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.secondaryText,
                            ),
                          ),
                      ],
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

  Widget _buildCodeSection(AppColorsTheme colors, AppTypography typo) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final enabled = _isExpanded;
        return Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: IgnorePointer(
            ignoring: !enabled,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          '驗證碼',
                          style: typo.detail.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                            fontWeight: FontWeight.w600,
                            color: colors.secondaryText,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextFormField(
                            controller: _codeController,
                            focusNode: _codeFocusNode,
                            enabled: enabled,
                            keyboardType: TextInputType.number,
                            cursorColor: colors.primaryText,
                            style: typo.detail.copyWith(
                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                              color: colors.primaryText,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: '請輸入驗證碼',
                              hintStyle: typo.detail.copyWith(
                                fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                color: colors.tertiary,
                              ),
                              filled: true,
                              fillColor: colors.secondaryBackground,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colors.tertiary,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colors.quaternary,
                                  width: 2,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colors.tertiary,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (!enabled || state.isLoading) ? null : _handleVerifyCode,
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
                            style: typo.body.copyWith(
                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
}
