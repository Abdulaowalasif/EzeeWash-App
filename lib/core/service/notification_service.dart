// lib/core/service/notification_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../routes/routes_name.dart';
import '../constants/order_status.dart'; // ─── NEW IMPORT

class NotificationService {
  NotificationService._();

  static final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'ezeewash_orders',
    'Order Updates',
    description: 'Notifications about your laundry order status',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static GoRouter? _router;

  // Stores the route to navigate to after auth resolves.
  static String? _pendingRoute;

  static void setRouter(GoRouter router) {
    _router = router;
  }

  /// Returns the queued deep-link route and clears it.
  static String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  // =========================================================================
  // init() — call from main() before runApp()
  // =========================================================================
  static Future<void> init(String appId) async {
    const androidSettings = AndroidInitializationSettings('@mipmap/logo');
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
      onDidReceiveNotificationResponse: (res) {
        Map<String, dynamic>? data;
        if (res.payload != null) {
          try {
            data = jsonDecode(res.payload!);
          } catch (_) {}
        }
        _onTap(data);
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // OneSignal initialization
    OneSignal.Debug.setLogLevel(OSLogLevel.none);
    OneSignal.initialize(appId);

    // Foreground notification handling
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.preventDefault();
      final n = event.notification;
      _showStyledNotification(
        id: n.notificationId.hashCode,
        title: n.title ?? 'EzeeWash',
        body: n.body ?? '',
      );
    });

    // Tap handling
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('[NS] notification tapped');
      final additionalData = event.notification.additionalData;
      _onTap(additionalData);
    });
  }

  // =========================================================================
  // loginAndWaitForSubscription()
  // =========================================================================
  static Future<void> loginAndWaitForSubscription(String userId) async {
    final alreadyGranted = OneSignal.Notifications.permission;
    if (!alreadyGranted) {
      await OneSignal.Notifications.requestPermission(true);
    }

    await OneSignal.login(userId);
    debugPrint('[NS] OneSignal login → $userId');

    // Poll for subscription ID to ensure backend can send notifications
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final sub = OneSignal.User.pushSubscription;
      if (sub.id != null && sub.optedIn == true) {
        debugPrint('[NS] subscription ready ✓ id=${sub.id}');
        return;
      }
    }
    debugPrint('[NS] ⚠️ subscription not confirmed after 10 s');
  }

  // =========================================================================
  // clearUserId()
  // =========================================================================
  static void clearUserId() {
    OneSignal.logout();
    debugPrint('[NS] OneSignal unlinked');
  }

  // =========================================================================
  // showOrderUpdate()
  // =========================================================================
  static Future<void> showOrderUpdate({
    required String orderNumber,
    required String status,
    String? orderId,
  }) async {
    final (title, body) = _orderLabels(orderNumber, status);
    final payload = jsonEncode({'type': 'order_update', 'orderId': orderId});
    await _showStyledNotification(
      id: orderNumber.hashCode,
      title: title,
      body: body,
      payload: payload,
    );
  }

  // =========================================================================
  // Private Helpers
  // =========================================================================

  static void _onTap([Map<String, dynamic>? data]) {
    String targetRoute = RoutesName.alertsNavigate;
    
    if (data != null) {
      final type = data['type'] as String? ?? data['notification_type'] as String?;
      if (type == 'promo') {
        targetRoute = RoutesName.home;
      } else if (type == 'order_update') {
        final orderId = data['orderId'] ?? data['order_id'];
        if (orderId != null) {
          targetRoute = '${RoutesName.trackOrdersNavigate}?id=$orderId';
        } else {
          targetRoute = RoutesName.trackOrdersNavigate;
        }
      }
    }

    final router = _router;
    if (router != null) {
      final loc = router.routerDelegate.currentConfiguration.uri.toString();
      final isPreAuth = loc == RoutesName.splash || loc == RoutesName.login;

      if (!isPreAuth) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (targetRoute == RoutesName.home || targetRoute == RoutesName.alertsNavigate) {
            router.go(targetRoute);
          } else {
            router.push(targetRoute);
          }
        });
        return;
      }
    }

    debugPrint('[NS] queuing pending route → $targetRoute');
    _pendingRoute = targetRoute;
  }

  static Future<void> _showStyledNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _local.show(
     id:  id,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/logo',
          color: const Color(0xFF1D4BC7),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ─── UPDATED: Using OrderStatus constants ───
  static (String, String) _orderLabels(String orderNumber, String status) {
    return switch (status) {
      OrderStatus.confirmed      => ('✅ Order Confirmed',     'Your order #$orderNumber has been confirmed.'),
      OrderStatus.pickedUp       => ('🚗 Picked Up',           'Order #$orderNumber has been picked up.'),
      OrderStatus.inProcess      => ('🫧 In Progress',          'Your laundry is being washed!'),
      OrderStatus.ready          => ('📦 Ready for Delivery',  'Order #$orderNumber is ready!'),
      OrderStatus.outForDelivery => ('🛵 Out for Delivery',    'Order #$orderNumber is on its way.'),
      OrderStatus.delivered      => ('🎉 Delivered!',           'Order #$orderNumber has been delivered.'),
      OrderStatus.cancelled      => ('❌ Order Cancelled',      'Order #$orderNumber was cancelled.'),
      _                          => ('EzeeWash Update',         'Order #$orderNumber status: $status'),
    };
  }
}