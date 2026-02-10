import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../domain/entities/checkout.dart';
import '../../../common/widgets/app_alert_dialog.dart';
import '../bloc/bloc.dart';

/// Checkout page for purchasing tickets
/// UI matches FlutterFlow design exactly.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    context.read<CheckoutBloc>().add(const CheckoutLoadProducts());
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
      context.read<CheckoutBloc>().add(const CheckoutLoadProducts());
    }
  }

  Future<void> _handlePurchase(Product product) async {
    if (_isPurchasing) return;

    // Check if user is logged in
    if (!SupabaseService.isAuthenticated) {
      await _showLoginRequiredDialog();
      return;
    }

    _isPurchasing = true;
    try {
      await showAppAlertDialog(
        context: context,
        title: '即將前往綠界付款頁面',
        message: '我們不會儲存您的信用卡資料，所有支付都透過「綠界科技 ECPay」完成。',
      );

      if (mounted) {
        context.read<CheckoutBloc>().add(CheckoutCreateOrder(product.id));
      }
    } finally {
      _isPurchasing = false;
    }
  }

  Future<void> _showLoginRequiredDialog() async {
    await showAppAlertDialog(
      context: context,
      title: '錯誤',
      message: '您目前尚未登入，請登入後再繼續操作。',
      buttonText: '確定',
    );

    if (mounted) {
      context.go('${AppRoutes.login}?allowGuest=false');
    }
  }

  Future<void> _launchCheckoutUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return BlocConsumer<CheckoutBloc, CheckoutState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colors.error,
            ),
          );
          context.read<CheckoutBloc>().add(const CheckoutClearError());
        }

        if (state.orderResult != null && state.orderResult!.success) {
          final checkoutUrl = state.orderResult!.checkoutUrl;
          if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
            _launchCheckoutUrl(checkoutUrl);
          }
          context.read<CheckoutBloc>().add(const CheckoutClearSuccess());
        }
      },
      builder: (context, state) {
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header row (back button only, no title)
                    _buildHeader(colors),
                    // Main content
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.primaryBackground,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: state.status == CheckoutStatus.loading
                              ? const Center(child: CircularProgressIndicator())
                              : _buildContent(colors, textTheme, state),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppColorsTheme colors) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: const BoxDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: colors.secondaryText,
              size: 24,
            ),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 64, height: 64),
        ],
      ),
    );
  }

  Widget _buildContent(
    AppColorsTheme colors,
    TextTheme textTheme,
    CheckoutState state,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Hero image
        Padding(
          padding: const EdgeInsets.fromLTRB(48, 8, 48, 0),
          child: Image.asset(
            'assets/images/Photoroom3.png',
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(height: 100),
          ),
        ),
        // Tab section
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: colors.primaryBackground,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        // TabBar
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
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildStudyTab(colors, textTheme, state),
                              _buildGamesTab(colors, textTheme, state),
                            ],
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
      ],
    );
  }

  Widget _buildStudyTab(
    AppColorsTheme colors,
    TextTheme textTheme,
    CheckoutState state,
  ) {
    return Container(
      decoration: const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            // Header row: subtitle + ticket balance
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 0, 0),
                    child: Text(
                      '和其他書呆子一起',
                      style: textTheme.titleMedium?.copyWith(
                        fontFamily: GoogleFonts.notoSansTc().fontFamily,
                      ),
                    ),
                  ),
                  _buildTicketBalanceBox(
                    colors,
                    textTheme,
                    state.studyBalance,
                    'assets/images/ticket_study_work.png',
                    colors.primary,
                  ),
                ],
              ),
            ),
            // Description row
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
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
            // Product cards
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: _buildProductCards(
                  colors,
                  textTheme,
                  state.studyProducts,
                  state.selectedStudyIndex,
                  (index) => context
                      .read<CheckoutBloc>()
                      .add(CheckoutSelectStudyProduct(index)),
                ),
              ),
            ),
            // Purchase button
            _buildPurchaseButton(
              colors,
              textTheme,
              state.studyProducts,
              state.selectedStudyIndex,
              state.status == CheckoutStatus.creating,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesTab(
    AppColorsTheme colors,
    TextTheme textTheme,
    CheckoutState state,
  ) {
    return Container(
      decoration: const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            // Header row: subtitle + ticket balance
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 0, 0),
                    child: Text(
                      '和其他書呆子一起',
                      style: textTheme.titleMedium?.copyWith(
                        fontFamily: GoogleFonts.notoSansTc().fontFamily,
                      ),
                    ),
                  ),
                  _buildTicketBalanceBox(
                    colors,
                    textTheme,
                    state.gamesBalance,
                    'assets/images/ticket_games_work2.png',
                    colors.secondary,
                  ),
                ],
              ),
            ),
            // Description row
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '封印中文，全程英文遊戲',
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
            // Product cards
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: _buildProductCards(
                  colors,
                  textTheme,
                  state.gamesProducts,
                  state.selectedGamesIndex,
                  (index) => context
                      .read<CheckoutBloc>()
                      .add(CheckoutSelectGamesProduct(index)),
                ),
              ),
            ),
            // Purchase button
            _buildPurchaseButton(
              colors,
              textTheme,
              state.gamesProducts,
              state.selectedGamesIndex,
              state.status == CheckoutStatus.creating,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketBalanceBox(
    AppColorsTheme colors,
    TextTheme textTheme,
    int balance,
    String imagePath,
    Color fallbackColor,
  ) {
    return Container(
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
              padding: const EdgeInsets.fromLTRB(2, 2, 0, 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.confirmation_number,
                    color: fallbackColor,
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
    );
  }

  Widget _buildProductCards(
    AppColorsTheme colors,
    TextTheme textTheme,
    List<Product> products,
    int selectedIndex,
    void Function(int) onSelect,
  ) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          '目前沒有可購買的票券',
          style: textTheme.bodyLarge?.copyWith(
            color: colors.secondaryText,
          ),
        ),
      );
    }

    return Row(
      children: products.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        final isSelected = index == selectedIndex;
        final isFirst = index == 0;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 2,
              right: index == products.length - 1 ? 0 : 2,
            ),
            child: InkWell(
              onTap: () => onSelect(index),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.secondaryBackground
                      : colors.primaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? colors.tertiaryText
                        : colors.quaternary,
                    width: isSelected ? 2 : 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Label
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              isFirst
                                  ? '探索'
                                  : '節省${product.percentOff}%',
                              style: textTheme.bodyMedium?.copyWith(
                                fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                color: isSelected
                                    ? colors.primaryText
                                    : colors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Divider
                    Divider(
                      thickness: isSelected ? 2.2 : 2,
                      color: isSelected ? colors.quaternary : colors.tertiary,
                    ),
                    // Pack size
                    Flexible(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${product.packSize}張票',
                              style: textTheme.labelMedium?.copyWith(
                                fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                color: isSelected
                                    ? colors.primaryText
                                    : colors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Unit price
                    Flexible(
                      flex: 2,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'NT\$${product.unitPriceTwd ?? product.priceTwd ~/ product.packSize}/張',
                              style: textTheme.bodyLarge?.copyWith(
                                fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                color: isSelected
                                    ? colors.primaryText
                                    : colors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPurchaseButton(
    AppColorsTheme colors,
    TextTheme textTheme,
    List<Product> products,
    int selectedIndex,
    bool isLoading,
  ) {
    if (products.isEmpty) return const SizedBox.shrink();

    final selectedProduct =
        products[selectedIndex.clamp(0, products.length - 1)];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Purchase button
        Padding(
          padding: const EdgeInsets.only(top: 32),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed:
                  isLoading ? null : () => _handlePurchase(selectedProduct),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.alternate,
                foregroundColor: colors.primaryText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: colors.primaryText,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      '以 NT\$ ${selectedProduct.priceTwd} 購買 ${selectedProduct.packSize} 張票',
                      style: textTheme.labelLarge?.copyWith(
                        fontFamily: GoogleFonts.notoSansTc().fontFamily,
                      ),
                    ),
            ),
          ),
        ),
        // Ticket expiration notice
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: Text(
            '票券效期：依最近一次購買日起 1 年內。',
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: GoogleFonts.notoSansTc().fontFamily,
            ),
          ),
        ),
      ],
    );
  }
}
