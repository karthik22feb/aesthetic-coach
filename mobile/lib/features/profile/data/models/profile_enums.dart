/// Mirrors the backend's `UnitPreference` and `Sex` backed enums exactly
/// (backend/app/Modules/Auth/Enums/{UnitPreference,Sex}.php) -- enum
/// value names below are chosen so `.name` matches the wire value
/// exactly (`metric`, `imperial`, `male`, `female`, `unspecified`),
/// avoiding a separate string-mapping table.
enum UnitPreference {
  metric,
  imperial;

  static UnitPreference fromWire(String value) =>
      UnitPreference.values.byName(value);
}

/// Used only for DFS/nutrition baseline calculations, per
/// docs/04-database-design.md section 3.1 -- mirrored client-side purely
/// for profile display/edit, not used in any local calculation.
enum BiologicalSex {
  male,
  female,
  unspecified;

  static BiologicalSex fromWire(String value) =>
      BiologicalSex.values.byName(value);
}
