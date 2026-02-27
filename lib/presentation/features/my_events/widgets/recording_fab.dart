import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../bloc/recording_bloc.dart';
import '../bloc/recording_state.dart';
import '../bloc/recording_event.dart';

/// 錄音 FAB — 顯示在 EventDetailsPage 右下角
class RecordingFab extends StatelessWidget {
  const RecordingFab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordingBloc, RecordingState>(
      builder: (context, state) {
        // 只在可錄音/錄音中/已停止的狀態顯示
        if (state.phase == RecordingPhase.initial ||
            state.phase == RecordingPhase.uploading ||
            state.phase == RecordingPhase.analyzing ||
            state.phase == RecordingPhase.completed) {
          return const SizedBox.shrink();
        }

        final colors = context.appColors;
        final isRecording = state.phase == RecordingPhase.recording;
        final isPaused = state.phase == RecordingPhase.paused;
        final hasSegments = state.completedSegments.isNotEmpty;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 計時器（錄音中或暫停中時顯示）
            if (isRecording || isPaused)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  state.formattedCurrentDuration,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isRecording ? colors.tertiaryText : colors.secondaryText,
                  ),
                ),
              ),

            // FAB
            Stack(
              clipBehavior: Clip.none,
              children: [
                _AnimatedFab(
                  isRecording: isRecording,
                  icon: isRecording ? Icons.pause : Icons.mic,
                  backgroundColor:
                      isRecording ? colors.tertiaryText : colors.secondaryText,
                  onPressed: () => _handleTap(context, state),
                ),

                // 已錄段數 badge
                if (hasSegments)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 20, minHeight: 20),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: colors.tertiaryText,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${state.completedSegments.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.secondaryBackground,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _handleTap(BuildContext context, RecordingState state) {
    final bloc = context.read<RecordingBloc>();
    switch (state.phase) {
      case RecordingPhase.idle:
      case RecordingPhase.stopped:
      case RecordingPhase.error:
        bloc.add(const RecordingStart());
        break;
      case RecordingPhase.recording:
        bloc.add(const RecordingPause());
        break;
      case RecordingPhase.paused:
        bloc.add(const RecordingResume());
        break;
      default:
        break;
    }
  }
}

/// 帶閃爍動畫的 FAB（錄音中閃爍）
class _AnimatedFab extends StatefulWidget {
  final bool isRecording;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _AnimatedFab({
    required this.isRecording,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isRecording) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _AnimatedFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isRecording && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = widget.isRecording
            ? 0.5 + 0.5 * _controller.value
            : 1.0;
        return Opacity(
          opacity: opacity,
          child: FloatingActionButton(
            heroTag: 'recording_fab',
            onPressed: widget.onPressed,
            backgroundColor: widget.backgroundColor,
            child: Icon(widget.icon, color: Colors.white, size: 28),
          ),
        );
      },
    );
  }
}
