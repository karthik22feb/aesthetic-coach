import 'profile_enums.dart';

/// Mirrors the backend's `ProfileResource` exactly
/// (backend/app/Modules/Auth/Http/Resources/ProfileResource.php) --
/// `id`, `name`, `email`, `emailVerified`, `timezone`, `unitPreference`,
/// `dateOfBirth`, `sex`, `heightCm`, `dietaryRestrictions`. `email` is
/// present for display only -- nothing in this feature ever sends it
/// back to the server (see [ProfileRepository.updateProfile]'s
/// docblock).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.emailVerified,
    required this.timezone,
    required this.unitPreference,
    this.dateOfBirth,
    this.sex,
    this.heightCm,
    required this.dietaryRestrictions,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      emailVerified: json['emailVerified'] as bool,
      timezone: json['timezone'] as String,
      unitPreference: UnitPreference.fromWire(json['unitPreference'] as String),
      dateOfBirth: json['dateOfBirth'] as String?,
      sex: json['sex'] != null
          ? BiologicalSex.fromWire(json['sex'] as String)
          : null,
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      dietaryRestrictions: (json['dietaryRestrictions'] as List<dynamic>)
          .cast<String>(),
    );
  }

  final String id;
  final String name;
  final String email;
  final bool emailVerified;
  final String timezone;
  final UnitPreference unitPreference;

  /// ISO `yyyy-MM-dd`, matching the backend's `date_of_birth?->toDateString()`.
  /// Kept as a raw string rather than [DateTime] since it's a
  /// date-only value (no time/timezone component) and is only ever
  /// round-tripped, never computed on client-side.
  final String? dateOfBirth;
  final BiologicalSex? sex;
  final double? heightCm;
  final List<String> dietaryRestrictions;

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.emailVerified == emailVerified &&
      other.timezone == timezone &&
      other.unitPreference == unitPreference &&
      other.dateOfBirth == dateOfBirth &&
      other.sex == sex &&
      other.heightCm == heightCm &&
      _listEquals(other.dietaryRestrictions, dietaryRestrictions);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    email,
    emailVerified,
    timezone,
    unitPreference,
    dateOfBirth,
    sex,
    heightCm,
    Object.hashAll(dietaryRestrictions),
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
