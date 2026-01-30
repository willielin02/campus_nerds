import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Onboarding step progress indicator
///
/// Shows a horizontal progress bar with step indicators.
class OnboardingStepProgress extends StatelessWidget {
  const OnboardingStepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 24,
      child: Row(
        children: List.generate(totalSteps, (index) {
          final stepNumber = index + 1;
          final isCompleted = stepNumber < currentStep;
          final isCurrent = stepNumber == currentStep;
          final isActive = isCompleted || isCurrent;

          return Expanded(
            child: Row(
              children: [
                // Step circle
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? colors.primary : colors.tertiary,
                    border: isCurrent
                        ? Border.all(color: colors.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: colors.primaryText,
                          )
                        : Text(
                            '$stepNumber',
                            style: TextStyle(
                              color: isActive
                                  ? colors.primaryText
                                  : colors.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                // Connector line (except for last step)
                if (index < totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isCompleted ? colors.primary : colors.tertiary,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
