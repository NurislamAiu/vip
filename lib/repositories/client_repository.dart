import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/client.dart';

/// CRUD access to the `clients` collection, backed by Firestore streams so
/// every manager sees changes in real time.
class ClientRepository {
  ClientRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.clientsCollection);

  /// Live list of clients, newest first.
  ///
  /// [limit] caps how many documents are streamed (used for pagination — the
  /// dashboard grows the limit as the user scrolls, which keeps a single live
  /// subscription instead of stitching pages together).
  Stream<List<Client>> watchClients({int? limit}) {
    Query<Map<String, dynamic>> query =
        _col.orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(
          (snap) => snap.docs.map(Client.fromDoc).toList(),
        );
  }

  Stream<Client?> watchClient(String id) {
    return _col.doc(id).snapshots().map(
          (doc) => doc.exists ? Client.fromDoc(doc) : null,
        );
  }

  Future<String> createClient(Client client, {required String createdBy}) async {
    final ref = await _col.add({
      ...client.toMap(),
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateClient(Client client) {
    return _col.doc(client.id).update({
      ...client.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteClient(String id) => _col.doc(id).delete();
}
