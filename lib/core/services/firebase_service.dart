import 'package:expense_mate/core/utils/logger.dart';
import 'package:expense_mate/firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Background FCM handler — must be top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.i('FCM', 'Background message: ${message.messageId}');
}

/// Initializes and exposes all Firebase services.
class FirebaseService {
  FirebaseService({
    required FirebaseAnalytics analytics,
    required FirebaseRemoteConfig remoteConfig,
    required FirebaseMessaging messaging,
  })  : _analytics = analytics,
        _remoteConfig = remoteConfig,
        _messaging = messaging;

  final FirebaseAnalytics _analytics;
  final FirebaseRemoteConfig _remoteConfig;
  final FirebaseMessaging _messaging;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseRemoteConfig get remoteConfig => _remoteConfig;
  FirebaseMessaging get messaging => _messaging;

  static Future<FirebaseService> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    if (!kDebugMode) {
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.appAttest,
        );
      } catch (e, stack) {
        AppLogger.w(
          'AppCheck',
          'Activation failed — continuing without App Check',
          e,
          stack,
        );
      }
    } else {
      AppLogger.i('AppCheck', 'Skipped in debug builds');
    }

    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await remoteConfig.setDefaults(const {
      'enable_biometric': true,
      'enable_dark_mode': true,
      'budget_alert_threshold': 0.8,
      'daily_reminder_hour': 20,
    });
    await remoteConfig.fetchAndActivate();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final analytics = FirebaseAnalytics.instance;

    AppLogger.i('Firebase', 'All services initialized');

    return FirebaseService(
      analytics: analytics,
      remoteConfig: remoteConfig,
      messaging: messaging,
    );
  }

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<String?> get fcmToken => _messaging.getToken();
}

final firebaseServiceProvider = FutureProvider<FirebaseService>((ref) async {
  return FirebaseService.initialize();
});

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return ref.watch(firebaseServiceProvider).requireValue.analytics;
});
