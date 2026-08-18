import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the current access token **in memory only**, per
/// docs/03-system-architecture.md section 3.1 and
/// docs/08-mobile-architecture.md section 5. Never persisted -- this is
/// the single in-process source of truth [AuthInterceptor] reads to
/// attach the `Authorization` header, kept feature-agnostic (core/network)
/// so the interceptor never has to import features/auth/.
class AuthTokenStore extends Notifier<String?> {
  @override
  String? build() => null;

  void setAccessToken(String? token) => state = token;
}

final authTokenStoreProvider = NotifierProvider<AuthTokenStore, String?>(
  AuthTokenStore.new,
);
