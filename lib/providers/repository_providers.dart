import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import '../repositories/client_repository.dart';
import '../repositories/user_repository.dart';
import '../services/notification_service.dart';

/// Singletons for the data layer. Kept here so the whole app shares one
/// instance of each repository/service.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
