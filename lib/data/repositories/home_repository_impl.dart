import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/services/supabase_service.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/tables/cities.dart';
import '../models/tables/home_events_v.dart';

/// Implementation of HomeRepository using Supabase
class HomeRepositoryImpl implements HomeRepository {
  static const _cityPreferenceKey = 'user_city_preference';
  final _secureStorage = const FlutterSecureStorage();

  // Cache cities to avoid repeated queries
  List<City>? _citiesCache;

  @override
  Future<TicketBalance> getTicketBalance() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        return const TicketBalance();
      }

      final response = await SupabaseService.client
          .from('user_ticket_balances_v')
          .select()
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return const TicketBalance();
      }

      return TicketBalance(
        studyBalance: (response['study_balance'] as num?)?.toInt() ?? 0,
        gamesBalance: (response['games_balance'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      return const TicketBalance();
    }
  }

  @override
  Future<List<City>> getCities() async {
    if (_citiesCache != null) {
      return _citiesCache!;
    }

    try {
      final response = await CitiesTable().queryRows(
        queryFn: (q) => q.order('name'),
      );

      _citiesCache = response.map((row) {
        return City(
          id: row.id,
          name: row.name,
          slug: row.slug,
          imageAsset: CityImages.getImageForCity(row.id),
        );
      }).toList();

      return _citiesCache!;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Event>> getFocusedStudyEvents({
    String? cityId,
    int limit = 10,
  }) async {
    return _getEventsByCategory(
      category: EventCategory.focusedStudy,
      cityId: cityId,
      limit: limit,
    );
  }

  @override
  Future<List<Event>> getEnglishGamesEvents({
    String? cityId,
    int limit = 10,
  }) async {
    return _getEventsByCategory(
      category: EventCategory.englishGames,
      cityId: cityId,
      limit: limit,
    );
  }

  @override
  Future<List<Event>> getUpcomingEvents({
    String? cityId,
    EventCategory? category,
    int limit = 20,
  }) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final response = await HomeEventsVTable().queryRows(
        queryFn: (q) {
          // Apply filters first, then order and limit
          var query = q.gte('event_date', today.toIso8601String());

          if (cityId != null) {
            query = query.eq('city_id', cityId);
          }

          if (category != null) {
            query = query.eq('category', category.value);
          }

          return query.order('event_date').order('time_slot').limit(limit);
        },
      );

      return response.map(_mapRowToEvent).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Event?> getEventById(String eventId) async {
    try {
      final response = await HomeEventsVTable().queryRows(
        queryFn: (q) => q.eq('id', eventId).limit(1),
      );

      if (response.isEmpty) {
        return null;
      }

      return _mapRowToEvent(response.first);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<City?> getUserCityPreference() async {
    try {
      final cityId = await _secureStorage.read(key: _cityPreferenceKey);
      if (cityId == null) {
        return null;
      }

      final cities = await getCities();
      return cities.where((c) => c.id == cityId).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveUserCityPreference(String cityId) async {
    try {
      await _secureStorage.write(key: _cityPreferenceKey, value: cityId);
    } catch (e) {
      // Ignore storage errors
    }
  }

  @override
  Future<Map<String, int>> getEventCountsByCity(EventCategory category) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get all events for the category
      final response = await HomeEventsVTable().queryRows(
        queryFn: (q) => q
            .eq('category', category.value)
            .gte('event_date', today.toIso8601String()),
      );

      // Count events by city
      final Map<String, int> counts = {};
      for (final row in response) {
        final cityId = row.cityId;
        if (cityId != null) {
          counts[cityId] = (counts[cityId] ?? 0) + 1;
        }
      }

      return counts;
    } catch (e) {
      return {};
    }
  }

  Future<List<Event>> _getEventsByCategory({
    required EventCategory category,
    String? cityId,
    int limit = 10,
  }) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final response = await HomeEventsVTable().queryRows(
        queryFn: (q) {
          // Apply all filters first
          var query = q
              .eq('category', category.value)
              .gte('event_date', today.toIso8601String());

          if (cityId != null) {
            query = query.eq('city_id', cityId);
          }

          // Then apply order and limit
          return query.order('event_date').order('time_slot').limit(limit);
        },
      );

      return response.map(_mapRowToEvent).toList();
    } catch (e) {
      return [];
    }
  }

  Event _mapRowToEvent(HomeEventsVRow row) {
    return Event(
      id: row.id ?? '',
      universityId: row.universityId,
      cityId: row.cityId ?? '',
      category: EventCategory.fromString(row.category ?? 'focused_study'),
      eventDate: row.eventDate ?? DateTime.now(),
      timeSlot: TimeSlot.fromString(row.timeSlot ?? 'afternoon'),
      status: EventStatus.fromString(row.status ?? 'open'),
      locationDetail: row.locationDetail ?? '',
      signupOpenAt: row.signupOpenAt ?? DateTime.now(),
      signupDeadlineAt: row.signupDeadlineAt ?? DateTime.now(),
      notifyDeadlineAt: row.notifyDeadlineAt,
      hasConflictSameSlot: row.hasConflictSameSlot ?? false,
    );
  }
}
