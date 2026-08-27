import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/profile_providers.dart';
import '../../../core/error/failure.dart';
import '../data/models/user_profile.dart';
import 'profile_state.dart';

/// Owns the Profile screen's data-loading state. Hand-written `Notifier`
/// (no codegen), matching [AuthNotifier]'s convention -- see that
/// class's docblock for why.
class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    Future.microtask(loadProfile);
    return ProfileState.initial;
  }

  Future<void> loadProfile() async {
    state = state.copyWith(status: ProfileStatus.loading, clearFailure: true);
    try {
      final profile = await ref.read(profileRepositoryProvider).getProfile();
      state = ProfileState(status: ProfileStatus.loaded, profile: profile);
    } on Failure catch (failure) {
      state = ProfileState(
        status: ProfileStatus.error,
        profile: state.profile,
        failure: failure,
      );
    }
  }

  /// Submits a `PATCH /me` with [changes] (already column-mapped to the
  /// backend's camelCase field names by the Edit Profile sheet) and, on
  /// success, updates [state] with the server's returned profile.
  ///
  /// Deliberately *rethrows* [Failure] rather than absorbing it into
  /// [state] -- the Edit Profile sheet calls this directly and shows
  /// the failure inline within itself (docs/screens/profile.md's Error
  /// States: "edit failures shown inline within the Edit Profile sheet,
  /// not dismissing the sheet"), so this screen's own state is left
  /// untouched on failure.
  Future<UserProfile> updateProfile(Map<String, dynamic> changes) async {
    final profile = await ref
        .read(profileRepositoryProvider)
        .updateProfile(changes);
    state = ProfileState(status: ProfileStatus.loaded, profile: profile);
    return profile;
  }
}

final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
