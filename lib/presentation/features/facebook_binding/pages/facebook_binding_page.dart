import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../domain/repositories/facebook_repository.dart';
import '../bloc/bloc.dart';

/// Facebook binding page
/// UI style based on login page as requested
class FacebookBindingPage extends StatelessWidget {
  const FacebookBindingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FacebookBindingBloc(
        facebookRepository: getIt<FacebookRepository>(),
      )..add(const FacebookBindingCheckStatus()),
      child: const _FacebookBindingView(),
    );
  }
}

class _FacebookBindingView extends StatelessWidget {
  const _FacebookBindingView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return BlocListener<FacebookBindingBloc, FacebookBindingState>(
      listener: (context, state) {
        // Show success message
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ),
          );
          context
              .read<FacebookBindingBloc>()
              .add(const FacebookBindingClearError());
        }
        // Show error message
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colors.error,
            ),
          );
          context
              .read<FacebookBindingBloc>()
              .add(const FacebookBindingClearError());
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
                            // Title
                            Padding(
                              padding: const EdgeInsets.only(top: 32),
                              child: Row(
                                children: [
                                  Text(
                                    '臉書帳號綁定',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontFamily:
                                          GoogleFonts.notoSansTc().fontFamily,
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
                                      '綁定臉書帳號後，我們會在分組時避免將你與臉書好友分到同一組',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontFamily:
                                            GoogleFonts.notoSansTc().fontFamily,
                                        color: colors.secondaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Facebook button
                            Padding(
                              padding: const EdgeInsets.only(top: 32),
                              child:
                                  _buildFacebookButton(context, colors, textTheme),
                            ),
                            // Status info
                            BlocBuilder<FacebookBindingBloc,
                                FacebookBindingState>(
                              builder: (context, state) {
                                if (state.isLinked) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 24),
                                    child: Column(
                                      children: [
                                        // Linked status
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                                  Colors.green.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '臉書帳號已綁定',
                                                      style: textTheme.bodyLarge
                                                          ?.copyWith(
                                                        fontFamily: GoogleFonts
                                                                .notoSansTc()
                                                            .fontFamily,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    if (state.syncedFriendsCount !=
                                                        null)
                                                      Text(
                                                        '已同步 ${state.syncedFriendsCount} 位好友',
                                                        style: textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                          fontFamily: GoogleFonts
                                                                  .notoSansTc()
                                                              .fontFamily,
                                                          color: colors
                                                              .secondaryText,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Sync friends button
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 16),
                                          child: _buildSyncButton(
                                              context, colors, textTheme),
                                        ),
                                        // Unlink button
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: _buildUnlinkButton(
                                              context, colors, textTheme),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
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
        ),
      ),
    );
  }

  Widget _buildFacebookButton(
    BuildContext context,
    AppColorsTheme colors,
    TextTheme textTheme,
  ) {
    return BlocBuilder<FacebookBindingBloc, FacebookBindingState>(
      builder: (context, state) {
        final isLinked = state.isLinked;
        final isLoading = state.isLoading;

        return InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: isLoading
              ? null
              : () {
                  if (isLinked) {
                    // Already linked, do nothing or show management options
                  } else {
                    context
                        .read<FacebookBindingBloc>()
                        .add(const FacebookBindingLink());
                  }
                },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isLinked
                  ? colors.secondaryBackground.withOpacity(0.5)
                  : const Color(0xFF1877F2), // Facebook blue
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isLinked ? colors.tertiary : const Color(0xFF1877F2),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: isLoading && state.status == FacebookBindingStatus.linking
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.facebook,
                          color: isLinked ? colors.primaryText : Colors.white,
                          size: 24,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            isLinked ? '已綁定 Facebook 帳號' : '綁定 Facebook 帳號',
                            style: textTheme.bodyLarge?.copyWith(
                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                              color:
                                  isLinked ? colors.primaryText : Colors.white,
                              fontWeight: FontWeight.w600,
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

  Widget _buildSyncButton(
    BuildContext context,
    AppColorsTheme colors,
    TextTheme textTheme,
  ) {
    return BlocBuilder<FacebookBindingBloc, FacebookBindingState>(
      builder: (context, state) {
        final isLoading =
            state.isLoading && state.status == FacebookBindingStatus.syncing;

        return InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: isLoading
              ? null
              : () {
                  context
                      .read<FacebookBindingBloc>()
                      .add(const FacebookBindingSyncFriends());
                },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.secondaryBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.tertiary, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sync,
                          color: colors.primaryText,
                          size: 24,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '重新同步好友名單',
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

  Widget _buildUnlinkButton(
    BuildContext context,
    AppColorsTheme colors,
    TextTheme textTheme,
  ) {
    return BlocBuilder<FacebookBindingBloc, FacebookBindingState>(
      builder: (context, state) {
        final isLoading =
            state.isLoading && state.status == FacebookBindingStatus.unlinking;

        return InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: isLoading
              ? null
              : () {
                  _showUnlinkConfirmDialog(context, colors, textTheme);
                },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.error.withOpacity(0.5), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.error,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.link_off,
                          color: colors.error,
                          size: 24,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '解除綁定',
                            style: textTheme.bodyLarge?.copyWith(
                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                              color: colors.error,
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

  void _showUnlinkConfirmDialog(
    BuildContext context,
    AppColorsTheme colors,
    TextTheme textTheme,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '確定要解除綁定嗎？',
          style: textTheme.titleMedium?.copyWith(
            fontFamily: GoogleFonts.notoSansTc().fontFamily,
          ),
        ),
        content: Text(
          '解除綁定後，我們將無法在分組時避開你的臉書好友',
          style: textTheme.bodyMedium?.copyWith(
            fontFamily: GoogleFonts.notoSansTc().fontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              '取消',
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: GoogleFonts.notoSansTc().fontFamily,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<FacebookBindingBloc>()
                  .add(const FacebookBindingUnlink());
            },
            child: Text(
              '確定解除',
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: GoogleFonts.notoSansTc().fontFamily,
                color: colors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
