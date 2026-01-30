import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import 'auth_state_notifier.dart';

/// Navigation extension methods for BuildContext
extension NavigationExtensions on BuildContext {
  /// Navigate to login page
  void goToLogin({bool allowGuest = false}) {
    go('${AppRoutes.login}?allowGuest=$allowGuest');
  }

  /// Navigate to email login page
  void goToLoginEmail({bool allowGuest = false}) {
    go('${AppRoutes.loginEmail}?allowGuest=$allowGuest');
  }

  /// Navigate to basic info page
  void goToBasicInfo() {
    go(AppRoutes.basicInfo);
  }

  /// Navigate to school email verification page
  void goToSchoolEmailVerification() {
    go(AppRoutes.schoolEmailVerification);
  }

  /// Navigate to home page
  void goToHome() {
    go(AppRoutes.home);
  }

  /// Navigate to my events page
  void goToMyEvents() {
    go(AppRoutes.myEvents);
  }

  /// Navigate to account page
  void goToAccount() {
    go(AppRoutes.account);
  }

  /// Navigate to study event details
  void goToEventDetailsStudy({String? bookingId}) {
    if (bookingId != null) {
      go('${AppRoutes.eventDetailsStudy}?bookingId=$bookingId');
    } else {
      go(AppRoutes.eventDetailsStudy);
    }
  }

  /// Navigate to games event details
  void goToEventDetailsGames() {
    go(AppRoutes.eventDetailsGames);
  }

  /// Navigate to study booking confirmation
  void goToStudyBookingConfirmation({
    required String eventId,
    required DateTime eventDate,
    required String timeSlot,
    required String locationDetail,
  }) {
    go(
      AppRoutes.studyBookingConfirmation,
      extra: {
        'eventId': eventId,
        'eventDate': eventDate,
        'timeSlot': timeSlot,
        'locationDetail': locationDetail,
      },
    );
  }

  /// Navigate to games booking confirmation
  void goToGamesBookingConfirmation({
    required String eventId,
    required DateTime eventDate,
    required String timeSlot,
    required String locationDetail,
  }) {
    go(
      AppRoutes.gamesBookingConfirmation,
      extra: {
        'eventId': eventId,
        'eventDate': eventDate,
        'timeSlot': timeSlot,
        'locationDetail': locationDetail,
      },
    );
  }

  /// Navigate to checkout page
  void goToCheckout({int tabIndex = 0}) {
    go('${AppRoutes.checkout}?tabIndex=$tabIndex');
  }

  /// Navigate to payment web view
  void goToPaymentWebView({required String paymentHtml}) {
    go(
      AppRoutes.paymentWebView,
      extra: {'paymentHtml': paymentHtml},
    );
  }

  /// Safely pop the current route
  ///
  /// If there's no route to pop, navigates to home instead
  void safePop() {
    if (canPop()) {
      pop();
    } else {
      go(AppRoutes.home);
    }
  }

  /// Navigate with auth handling
  ///
  /// Prepares auth state before navigation to prevent
  /// unnecessary rebuilds during auth flows.
  void goWithAuth(
    String location, {
    Object? extra,
    bool ignoreRedirect = false,
  }) {
    final authNotifier = AuthStateNotifier.instance;

    if (!ignoreRedirect && authNotifier.shouldRedirect) {
      return;
    }

    authNotifier.updateNotifyOnAuthChange(false);
    go(location, extra: extra);
  }

  /// Push with auth handling
  void pushWithAuth(
    String location, {
    Object? extra,
    bool ignoreRedirect = false,
  }) {
    final authNotifier = AuthStateNotifier.instance;

    if (!ignoreRedirect && authNotifier.shouldRedirect) {
      return;
    }

    authNotifier.updateNotifyOnAuthChange(false);
    push(location, extra: extra);
  }
}

/// Router extension methods
extension GoRouterExtensions on GoRouter {
  /// Get current route location
  String get currentLocation {
    final lastMatch = routerDelegate.currentConfiguration.last;
    final matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  /// Prepare for auth event
  ///
  /// Disables auth change notifications temporarily
  void prepareAuthEvent() {
    AuthStateNotifier.instance.updateNotifyOnAuthChange(false);
  }
}
