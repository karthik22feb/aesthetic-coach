import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../application/auth_notifier.dart';
import '../application/auth_state.dart';

final _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// docs/screens/login.md. Email/password only -- Google/Apple buttons
/// shown in that spec are deliberately out of scope for this task (see
/// NEXT_TASK.md). Successful login is not handled here by navigating
/// directly; the router's redirect (lib/app/router.dart) reacts to
/// [authNotifierProvider] becoming authenticated, avoiding a
/// race/double-navigation between this screen and the redirect guard.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref
        .read(authNotifierProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isSubmitting = authState.status == AuthStatus.authenticating;

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
                    'Aesthetic Coach',
                    key: const Key('login_brand_mark'),
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (authState.failure != null) ...[
                    Text(
                      key: const Key('login_error_text'),
                      _messageFor(authState.failure!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      semanticsLabel: _messageFor(authState.failure!),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    key: const Key('login_email_field'),
                    controller: _emailController,
                    enabled: !isSubmitting,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
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
                    key: const Key('login_password_field'),
                    controller: _passwordController,
                    enabled: !isSubmitting,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('login_submit_button'),
                    onPressed: isSubmitting ? null : _submit,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Log In'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    key: const Key('login_signup_link'),
                    onPressed: isSubmitting
                        ? null
                        : () => context.go('/signup'),
                    child: const Text("Don't have an account? Sign up"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Per docs/screens/login.md § Error States: `401 unauthenticated` never
  /// specifies which field is wrong (anti-enumeration); other failure
  /// types get a general, non-technical message -- never a raw backend
  /// stack trace or internal detail.
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
