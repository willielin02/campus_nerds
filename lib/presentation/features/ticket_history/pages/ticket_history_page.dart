import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/ticket_history.dart';
import '../bloc/bloc.dart';

/// Ticket History page for viewing ticket transaction records
/// UI matches the Home page TabBar style
class TicketHistoryPage extends StatefulWidget {
  const TicketHistoryPage({super.key});

  @override
  State<TicketHistoryPage> createState() => _TicketHistoryPageState();
}

class _TicketHistoryPageState extends State<TicketHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Load study entries initially
    context.read<TicketHistoryBloc>().add(const TicketHistoryLoadStudy());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      context.read<TicketHistoryBloc>().add(const TicketHistoryLoadStudy());
    } else {
      context.read<TicketHistoryBloc>().add(const TicketHistoryLoadGames());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '票券紀錄',
          style: textTheme.titleMedium?.copyWith(
            fontFamily: GoogleFonts.notoSansTc().fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: colors.primaryBackground,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // TabBar - matching Home page style exactly
                Align(
                  alignment: Alignment.center,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: colors.primaryText,
                    unselectedLabelColor: colors.tertiary,
                    labelStyle: textTheme.labelLarge?.copyWith(
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    ),
                    unselectedLabelStyle: textTheme.bodyLarge?.copyWith(
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    ),
                    indicatorColor: colors.secondaryText,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Focused Study'),
                      Tab(text: 'English Games'),
                    ],
                  ),
                ),

                // TabBarView
                Expanded(
                  child: BlocBuilder<TicketHistoryBloc, TicketHistoryState>(
                    builder: (context, state) {
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          // Focused Study tab - with horizontal padding like Home page
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildTabContent(
                              colors,
                              textTheme,
                              state.studyEntries,
                              state.status == TicketHistoryStatus.loading,
                              isStudy: true,
                              balance: state.ticketBalance.studyBalance,
                            ),
                          ),
                          // English Games tab - with horizontal padding like Home page
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildTabContent(
                              colors,
                              textTheme,
                              state.gamesEntries,
                              state.status == TicketHistoryStatus.loading,
                              isStudy: false,
                              balance: state.ticketBalance.gamesBalance,
                            ),
                          ),
                        ],
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
  }

  Widget _buildTabContent(
    AppColorsTheme colors,
    TextTheme textTheme,
    List<TicketHistoryEntry> entries,
    bool isLoading, {
    required bool isStudy,
    required int balance,
  }) {
    return Column(
      children: [
        // Ticket balance row - right aligned like Home page
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildTicketBalanceBox(colors, textTheme, isStudy, balance),
            ],
          ),
        ),

        // History list
        Expanded(
          child: _buildHistoryList(
            colors,
            textTheme,
            entries,
            isLoading,
            isStudy: isStudy,
          ),
        ),
      ],
    );
  }

  Widget _buildTicketBalanceBox(
    AppColorsTheme colors,
    TextTheme textTheme,
    bool isStudy,
    int balance,
  ) {
    final imageAsset = isStudy
        ? 'assets/images/ticket_study_work.png'
        : 'assets/images/ticket_games_work2.png';
    final iconColor = isStudy ? colors.primary : colors.secondary;
    final tabIndex = isStudy ? 0 : 1;

    return InkWell(
      onTap: () {
        context.push('${AppRoutes.checkout}?tabIndex=$tabIndex');
      },
      child: Container(
      width: 96,
      height: 48,
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.tertiary,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, top: 2, bottom: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.confirmation_number,
                    color: iconColor,
                    size: 28,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                '$balance',
                style: textTheme.labelLarge?.copyWith(
                  fontFamily: GoogleFonts.notoSansTc().fontFamily,
                  color: colors.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHistoryList(
    AppColorsTheme colors,
    TextTheme textTheme,
    List<TicketHistoryEntry> entries,
    bool isLoading, {
    required bool isStudy,
  }) {
    if (isLoading && entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (entries.isEmpty) {
      return _buildEmptyState(colors, textTheme);
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _TicketHistoryCard(
          entry: entry,
          isStudy: isStudy,
        );
      },
    );
  }

  Widget _buildEmptyState(AppColorsTheme colors, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.tertiary,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: colors.tertiary,
              ),
              const SizedBox(height: 12),
              Text(
                '目前沒有票券紀錄',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.secondaryText,
                  fontFamily: GoogleFonts.notoSansTc().fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card widget for displaying a single ticket history entry
/// Layout matches EventCard style exactly
class _TicketHistoryCard extends StatelessWidget {
  const _TicketHistoryCard({
    required this.entry,
    required this.isStudy,
  });

  final TicketHistoryEntry entry;
  final bool isStudy;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    final delta = isStudy ? entry.deltaStudy : entry.deltaGames;
    final isPositive = delta > 0;
    final deltaNumberText = isPositive ? '+ $delta ' : '- ${delta.abs()} ';

    // Format timestamp
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final formattedDate = dateFormat.format(entry.createdAt.toLocal());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.tertiary,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // First row: Reason + Delta (18px, top 16px, bottom 0px, Primary Text)
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.reason.displayText,
                  style: textTheme.labelLarge?.copyWith(
                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    color: colors.primaryText,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      deltaNumberText,
                      style: textTheme.labelLarge?.copyWith(
                        fontFamily: GoogleFonts.notoSansTc().fontFamily,
                        color: colors.primaryText,
                      ),
                    ),
                    Text(
                      '張',
                      style: textTheme.labelMedium?.copyWith(
                        fontFamily: GoogleFonts.notoSansTc().fontFamily,
                        color: colors.primaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Second row: Timestamp (12px, top 2px, bottom 0px, Secondary Text)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 16, right: 16),
            child: Row(
              children: [
                Text(
                  formattedDate,
                  style: textTheme.bodySmall?.copyWith(
                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    color: colors.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          // Third row: Description (14px, top 8px, bottom 16px, Primary Text)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    _getSimpleDescription(),
                    style: textTheme.bodyMedium?.copyWith(
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                      color: colors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get simplified description without the reason prefix
  String _getSimpleDescription() {
    switch (entry.reason) {
      case TicketLedgerReason.purchaseCredit:
        if (entry.orderDetail != null) {
          final ticketType =
              entry.orderDetail!.ticketType == 'study' ? 'Study票券' : 'Games票券';
          return '$ticketType ${entry.orderDetail!.packSize} 張';
        }
        return '票券';
      case TicketLedgerReason.bookingDebit:
        if (entry.bookingDetail != null) {
          return '${entry.bookingDetail!.cityName} ${entry.bookingDetail!.formattedDate}\n${entry.bookingDetail!.locationDetailText}';
        }
        return '活動';
      case TicketLedgerReason.bookingRefund:
        if (entry.bookingDetail != null) {
          return '${entry.bookingDetail!.cityName} ${entry.bookingDetail!.formattedDate}\n${entry.bookingDetail!.locationDetailText}';
        }
        return '活動';
      case TicketLedgerReason.adminAdjust:
        return '系統調整';
    }
  }
}
