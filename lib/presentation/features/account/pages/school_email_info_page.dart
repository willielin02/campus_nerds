import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../bloc/bloc.dart';

/// 學校信箱資訊頁面
/// 已驗證：顯示綁定的學校信箱和學校名稱
/// 未驗證：導向驗證流程（由 Account 頁面判斷）
class SchoolEmailInfoPage extends StatelessWidget {
  const SchoolEmailInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 進入頁面時重新載入 profile
    context.read<AccountBloc>().add(const AccountLoadProfile());
    return const _SchoolEmailInfoView();
  }
}

class _SchoolEmailInfoView extends StatelessWidget {
  const _SchoolEmailInfoView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    return Scaffold(
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
              // Header row: 64px height with back button
              Container(
                width: double.infinity,
                height: 64,
                decoration: const BoxDecoration(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      iconSize: 64,
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: colors.secondaryText,
                        size: 24,
                      ),
                      onPressed: () => context.pop(),
                    ),
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
                        // Title
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Row(
                            children: [
                              Text(
                                '學校信箱驗證',
                                style: textTheme.titleMedium?.copyWith(
                                  fontFamily: fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Description
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '為了確保活動品質，我們需要驗證所有參與者的大學生身分。',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontFamily: fontFamily,
                                    color: colors.secondaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Verified status button (matching Facebook binding style)
                        Padding(
                          padding: const EdgeInsets.only(top: 32, bottom: 24),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colors.quaternary,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colors.tertiary,
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    color: colors.primaryText,
                                    size: 24,
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(left: 12),
                                    child: Text(
                                      '已驗證學校信箱',
                                      style: textTheme.bodyLarge?.copyWith(
                                        fontFamily: fontFamily,
                                        color: colors.primaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // School email info
                        BlocBuilder<AccountBloc, AccountState>(
                          builder: (context, state) {
                            final email = state.profile?.schoolEmail;
                            if (email == null) {
                              return const SizedBox.shrink();
                            }
                            final school =
                                state.profile?.universityName ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '你的學校：$school',
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontFamily: fontFamily,
                                      color: colors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '你的信箱：$email',
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontFamily: fontFamily,
                                      color: colors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
    );
  }
}
