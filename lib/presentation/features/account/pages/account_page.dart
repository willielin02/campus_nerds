import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/user.dart';
import '../bloc/bloc.dart';

/// Account page matching FlutterFlow design exactly
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    context.read<AccountBloc>().add(const AccountLoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return BlocConsumer<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state.status == AccountStatus.loggedOut) {
          context.go(AppRoutes.loginEmail);
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colors.error,
            ),
          );
          context.read<AccountBloc>().add(const AccountClearError());
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.primaryBackground,
          body: SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: colors.primaryBackground,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile card
                        _buildProfileCard(colors, textTheme, state.profile),

                        // 帳號設定 section header
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            '帳號設定',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.primaryText,
                            ),
                          ),
                        ),

                        // Account settings container
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildSettingsContainer(
                            colors,
                            textTheme,
                            [
                              _SettingsItem(
                                icon: Icons.email_rounded,
                                title: '學校信箱驗證',
                                onTap: () {
                                  context.push(AppRoutes.schoolEmailVerification);
                                },
                              ),
                              _SettingsItem(
                                icon: Icons.confirmation_number_outlined,
                                title: '票券紀錄',
                                onTap: () {
                                  context.push(AppRoutes.checkout);
                                },
                              ),
                              _SettingsItem(
                                icon: Icons.facebook_rounded,
                                title: '臉書綁定',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('功能開發中')),
                                  );
                                },
                                isLast: true,
                              ),
                            ],
                          ),
                        ),

                        // 幫助 section header
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            '幫助',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.primaryText,
                            ),
                          ),
                        ),

                        // Help container
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildSettingsContainer(
                            colors,
                            textTheme,
                            [
                              _SettingsItem(
                                icon: Icons.question_mark_rounded,
                                title: '常見問題與使用說明',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('功能開發中')),
                                  );
                                },
                              ),
                              _SettingsItem(
                                icon: Icons.contact_mail_rounded,
                                title: '聯絡客服',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('功能開發中')),
                                  );
                                },
                                isLast: true,
                              ),
                            ],
                          ),
                        ),

                        // Logout container
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _buildLogoutContainer(colors, textTheme, state),
                        ),
                      ],
                    ),

                    // Bottom section - Version
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'v1.0.3 (103)',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.quaternary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(
    AppColorsTheme colors,
    TextTheme textTheme,
    UserProfile? profile,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.tertiary,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.alternate,
                borderRadius: BorderRadius.circular(48),
              ),
              child: ClipOval(
                child: profile?.avatarUrl != null
                    ? Image.network(
                        profile!.avatarUrl!,
                        fit: BoxFit.fill,
                        errorBuilder: (_, __, ___) => _buildDefaultAvatar(colors),
                      )
                    : Image.asset(
                        'assets/images/Gemini_Generated_Image_wn5duxwn5duxwn5d.png',
                        fit: BoxFit.fill,
                        errorBuilder: (_, __, ___) => _buildDefaultAvatar(colors),
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // Name and info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.displayNameWithPrefix ?? '書呆子',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      profile?.universityName ?? '',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                    Text(
                      '  |  ${profile?.ageDisplay ?? ''}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(AppColorsTheme colors) {
    return Container(
      color: colors.alternate,
      child: Icon(
        Icons.person,
        size: 32,
        color: colors.secondaryText,
      ),
    );
  }

  Widget _buildSettingsContainer(
    AppColorsTheme colors,
    TextTheme textTheme,
    List<_SettingsItem> items,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.tertiary,
          width: 2,
        ),
      ),
      child: Column(
        children: items.map((item) {
          return Column(
            children: [
              _buildSettingsRow(colors, textTheme, item),
              if (!item.isLast)
                Divider(
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colors.alternate,
                  height: 1,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsRow(
    AppColorsTheme colors,
    TextTheme textTheme,
    _SettingsItem item,
  ) {
    final isFirst = item == item; // placeholder for first item detection
    final isLast = item.isLast;

    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, isFirst ? 8 : 0, 8, isLast ? 8 : 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  item.icon,
                  color: colors.secondaryText,
                  size: 20,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 3),
                  child: Text(
                    item.title,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: item.onTap,
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                color: colors.secondaryText,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutContainer(
    AppColorsTheme colors,
    TextTheme textTheme,
    AccountState state,
  ) {
    return InkWell(
      onTap: state.status == AccountStatus.loggingOut
          ? null
          : () {
              context.read<AccountBloc>().add(const AccountLogout());
            },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.secondaryBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colors.tertiary,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  state.status == AccountStatus.loggingOut
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.secondaryText,
                          ),
                        )
                      : Icon(
                          Icons.logout_rounded,
                          color: colors.secondaryText,
                          size: 20,
                        ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 3),
                    child: Text(
                      '登出',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: null,
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.secondaryText,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLast;

  _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLast = false,
  });
}
