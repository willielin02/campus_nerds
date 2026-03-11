import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/services/supabase_service.dart';
import '../../core/utils/app_clock.dart';
import '../../core/utils/domain_validators.dart';
import '../../domain/entities/university.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../models/tables/universities.dart';
import '../models/tables/university_email_domains.dart';
import '../models/tables/users.dart';

/// Implementation of OnboardingRepository using Supabase
class OnboardingRepositoryImpl implements OnboardingRepository {
  // Cache universities to avoid repeated queries
  List<University>? _universitiesCache;

  @override
  Future<List<University>> getUniversities() async {
    if (_universitiesCache != null) {
      return _universitiesCache!;
    }

    try {
      // Fetch universities
      final universitiesResponse = await UniversitiesTable().queryRows(
        queryFn: (q) => q.order('name'),
      );

      // Fetch all email domains
      final domainsResponse = await UniversityEmailDomainsTable().queryRows(
        queryFn: (q) => q,
      );

      // Group domains by university ID
      final domainsByUniversity = <String, List<String>>{};
      for (final domain in domainsResponse) {
        domainsByUniversity
            .putIfAbsent(domain.universityId, () => [])
            .add(domain.domain);
      }

      // Convert to entities
      _universitiesCache = universitiesResponse.map((row) {
        return University(
          id: row.id,
          name: row.name,
          shortName: row.shortName,
          code: row.code,
          cityId: row.cityId,
          emailDomains: domainsByUniversity[row.id] ?? [],
        );
      }).toList();

      return _universitiesCache!;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<University?> getUniversityByEmailDomain(String email) async {
    final universities = await getUniversities();

    for (final university in universities) {
      if (DomainValidators.isEmailDomainAllowed(email, university.emailDomains)) {
        return university;
      }
    }

    return null;
  }

  @override
  Future<OnboardingResult> sendVerificationCode({
    required String schoolEmail,
  }) async {
    try {
      // Domain validation is handled by Edge Function (single source of truth)
      // Call Supabase Edge Function to send verification code
      final response = await SupabaseService.client.functions.invoke(
        'send-school-email-code',
        body: {
          'school_email': schoolEmail.trim().toLowerCase(),
        },
      );

      if (response.status == 200) {
        return OnboardingResult.success();
      } else {
        final data = response.data as Map<String, dynamic>?;
        final error = data?['error'] as String? ?? '';
        return OnboardingResult.failure(_mapSendCodeError(error));
      }
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      return OnboardingResult.failure(_mapSendCodeError(errorString));
    }
  }

  @override
  Future<OnboardingResult> verifyCode({
    required String schoolEmail,
    required String code,
  }) async {
    try {
      // Call Supabase Edge Function to verify code
      final response = await SupabaseService.client.functions.invoke(
        'verify-school-email-code',
        body: {
          'school_email': schoolEmail.trim().toLowerCase(),
          'code': code.trim(),
        },
      );

      if (response.status == 200) {
        // Clear cache since user's university status changed
        _universitiesCache = null;
        return OnboardingResult.success();
      } else {
        final data = response.data as Map<String, dynamic>?;
        final errorMessage = data?['error'] as String? ?? '驗證碼無效';
        return OnboardingResult.failure(errorMessage);
      }
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('expired')) {
        return OnboardingResult.failure('驗證碼已過期，請重新發送');
      }
      if (errorString.contains('invalid') || errorString.contains('incorrect')) {
        return OnboardingResult.failure('驗證碼不正確');
      }
      if (errorString.contains('attempts') || errorString.contains('locked')) {
        return OnboardingResult.failure('嘗試次數過多，請稍後再試');
      }
      return OnboardingResult.failure('驗證碼驗證失敗');
    }
  }

  @override
  Future<OnboardingResult> updateBasicInfo({
    required String nickname,
    required String gender,
    required DateTime birthday,
  }) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        return OnboardingResult.failure('用戶未登入');
      }

      // Determine client OS
      String clientOs;
      if (kIsWeb) {
        clientOs = 'web';
      } else if (Platform.isIOS) {
        clientOs = 'ios';
      } else if (Platform.isAndroid) {
        clientOs = 'android';
      } else {
        clientOs = 'unknown';
      }

      // Update user's basic info (matching FlutterFlow fields)
      await UsersTable().update(
        data: {
          'nickname': nickname.trim(),
          'gender': gender,
          'birthday': birthday.toIso8601String().split('T')[0], // Date only
          'os': clientOs,
          'updated_at': AppClock.now().toIso8601String(),
        },
        matchingRows: (q) => q.eq('id', userId),
      );

      return OnboardingResult.success();
    } catch (e) {
      return OnboardingResult.failure('更新資料失敗');
    }
  }

  @override
  Future<int> getResendCooldownSeconds(String schoolEmail) async {
    try {
      // Query the latest verification record for this email
      final response = await SupabaseService.from('school_email_verifications')
          .select('last_sent_at')
          .eq('school_email', schoolEmail.trim().toLowerCase())
          .eq('user_id', SupabaseService.currentUserId ?? '')
          .order('last_sent_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return 0; // No previous attempt, can send immediately
      }

      final lastSentAt = DateTime.parse(response['last_sent_at'] as String);
      const cooldownDuration = Duration(seconds: 60);
      final cooldownEnd = lastSentAt.add(cooldownDuration);
      final now = AppClock.now();

      if (now.isAfter(cooldownEnd)) {
        return 0;
      }

      return cooldownEnd.difference(now).inSeconds;
    } catch (e) {
      return 0; // On error, allow sending
    }
  }

  @override
  Future<OnboardingResult> submitStudentIdVerification({
    required String imagePath,
  }) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        return OnboardingResult.failure('用戶未登入');
      }

      // 1. Upload photo to student-id-uploads bucket
      final file = File(imagePath);
      final ext = imagePath.split('.').last.toLowerCase();
      final timestamp = AppClock.now().millisecondsSinceEpoch;
      final storagePath = '$userId/$timestamp.$ext';

      await SupabaseService.client.storage
          .from('student-id-uploads')
          .upload(storagePath, file);

      // 2. Call verify-student-id Edge Function
      final response = await SupabaseService.client.functions.invoke(
        'verify-student-id',
        body: {
          'storage_path': storagePath,
        },
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>?;
        final status = data?['status'] as String?;

        if (status == 'verified') {
          return OnboardingResult.success('verified');
        } else if (status == 'pending_review') {
          return OnboardingResult.success('pending_review');
        } else {
          return OnboardingResult.failure(
              data?['error'] as String? ?? '驗證失敗');
        }
      } else {
        final data = response.data as Map<String, dynamic>?;
        return OnboardingResult.failure(
            data?['error'] as String? ?? '驗證服務暫時無法使用');
      }
    } catch (e) {
      return OnboardingResult.failure('提交驗證失敗，請稍後再試');
    }
  }

  String _mapSendCodeError(String error) {
    if (error.contains('unsupported_domain')) {
      return '此電子郵件網域不屬於我們支援的學校網域';
    }
    if (error.contains('email_already_bound')) {
      return 'email_already_bound';
    }
    if (error.contains('rate') || error.contains('cooldown')) {
      return '請稍後再試，驗證碼發送過於頻繁';
    }
    if (error.contains('already') || error.contains('verified')) {
      return '此電子郵件已被驗證';
    }
    return '發送驗證碼時發生錯誤';
  }
}
