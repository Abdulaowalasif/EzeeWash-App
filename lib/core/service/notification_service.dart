// lib/core/service/notification_service.dart
//
// ROOT CAUSE OF "subscription not confirmed after 8 s"
// ─────────────────────────────────────────────────────
// requestPermission() was called AFTER setUserId(). The subscription polls
// for optedIn == true, but the OS permission dialog had not been shown yet,
// so optedIn was always false. The poll timed out and the device was left
// with an inactive subscription — OneSignal won't deliver to it.
//
// THE FIX
// ───────
// loginAndWaitForSubscription() now does everything in the correct order:
//   1. Request OS permission FIRST  (optedIn can only become true after this)
//   2. Call OneSignal.login()       (links external_id to the subscription)
//   3. Poll for optedIn == true     (now succeeds because permission is granted)
//
// main.dart calls ONLY loginAndWaitForSubscription() — the old separate
// setUserId() + requestPermission() calls are replaced by this single method.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../routes/routes_name.dart';

class NotificationService {
  NotificationService._();

  static final _local = FlutterLocalNotificationsPlugin();

  // Channel ID must match android_channel_id in the Supabase Edge Function.
  static const _channel = AndroidNotificationChannel(
    'ezeewash_orders',
    'Order Updates',
    description: 'Notifications about your laundry order status',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // Injected by app_router.dart after GoRouter is created.
  static GoRouter? _router;
  static void setRouter(GoRouter router) => _router = router;

  // =========================================================================
  // STEP 1 — init()  →  call from main(), before runApp()
  // =========================================================================
  static Future<void> init(String appId) async {
    // ── flutter_local_notifications ────────────────────────────────────────
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (res) => _handleDeepLink(res.payload),
      onDidReceiveBackgroundNotificationResponse: _bgTapHandler,
    );

    // Create the Android notification channel (idempotent on re-runs).
    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // ── OneSignal ──────────────────────────────────────────────────────────
    OneSignal.Debug.setLogLevel(OSLogLevel.none);
    OneSignal.initialize(appId);

    // ── FOREGROUND listener ────────────────────────────────────────────────
    // Fires ONLY while the Flutter engine is running (app in foreground).
    // Suppresses the raw OneSignal heads-up and shows a styled local banner.
    // In background/killed state this never runs — the OS handles delivery
    // natively via FCM without involving Flutter.
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.preventDefault(); // suppress raw OneSignal heads-up

      final n = event.notification;

      _showStyledNotification(
        id: _uuidToId(n.notificationId),
        title: n.title ?? 'EzeeWash',
        body: n.body ?? '',
        payload: jsonEncode(n.additionalData ?? {}),
      ).catchError((e) {
        // If local show fails after preventDefault(), restore the original
        // so the user always sees something rather than nothing.
        debugPrint('[NotificationService] local show failed ($e) — restoring');
        event.notification.display();
      });
    });

    // ── TAP / CLICK listener ───────────────────────────────────────────────
    // Fires when the user taps a notification from any app state.
    OneSignal.Notifications.addClickListener((event) {
      _handleDeepLink(jsonEncode(event.notification.additionalData ?? {}));
    });

    debugPrint('[NotificationService] initialised');
  }

  // =========================================================================
  // STEP 2 — loginAndWaitForSubscription()  →  call after login in main.dart
  //
  // THE KEY FIX: permission is requested FIRST, then login, then we poll.
  // optedIn can only become true once the OS permission is granted.
  // Calling login() before permission means the subscription stays opted-out
  // and the 8-second poll always times out.
  // =========================================================================
  static Future<void> loginAndWaitForSubscription(String userId) async {
    // ── STEP A: Request OS permission FIRST ───────────────────────────────
    // optedIn cannot become true until the user grants notification permission.
    // This must happen before login() + polling or the poll always times out.
    final alreadyGranted = await OneSignal.Notifications.permission;
    if (!alreadyGranted) {
      debugPrint('[NotificationService] requesting OS permission...');
      await OneSignal.Notifications.requestPermission(true);
    }

    // iOS also needs flutter_local_notifications permission.
    await _local
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // ── STEP B: Link the user's Supabase UUID to their OneSignal device ───
    await OneSignal.login(userId);
    debugPrint('[NotificationService] OneSignal login called → $userId');

    // ── STEP C: Poll until subscription is active ─────────────────────────
    // Now that permission is granted, optedIn should become true quickly.
    // We wait up to 10 s to ensure the external_id is confirmed server-side
    // before returning, so any immediately-following Supabase DB insert
    // (which triggers the push webhook) finds a valid subscription.
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final sub = OneSignal.User.pushSubscription;
      debugPrint(
          '[NotificationService] poll $i — id=${sub.id} optedIn=${sub.optedIn}');
      if (sub.id != null && sub.optedIn == true) {
        debugPrint('[NotificationService] subscription ready ✓  id=${sub.id}');
        return;
      }
    }

    debugPrint(
        '[NotificationService] ⚠️ subscription not confirmed after 10 s. '
            'Check: (1) device has granted notification permission, '
            '(2) google-services.json matches app package name, '
            '(3) device has internet connectivity.');
  }

  // =========================================================================
  // STEP 3 — clearUserId()  →  call on logout
  // =========================================================================
  static void clearUserId() {
    OneSignal.logout();
    debugPrint('[NotificationService] OneSignal unlinked');
  }

  // =========================================================================
  // showOrderUpdate()  →  called from OrdersBloc listener (foreground only)
  // Background/killed-state pushes arrive through OneSignal natively.
  // =========================================================================
  static Future<void> showOrderUpdate({
    required String orderNumber,
    required String status,
    String? orderId,
  }) async {
    final (title, body) = _orderLabels(orderNumber, status);
    await _showStyledNotification(
      id: orderNumber.hashCode,
      title: title,
      body: body,
      payload: orderId != null ? jsonEncode({'orderId': orderId}) : null,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static Future<void> _showStyledNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _local.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF1D4BC7),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Convert a UUID string to a stable int notification ID by parsing the
  /// first 8 hex chars. Avoids Dart's String.hashCode collisions that can
  /// silently overwrite previous notifications with the same computed int.
  static int _uuidToId(String uuid) {
    try {
      final hex = uuid.replaceAll('-', '').substring(0, 8);
      return int.parse(hex, radix: 16);
    } catch (_) {
      return uuid.hashCode;
    }
  }

  static (String, String) _orderLabels(String orderNumber, String status) {
    return switch (status) {
      'confirmed' => (
      '✅ Order Confirmed',
      'Your order #$orderNumber has been confirmed.'
      ),
      'picked_up' => (
      '🚗 Picked Up',
      'Order #$orderNumber has been picked up for washing.'
      ),
      'in_process' => (
      '🫧 In Progress',
      'Your laundry is being washed right now!'
      ),
      'ready' => (
      '📦 Ready for Delivery',
      'Order #$orderNumber is clean and ready!'
      ),
      'out_for_delivery' => (
      '🛵 Out for Delivery',
      'Order #$orderNumber is on its way to you.'
      ),
      'delivered' => (
      '🎉 Delivered!',
      'Order #$orderNumber has been delivered. Enjoy!'
      ),
      'cancelled' => (
      '❌ Order Cancelled',
      'Order #$orderNumber has been cancelled.'
      ),
      _ => ('EzeeWash Update', 'Order #$orderNumber is now $status'),
    };
  }

  static void _handleDeepLink(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final orderId = data['orderId'] as String?;
      if (orderId != null && _router != null) {
        debugPrint('[NotificationService] deep-link → order: $orderId');
        _router!.go(RoutesName.trackOrdersNavigate, extra: orderId);
      }
    } catch (e) {
      debugPrint('[NotificationService] deep-link error: $e');
    }
  }
}

// Top-level function — runs in a background isolate when the app is killed.
@pragma('vm:entry-point')
void _bgTapHandler(NotificationResponse response) {
  debugPrint('[NotificationService] bg tap payload: ${response.payload}');
}