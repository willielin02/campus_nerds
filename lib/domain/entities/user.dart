import 'package:equatable/equatable.dart';

/// School email verification status
enum SchoolEmailStatus {
  unverified('unverified', '未驗證'),
  pending('pending', '驗證中'),
  verified('verified', '已驗證'),
  failed('failed', '驗證失敗');

  final String value;
  final String displayName;

  const SchoolEmailStatus(this.value, this.displayName);

  static SchoolEmailStatus fromString(String value) {
    return SchoolEmailStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SchoolEmailStatus.unverified,
    );
  }
}

/// User profile entity
class UserProfile extends Equatable {
  final String id;
  final String? nickname;
  final String? gender;
  final DateTime? birthday;
  final int? age;
  final String? universityId;
  final String? universityName;
  final String? schoolEmail;
  final SchoolEmailStatus schoolEmailStatus;
  final String? avatarUrl;
  final bool hasFacebookLinked;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    this.nickname,
    this.gender,
    this.birthday,
    this.age,
    this.universityId,
    this.universityName,
    this.schoolEmail,
    this.schoolEmailStatus = SchoolEmailStatus.unverified,
    this.avatarUrl,
    this.hasFacebookLinked = false,
    required this.createdAt,
  });

  /// Get display name (nickname or anonymous)
  String get displayName => nickname ?? '匿名';

  /// Get formatted display name with prefix
  String get displayNameWithPrefix => '書呆子 $displayName';

  /// Get gender display
  String get genderDisplay {
    if (gender == 'male') return '男';
    if (gender == 'female') return '女';
    return '未設定';
  }

  /// Get age display
  String get ageDisplay => age != null ? '$age 歲' : '未設定';

  /// Check if profile is complete
  bool get isProfileComplete =>
      nickname != null &&
      gender != null &&
      birthday != null &&
      universityId != null;

  /// Check if school email is verified
  bool get isSchoolEmailVerified =>
      schoolEmailStatus == SchoolEmailStatus.verified;

  @override
  List<Object?> get props => [
        id,
        nickname,
        gender,
        birthday,
        age,
        universityId,
        universityName,
        schoolEmail,
        schoolEmailStatus,
        avatarUrl,
        hasFacebookLinked,
        createdAt,
      ];
}

/// Settings item for account page
class SettingsItem extends Equatable {
  final String id;
  final String title;
  final String? subtitle;
  final String? iconName;
  final bool showChevron;
  final bool isDestructive;

  const SettingsItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.iconName,
    this.showChevron = true,
    this.isDestructive = false,
  });

  @override
  List<Object?> get props => [id, title, subtitle, iconName, showChevron, isDestructive];
}
