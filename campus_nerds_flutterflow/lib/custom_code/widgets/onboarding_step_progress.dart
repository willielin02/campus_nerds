// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class OnboardingStepProgress extends StatefulWidget {
  const OnboardingStepProgress({
    super.key,
    this.width,
    this.height,
    required this.currentStep, // 1-based
    this.totalSteps = 3,

    // Visual
    this.barHeight = 8,
    this.gap = 8,
    this.radius = 2,

    // Colors
    this.activeColor = const Color(0xFF57636c),
    this.inactiveColor = const Color(0xFFeeeef1),
    this.completedColor = const Color(0xFF57636c),

    /// Animation timings
    /// Fill duration (ms): 0 -> 100% with easeInOut
    this.fillMs = 2222,

    /// Fade duration (ms): after filled, opacity 1 -> 0 (easeOut)
    this.fadeMs = 1222,
  });

  /// FlutterFlow will pass these automatically.
  final double? width;
  final double? height;

  final int currentStep;
  final int totalSteps;

  /// Thickness of each step bar (NOT the widget height).
  final double barHeight;
  final double gap;
  final double radius;

  final Color activeColor;
  final Color inactiveColor;
  final Color completedColor;

  final int fillMs;
  final int fadeMs;

  @override
  State<OnboardingStepProgress> createState() => _OnboardingStepProgressState();
}

class _OnboardingStepProgressState extends State<OnboardingStepProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Duration _totalDuration() {
    final fill = widget.fillMs < 0 ? 0 : widget.fillMs;
    final fade = widget.fadeMs < 0 ? 0 : widget.fadeMs;
    final total = (fill + fade).clamp(1, 600000); // at least 1ms
    return Duration(milliseconds: total);
  }

  double _fillFraction() {
    final fill = widget.fillMs < 0 ? 0 : widget.fillMs;
    final fade = widget.fadeMs < 0 ? 0 : widget.fadeMs;
    final total = (fill + fade);
    if (total <= 0) return 1.0;
    return (fill / total).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration())
      ..repeat(); // 0 -> 1 -> reset -> repeat :contentReference[oaicite:1]{index=1}
  }

  @override
  void didUpdateWidget(covariant OnboardingStepProgress oldWidget) {
    super.didUpdateWidget(oldWidget);

    final timingsChanged =
        oldWidget.fillMs != widget.fillMs || oldWidget.fadeMs != widget.fadeMs;

    if (timingsChanged) {
      _controller
        ..stop()
        ..duration = _totalDuration()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalSteps.clamp(1, 50);
    final cur = (widget.currentStep - 1).clamp(0, total - 1);

    final barH = widget.barHeight <= 0 ? 8.0 : widget.barHeight;
    final widgetH =
        (widget.height == null || widget.height! <= 0) ? barH : widget.height!;

    final fillFrac = _fillFraction();
    final hasFade = (widget.fadeMs > 0) && (fillFrac < 1.0);

    // Active fill: easeInOut during [0, fillFrac], then stays at 1
    final fillAnim = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        0.0,
        fillFrac.clamp(0.0, 1.0),
        curve: Curves.easeInOut,
      ),
    );

    // Fade out: easeOut during [fillFrac, 1], opacity 1 -> 0
    final fadeAnim = hasFade
        ? CurvedAnimation(
            parent: _controller,
            curve: Interval(
              fillFrac.clamp(0.0, 1.0),
              1.0,
              curve: Curves.easeOut,
            ),
          )
        : null;

    return SizedBox(
      width: widget.width,
      height: widgetH,
      child: Row(
        children: List.generate(total, (i) {
          final isCompleted = i < cur;
          final isActive = i == cur;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == total - 1 ? 0 : widget.gap),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.radius),
                child: SizedBox(
                  height: barH,
                  child: Stack(
                    children: [
                      // Background
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? widget.completedColor
                                : widget.inactiveColor,
                          ),
                        ),
                      ),

                      // Active animated fill (fill -> fade -> reset)
                      if (isActive)
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              // After fill interval, keep progress at 1.0
                              final progress = (_controller.value >= fillFrac &&
                                      fillFrac > 0)
                                  ? 1.0
                                  : fillAnim.value;

                              final opacity = hasFade
                                  ? (1.0 - (fadeAnim?.value ?? 0.0))
                                      .clamp(0.0, 1.0)
                                  : 1.0;

                              return Opacity(
                                opacity: opacity,
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation(
                                      widget.activeColor),
                                  minHeight: barH,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
