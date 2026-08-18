/// Mirrors the backend's `UserResource`
/// (backend/app/Modules/Auth/Http/Resources/UserResource.php) exactly --
/// `id`, `name`, `email`, `emailVerified` only. No password, no other
/// sensitive fields are ever present in this model.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.emailVerified,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      emailVerified: json['emailVerified'] as bool,
    );
  }

  final String id;
  final String name;
  final String email;
  final bool emailVerified;

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.emailVerified == emailVerified;

  @override
  int get hashCode => Object.hash(id, name, email, emailVerified);
}
