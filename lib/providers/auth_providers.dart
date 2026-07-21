import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import 'repository_providers.dart';

/// Raw Firebase auth state (signed-in [User] or null).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// The signed-in staff member's profile document, resolved from `users`.
///
/// Resolves to `null` when signed out, when no profile document exists, or
/// when the account has been deactivated — the router treats all three as
/// "not allowed in".
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value(null);

  return ref.watch(authRepositoryProvider).userProfile(user.uid).map(
        (profile) => (profile != null && profile.isActive) ? profile : null,
      );
});
