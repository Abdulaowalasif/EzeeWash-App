// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/service/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'features/orders/presentation/bloc/order_event.dart';
import 'features/orders/presentation/bloc/orders_bloc.dart';
import 'features/orders/presentation/bloc/orders_state.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/profile/presentation/bloc/profile_event.dart';
import 'features/services/presentation/bloc/service_bloc.dart';
import 'features/services/presentation/bloc/service_event.dart';
import 'features/store/presentation/bloc/store_bloc.dart';
import 'features/store/presentation/bloc/stores_event.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';

// ─── FCM background handler ────────────────────────────────────────────────
// Must be top-level. Registers the background isolate so FCM can wake the app
// in killed state. OneSignal handles display — no action needed here.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Environment variables
  await dotenv.load(fileName: '.env');

  // 2. Stripe
  Stripe.publishableKey = AppConstants.stripePubKey;
  // await Stripe.instance.applySettings();

  // 3. Firebase — must come before FCM handler registration
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 4. Register FCM background handler immediately after Firebase.initializeApp()
  //    and before any other async gaps. Required for killed-state push delivery.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 5. Bootstrap the FCM token pipeline. Without getToken(), the device never
  //    registers with FCM and OneSignal has no delivery channel for background
  //    / killed-state pushes.
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  final fcmToken = await FirebaseMessaging.instance.getToken();
  debugPrint('[FCM] token: $fcmToken');

  // 6. Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // 7. Notification Service — creates Android channel + initialises OneSignal.
  //    Permission is NOT requested here; it happens inside
  //    loginAndWaitForSubscription() after the user signs in.
  await NotificationService.init(AppConstants.oneSignalAppId);

  // 8. Dependency injection
  await initDependencies();

  runApp(const EzeeWashApp());
}

class EzeeWashApp extends StatefulWidget {
  const EzeeWashApp({super.key});

  @override
  State<EzeeWashApp> createState() => _EzeeWashAppState();
}

class _EzeeWashAppState extends State<EzeeWashApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthCheckRequested());
    // createRouter() also calls NotificationService.setRouter() internally.
    _router = createRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider(
          create: (_) => sl<ServicesBloc>()..add(const ServicesLoadRequested()),
        ),
        BlocProvider(
          create: (_) => sl<StoresBloc>()..add(const StoresLoadRequested()),
        ),
        BlocProvider(create: (_) => sl<OrdersBloc>()),
        BlocProvider(create: (_) => sl<NotificationsBloc>()),
        BlocProvider(create: (_) => sl<ProfileBloc>()),
      ],
      child: _AuthReactiveLoader(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          routerConfig: _router,
        ),
      ),
    );
  }
}

// ─── Auth-Reactive Loader ──────────────────────────────────────────────────

class _AuthReactiveLoader extends StatefulWidget {
  final Widget child;
  const _AuthReactiveLoader({required this.child});

  @override
  State<_AuthReactiveLoader> createState() => _AuthReactiveLoaderState();
}

class _AuthReactiveLoaderState extends State<_AuthReactiveLoader> {
  bool _loaded = false;
  final Map<String, String> _prevStatuses = {};

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [

        // ── Auth state ─────────────────────────────────────────────────────
        BlocListener<AuthBloc, AuthState>(
          listener: (ctx, state) async {
            if (state is AuthAuthenticated) {
              final userId = state.user.id;

              // loginAndWaitForSubscription() does these steps in order:
              //   1. Request OS notification permission  ← MUST be first
              //   2. Call OneSignal.login(userId)
              //   3. Poll until optedIn == true (up to 10 s)
              //
              // We await the whole thing so the subscription is confirmed
              // active before we load orders/notifications. Any Supabase
              // DB insert after this point will find a valid subscription.
              await NotificationService.loginAndWaitForSubscription(userId);

              // Load user data — runs once per session.
              if (!_loaded) {
                _loaded = true;
                ctx.read<OrdersBloc>().add(const OrdersLoadRequested());
                ctx.read<NotificationsBloc>()
                    .add(const NotificationsLoadRequested());
                ctx.read<ProfileBloc>().add(const ProfileLoadRequested());
              }
            } else if (state is AuthUnauthenticated || state is AuthError) {
              // Always unlink — unconditional so logout before data loads
              // doesn't leave the device linked to the old user's external_id.
              _loaded = false;
              NotificationService.clearUserId();
            }
          },
        ),

        // ── Orders realtime (foreground status-change local notifications) ─
        // Background/killed-state pushes arrive through OneSignal natively.
        BlocListener<OrdersBloc, OrdersState>(
          listener: (ctx, state) {
            if (state is! OrdersLoaded) return;
            for (final order in state.orders) {
              final prev = _prevStatuses[order.id];
              final curr = order.status;
              if (prev != null && prev != curr) {
                NotificationService.showOrderUpdate(
                  orderNumber: order.orderNumber,
                  status: curr,
                  orderId: order.id,
                );
              }
              _prevStatuses[order.id] = curr;
            }
          },
        ),

      ],
      child: widget.child,
    );
  }
}