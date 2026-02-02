import '../../core/services/supabase_service.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/ticket_history.dart';
import '../../domain/repositories/ticket_history_repository.dart';

/// Implementation of TicketHistoryRepository using Supabase
class TicketHistoryRepositoryImpl implements TicketHistoryRepository {
  // Cache cities to avoid repeated queries
  Map<String, String>? _citiesCache;

  @override
  Future<List<TicketHistoryEntry>> getTicketHistory({
    required String ticketType,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        return [];
      }

      // Query ticket_ledger with filter for ticket type
      final deltaColumn = ticketType == 'study' ? 'delta_study' : 'delta_games';

      final response = await SupabaseService.client
          .from('ticket_ledger')
          .select()
          .eq('user_id', userId)
          .neq(deltaColumn, 0)
          .order('created_at', ascending: false);

      final entries = <TicketHistoryEntry>[];

      for (final row in response as List) {
        final orderId = row['order_id'] as String?;
        final bookingId = row['booking_id'] as String?;

        TicketOrderDetail? orderDetail;
        TicketBookingDetail? bookingDetail;

        // Fetch order details if this is a purchase entry
        if (orderId != null) {
          orderDetail = await _fetchOrderDetail(orderId);
        }

        // Fetch booking details if this is a booking entry
        if (bookingId != null) {
          bookingDetail = await _fetchBookingDetail(bookingId);
        }

        entries.add(TicketHistoryEntry(
          id: row['id'] as String,
          userId: row['user_id'] as String,
          orderId: orderId,
          bookingId: bookingId,
          deltaStudy: (row['delta_study'] as num).toInt(),
          deltaGames: (row['delta_games'] as num).toInt(),
          reason: TicketLedgerReason.fromString(row['reason'] as String),
          createdAt: DateTime.parse(row['created_at'] as String),
          orderDetail: orderDetail,
          bookingDetail: bookingDetail,
        ));
      }

      return entries;
    } catch (e) {
      return [];
    }
  }

  /// Fetch order details for a purchase entry
  Future<TicketOrderDetail?> _fetchOrderDetail(String orderId) async {
    try {
      final response = await SupabaseService.client
          .from('orders')
          .select()
          .eq('id', orderId)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return TicketOrderDetail(
        ticketType: response['ticket_type_snapshot'] as String,
        packSize: (response['pack_size_snapshot'] as num).toInt(),
        priceTwd: (response['price_snapshot_twd'] as num).toInt(),
        title: response['title_snapshot'] as String,
      );
    } catch (e) {
      return null;
    }
  }

  /// Fetch booking details for a booking entry
  Future<TicketBookingDetail?> _fetchBookingDetail(String bookingId) async {
    try {
      // First, get the booking to find the event_id
      final bookingResponse = await SupabaseService.client
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .limit(1)
          .maybeSingle();

      if (bookingResponse == null) return null;

      final eventId = bookingResponse['event_id'] as String;

      // Then fetch the event details
      final eventResponse = await SupabaseService.client
          .from('events')
          .select()
          .eq('id', eventId)
          .limit(1)
          .maybeSingle();

      if (eventResponse == null) return null;

      final cityId = eventResponse['city_id'] as String;
      final cityName = await _getCityName(cityId);

      return TicketBookingDetail(
        eventId: eventId,
        eventDate: DateTime.parse(eventResponse['event_date'] as String),
        timeSlot: eventResponse['time_slot'] as String,
        cityId: cityId,
        cityName: cityName,
        locationDetail: eventResponse['location_detail'] as String,
        category: eventResponse['category'] as String,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get city name from cache or fetch from database
  Future<String> _getCityName(String cityId) async {
    // Load cities cache if not loaded
    if (_citiesCache == null) {
      await _loadCitiesCache();
    }

    return _citiesCache?[cityId] ?? cityId;
  }

  /// Load cities into cache
  Future<void> _loadCitiesCache() async {
    try {
      final response = await SupabaseService.client.from('cities').select();

      _citiesCache = {};
      for (final row in response as List) {
        final id = row['id'] as String;
        final name = row['name'] as String;
        _citiesCache![id] = name;
      }
    } catch (e) {
      _citiesCache = {};
    }
  }

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
}
