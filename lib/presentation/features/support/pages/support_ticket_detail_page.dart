import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../domain/entities/support.dart';
import '../bloc/bloc.dart';
import '../widgets/message_bubble.dart';

/// 工單對話頁
class SupportTicketDetailPage extends StatelessWidget {
  const SupportTicketDetailPage({
    super.key,
    required this.ticketId,
  });

  final String ticketId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<SupportBloc>()..add(SupportLoadMessages(ticketId)),
      child: _SupportTicketDetailView(ticketId: ticketId),
    );
  }
}

class _SupportTicketDetailView extends StatefulWidget {
  const _SupportTicketDetailView({required this.ticketId});

  final String ticketId;

  @override
  State<_SupportTicketDetailView> createState() =>
      _SupportTicketDetailViewState();
}

class _SupportTicketDetailViewState
    extends State<_SupportTicketDetailView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  String? _imagePath;
  bool _hasFocus = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _textController.text.trim().isNotEmpty || _imagePath != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.primaryText),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '工單詳情',
          style: typo.pageTitle.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<SupportBloc, SupportState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: colors.error,
              ),
            );
            context.read<SupportBloc>().add(const SupportClearError());
          }
        },
        builder: (context, state) {
          if (state.status == SupportStatus.loading &&
              state.messages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // 找到該工單以判斷是否已結案
          final ticket = state.tickets
              .where((t) => t.id == widget.ticketId)
              .firstOrNull;
          final isClosed = ticket?.status.isClosed ?? false;

          return SafeArea(
            child: Column(
              children: [
                // Messages list
                Expanded(
                  child: state.messages.isEmpty
                      ? Center(
                          child: Text(
                            '尚無訊息',
                            style: typo.body
                                .copyWith(color: colors.secondaryText),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            return MessageBubble(
                              message: state.messages[index],
                            );
                          },
                        ),
                ),
                // Input bar (hidden when closed)
                if (!isClosed)
                  _buildInputBar(context, colors, typo, state.isSending),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(
    BuildContext context,
    AppColorsTheme colors,
    AppTypography typo,
    bool isSending,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        border: Border(
          top: BorderSide(color: colors.tertiary, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview
            if (_imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_imagePath!),
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => setState(() => _imagePath = null),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: colors.primaryText.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: colors.secondaryBackground,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                // Attachment button
                IconButton(
                  icon: Icon(
                    Icons.attach_file_rounded,
                    color: colors.secondaryText,
                    size: 22,
                  ),
                  onPressed: isSending ? null : _pickImage,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                const SizedBox(width: 4),
                // Text field
                Expanded(
                  child: Focus(
                    onFocusChange: (f) => setState(() => _hasFocus = f),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.secondaryBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hasFocus
                              ? colors.quaternary
                              : colors.tertiary,
                          width: 2,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _canSend ? _send() : null,
                        style:
                            typo.detail.copyWith(color: colors.primaryText),
                        decoration: InputDecoration(
                          hintText: '輸入訊息',
                          hintStyle:
                              typo.detail.copyWith(color: colors.quaternary),
                          border: InputBorder.none,
                          isDense: true,
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Send button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _canSend && !isSending
                        ? colors.primary
                        : colors.tertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: _canSend && !isSending ? _send : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: isSending
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.secondaryBackground,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: colors.secondaryText,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _imagePath = result.files.single.path);
    }
  }

  void _send() {
    final content = _textController.text.trim();
    context.read<SupportBloc>().add(SupportSendMessage(
          ticketId: widget.ticketId,
          content: content.isNotEmpty ? content : null,
          imagePath: _imagePath,
        ));
    _textController.clear();
    setState(() => _imagePath = null);

    // 滾到底部
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
