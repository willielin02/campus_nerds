import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/repositories/facebook_repository.dart';
import 'facebook_binding_event.dart';
import 'facebook_binding_state.dart';

/// BLoC for managing Facebook binding state
class FacebookBindingBloc
    extends Bloc<FacebookBindingEvent, FacebookBindingState> {
  final FacebookRepository _facebookRepository;

  FacebookBindingBloc({
    required FacebookRepository facebookRepository,
  })  : _facebookRepository = facebookRepository,
        super(const FacebookBindingState()) {
    on<FacebookBindingCheckStatus>(_onCheckStatus);
    on<FacebookBindingLink>(_onLink);
    on<FacebookBindingUnlink>(_onUnlink);
    on<FacebookBindingSyncFriends>(_onSyncFriends);
    on<FacebookBindingClearError>(_onClearError);
  }

  Future<void> _onCheckStatus(
    FacebookBindingCheckStatus event,
    Emitter<FacebookBindingState> emit,
  ) async {
    emit(state.copyWith(status: FacebookBindingStatus.loading));

    final isLinked = await _facebookRepository.isFacebookLinked();
    String? fbUserId;

    if (isLinked) {
      fbUserId = await _facebookRepository.getFacebookUserId();
    }

    emit(state.copyWith(
      status: isLinked
          ? FacebookBindingStatus.linked
          : FacebookBindingStatus.notLinked,
      isLinked: isLinked,
      fbUserId: fbUserId,
    ));
  }

  Future<void> _onLink(
    FacebookBindingLink event,
    Emitter<FacebookBindingState> emit,
  ) async {
    emit(state.copyWith(status: FacebookBindingStatus.linking));

    final result = await _facebookRepository.linkFacebookAccount();

    if (result.success) {
      emit(state.copyWith(
        status: FacebookBindingStatus.linked,
        isLinked: true,
        fbUserId: result.fbUserId,
        successMessage: '臉書帳號綁定成功！',
      ));
    } else {
      emit(state.copyWith(
        status: FacebookBindingStatus.notLinked,
        isLinked: false,
        errorMessage: result.errorMessage ?? '綁定失敗',
      ));
    }
  }

  Future<void> _onUnlink(
    FacebookBindingUnlink event,
    Emitter<FacebookBindingState> emit,
  ) async {
    emit(state.copyWith(status: FacebookBindingStatus.unlinking));

    await _facebookRepository.unlinkFacebookAccount();

    emit(state.copyWith(
      status: FacebookBindingStatus.notLinked,
      isLinked: false,
      fbUserId: null,
      syncedFriendsCount: null,
      successMessage: '已解除臉書綁定',
    ));
  }

  Future<void> _onSyncFriends(
    FacebookBindingSyncFriends event,
    Emitter<FacebookBindingState> emit,
  ) async {
    emit(state.copyWith(status: FacebookBindingStatus.syncing));

    final result = await _facebookRepository.syncFacebookFriends();

    if (result.success) {
      emit(state.copyWith(
        status: FacebookBindingStatus.linked,
        syncedFriendsCount: result.friendsCount,
        successMessage: '已同步 ${result.friendsCount} 位好友',
      ));
    } else {
      emit(state.copyWith(
        status: FacebookBindingStatus.linked,
        errorMessage: result.errorMessage ?? '同步失敗',
      ));
    }
  }

  void _onClearError(
    FacebookBindingClearError event,
    Emitter<FacebookBindingState> emit,
  ) {
    emit(state.clearMessages());
  }
}
