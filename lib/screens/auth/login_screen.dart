import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/validators.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/brand_mark.dart';

/// Email + password sign-in. On success the [AuthGate] swaps to the dashboard.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      debugPrint('[login] signing in as "${_emailController.text.trim()}"…');
      await auth.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      debugPrint('[login] signIn OK, uid=${auth.currentUser?.uid}');

      // Sign-in succeeded at the auth level — now make sure this account has an
      // active staff profile, otherwise the app would silently bounce back
      // here. Bootstrap one when missing; block disabled accounts clearly.
      final profile = await auth.ensureProfile();
      debugPrint('[login] ensureProfile -> '
          '${profile == null ? 'null' : 'role=${profile.role.asString}, active=${profile.isActive}'}');
      if (profile == null || !profile.isActive) {
        await auth.signOut();
        if (mounted) {
          setState(() => _error =
              'This account is not active yet. Ask an administrator to enable it.');
        }
        return;
      }
      debugPrint('[login] success — AuthGate should swap to dashboard');
      // AuthGate reacts to the profile becoming available; nothing else to do.
    } on FirebaseAuthException catch (e) {
      debugPrint('[login] FirebaseAuthException: ${e.code} — ${e.message}');
      setState(() => _error = _messageFor(e));
    } on FirebaseException catch (e) {
      // Firestore/permission errors while resolving or bootstrapping profile.
      debugPrint('[login] FirebaseException (${e.plugin}): ${e.code} — ${e.message}');
      setState(() => _error = 'Profile check failed: ${e.code}. '
          '${e.code == 'permission-denied' ? 'Deploy the updated Firestore rules.' : (e.message ?? '')}');
    } catch (e, st) {
      debugPrint('[login] unexpected error: $e\n$st');
      setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _messageFor(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'That email address is not valid.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'Incorrect email or password.',
      'too-many-requests' => 'Too many attempts. Try again later.',
      _ => 'Unable to sign in. Please try again.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: BrandMark(size: 68),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text(
                          'Welcome back',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 10),
                        const VipTag(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to VIP Client Manager',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
