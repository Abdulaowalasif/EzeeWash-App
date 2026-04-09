import 'package:ezzewash/routes/app_router.dart';
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
import 'features/store/presentation/bloc/store_bloc.dart';

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
        BlocProvider(create: (_) => sl<ServicesBloc>()),
        BlocProvider(create: (_) => sl<StoresBloc>()),
        BlocProvider(create: (_) => sl<OrdersBloc>()),
        BlocProvider(create: (_) => sl<NotificationsBloc>()),
        BlocProvider(create: (_) => sl<ProfileBloc>()),
      ],
      child: AuthReactiveLoader(
        onLogout: _recreateRouter,
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemePrefs.notifier,
          builder: (context, currentMode, child) {
            // Determine if dark mode is active for the connectivity overlay
            final isDarkMode = currentMode == ThemeMode.dark ||
                (currentMode == ThemeMode.system &&
                    View.of(context).platformDispatcher.platformBrightness ==
                        Brightness.dark);

            return ConnectivityWrapper(
              isDarkMode: isDarkMode,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: AppConstants.appName,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: currentMode,
                routerConfig: _router,
              ),
            );
          },
        ),
      ),
    );
  }
}
