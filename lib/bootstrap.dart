import 'dart:async';

import 'package:expense_mate/app.dart';
import 'package:expense_mate/core/services/firebase_service.dart';
import 'package:expense_mate/core/services/local_storage_service.dart';
import 'package:expense_mate/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initializes Firebase, database, and sync before launching the app.
Future<void> bootstrap() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await FirebaseService.initialize();
      final prefs = await SharedPreferences.getInstance();

      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ExpenseMateApp(),
        ),
      );
    },
    (error, stack) {
      AppLogger.e('Bootstrap', 'Uncaught error', error, stack);
    },
  );
}
