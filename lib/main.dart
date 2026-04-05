// lib/main.dart

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
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
import 'core/utils/theme_prefs.dart';
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

  // ─── Cap the Flutter image cache to avoid unbounded memory growth ──────────
  // Default is 1000 images / 100 MB — too large for a mobile laundry app.
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

  await dotenv.load(fileName: '.env');

  // ─── Load Saved Theme on App Start ─────────────────────────────────────────
  await ThemePrefs.load();

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
        // Services and stores are public/static data — kept alive as
        // singletons (see injection_container) so _allServices is preserved
        // across screen navigations. Loaded after auth in _AuthReactiveLoader.
        BlocProvider(create: (_) => sl<ServicesBloc>()),
        BlocProvider(create: (_) => sl<StoresBloc>()),
        BlocProvider(create: (_) => sl<OrdersBloc>()),
        BlocProvider(create: (_) => sl<NotificationsBloc>()),
        BlocProvider(create: (_) => sl<ProfileBloc>()),
      ],
      child: _AuthReactiveLoader(
        onLogout: _recreateRouter,
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemePrefs.notifier,
          builder: (context, currentMode, child) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: AppConstants.appName,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: currentMode,
              routerConfig: _router,
            );
          },
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

              if (!_loaded || _lastLoadedUserId != userId) {
                _loaded = true;
                _lastLoadedUserId = userId;

                ctx.read<OrdersBloc>().resetSubscription();
                ctx.read<NotificationsBloc>().resetSubscription();

                ctx.read<ServicesBloc>().add(const ServicesLoadRequested());
                ctx.read<StoresBloc>().add(const StoresLoadRequested());
                ctx.read<OrdersBloc>().add(const OrdersLoadRequested());
                ctx.read<NotificationsBloc>().add(const NotificationsLoadRequested());
                ctx.read<ProfileBloc>().add(const ProfileLoadRequested());
              }
            } else if (state is AuthUnauthenticated || state is AuthError) {
              if (_loaded && state is AuthUnauthenticated) {
                widget.onLogout();
              }

              _loaded = false;
              _lastLoadedUserId = null;
              _prevStatuses.clear();
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