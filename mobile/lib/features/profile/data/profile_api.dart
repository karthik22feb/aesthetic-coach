import 'package:dio/dio.dart';

import 'models/user_profile.dart';

/// Raw HTTP calls against `GET/PATCH /me`
/// (backend/app/Modules/Auth/routes.php). Returns a parsed [UserProfile]
/// or lets [DioException] propagate -- [ProfileRepository] maps
/// exceptions into [Failure]s, matching the split already established by
/// AuthApi/AuthRepository (see features/auth/data/auth_api.dart).
///
/// Extracted as an interface ([ProfileApiClient]) purely so
/// [ProfileRepository] can be unit-tested against a fake implementation
/// without a real Dio/network round trip -- see profile_repository_test.dart.
abstract interface class ProfileApiClient {
  Future<UserProfile> getProfile();

  /// [changes] is sent as-is as the PATCH body -- callers (the Edit
  /// Profile sheet) are responsible for only including the editable
  /// fields the backend's `UpdateProfileRequest` accepts (`name`,
  /// `timezone`, `unitPreference`, `dateOfBirth`, `sex`, `heightCm`,
  /// `dietaryRestrictions`). `email` must never appear in this map --
  /// the backend's column allowlist would silently ignore it, but this
  /// class enforces nothing about that; the UI layer is the actual
  /// enforcement point (no form field for it exists).
  Future<UserProfile> updateProfile(Map<String, dynamic> changes);
}

class ProfileApi implements ProfileApiClient {
  ProfileApi(this._dio);

  final Dio _dio;

  @override
  Future<UserProfile> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('me');
    return UserProfile.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> changes) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      'me',
      data: changes,
    );
    return UserProfile.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
