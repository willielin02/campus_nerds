import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/repositories/checkout_repository.dart';
import '../../../../domain/repositories/my_events_repository.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';

/// Checkout BLoC for managing ticket purchase flow
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final CheckoutRepository _checkoutRepository;
  final MyEventsRepository _myEventsRepository;

  CheckoutBloc({
    required CheckoutRepository checkoutRepository,
    required MyEventsRepository myEventsRepository,
  })  : _checkoutRepository = checkoutRepository,
        _myEventsRepository = myEventsRepository,
        super(const CheckoutState()) {
    on<CheckoutLoadProducts>(_onLoadProducts);
    on<CheckoutSelectStudyProduct>(_onSelectStudyProduct);
    on<CheckoutSelectGamesProduct>(_onSelectGamesProduct);
    on<CheckoutCreateOrder>(_onCreateOrder);
    on<CheckoutClearError>(_onClearError);
    on<CheckoutClearSuccess>(_onClearSuccess);
  }

  /// Load products and user balance
  /// Uses stale-while-revalidate pattern: show cached data first, refresh in background
  Future<void> _onLoadProducts(
    CheckoutLoadProducts event,
    Emitter<CheckoutState> emit,
  ) async {
    // If we have cached data, show it immediately and refresh in background
    if (state.hasCachedData) {
      emit(state.copyWith(
        status: CheckoutStatus.loaded,
        isRefreshing: true,
      ));
    } else {
      // No cached data, show loading state
      emit(state.copyWith(status: CheckoutStatus.loading));
    }

    try {
      // Load products in parallel
      final studyProducts = await _checkoutRepository.getProducts('study');
      final gamesProducts = await _checkoutRepository.getProducts('games');
      final ticketBalance = await _myEventsRepository.getTicketBalance();

      // Determine selected indices
      // Only set default selection if this is the first load (no cached data)
      final selectedStudyIndex = state.hasCachedData
          ? state.selectedStudyIndex
          : (studyProducts.length > 1 ? 1 : 0);
      final selectedGamesIndex = state.hasCachedData
          ? state.selectedGamesIndex
          : (gamesProducts.length > 1 ? 1 : 0);

      emit(state.copyWith(
        status: CheckoutStatus.loaded,
        studyProducts: studyProducts,
        gamesProducts: gamesProducts,
        studyBalance: ticketBalance.studyBalance,
        gamesBalance: ticketBalance.gamesBalance,
        selectedStudyIndex: selectedStudyIndex,
        selectedGamesIndex: selectedGamesIndex,
        isRefreshing: false,
      ));
    } catch (e) {
      // If we have cached data, keep showing it even if refresh fails
      if (state.hasCachedData) {
        emit(state.copyWith(isRefreshing: false));
      } else {
        emit(state.copyWith(
          status: CheckoutStatus.error,
          errorMessage: '載入商品失敗',
        ));
      }
    }
  }

  /// Select study product by index
  void _onSelectStudyProduct(
    CheckoutSelectStudyProduct event,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(selectedStudyIndex: event.index));
  }

  /// Select games product by index
  void _onSelectGamesProduct(
    CheckoutSelectGamesProduct event,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(selectedGamesIndex: event.index));
  }

  /// Create order and get checkout URL
  Future<void> _onCreateOrder(
    CheckoutCreateOrder event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(status: CheckoutStatus.creating));

    try {
      final result = await _checkoutRepository.createOrder(event.productId);

      if (result.success) {
        emit(state.copyWith(
          status: CheckoutStatus.loaded,
          orderResult: result,
        ));
      } else {
        emit(state.copyWith(
          status: CheckoutStatus.loaded,
          errorMessage: result.errorMessage ?? '建立訂單失敗',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CheckoutStatus.loaded,
        errorMessage: '建立訂單失敗，請稍後再試',
      ));
    }
  }

  /// Clear error state
  void _onClearError(
    CheckoutClearError event,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }

  /// Clear success/order result state
  void _onClearSuccess(
    CheckoutClearSuccess event,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(clearOrderResult: true));
  }
}
