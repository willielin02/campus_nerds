import '../entities/booking.dart';
import '../entities/city.dart';
import '../entities/event.dart';

/// Abstract repository for home page data operations
abstract class HomeRepository {
  /// Get user's ticket balance
  Future<TicketBalance> getTicketBalance();
  /// Get all available cities
  Future<List<City>> getCities();

  /// Get events for focused study category
  /// [cityId] - Filter by city, null for all cities
  /// [limit] - Maximum number of events to return
  Future<List<Event>> getFocusedStudyEvents({
    String? cityId,
    int limit = 10,
  });

  /// Get events for english games category
  /// [cityId] - Filter by city, null for all cities
  /// [limit] - Maximum number of events to return
  Future<List<Event>> getEnglishGamesEvents({
    String? cityId,
    int limit = 10,
  });

  /// Get all upcoming events
  /// [cityId] - Filter by city, null for all cities
  /// [category] - Filter by category, null for all categories
  /// [limit] - Maximum number of events to return
  Future<List<Event>> getUpcomingEvents({
    String? cityId,
    EventCategory? category,
    int limit = 20,
  });

  /// Get a single event by ID
  Future<Event?> getEventById(String eventId);

  /// Get user's current city preference
  Future<City?> getUserCityPreference();

  /// Save user's city preference
  Future<void> saveUserCityPreference(String cityId);

  /// Get event counts for all cities by category
  /// Returns a map of cityId -> event count
  Future<Map<String, int>> getEventCountsByCity(EventCategory category);
}
