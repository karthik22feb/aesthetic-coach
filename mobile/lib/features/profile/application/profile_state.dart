import '../../../core/error/failure.dart';
import '../data/models/user_profile.dart';

enum ProfileStatus {
  /// Initial `GET /me` is in flight (or a retry after a load failure).
  loading,

  /// `profile` holds the last-known-good profile. Also the status while
  /// the Edit Profile sheet is open and submitting -- that submission's
  /// loading/error state is owned locally by the sheet itself, not this
  /// notifier, per docs/screens/profile.md's Error States ("edit
  /// failures shown inline within the Edit Profile sheet, not
  /// dismissing the sheet") -- see [ProfileNotifier.updateProfile].
  loaded,

  /// The initial `GET /me` failed; `failure` is set so the screen can
  /// show an inline error with a retry action.
  error,
}

class ProfileState {
  const ProfileState({required this.status, this.profile, this.failure});

  static const initial = ProfileState(status: ProfileStatus.loading);

  final ProfileStatus status;
  final UserProfile? profile;
  final Failure? failure;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProfileState &&
      other.status == status &&
      other.profile == profile &&
      other.failure == failure;

  @override
  int get hashCode => Object.hash(status, profile, failure);
}
