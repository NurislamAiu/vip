import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

/// Wraps Firebase Authentication and resolves the signed-in user's profile
/// document from the `users` collection.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Emits on every sign-in / sign-out.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  /// Live profile for the given auth uid, or `null` while it does not exist.
  Stream<AppUser?> userProfile(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);
  }

  /// Resolves the signed-in user's profile after sign-in, bootstrapping one
  /// when it is missing.
  ///
  /// Staff created by an administrator always have a profile document already;
  /// the only accounts that reach here without one are those created directly
  /// in the Firebase console (the first/owner account). For those we create an
  /// **administrator** profile so the app is usable out of the box. Existing
  /// profiles are returned untouched.
  ///
  /// Returns the resulting [AppUser], or `null` if there is no signed-in user.
  Future<AppUser?> ensureProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[auth] ensureProfile: no signed-in user');
      return null;
    }

    final ref =
        _firestore.collection(AppConstants.usersCollection).doc(user.uid);

    debugPrint('[auth] ensureProfile: reading users/${user.uid}…');
    var snapshot = await ref.get();
    debugPrint('[auth] ensureProfile: exists=${snapshot.exists}');

    if (!snapshot.exists) {
      final fallbackName = (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'Administrator');

      debugPrint('[auth] ensureProfile: bootstrapping administrator profile…');
      await ref.set({
        'name': fallbackName,
        'phone': user.phoneNumber ?? '',
        'email': user.email ?? '',
        'role': UserRole.administrator.asString,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[auth] ensureProfile: profile created');
      snapshot = await ref.get();
    }

    return snapshot.exists ? AppUser.fromDoc(snapshot) : null;
  }
}
