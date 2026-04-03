// lib/main.dart

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request required permissions on app launch
  await _requestAppPermissions();

  // 1. Load environment variables
  await dotenv.load(fileName: '.env');

  // 2. Stripe initialization
  Stripe.publishableKey = AppConstants.stripePubKey;

  // 3. Firebase initialization for notification transport
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 4. Supabase initialization
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // 5. Notification Service initialization
  await NotificationService.init(AppConstants.oneSignalAppId);

  // 6. Dependency injection setup
  await initDependencies();

  runApp(const EzeeWashApp());
}

// Helper function to request permissions using permission_handler
Future<void> _requestAppPermissions() async {
  await [
    Permission.location,
    Permission.notification,
  ].request();
}

class EzeeWashApp extends StatefulWidget {
  const EzeeWashApp({super.key});

  @override
  State<EzeeWashApp> createState() => _EzeeWashAppState();
}

class _EzeeWashAppState extends State<EzeeWashApp> {
  late final AuthBloc _authBloc;
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthCheckRequested());
    _router = createRouter(_authBloc);
  }

  // FIX: Recreating the GoRouter instance completely wipes out the routing state,
  // including the cached StatefulShellRoute branches. This completely fixes the
  // infamous "blank/grey screen after logout and relogin" bug in GoRouter.
  void _recreateRouter() {
    setState(() {
      _router = createRouter(_authBloc);
    });
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
        onLogout: _recreateRouter, // Pass the reset callback here
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
  final VoidCallback onLogout;

  const _AuthReactiveLoader({
    required this.child,
    required this.onLogout,
  });

  @override
  State<_AuthReactiveLoader> createState() => _AuthReactiveLoaderState();
}

class _AuthReactiveLoaderState extends State<_AuthReactiveLoader> {
  // Tracks whether we've already dispatched data-load events for the
  // current authenticated session. Reset to false on logout so that
  // a subsequent login always re-loads fresh data (fixes grey screens
  // after logout → re-login on first install and subsequent sessions).
  bool _loaded = false;
  String? _lastLoadedUserId;
  final Map<String, String> _prevStatuses = {};

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (ctx, state) {
            if (state is AuthAuthenticated) {
              final userId = state.user.id;
              unawaited(NotificationService.loginAndWaitForSubscription(userId));

              // Dispatch load events if:
              //   1. Never loaded yet (_loaded == false), OR
              //   2. A different user logged in (e.g. after logout → re-login)
              if (!_loaded || _lastLoadedUserId != userId) {
                _loaded = true;
                _lastLoadedUserId = userId;
                ctx.read<OrdersBloc>().add(const OrdersLoadRequested());
                ctx.read<NotificationsBloc>().add(const NotificationsLoadRequested());
                ctx.read<ProfileBloc>().add(const ProfileLoadRequested());
              }
            } else if (state is AuthUnauthenticated || state is AuthError) {
              // If we were previously logged in and just logged out, trigger router recreation
              if (_loaded && state is AuthUnauthenticated) {
                widget.onLogout();
              }

              // Reset so the next login always triggers a fresh data load.
              _loaded = false;
              _lastLoadedUserId = null;
              NotificationService.clearUserId();
            }
          },
        ),
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