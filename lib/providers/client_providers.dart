import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/client.dart';
import '../models/client_filter.dart';
import 'repository_providers.dart';

/// How many clients are currently streamed. Grows by a page as the user
/// reaches the end of the list (Firestore-side pagination via `.limit`).
final clientsLimitProvider = StateProvider<int>((ref) {
  return AppConstants.clientsPageSize;
});

/// Free-text search query typed in the dashboard search field.
final clientSearchProvider = StateProvider<String>((ref) => '');

/// Active quick filter chip.
final clientFilterProvider =
    StateProvider<ClientFilter>((ref) => ClientFilter.all);

/// Live, unfiltered client list (already capped by [clientsLimitProvider]).
final clientsStreamProvider = StreamProvider<List<Client>>((ref) {
  final limit = ref.watch(clientsLimitProvider);
  return ref.watch(clientRepositoryProvider).watchClients(limit: limit);
});

/// Single client, kept live for the detail screen.
final clientProvider =
    StreamProvider.family<Client?, String>((ref, id) {
  return ref.watch(clientRepositoryProvider).watchClient(id);
});

/// The list after applying search + filter in memory. Searching and filtering
/// on the already-streamed data keeps results instant and avoids extra reads.
final filteredClientsProvider = Provider<List<Client>>((ref) {
  final clients = ref.watch(clientsStreamProvider).valueOrNull ?? const [];
  final query = ref.watch(clientSearchProvider).trim().toLowerCase();
  final filter = ref.watch(clientFilterProvider);
  final now = DateTime.now();

  return clients.where((client) {
    if (!filter.matches(client, now)) return false;
    if (query.isEmpty) return true;
    return client.searchHaystack.contains(query);
  }).toList();
});
