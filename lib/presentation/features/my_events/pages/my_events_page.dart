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

    // 如果有 pendingTabIndex，立即套用
    final pending = context.read<MyEventsBloc>().state.pendingTabIndex;
    if (pending != null) {
      _tabController.index = pending;
      context.read<MyEventsBloc>().add(const MyEventsClearPendingTab());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleEventTap(MyEvent event) {
    final route = event.isFocusedStudy
        ? '${AppRoutes.eventDetailsStudy}?bookingId=${event.bookingId}'
        : '${AppRoutes.eventDetailsGames}?bookingId=${event.bookingId}';
    context.push(route).then((_) {
      if (mounted) {
        context.read<MyEventsBloc>().add(const MyEventsRefresh());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;

    return BlocListener<MyEventsBloc, MyEventsState>(
      listenWhen: (prev, curr) =>
          curr.pendingTabIndex != null && prev.pendingTabIndex != curr.pendingTabIndex,
      listener: (context, state) {
        if (state.pendingTabIndex != null) {
          _tabController.animateTo(state.pendingTabIndex!);
          context.read<MyEventsBloc>().add(const MyEventsClearPendingTab());
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
                          const SizedBox(height: 6),
                          // TabBar - matching FlutterFlow exactly
                          Align(
                            alignment: Alignment.center,
                            child: TabBar(
                              controller: _tabController,
                              labelColor: colors.secondaryText,
                              unselectedLabelColor: colors.tertiary,
                              labelStyle: typo.heading.copyWith(
                                fontFamily: GoogleFonts.notoSansTc().fontFamily,
                              ),
                              unselectedLabelStyle: typo.body.copyWith(
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
                                      state.upcomingEvents,
                                      state.status == MyEventsStatus.loading,
                                      isUpcoming: true,
                                    ),
                                    // History tab
                                    _buildEventsList(
                                      colors,
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
              Expanded(
                child: isUpcoming
                    ? _MyEventCardEmptyUpcoming(onGoHome: () => context.go(AppRoutes.home))
                    : const _MyEventCardEmptyHistory(),
              )
            else
              Expanded(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.03, 0.97, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
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
                  Container(
                    width: 48,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colors.alternate,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      width: 108,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colors.alternate,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      width: 48,
                      height: 20,
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
                  Container(
                    width: 48,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colors.alternate,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      width: 128,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colors.alternate,
                        borderRadius: BorderRadius.circular(6),
                      ),
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
  const _MyEventCardEmptyUpcoming({required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;

    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight * 0.25,
              child: Image.asset(
                'assets/images/black_only_transparent.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '快去探索新活動！',
              style: typo.heading.copyWith(
                color: colors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '首頁有好多活動正在等著你',
              style: typo.detail.copyWith(
                color: colors.tertiaryText,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    spreadRadius: -2,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: onGoHome,
                style: TextButton.styleFrom(
                  backgroundColor: colors.alternate,
                  foregroundColor: colors.secondaryText,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '去逛逛',
                  style: typo.body.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ),
            ),
          ],
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
    final typo = context.appTypography;

    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight * 0.25,
              child: Image.asset(
                'assets/images/black_only_transparent_2.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '還沒有回憶呢',
              style: typo.heading.copyWith(
                color: colors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '參加活動後，精采回顧都會在這裡！',
              style: typo.detail.copyWith(
                color: colors.tertiaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
