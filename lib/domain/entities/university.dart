import 'package:equatable/equatable.dart';

/// University entity representing a supported university
class University extends Equatable {
  final String id;
  final String name;
  final String? shortName;
  final String code;
  final String cityId;
  final List<String> emailDomains;

  const University({
    required this.id,
    required this.name,
    this.shortName,
    required this.code,
    required this.cityId,
    this.emailDomains = const [],
  });

  @override
  List<Object?> get props => [id, name, shortName, code, cityId, emailDomains];
}
