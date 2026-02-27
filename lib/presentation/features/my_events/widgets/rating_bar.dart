import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// 5 顆星評分元件
class RatingBar extends StatelessWidget {
  final String label;
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final bool enabled;

  const RatingBar({
    super.key,
    required this.label,
    required this.rating,
    required this.onRatingChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colors.primaryText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          final starIndex = index + 1;
          final isSelected = starIndex <= rating;
          return GestureDetector(
            onTap: enabled ? () => onRatingChanged(starIndex) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 32,
                color: isSelected ? colors.tertiaryText : colors.tertiary,
              ),
            ),
          );
        }),
      ],
    );
  }
}
