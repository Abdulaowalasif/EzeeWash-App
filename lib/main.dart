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

  await _requestAppPermissions();

  await dotenv.load(fileName: '.env');

  Stripe.publishableKey = AppConstants.stripePubKey;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await NotificationService.init(AppConstants.oneSignalAppId);

  await initDependencies();

  runApp(const EzeeWashApp());
}

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
        onLogout: _recreateRouter,
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

              // FIX: Trigger data load whenever a new user is authenticated.
              //
              // This fires for ALL login methods — email/password AND Google OAuth.
              //
              // Email/password: AuthAuthenticated is emitted directly from
              //   _onSignIn in AuthBloc (synchronous path).
              //
              // Google OAuth: AuthAuthenticated arrives via the authStateChanges
              //   stream inside AuthBloc (async path — browser redirect). Because
              //   _suppressStream is NOT set for Google, _onStreamEvent fires and
              //   emits AuthAuthenticated, which this listener catches.
              //   Previously, Google auth appeared to "work" (the user reached the
              //   home screen) but the orders never loaded because the stream
              //   emission was not reliably triggering this block, or because
              //   _loaded was already true from a previous session check.
              //
              // The _lastLoadedUserId guard ensures we don't spam re-loads on
              // token refresh events (which also fire onAuthStateChange).
              if (!_loaded || _lastLoadedUserId != userId) {
                _loaded = true;
                _lastLoadedUserId = userId;

                // Reset the realtime subscription so it re-subscribes with
                // the correct userId. This matters after logout → re-login
                // where the subscription might still hold the old user's filter.
                ctx.read<OrdersBloc>().resetSubscription();

                ctx.read<OrdersBloc>().add(const OrdersLoadRequested());
                ctx.read<NotificationsBloc>().add(const NotificationsLoadRequested());
                ctx.read<ProfileBloc>().add(const ProfileLoadRequested());
              }
            } else if (state is AuthUnauthenticated || state is AuthError) {
              if (_loaded && state is AuthUnauthenticated) {
                widget.onLogout();
              }

              // Reset flags so the NEXT login (including Google OAuth on the
              // same app session) always triggers a fresh data load.
              _loaded = false;
              _lastLoadedUserId = null;
              NotificationService.clearUserId();
            }
            // AuthLoading is intentionally ignored here:
            // - For email/password, _suppressStream is true so the stream won't
            //   interfere; AuthAuthenticated or AuthError will follow directly.
            // - For Google OAuth, AuthLoading is the state while the browser is
            //   open. We must NOT reset _loaded here — that would break the
            //   _lastLoadedUserId guard when AuthAuthenticated arrives. We also
            //   must NOT pre-dispatch any load events — no session exists yet.
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