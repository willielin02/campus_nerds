import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../bloc/bloc.dart';
import '../widgets/ticket_card.dart';

/// 工單列表頁（取代 ContactSupportPage）
class SupportTicketsPage extends StatelessWidget {
  const SupportTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SupportBloc>()..add(const SupportLoadTickets()),
      child: const _SupportTicketsView(),
    );
  }
}

class _SupportTicketsView extends StatelessWidget {
  const _SupportTicketsView();

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
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: colors.primaryText,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '聯絡客服',
          style: typo.pageTitle.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_rounded,
              color: colors.primaryText,
              size: 28,
            ),
            onPressed: () async {
              final result = await context.push(AppRoutes.createTicket);
              if (result == true && context.mounted) {
                context.read<SupportBloc>().add(const SupportLoadTickets());
              }
            },
          ),
        ],
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
          if (state.status == SupportStatus.loading && state.tickets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.tickets.isEmpty) {
            return _buildEmptyState(colors, typo, context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<SupportBloc>().add(const SupportLoadTickets());
              // 等待載入完成
              await context.read<SupportBloc>().stream.firstWhere(
                    (s) => s.status != SupportStatus.loading,
                  );
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              itemCount: state.tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ticket = state.tickets[index];
                return TicketCard(
                  ticket: ticket,
                  onTap: () async {
                    await context.push(
                      '${AppRoutes.supportTicketDetail}?ticketId=${ticket.id}',
                    );
                    if (context.mounted) {
                      context
                          .read<SupportBloc>()
                          .add(const SupportLoadTickets());
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    AppColorsTheme colors,
    AppTypography typo,
    BuildContext context,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.support_agent_outlined,
            size: 64,
            color: colors.secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            '尚無工單',
            style: typo.body.copyWith(color: colors.secondaryText),
          ),
          const SizedBox(height: 8),
          Text(
            '點擊右上角「+」建立新工單',
            style: typo.caption.copyWith(color: colors.quaternary),
          ),
        ],
      ),
    );
  }
}
