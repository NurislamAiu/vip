import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import 'repository_providers.dart';

/// Live list of all staff members (administrator-only screen).
final usersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).watchUsers();
});
