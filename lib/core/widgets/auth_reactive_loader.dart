// ─── Auth-Reactive Loader ──────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/orders/presentation/bloc/order_event.dart';
import '../../features/orders/presentation/bloc/orders_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';
import '../../features/services/presentation/bloc/service_bloc.dart';
import '../../features/services/presentation/bloc/service_event.dart';
import '../../features/store/presentation/bloc/store_bloc.dart';
import '../../features/store/presentation/bloc/stores_event.dart';
import '../service/notification_service.dart';

class AuthReactiveLoader extends StatefulWidget {
  final Widget child;
  final VoidCallback onLogout;

  const AuthReactiveLoader({super.key, 
    required this.child,
    required this.onLogout,
  });

  @override
  State<AuthReactiveLoader> createState() => AuthReactiveLoaderState();
}

class AuthReactiveLoaderState extends State<AuthReactiveLoader> {
  bool _loaded = false;
  String? _lastLoadedUserId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (ctx, state) {
            if (state is AuthAuthenticated) {
              final userId = state.user.id;
              unawaited(
                  NotificationService.loginAndWaitForSubscription(userId));

              if (!_loaded || _lastLoadedUserId != userId) {
                _loaded = true;
                _lastLoadedUserId = userId;

                ctx.read<OrdersBloc>().resetSubscription();
                ctx.read<NotificationsBloc>().resetSubscription();

                ctx.read<ServicesBloc>().add(const ServicesLoadRequested());
                ctx.read<StoresBloc>().add(const StoresLoadRequested());
                ctx.read<OrdersBloc>().add(const OrdersLoadRequested());
                ctx.read<NotificationsBloc>()
                    .add(const NotificationsLoadRequested());
                ctx.read<ProfileBloc>().add(const ProfileLoadRequested());
              }
            } else if (state is AuthUnauthenticated || state is AuthError) {
              if (_loaded && state is AuthUnauthenticated) {
                widget.onLogout();
              }

              _loaded = false;
              _lastLoadedUserId = null;
              NotificationService.clearUserId();
            }
          },
        ),
      ],
      child: widget.child,
    );
  }
}