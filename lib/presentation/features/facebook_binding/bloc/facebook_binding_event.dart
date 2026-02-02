import 'package:equatable/equatable.dart';

/// Base class for Facebook binding events
abstract class FacebookBindingEvent extends Equatable {
  const FacebookBindingEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check Facebook link status
class FacebookBindingCheckStatus extends FacebookBindingEvent {
  const FacebookBindingCheckStatus();
}

/// Event to link Facebook account
class FacebookBindingLink extends FacebookBindingEvent {
  const FacebookBindingLink();
}

/// Event to unlink Facebook account
class FacebookBindingUnlink extends FacebookBindingEvent {
  const FacebookBindingUnlink();
}

/// Event to sync Facebook friends
class FacebookBindingSyncFriends extends FacebookBindingEvent {
  const FacebookBindingSyncFriends();
}

/// Event to clear error
class FacebookBindingClearError extends FacebookBindingEvent {
  const FacebookBindingClearError();
}
