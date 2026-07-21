/// The two roles a staff member can hold.
///
/// [administrator] has full access (including deletion and manager management).
/// [manager] can read/create/update clients but cannot delete anything.
enum UserRole {
  administrator,
  manager;

  /// Firestore stores the role as a plain string.
  String get asString => name;

  bool get isAdmin => this == UserRole.administrator;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.manager,
    );
  }

  String get label => switch (this) {
        UserRole.administrator => 'Administrator',
        UserRole.manager => 'Manager',
      };
}
