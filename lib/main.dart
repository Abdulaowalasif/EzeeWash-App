// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_event.dart';
import 'features/orders/presentation/bloc/order_event.dart';
import 'features/orders/presentation/bloc/orders_bloc.dart';
import 'features/orders/presentation/bloc/orders_state.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/profile/presentation/bloc/profile_event.dart';
import 'features/services/presentation/bloc/service_bloc.dart';
import 'features/services/presentation/bloc/service_bloc.dart';
import 'features/services/presentation/bloc/service_event.dart';
import 'features/store/presentation/bloc/store_bloc.dart';
import 'features/store/presentation/bloc/stores_event.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
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
        // Public data — load immediately
        BlocProvider(
          create: (_) => sl<ServicesBloc>()..add(const ServicesLoadRequested()),
        ),
        BlocProvider(
          create: (_) => sl<StoresBloc>()..add(const StoresLoadRequested()),
        ),
        // Auth-gated — loaded reactively after login
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

/// Fires auth-gated bloc loads exactly once after login,
/// and resets the loaded flag on logout.
class _AuthReactiveLoader extends StatefulWidget {
  final Widget child;
  const _AuthReactiveLoader({required this.child});
  @override
  State<_AuthReactiveLoader> createState() => _AuthReactiveLoaderState();
}

class _AuthReactiveLoaderState extends State<_AuthReactiveLoader> {
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated && !_loaded) {
          _loaded = true;
          ctx.read<OrdersBloc>().add(const OrdersLoadRequested());
          ctx.read<NotificationsBloc>().add(const NotificationsLoadRequested());
          ctx.read<ProfileBloc>().add(const ProfileLoadRequested());
        } else if (state is AuthUnauthenticated || state is AuthError) {
          _loaded = false;
        }
      },
      child: widget.child,
    );
  }
}