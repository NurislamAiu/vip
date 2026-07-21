import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/splash/splash_screen.dart';

/// Routes between login and the dashboard based on the authenticated profile.
///
/// While auth state is resolving it shows the splash; a signed-in, active
/// staff member lands on the dashboard, everyone else on the login screen.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const SplashScreen(),
      error: (e, _) {
        debugPrint('[gate] authState error: $e -> login');
        return const LoginScreen();
      },
      data: (user) {
        if (user == null) {
          debugPrint('[gate] no user -> login');
          return const LoginScreen();
        }

        // Signed in with Firebase — now resolve the staff profile.
        final profile = ref.watch(currentUserProvider);
        return profile.when(
          loading: () {
            debugPrint('[gate] profile loading -> splash');
            return const SplashScreen();
          },
          error: (e, _) {
            debugPrint('[gate] profile error: $e -> login');
            return const LoginScreen();
          },
          data: (appUser) {
            debugPrint('[gate] profile resolved: '
                '${appUser == null ? 'null -> login' : 'ok -> dashboard'}');
            return appUser == null
                ? const LoginScreen()
                : const DashboardScreen();
          },
        );
      },
    );
  }
}
