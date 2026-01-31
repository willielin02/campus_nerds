import '../../core/services/supabase_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/account_repository.dart';

/// Implementation of AccountRepository using Supabase
class AccountRepositoryImpl implements AccountRepository {
  @override
  Future<UserProfile?> getUserProfile() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return null;

      final response = await SupabaseService.from('user_profile_v')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return _parseUserProfile(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await SupabaseService.signOut();
  }

  /// Parse user profile from map
  UserProfile _parseUserProfile(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      nickname: map['nickname'] as String?,
      gender: map['gender'] as String?,
      birthday: _parseDateTime(map['birthday']),
      age: map['age'] as int?,
      universityId: map['university_id'] as String?,
      universityName: map['university_name'] as String?,
      schoolEmail: map['school_email'] as String?,
      schoolEmailStatus: SchoolEmailStatus.fromString(
        map['school_email_status'] as String? ?? 'unverified',
      ),
      avatarUrl: map['avatar_url'] as String?,
      hasFacebookLinked: map['has_facebook_linked'] as bool? ?? false,
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
