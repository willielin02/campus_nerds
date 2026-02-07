import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/booking.dart';
import '../bloc/bloc.dart';
import '../widgets/my_event_card.dart';

/// My Events page matching FlutterFlow design exactly
class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<MyEventsBloc>().add(const MyEventsLoadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleEventTap(MyEvent event) {
    if (event.isFocusedStudy) {
      context.push(
        '${AppRoutes.eventDetailsStudy}?bookingId=${event.bookingId}',
      );
    } else {
      context.push(
        '${AppRoutes.eventDetailsGames}?bookingId=${event.bookingId}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return BlocListener<MyEventsBloc, MyEventsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colors.error,
            ),
          );
          context.read<MyEventsBloc>().add(const MyEventsClearError());
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: colors.success,
            ),
          );
          context.read<MyEventsBloc>().add(const MyEventsClearSuccess());
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          backgroundColor: colors.primaryBackground,
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
                    Expanded(
                      child: Column(
                        children: [
                          // TabBar - matching FlutterFlow exactly
                          Align(
                            alignment: Alignment.center,
                            child: TabBar(
                              controller: _tabController,
                              labelColor: colors.secondaryText,
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
                                Tab(text: 'Upcoming'),
                                Tab(text: 'History'),
                              ],
                            ),
                          ),

                          // TabBarView
                          Expanded(
                            child: BlocBuilder<MyEventsBloc, MyEventsState>(
                              builder: (context, state) {
                                return TabBarView(
                                  controller: _tabController,
                                  children: [
                                    // Upcoming tab
                                    _buildEventsList(
                                      colors,
                                      textTheme,
                                      state.upcomingEvents,
                                      state.status == MyEventsStatus.loading,
                                      isUpcoming: true,
                                    ),
                                    // History tab
                                    _buildEventsList(
                                      colors,
                                      textTheme,
                                      state.pastEvents,
                                      state.status == MyEventsStatus.loading,
                                      isUpcoming: false,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ].map((widget) {
                    // Add 12px spacing between children (matching FlutterFlow's .divide)
                    return widget;
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(
    AppColorsTheme colors,
    TextTheme textTheme,
    List<MyEvent> events,
    bool isLoading, {
    required bool isUpcoming,
  }) {
    return Container(
      decoration: const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            if (isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: const _MyEventCardLoading(),
                ),
              )
            else if (events.isEmpty)
              isUpcoming
                  ? const _MyEventCardEmptyUpcoming()
                  : const _MyEventCardEmptyHistory()
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
                  shrinkWrap: true,
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return MyEventCard(
                      event: event,
                      onTap: () => _handleEventTap(event),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading placeholder matching MyEventCard layout
class _MyEventCardLoading extends StatelessWidget {
  const _MyEventCardLoading();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: category + status badge placeholder
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 144,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colors.alternate,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          width: 48,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colors.alternate,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.quaternary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            // Row 2: time placeholder
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Text(
                    '時間： ',
                    style: textTheme.labelMedium?.copyWith(
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    ),
                  ),
                  Container(
                    width: 108,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.alternate,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      width: 48,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colors.alternate,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Row 3: location placeholder
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 18),
              child: Row(
                children: [
                  Text(
                    '地點： ',
                    style: textTheme.labelMedium?.copyWith(
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    ),
                  ),
                  Container(
                    width: 128,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.alternate,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state for upcoming events
class _MyEventCardEmptyUpcoming extends StatelessWidget {
  const _MyEventCardEmptyUpcoming();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
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
                Icons.event_available_outlined,
                size: 48,
                color: colors.tertiary,
              ),
              const SizedBox(height: 12),
              Text(
                '目前沒有即將到來的活動',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state for history events
class _MyEventCardEmptyHistory extends StatelessWidget {
  const _MyEventCardEmptyHistory();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
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
                Icons.history,
                size: 48,
                color: colors.tertiary,
              ),
              const SizedBox(height: 12),
              Text(
                '目前沒有過去的活動',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
