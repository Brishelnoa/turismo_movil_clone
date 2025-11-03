import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'auth_service.dart';
import 'network.dart';

/// Plugin para notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Servicio responsable de inicializar Firebase Messaging, obtener el token
/// FCM y registrarlo en el backend mediante el endpoint `/api/fcm-dispositivos/registrar/`.
class FcmService {
  /// Initialize Firebase and register handlers. Call from main() before runApp.
  static Future<void> init() async {
    try {
      // Initialize Firebase SDK
      await Firebase.initializeApp();
      if (kDebugMode) debugPrint('[FcmService] Firebase initialized');

      // Request notification permissions
      await _requestNotificationPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((message) {
        if (kDebugMode)
          debugPrint(
              '[FcmService] onMessage: ${message.messageId} ${message.notification?.title}');
        // Show local notification when app is in foreground
        _showLocalNotification(message);
      });

      // When the user taps a notification
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (kDebugMode)
          debugPrint('[FcmService] onMessageOpenedApp: ${message.messageId}');
      });

      // Obtain initial token and register it
      final token = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) debugPrint('[FcmService] FCM token: $token');
      if (token != null) {
        await registerTokenWithBackend(token);
      }

      // Listen for token refreshes and re-register
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) debugPrint('[FcmService] token refreshed: $newToken');
        await registerTokenWithBackend(newToken);
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FcmService] init error: $e');
        // Detect common Android misconfiguration where google-services.json
        // wasn't added and the Gradle plugin didn't generate the resource
        // values. The native plugin emits a PlatformException with this text.
        final msg = e.toString();
        if (msg.contains('Failed to load FirebaseOptions') ||
            msg.contains('No Firebase App') ||
            msg.contains('FirebaseOptions')) {
          debugPrint(
              '[FcmService] It looks like the Android/iOS Firebase native config is missing or malformed.');
          debugPrint(
              '[FcmService] Please add android/app/google-services.json (and iOS GoogleService-Info.plist) or run `flutterfire configure`.');
        }
        debugPrint(st.toString());
      }
    }
  }

  /// Request notification permissions (Android 13+)
  static Future<void> _requestNotificationPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint(
          '[FcmService] Notification permission status: ${settings.authorizationStatus}');
    }

    // Also request Android notification permission via local notifications
    if (Platform.isAndroid) {
      final bool? granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      if (kDebugMode) {
        debugPrint(
            '[FcmService] Android notification permission granted: $granted');
      }
    }
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode)
          debugPrint('[FcmService] Notification tapped: ${response.payload}');
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    if (kDebugMode) debugPrint('[FcmService] Local notifications initialized');
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    // Si el mensaje tiene notification, usarla
    String? title = notification?.title;
    String? body = notification?.body;

    // Si no tiene notification, intentar extraer de data
    if (title == null && message.data.isNotEmpty) {
      title = message.data['title'] ??
          message.data['titulo'] ??
          'Nueva notificación';
      body = message.data['body'] ??
          message.data['mensaje'] ??
          message.data['message'];
    }

    // Si aún no hay título, usar un valor por defecto
    title ??= 'Notificación';
    body ??= 'Tienes una nueva notificación';

    if (kDebugMode) {
      debugPrint('[FcmService] Showing notification: title=$title, body=$body');
      debugPrint('[FcmService] Message data: ${message.data}');
      debugPrint('[FcmService] Has notification: ${notification != null}');
    }

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );

    if (kDebugMode)
      debugPrint('[FcmService] Local notification shown successfully');
  }

  /// Register a token at backend. Uses AuthService.getAccessToken() to include Authorization header.
  static Future<bool> registerTokenWithBackend(String token,
      {String tipo = 'android', String? nombre}) async {
    try {
      final apiToken = await AuthService.getAccessToken();
      if (apiToken == null) {
        if (kDebugMode)
          debugPrint(
              '[FcmService] No API token available to register FCM token');
        return false;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization':
            apiToken.contains('.') ? 'Bearer $apiToken' : 'Token $apiToken'
      };

      final body = {
        'registration_id': token,
        'tipo_dispositivo': tipo,
        'nombre':
            nombre ?? (Platform.isAndroid ? 'android_device' : 'ios_device')
      };

      final resp = await postPath('/api/fcm-dispositivos/registrar/',
          headers: headers, body: body);
      if (kDebugMode) {
        debugPrint(
            '[FcmService] register response: ${resp.statusCode} ${resp.body}');
        // Try to decode JSON body for clearer logs
        try {
          final parsed = resp.body.isNotEmpty ? jsonDecode(resp.body) : null;
          debugPrint('[FcmService] register response json: $parsed');
        } catch (_) {}
      }
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      if (kDebugMode)
        debugPrint('[FcmService] registerTokenWithBackend error: $e');
      return false;
    }
  }

  /// Like [registerTokenWithBackend] but returns structured response for
  /// debugging/inspection (statusCode + parsed body). Does not throw.
  static Future<Map<String, dynamic>> registerTokenWithBackendVerbose(
      String token,
      {String tipo = 'android',
      String? nombre}) async {
    try {
      final apiToken = await AuthService.getAccessToken();
      if (apiToken == null) return {'success': false, 'error': 'no_api_token'};

      final headers = {
        'Content-Type': 'application/json',
        'Authorization':
            apiToken.contains('.') ? 'Bearer $apiToken' : 'Token $apiToken'
      };

      final body = {
        'registration_id': token,
        'tipo_dispositivo': tipo,
        'nombre':
            nombre ?? (Platform.isAndroid ? 'android_device' : 'ios_device')
      };

      final resp = await postPath('/api/fcm-dispositivos/registrar/',
          headers: headers, body: body);
      dynamic parsed;
      try {
        parsed = resp.body.isNotEmpty ? jsonDecode(resp.body) : null;
      } catch (e) {
        parsed = resp.body;
      }
      final success = resp.statusCode == 200 || resp.statusCode == 201;
      return {
        'success': success,
        'statusCode': resp.statusCode,
        'body': parsed,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Ensure Firebase is initialized and obtain current token, then register it.
  /// This is a safe fallback for callers that may run before `init()` completed.
  static Future<bool> ensureInitializedAndRegister(
      {String tipo = 'android', String? nombre}) async {
    try {
      // If no app exists, attempt initialization (non-blocking if already initialized)
      if (Firebase.apps.isEmpty) {
        if (kDebugMode)
          debugPrint(
              '[FcmService] Firebase not initialized, calling initializeApp() as fallback');
        await Firebase.initializeApp();
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        if (kDebugMode)
          debugPrint(
              '[FcmService] ensureInitializedAndRegister: token is null');
        return false;
      }
      return await registerTokenWithBackend(token, tipo: tipo, nombre: nombre);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FcmService] ensureInitializedAndRegister error: $e');
        final msg = e.toString();
        if (msg.contains('Failed to load FirebaseOptions') ||
            msg.contains('No Firebase App') ||
            msg.contains('FirebaseOptions')) {
          debugPrint(
              '[FcmService] ensureInitializedAndRegister: missing native Firebase config. Add google-services.json / GoogleService-Info.plist or run `flutterfire configure`.');
        }
      }
      return false;
    }
  }
}

/// Top-level background handler required by firebase_messaging. Must be a top-level
/// function (not a closure or class method) so the native side can invoke it.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to use plugins in this handler, ensure Firebase.initializeApp is called.
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint(
        '[FcmService] Background message received: ${message.messageId}');
    debugPrint('[FcmService] Data: ${message.data}');
  }
}
