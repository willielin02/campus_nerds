import 'package:collection/collection.dart';

enum EventCategory {
  focused_study,
  english_games,
}

enum EventTimeSlot {
  morning,
  afternoon,
  evening,
}

enum EventStatus {
  draft,
  scheduled,
  cancelled,
  completed,
}

enum EventLocationDetail {
  ntu_main_library_reading_area,
  nycu_haoran_library_reading_area,
  nycu_yangming_campus_library_reading_area,
  nthu_main_library_reading_area,
  ncku_main_library_reading_area,
  nccu_daxian_library_reading_area,
  ncu_main_library_reading_area,
  nsysu_library_reading_area,
  nchu_main_library_reading_area,
  ccu_library_reading_area,
  ntnu_main_library_reading_area,
  ntpu_library_reading_area,
  ntust_library_reading_area,
  ntut_library_reading_area,
  library_or_cafe,
  boardgame_or_escape_room,
}

enum Gender {
  male,
  female,
  prefer_not_to_say,
}

enum ClientOs {
  ios,
  android,
  web,
  unknown,
}

extension FFEnumExtensions<T extends Enum> on T {
  String serialize() => name;
}

extension FFEnumListExtensions<T extends Enum> on Iterable<T> {
  T? deserialize(String? value) =>
      firstWhereOrNull((e) => e.serialize() == value);
}

T? deserializeEnum<T>(String? value) {
  switch (T) {
    case (EventCategory):
      return EventCategory.values.deserialize(value) as T?;
    case (EventTimeSlot):
      return EventTimeSlot.values.deserialize(value) as T?;
    case (EventStatus):
      return EventStatus.values.deserialize(value) as T?;
    case (EventLocationDetail):
      return EventLocationDetail.values.deserialize(value) as T?;
    case (Gender):
      return Gender.values.deserialize(value) as T?;
    case (ClientOs):
      return ClientOs.values.deserialize(value) as T?;
    default:
      return null;
  }
}
