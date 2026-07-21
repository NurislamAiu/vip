import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'providers/repository_providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Russian is the app's language: default Intl locale + date symbols so
  // Formatters and the localized widgets render Russian month names.
  Intl.defaultLocale = 'ru';
  await initializeDateFormatting('ru', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Offline-first: cache everything locally and reconcile when back online.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Register the background message handler before runApp.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final container = ProviderContainer();
  // Fire-and-forget: set up FCM + local notifications without blocking launch.
  unawaited(container.read(notificationServiceProvider).initialize());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const VipApp(),
    ),
  );
}
