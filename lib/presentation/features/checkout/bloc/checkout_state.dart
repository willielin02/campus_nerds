import '../../../../domain/entities/checkout.dart';

/// Checkout page status
enum CheckoutStatus {
  initial,
  loading,
  loaded,
  creating,
  error,
}

/// Checkout BLoC state
class CheckoutState {
  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.studyProducts = const [],
    this.gamesProducts = const [],
    this.selectedStudyIndex = 1,
    this.selectedGamesIndex = 1,
    this.studyBalance = 0,
    this.gamesBalance = 0,
    this.orderResult,
    this.errorMessage,
    this.isRefreshing = false,
  });

  final CheckoutStatus status;
  final List<Product> studyProducts;
  final List<Product> gamesProducts;
  final int selectedStudyIndex;
  final int selectedGamesIndex;
  final int studyBalance;
  final int gamesBalance;
  final CreateOrderResult? orderResult;
  final String? errorMessage;
  final bool isRefreshing;

  /// Check if we have cached data
  bool get hasCachedData => studyProducts.isNotEmpty || gamesProducts.isNotEmpty;

  /// Get currently selected study product
  Product? get selectedStudyProduct {
    if (studyProducts.isEmpty) return null;
    final index = selectedStudyIndex.clamp(0, studyProducts.length - 1);
    return studyProducts[index];
  }

  /// Get currently selected games product
  Product? get selectedGamesProduct {
    if (gamesProducts.isEmpty) return null;
    final index = selectedGamesIndex.clamp(0, gamesProducts.length - 1);
    return gamesProducts[index];
  }

  CheckoutState copyWith({
    CheckoutStatus? status,
    List<Product>? studyProducts,
    List<Product>? gamesProducts,
    int? selectedStudyIndex,
    int? selectedGamesIndex,
    int? studyBalance,
    int? gamesBalance,
    CreateOrderResult? orderResult,
    String? errorMessage,
    bool? isRefreshing,
    bool clearOrderResult = false,
    bool clearError = false,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      studyProducts: studyProducts ?? this.studyProducts,
      gamesProducts: gamesProducts ?? this.gamesProducts,
      selectedStudyIndex: selectedStudyIndex ?? this.selectedStudyIndex,
      selectedGamesIndex: selectedGamesIndex ?? this.selectedGamesIndex,
      studyBalance: studyBalance ?? this.studyBalance,
      gamesBalance: gamesBalance ?? this.gamesBalance,
      orderResult: clearOrderResult ? null : (orderResult ?? this.orderResult),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}
