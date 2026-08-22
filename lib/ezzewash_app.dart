// lib/ezzewash_app.dart
import 'package:ezzewash/features/promos/presentation/bloc/promo_bloc.dart';
import 'package:ezzewash/routes/app_router.dart';
import 'package:ezzewash/routes/routes_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/theme_prefs.dart';
import 'core/widgets/auth_reactive_loader.dart';
import 'core/widgets/connectivity_wrapper.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'features/orders/presentation/bloc/orders_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/services/presentation/bloc/service_bloc.dart';
import 'features/services/presentation/bloc/service_event.dart'; // ADDED
import 'features/store/presentation/bloc/store_bloc.dart';
import 'features/store/presentation/bloc/stores_event.dart'; // ADDED
import 'features/promos/presentation/bloc/promo_event.dart'; // ADDED
import 'features/orders/presentation/bloc/order_event.dart';
import 'features/profile/presentation/bloc/profile_event.dart';

class EzzeWashApp extends StatefulWidget {
  const EzzeWashApp({super.key});

  @override
  State<EzzeWashApp> createState() => _EzzeWashAppState();
}

class _EzzeWashAppState extends State<EzzeWashApp> {
  late final AuthBloc _authBloc;
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthCheckRequested());
    _router = createRouter(_authBloc);
  }

  void _handleLogout() {
    setState(() {
      _router = createRouter(_authBloc, initialLocation: RoutesName.login);
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
        // FIX: Dispatch load events immediately on creation
        BlocProvider(
          create: (_) => sl<ServicesBloc>()..add(const ServicesLoadRequested()),
        ),
        BlocProvider(
          create: (_) => sl<StoresBloc>()..add(const StoresLoadRequested()),
        ),
        BlocProvider(
          create: (_) => sl<OrdersBloc>()..add(const OrdersLoadRequested()),
        ),
        BlocProvider(
          create: (_) =>
              sl<NotificationsBloc>()..add(const NotificationsLoadRequested()),
        ),
        BlocProvider(
          create: (_) => sl<ProfileBloc>()..add(const ProfileLoadRequested()),
        ),
        BlocProvider(
          create: (_) => sl<PromoBloc>()..add(const WatchPromosStarted()),
        ),
      ],
      child: AuthReactiveLoader(
        onLogout: _handleLogout,
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemePrefs.notifier,
          builder: (context, currentMode, child) {
            final isDarkMode =
                currentMode == ThemeMode.dark ||
                (currentMode == ThemeMode.system &&
                    View.of(context).platformDispatcher.platformBrightness ==
                        Brightness.dark);

            return ConnectivityWrapper(
              isDarkMode: isDarkMode,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: MaterialApp.router(
                  key: ValueKey(_router),
                  debugShowCheckedModeBanner: false,
                  title: AppConstants.appName,
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  themeMode: currentMode,
                  routerConfig: _router,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
