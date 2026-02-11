import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../common/widgets/app_confirm_dialog.dart';
import '../bloc/bloc.dart';

/// Facebook binding page
/// UI style based on login page as requested
class FacebookBindingPage extends StatelessWidget {
  const FacebookBindingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger a refresh each time the page is opened;
    // the bloc is a global singleton so cached state shows immediately
    context.read<FacebookBindingBloc>().add(const FacebookBindingCheckStatus());
    return const _FacebookBindingView();
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
              backgroundColor: colors.secondaryText,
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
                        // More menu (only when linked)
                        BlocBuilder<FacebookBindingBloc,
                            FacebookBindingState>(
                          builder: (context, state) {
                            if (!state.isLinked) {
                              return const SizedBox(width: 64, height: 64);
                            }
                            return IconButton(
                              iconSize: 64,
                              icon: Icon(
                                Icons.more_vert,
                                color: colors.secondaryText,
                                size: 24,
                              ),
                              onPressed: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  backgroundColor: colors.secondaryBackground,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  builder: (sheetContext) => SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.link_off,
                                          color: colors.secondaryText,
                                        ),
                                        title: Text(
                                          '解除綁定',
                                          style:
                                              textTheme.bodyLarge?.copyWith(
                                            fontFamily:
                                                GoogleFonts.notoSansTc()
                                                    .fontFamily,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.of(sheetContext).pop();
                                          _showUnlinkConfirmDialog(
                                              context, colors, textTheme);
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
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
                              padding: const EdgeInsets.only(top: 32, bottom: 24),
                              child:
                                  _buildFacebookButton(context, colors, textTheme),
                            ),
                            // Synced friends count (subtle info when linked)
                            BlocBuilder<FacebookBindingBloc,
                                FacebookBindingState>(
                              builder: (context, state) {
                                if (state.isLinked &&
                                    state.syncedFriendsCount != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '已同步 ${state.syncedFriendsCount} 位好友',
                                      style: textTheme.bodySmall?.copyWith(
                                        fontFamily:
                                            GoogleFonts.notoSansTc().fontFamily,
                                        color: colors.secondaryText,
                                      ),
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
                  ? colors.quaternary
                  : colors.secondaryText,
              borderRadius: BorderRadius.circular(24),
              border: isLinked
                  ? Border.all(color: colors.tertiary, width: 2)
                  : null,
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

  void _showUnlinkConfirmDialog(
    BuildContext context,
    AppColorsTheme colors,
    TextTheme textTheme,
  ) {
    showAppConfirmDialog(
      context: context,
      title: '確定要解除綁定嗎？',
      message: '解除綁定後，我們將無法在分組時避開你的臉書好友',
      confirmText: '確定解除',
      onConfirm: () {
        context
            .read<FacebookBindingBloc>()
            .add(const FacebookBindingUnlink());
      },
    );
  }
}
