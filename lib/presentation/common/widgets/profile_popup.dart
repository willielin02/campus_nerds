import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Lightweight data holder for profile popup display
class ProfilePopupData {
  final String displayName;
  final String? gender;
  final String? universityName;
  final int? age;

  const ProfilePopupData({
    required this.displayName,
    this.gender,
    this.universityName,
    this.age,
  });

  String get ageDisplay => age != null ? '$age 歲' : '';
}

/// Shows a profile popup overlay anchored to a widget identified by [anchorKey].
/// The popup appears above or below depending on available space.
void showProfilePopup(BuildContext context, GlobalKey anchorKey, ProfilePopupData data) {
  final renderBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final overlay = Overlay.of(context);
  final position = renderBox.localToGlobal(Offset.zero);
  final headerSize = renderBox.size;
  final screenSize = MediaQuery.of(context).size;

  final spaceBelow = screenSize.height - position.dy - headerSize.height;
  final spaceAbove = position.dy;
  final showBelow = spaceBelow >= spaceAbove;

  late final OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (ctx) {
      return _ProfilePopupOverlay(
        data: data,
        anchorPosition: position,
        anchorSize: headerSize,
        showBelow: showBelow,
        onDismiss: () => overlayEntry.remove(),
      );
    },
  );

  overlay.insert(overlayEntry);
}

class _ProfilePopupOverlay extends StatelessWidget {
  const _ProfilePopupOverlay({
    required this.data,
    required this.anchorPosition,
    required this.anchorSize,
    required this.showBelow,
    required this.onDismiss,
  });

  final ProfilePopupData data;
  final Offset anchorPosition;
  final Size anchorSize;
  final bool showBelow;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Stack(
      children: [
        // Dismiss barrier
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        // Profile card
        Positioned(
          left: 32,
          right: 32,
          top: showBelow ? anchorPosition.dy + anchorSize.height + 8 : null,
          bottom: showBelow ? null : MediaQuery.of(context).size.height - anchorPosition.dy + 8,
          child: Material(
            color: Colors.transparent,
            child: _buildProfileCard(context, colors, textTheme),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    AppColorsTheme colors,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.quaternary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
                child: Image.asset(
                  data.gender == 'female'
                      ? 'assets/images/Gemini_Generated_Image_ajjb8yajjb8yajjb.png'
                      : 'assets/images/Gemini_Generated_Image_wn5duxwn5duxwn5d.png',
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => Container(
                    color: colors.alternate,
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: colors.primaryText,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Name and info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '書呆子 ${data.displayName}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.universityName ?? '',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.primaryText,
                      ),
                    ),
                    if (data.age != null)
                      Text(
                        '  |  ${data.ageDisplay}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.primaryText,
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
}
