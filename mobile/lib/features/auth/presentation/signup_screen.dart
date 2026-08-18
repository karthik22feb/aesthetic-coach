import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../application/auth_notifier.dart';
import '../application/auth_state.dart';

final _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _passwordHasLetter = RegExp('[A-Za-z]');
final _passwordHasDigit = RegExp('[0-9]');

/// docs/screens/signup.md. Password policy mirrors BR-1 exactly
/// (backend/app/Modules/Auth/Http/Requests/RegisterRequest.php: min 10
/// chars, >=1 letter, >=1 digit) as a client-side UX hint -- the server
/// remains authoritative, per that screen's Validation section.
///
/// Documented destination on success is Onboarding (Module 4), which
/// does not exist yet -- this screen relies on the same router redirect
/// as Login, which currently sends every authenticated user to the app
/// shell (Home). See NEXT_TASK.md for this gap.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref
        .read(authNotifierProvider.notifier)
        .register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isSubmitting = authState.status == AuthStatus.authenticating;
    final validationDetails = switch (authState.failure) {
      ValidationFailure(:final fieldErrors) => fieldErrors,
      _ => const <String, List<String>>{},
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create your account',
                    key: const Key('signup_brand_mark'),
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (authState.failure != null &&
                      validationDetails.isEmpty) ...[
                    Text(
                      key: const Key('signup_error_text'),
                      _messageFor(authState.failure!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    key: const Key('signup_name_field'),
                    controller: _nameController,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      errorText: validationDetails['name']?.first,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (value.trim().length > 120) {
                        return 'Name must be 120 characters or fewer';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('signup_email_field'),
                    controller: _emailController,
                    enabled: !isSubmitting,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: validationDetails['email']?.first,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!_emailFormat.hasMatch(value.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('signup_password_field'),
                    controller: _passwordController,
                    enabled: !isSubmitting,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: validationDetails['password']?.first,
                      helperText:
                          'At least 10 characters, with a letter and a number',
                      helperMaxLines: 2,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 10) {
                        return 'Password must be at least 10 characters';
                      }
                      if (!_passwordHasLetter.hasMatch(value)) {
                        return 'Password must include a letter';
                      }
                      if (!_passwordHasDigit.hasMatch(value)) {
                        return 'Password must include a number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('signup_confirm_password_field'),
                    controller: _confirmPasswordController,
                    enabled: !isSubmitting,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('signup_submit_button'),
                    onPressed: isSubmitting ? null : _submit,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Account'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    key: const Key('signup_login_link'),
                    onPressed: isSubmitting ? null : () => context.go('/login'),
                    child: const Text('Already have an account? Log in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
