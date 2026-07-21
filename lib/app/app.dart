import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'routes/auth_gate.dart';

/// Root widget: wires the Material 3 themes and the auth-aware entry point.
class VipApp extends StatelessWidget {
  const VipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIP Client Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}
