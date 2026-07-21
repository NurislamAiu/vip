import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

/// Manages the `users` collection: administrators use it to create, edit,
/// enable/disable, and remove managers.
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.usersCollection);

  /// Live, name-ordered list of all staff members.
  Stream<List<AppUser>> watchUsers() {
    return _col.orderBy('name').snapshots().map(
          (snap) => snap.docs.map(AppUser.fromDoc).toList(),
        );
  }

  /// Creates a new staff account.
  ///
  /// Auth users cannot be provisioned on behalf of someone else with the
  /// primary [FirebaseAuth] instance without hijacking the current session, so
  /// this spins up an isolated secondary [FirebaseApp], creates the account
  /// there, writes the matching profile document, then disposes it — leaving
  /// the administrator's session untouched.
  Future<void> createStaff({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'user-provisioning-${DateTime.now().microsecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      final credential =
          await FirebaseAuth.instanceFor(app: secondaryApp)
              .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;

      await _col.doc(uid).set({
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'role': role.asString,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } finally {
      await secondaryApp.delete();
    }
  }

  Future<void> updateStaff(AppUser user) {
    return _col.doc(user.id).update({
      'name': user.name.trim(),
      'phone': user.phone.trim(),
      'role': user.role.asString,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setActive(String uid, bool isActive) {
    return _col.doc(uid).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes the staff member's profile document.
  ///
  /// Deleting the underlying Auth account requires the Admin SDK (a Cloud
  /// Function), which is out of scope for the client. Once the document is gone
  /// the app treats the account as non-existent and blocks sign-in.
  Future<void> deleteStaff(String uid) {
    return _col.doc(uid).delete();
  }
}
