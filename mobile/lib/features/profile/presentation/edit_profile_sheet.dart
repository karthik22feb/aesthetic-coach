import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../application/profile_notifier.dart';
import '../data/models/profile_enums.dart';
import '../data/models/user_profile.dart';

/// docs/components/bottom-sheet.md's "Bottom Sheet Logger" pattern,
/// docs/screens/profile.md's Edit Profile sheet. Every field maps
/// directly onto a `PATCH /me` field from
/// backend/app/Modules/Auth/Http/Requests/UpdateProfileRequest.php --
/// `name`, `timezone`, `unitPreference`, `dateOfBirth`, `sex`,
/// `heightCm`, `dietaryRestrictions`. `email` intentionally has no field
/// here at all (see ProfileScreen's docblock) -- the backend's column
/// allowlist would silently drop it even if sent, but the stronger
/// guarantee is that this form has no way to produce it in the first
/// place.
///
/// On submit, the full set of editable fields is always sent (not just
/// the ones the user touched this session) -- since the sheet is always
/// initialized from the current profile, this is equivalent to a
/// partial update in effect, and avoids a separate touched-field-tracking
/// mechanism for an "S complexity" screen (per
/// docs/IMPLEMENTATION_ORDER.md#3-user-profile).
///
/// Per docs/screens/profile.md's Error States ("edit failures shown
/// inline within the Edit Profile sheet, not dismissing the sheet"),
/// this sheet owns its own submit-in-flight and error state locally --
/// it does not go through [ProfileState], which only tracks the
/// underlying screen's load state.
class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _timezoneController;
  late final TextEditingController _heightController;
  final _dietaryInputController = TextEditingController();

  late UnitPreference _unitPreference;
  late BiologicalSex? _sex;
  late String? _dateOfBirth;
  late List<String> _dietaryRestrictions;

  bool _isSubmitting = false;
  Map<String, List<String>> _fieldErrors = const {};
  String? _generalError;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(text: profile.name);
    _timezoneController = TextEditingController(text: profile.timezone);
    _heightController = TextEditingController(
      text: profile.heightCm?.toStringAsFixed(1) ?? '',
    );
    _unitPreference = profile.unitPreference;
    _sex = profile.sex;
    _dateOfBirth = profile.dateOfBirth;
    _dietaryRestrictions = List.of(profile.dietaryRestrictions);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timezoneController.dispose();
    _heightController.dispose();
    _dietaryInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                if (_generalError != null) ...[
                  Text(
                    key: const Key('edit_profile_error_text'),
                    _generalError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  key: const Key('edit_profile_name_field'),
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: _errorFor('name'),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('edit_profile_timezone_field'),
                  controller: _timezoneController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Timezone',
                    hintText: 'e.g. Asia/Kolkata',
                    errorText: _errorFor('timezone'),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Timezone is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Unit preference',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SegmentedButton<UnitPreference>(
                  key: const Key('edit_profile_unit_preference_field'),
                  segments: const [
                    ButtonSegment(
                      value: UnitPreference.metric,
                      label: Text('Metric'),
                    ),
                    ButtonSegment(
                      value: UnitPreference.imperial,
                      label: Text('Imperial'),
                    ),
                  ],
                  selected: {_unitPreference},
                  onSelectionChanged: _isSubmitting
                      ? null
                      : (selection) =>
                            setState(() => _unitPreference = selection.first),
                ),
                const SizedBox(height: 16),
                ListTile(
                  key: const Key('edit_profile_dob_button'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date of birth'),
                  subtitle: Text(_dateOfBirth ?? 'Not set'),
                  trailing: _dateOfBirth == null
                      ? null
                      : IconButton(
                          key: const Key('edit_profile_dob_clear_button'),
                          icon: const Icon(Icons.clear),
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(() => _dateOfBirth = null),
                        ),
                  onTap: _isSubmitting ? null : _pickDateOfBirth,
                ),
                if (_errorFor('dateOfBirth') != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _errorFor('dateOfBirth')!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                DropdownButtonFormField<BiologicalSex?>(
                  key: const Key('edit_profile_sex_field'),
                  initialValue: _sex,
                  decoration: InputDecoration(
                    labelText: 'Sex',
                    errorText: _errorFor('sex'),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Not set')),
                    DropdownMenuItem(
                      value: BiologicalSex.male,
                      child: Text('Male'),
                    ),
                    DropdownMenuItem(
                      value: BiologicalSex.female,
                      child: Text('Female'),
                    ),
                    DropdownMenuItem(
                      value: BiologicalSex.unspecified,
                      child: Text('Unspecified'),
                    ),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _sex = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('edit_profile_height_field'),
                  controller: _heightController,
                  enabled: !_isSubmitting,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Height (cm)',
                    errorText: _errorFor('heightCm'),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null) return 'Enter a valid number';
                    if (parsed < 50 || parsed > 250) {
                      return 'Height must be between 50 and 250 cm';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Dietary restrictions',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('edit_profile_dietary_input_field'),
                        controller: _dietaryInputController,
                        enabled: !_isSubmitting,
                        decoration: const InputDecoration(
                          hintText: 'e.g. vegetarian',
                        ),
                        onFieldSubmitted: (_) => _addDietaryRestriction(),
                      ),
                    ),
                    IconButton(
                      key: const Key('edit_profile_dietary_add_button'),
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _isSubmitting ? null : _addDietaryRestriction,
                    ),
                  ],
                ),
                if (_errorFor('dietaryRestrictions') != null)
                  Text(
                    _errorFor('dietaryRestrictions')!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                if (_dietaryRestrictions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    key: const Key('edit_profile_dietary_chip_list'),
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final restriction in _dietaryRestrictions)
                        Chip(
                          label: Text(restriction),
                          onDeleted: _isSubmitting
                              ? null
                              : () => setState(
                                  () =>
                                      _dietaryRestrictions.remove(restriction),
                                ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('edit_profile_save_button'),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _errorFor(String field) => _fieldErrors[field]?.first;

  void _addDietaryRestriction() {
    final value = _dietaryInputController.text.trim();
    if (value.isEmpty) return;
    if (!_dietaryRestrictions.contains(value)) {
      setState(() => _dietaryRestrictions.add(value));
    }
    _dietaryInputController.clear();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    // Mirrors the backend's own `before_or_equal:` rule
    // (UpdateProfileRequest.php: `Carbon::now()->subYears(18)`) --
    // matching this client-side keeps the date picker from ever
    // offering a value the server would reject.
    final latestAllowed = DateTime(now.year - 18, now.month, now.day);
    final earliestAllowed = DateTime(now.year - 100, now.month, now.day);
    final current = _dateOfBirth != null
        ? DateTime.parse(_dateOfBirth!)
        : latestAllowed;

    final picked = await showDatePicker(
      context: context,
      initialDate: current.isAfter(latestAllowed) ? latestAllowed : current,
      firstDate: earliestAllowed,
      lastDate: latestAllowed,
    );
    if (picked != null) {
      setState(() => _dateOfBirth = _formatDate(picked));
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _fieldErrors = const {};
      _generalError = null;
    });

    final heightText = _heightController.text.trim();
    final changes = <String, dynamic>{
      'name': _nameController.text.trim(),
      'timezone': _timezoneController.text.trim(),
      'unitPreference': _unitPreference.name,
      'dateOfBirth': _dateOfBirth,
      'sex': _sex?.name,
      'heightCm': heightText.isEmpty ? null : double.parse(heightText),
      'dietaryRestrictions': _dietaryRestrictions,
    };

    try {
      await ref.read(profileNotifierProvider.notifier).updateProfile(changes);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        if (failure is ValidationFailure) {
          _fieldErrors = failure.fieldErrors;
          _generalError = null;
        } else {
          _fieldErrors = const {};
          _generalError = _messageFor(failure);
        }
      });
    }
  }

  String _messageFor(Failure failure) {
    return switch (failure) {
      AuthFailure(:final message) => message,
      ValidationFailure(:final message) => message,
      RateLimitedFailure(:final message) => message,
      NetworkFailure(:final message) => message,
      ServerFailure(:final message) => message,
    };
  }
}
