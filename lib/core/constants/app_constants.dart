/// Global, compile-time constants shared across the app.
class AppConstants {
  AppConstants._();

  // Firestore collection names.
  static const String usersCollection = 'users';
  static const String clientsCollection = 'clients';

  // FCM topic every authenticated staff member subscribes to.
  static const String staffTopic = 'staff';

  // Pagination page size for the clients list.
  static const int clientsPageSize = 20;
}
