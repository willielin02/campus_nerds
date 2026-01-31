/// Checkout BLoC events
abstract class CheckoutEvent {
  const CheckoutEvent();
}

/// Load products for checkout
class CheckoutLoadProducts extends CheckoutEvent {
  const CheckoutLoadProducts();
}

/// Select a product for study tickets
class CheckoutSelectStudyProduct extends CheckoutEvent {
  const CheckoutSelectStudyProduct(this.index);
  final int index;
}

/// Select a product for games tickets
class CheckoutSelectGamesProduct extends CheckoutEvent {
  const CheckoutSelectGamesProduct(this.index);
  final int index;
}

/// Create an order for purchase
class CheckoutCreateOrder extends CheckoutEvent {
  const CheckoutCreateOrder(this.productId);
  final String productId;
}

/// Clear error state
class CheckoutClearError extends CheckoutEvent {
  const CheckoutClearError();
}

/// Clear success state
class CheckoutClearSuccess extends CheckoutEvent {
  const CheckoutClearSuccess();
}
