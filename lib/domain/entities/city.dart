import 'package:equatable/equatable.dart';

/// City entity representing a location where events are held
class City extends Equatable {
  final String id;
  final String name;
  final String slug;

  const City({
    required this.id,
    required this.name,
    required this.slug,
  });

  @override
  List<Object?> get props => [id, name, slug];
}
