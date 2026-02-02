import 'package:equatable/equatable.dart';

/// Status for Facebook binding operations
enum FacebookBindingStatus {
  initial,
  loading,
  linked,
  notLinked,
  linking,
  unlinking,
  syncing,
  error,
}

/// State for Facebook binding feature
class FacebookBindingState extends Equatable {
  const FacebookBindingState({
    this.status = FacebookBindingStatus.initial,
    this.isLinked = false,
    this.fbUserId,
    this.syncedFriendsCount,
    this.errorMessage,
    this.successMessage,
  });

  final FacebookBindingStatus status;
  final bool isLinked;
  final String? fbUserId;
  final int? syncedFriendsCount;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading =>
      status == FacebookBindingStatus.loading ||
      status == FacebookBindingStatus.linking ||
      status == FacebookBindingStatus.unlinking ||
      status == FacebookBindingStatus.syncing;

  FacebookBindingState copyWith({
    FacebookBindingStatus? status,
    bool? isLinked,
    String? fbUserId,
    int? syncedFriendsCount,
    String? errorMessage,
    String? successMessage,
  }) {
    return FacebookBindingState(
      status: status ?? this.status,
      isLinked: isLinked ?? this.isLinked,
      fbUserId: fbUserId ?? this.fbUserId,
      syncedFriendsCount: syncedFriendsCount ?? this.syncedFriendsCount,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  FacebookBindingState clearMessages() {
    return FacebookBindingState(
      status: status,
      isLinked: isLinked,
      fbUserId: fbUserId,
      syncedFriendsCount: syncedFriendsCount,
      errorMessage: null,
      successMessage: null,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isLinked,
        fbUserId,
        syncedFriendsCount,
        errorMessage,
        successMessage,
      ];
}
