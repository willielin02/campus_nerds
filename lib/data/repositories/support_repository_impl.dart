import 'dart:io';

import '../../core/services/supabase_service.dart';
import '../../domain/entities/support.dart';
import '../../domain/repositories/support_repository.dart';

class SupportRepositoryImpl implements SupportRepository {
  static const _bucketName = 'support-attachments';

  @override
  Future<List<SupportTicket>> getMyTickets() async {
    final response = await SupabaseService.from('support_tickets')
        .select()
        .order('updated_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) => _parseTicket(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SupportTicket> createTicket({
    required TicketCategory category,
    required String subject,
    required String message,
    String? imagePath,
  }) async {
    final userId = SupabaseService.currentUserId!;

    // 1. Create ticket
    final ticketResponse = await SupabaseService.from('support_tickets')
        .insert({
          'user_id': userId,
          'category': category.value,
          'subject': subject,
        })
        .select()
        .single();

    final ticket = _parseTicket(ticketResponse);

    // 2. Upload image if provided
    String? storagePath;
    if (imagePath != null) {
      storagePath = await uploadAttachment(
        ticketId: ticket.id,
        filePath: imagePath,
      );
    }

    // 3. Create initial message
    await SupabaseService.from('support_messages').insert({
      'ticket_id': ticket.id,
      'sender_type': 'user',
      'sender_id': userId,
      'content': message.isNotEmpty ? message : null,
      'image_path': storagePath,
    });

    return ticket;
  }

  @override
  Future<List<SupportMessage>> getTicketMessages(String ticketId) async {
    final response = await SupabaseService.from('support_messages')
        .select()
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    final messages = <SupportMessage>[];
    for (final item in response as List<dynamic>) {
      final map = item as Map<String, dynamic>;
      String? imageUrl;
      final imagePath = map['image_path'] as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        imageUrl = await getImageUrl(imagePath);
      }
      messages.add(_parseMessage(map, imageUrl: imageUrl));
    }
    return messages;
  }

  @override
  Future<SupportMessage> sendMessage({
    required String ticketId,
    String? content,
    String? imagePath,
  }) async {
    final userId = SupabaseService.currentUserId!;

    String? storagePath;
    if (imagePath != null) {
      storagePath = await uploadAttachment(
        ticketId: ticketId,
        filePath: imagePath,
      );
    }

    final response = await SupabaseService.from('support_messages')
        .insert({
          'ticket_id': ticketId,
          'sender_type': 'user',
          'sender_id': userId,
          'content': content,
          'image_path': storagePath,
        })
        .select()
        .single();

    String? imageUrl;
    if (storagePath != null) {
      imageUrl = await getImageUrl(storagePath);
    }

    return _parseMessage(response, imageUrl: imageUrl);
  }

  @override
  Future<String> uploadAttachment({
    required String ticketId,
    required String filePath,
  }) async {
    final userId = SupabaseService.currentUserId!;
    final file = File(filePath);
    final ext = filePath.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/$ticketId/${timestamp}.$ext';

    await SupabaseService.client.storage
        .from(_bucketName)
        .upload(storagePath, file);

    return storagePath;
  }

  @override
  Future<String?> getImageUrl(String imagePath) async {
    try {
      final response = await SupabaseService.client.storage
          .from(_bucketName)
          .createSignedUrl(imagePath, 3600);
      return response;
    } catch (e) {
      return null;
    }
  }

  SupportTicket _parseTicket(Map<String, dynamic> map) {
    return SupportTicket(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      category: TicketCategory.fromString(map['category'] as String),
      subject: map['subject'] as String,
      status: TicketStatus.fromString(map['status'] as String),
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updated_at']) ?? DateTime.now(),
      resolvedAt: _parseDateTime(map['resolved_at']),
    );
  }

  SupportMessage _parseMessage(Map<String, dynamic> map, {String? imageUrl}) {
    return SupportMessage(
      id: map['id'] as String,
      ticketId: map['ticket_id'] as String,
      senderType: map['sender_type'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String?,
      imagePath: map['image_path'] as String?,
      imageUrl: imageUrl,
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now(),
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
