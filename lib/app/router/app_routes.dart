/// Route path constants for the app
abstract class AppRoutes {
  // Initial
  static const String splash = '/';

  // Auth routes
  static const String login = '/login';
  static const String basicInfo = '/basic-info';
  static const String schoolEmailVerification = '/school-email-verification';

  // Main tabs (NavBar)
  static const String home = '/home';
  static const String myEvents = '/my-events';
  static const String account = '/account';

  // Event details
  static const String eventDetailsStudy = '/event-details-study';
  static const String eventDetailsGames = '/event-details-games';

  // Booking confirmation
  static const String studyBookingConfirmation = '/study-booking-confirmation';
  static const String gamesBookingConfirmation = '/games-booking-confirmation';

  // Payment
  static const String checkout = '/checkout';
  // Ticket History
  static const String ticketHistory = '/ticket-history';

  // School Email Info
  static const String schoolEmailInfo = '/school-email-info';

  // Facebook Binding
  static const String facebookBinding = '/facebook-binding';

  // Contact Support
  static const String contactSupport = '/contact-support';

  // FAQ
  static const String faq = '/faq';

  // Feedback & Learning Report
  static const String feedback = '/feedback';
  static const String learningReport = '/learning-report';
}

/// Route names for named navigation
abstract class AppRouteNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String basicInfo = 'basicInfo';
  static const String schoolEmailVerification = 'schoolEmailVerification';
  static const String home = 'home';
  static const String myEvents = 'myEvents';
  static const String account = 'account';
  static const String eventDetailsStudy = 'eventDetailsStudy';
  static const String eventDetailsGames = 'eventDetailsGames';
  static const String studyBookingConfirmation = 'studyBookingConfirmation';
  static const String gamesBookingConfirmation = 'gamesBookingConfirmation';
  static const String checkout = 'checkout';
  static const String ticketHistory = 'ticketHistory';
  static const String schoolEmailInfo = 'schoolEmailInfo';
  static const String facebookBinding = 'facebookBinding';
  static const String contactSupport = 'contactSupport';
  static const String faq = 'faq';
  static const String feedback = 'feedback';
  static const String learningReport = 'learningReport';
}
