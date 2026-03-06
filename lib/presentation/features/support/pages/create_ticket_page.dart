import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../domain/entities/support.dart';
import '../bloc/bloc.dart';

/// 建立工單頁
class CreateTicketPage extends StatelessWidget {
  const CreateTicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SupportBloc>(),
      child: const _CreateTicketView(),
    );
  }
}

class _CreateTicketView extends StatefulWidget {
  const _CreateTicketView();

  @override
  State<_CreateTicketView> createState() => _CreateTicketViewState();
}

class _CreateTicketViewState extends State<_CreateTicketView> {
  TicketCategory _category = TicketCategory.other;
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String? _imagePath;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _subjectController.text.trim().isNotEmpty &&
      _messageController.text.trim().isNotEmpty;

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
          '新建工單',
          style: typo.pageTitle.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<SupportBloc, SupportState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            context.pop(true); // 返回列表頁並通知刷新
          }
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
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Category dropdown
                    Text('分類', style: typo.detail.copyWith(color: colors.secondaryText)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: colors.secondaryBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.tertiary, width: 2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TicketCategory>(
                          value: _category,
                          isExpanded: true,
                          dropdownColor: colors.secondaryBackground,
                          style: typo.body.copyWith(color: colors.primaryText),
                          items: TicketCategory.values.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c.label),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _category = v);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Subject
                    Text('主旨', style: typo.detail.copyWith(color: colors.secondaryText)),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _subjectController,
                      hint: '簡述您遇到的問題',
                      colors: colors,
                      typo: typo,
                      maxLines: 1,
                    ),

                    const SizedBox(height: 16),
                    // Message
                    Text('描述', style: typo.detail.copyWith(color: colors.secondaryText)),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _messageController,
                      hint: '詳細說明問題內容',
                      colors: colors,
                      typo: typo,
                      maxLines: 5,
                    ),

                    const SizedBox(height: 16),
                    // Image picker
                    Text('附件（選填）', style: typo.detail.copyWith(color: colors.secondaryText)),
                    const SizedBox(height: 8),
                    if (_imagePath != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_imagePath!),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _imagePath = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colors.primaryText.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: colors.secondaryBackground,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          height: 80,
                          decoration: BoxDecoration(
                            color: colors.secondaryBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colors.tertiary,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: colors.secondaryText,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '選擇圖片',
                                style: typo.caption.copyWith(
                                  color: colors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Submit button
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              state.isCreating || !_canSubmit ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.alternate,
                            disabledBackgroundColor: colors.tertiary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: state.isCreating
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.secondaryBackground,
                                  ),
                                )
                              : Text(
                                  '提交工單',
                                  style: typo.body.copyWith(
                                    color: colors.secondaryText,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required AppColorsTheme colors,
    required AppTypography typo,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: typo.body.copyWith(color: colors.primaryText),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: typo.body.copyWith(color: colors.quaternary),
        filled: true,
        fillColor: colors.secondaryBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.tertiary, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.quaternary, width: 2),
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

  void _submit() {
    context.read<SupportBloc>().add(SupportCreateTicket(
          category: _category,
          subject: _subjectController.text.trim(),
          message: _messageController.text.trim(),
          imagePath: _imagePath,
        ));
  }
}
