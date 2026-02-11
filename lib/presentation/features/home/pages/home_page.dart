import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/event.dart';
import '../bloc/bloc.dart';
import '../widgets/city_selector_bottom_sheet.dart';
import '../widgets/event_card.dart';

/// Home page matching FlutterFlow design exactly
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    context.read<HomeBloc>().add(const HomeLoadData());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeBloc>().add(const HomeRefreshBalance());
    }
  }

  void _showCitySelector({required bool isFocusedStudy}) {
    final state = context.read<HomeBloc>().state;
    CitySelectorBottomSheet.show(
      context: context,
      cities: state.cities,
      selectedCity: state.selectedCity,
      category: isFocusedStudy
          ? CitySelectorCategory.focusedStudy
          : CitySelectorCategory.englishGames,
      eventCountsByCity: isFocusedStudy
          ? state.focusedStudyCountsByCity
          : state.englishGamesCountsByCity,
      onCitySelected: (city) {
        context.read<HomeBloc>().add(HomeChangeCity(city));
      },
    );
  }

  void _handleEventTap(Event event) {
    if (event.hasConflictSameSlot) {
      // Show conflict dialog
      _showConflictDialog();
    } else {
      // Navigate to booking confirmation with Event object
      if (event.isFocusedStudy) {
        context.push(AppRoutes.studyBookingConfirmation, extra: event);
      } else {
        context.push(AppRoutes.gamesBookingConfirmation, extra: event);
      }
    }
  }

  void _showConflictDialog() {
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '無法報名此活動',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '你在此日期的同一時段已經報名其他活動，請改選其他時段或日期。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.secondaryText,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('確定'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return GestureDetector(
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
                          child: BlocBuilder<HomeBloc, HomeState>(
                            builder: (context, state) {
                              return TabBarView(
                                controller: _tabController,
                                children: [
                                  // Focused Study tab
                                  _buildFocusedStudyTab(colors, textTheme, state),
                                  // English Games tab
                                  _buildEnglishGamesTab(colors, textTheme, state),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusedStudyTab(
    AppColorsTheme colors,
    TextTheme textTheme,
    HomeState state,
  ) {
    return Container(
      decoration: const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            // Header row: city selector (left) + ticket balance (right)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // City selector
                  InkWell(
                    onTap: () => _showCitySelector(isFocusedStudy: true),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_pin,
                          color: colors.secondaryText,
                          size: 32,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            state.selectedCityName,
                            style: textTheme.labelLarge?.copyWith(
                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ticket balance box
                  InkWell(
                    onTap: () {
                      context.push('${AppRoutes.checkout}?tabIndex=0');
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
                                  'assets/images/ticket_study_work.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.confirmation_number,
                                    color: colors.primary,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                '${state.ticketBalance.studyBalance}',
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
                  ),
                ],
              ),
            ),

            // Description text
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '和其他書呆子一起',
                          style: textTheme.titleMedium?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '交出手機，全程專注學習',
                          style: textTheme.titleMedium?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Events list
            Expanded(
              child: _buildEventsList(
                colors,
                textTheme,
                state.focusedStudyEvents,
                state.status == HomeStatus.loading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnglishGamesTab(
    AppColorsTheme colors,
    TextTheme textTheme,
    HomeState state,
  ) {
    return Container(
      decoration: const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            // Header row: city selector (left) + ticket balance (right)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // City selector
                  InkWell(
                    onTap: () => _showCitySelector(isFocusedStudy: false),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_pin,
                          color: colors.secondaryText,
                          size: 32,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            state.selectedCityName,
                            style: textTheme.labelLarge?.copyWith(
                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ticket balance box
                  InkWell(
                    onTap: () {
                      context.push('${AppRoutes.checkout}?tabIndex=1');
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
                                  'assets/images/ticket_games_work2.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.confirmation_number,
                                    color: colors.secondary,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                '${state.ticketBalance.gamesBalance}',
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
                  ),
                ],
              ),
            ),

            // Description text for English Games (different from Focused Study)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '和其他書呆子一起',
                          style: textTheme.titleMedium?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '用英文玩桌遊、密室逃脫',
                          style: textTheme.titleMedium?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Events list
            Expanded(
              child: _buildEventsList(
                colors,
                textTheme,
                state.englishGamesEvents,
                state.status == HomeStatus.loading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(
    AppColorsTheme colors,
    TextTheme textTheme,
    List<Event> events,
    bool isLoading,
  ) {
    if (isLoading) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: const _EventCardLoading(),
        ),
      );
    }

    if (events.isEmpty) {
      return Align(
        alignment: Alignment.topCenter,
        child: const _EventCardEmpty(),
      );
    }

    return ShaderMask(
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
          return InkWell(
            onTap: () => _handleEventTap(event),
            child: EventCard(
              event: event,
              onTap: () => _handleEventTap(event),
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton loading placeholder matching EventCard layout
class _EventCardLoading extends StatelessWidget {
  const _EventCardLoading();

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: date + time slot placeholder
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 160,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colors.alternate,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          width: 80,
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
              ],
            ),
          ),
          // Row 2: location placeholder
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 18),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Container(
                    width: 180,
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
        ],
      ),
    );
  }
}

/// Empty state widget
class _EventCardEmpty extends StatelessWidget {
  const _EventCardEmpty();

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
              Opacity(
                opacity: 0.8,
                child: Image.asset(
                  'assets/images/Gemini_Generated_Image_v0nidjv0nidjv0ni.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '很抱歉，\n目前這個城市沒有可報名的活動。',
                textAlign: TextAlign.left,
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
