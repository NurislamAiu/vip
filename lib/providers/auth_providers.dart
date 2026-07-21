import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import 'repository_providers.dart';

/// Raw Firebase auth state (signed-in [User] or null).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges().map((user) {
    debugPrint('[auth] authState -> ${user == null ? 'signed out' : 'uid=${user.uid}'}');
    return user;
  });
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
    (profile) {
      final allowed = profile != null && profile.isActive;
      debugPrint('[auth] profile stream for ${user.uid}: '
          'exists=${profile != null}, active=${profile?.isActive}, allowedIn=$allowed');
      return allowed ? profile : null;
    },
  ).handleError((Object e) {
    debugPrint('[auth] profile stream ERROR: $e');
    throw e; // keep forwarding so AuthGate can fall back to the login screen
  });
});
