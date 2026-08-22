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
import '../../features/promos/presentation/bloc/promo_bloc.dart';
import '../../features/promos/presentation/bloc/promo_event.dart';
import '../../features/services/presentation/bloc/service_bloc.dart';
import '../../features/services/presentation/bloc/service_event.dart';
import '../../features/store/presentation/bloc/store_bloc.dart';
import '../../features/store/presentation/bloc/stores_event.dart';
import '../service/notification_service.dart';

class AuthReactiveLoader extends StatefulWidget {
  final Widget child;
  final VoidCallback onLogout;

  const AuthReactiveLoader({
    super.key,
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _triggerLoad(authState.user.id);
      }
    });
  }

  void _triggerLoad(String userId) {
    unawaited(NotificationService.loginAndWaitForSubscription(userId));

    if (!_loaded || _lastLoadedUserId != userId) {
      _loaded = true;
      _lastLoadedUserId = userId;

      context.read<OrdersBloc>().resetSubscription();
      context.read<NotificationsBloc>().resetSubscription();

      context.read<ServicesBloc>().add(const ServicesLoadRequested());
      context.read<StoresBloc>().add(const StoresLoadRequested());
      context.read<OrdersBloc>().add(const OrdersLoadRequested());
      context.read<NotificationsBloc>().add(const NotificationsLoadRequested());
      context.read<ProfileBloc>().add(const ProfileLoadRequested());
      context.read<PromoBloc>().add(const WatchPromosStarted());
    }
  }

  void _handleUnauthenticated() {
    if (_loaded) {
      widget.onLogout();
      
      // Clear all user-specific data from BLoCs
      context.read<OrdersBloc>().add(const OrdersClearData());
      context.read<NotificationsBloc>().add(const NotificationsClearData());
      context.read<ProfileBloc>().add(const ProfileClearData());
    }
    _loaded = false;
    _lastLoadedUserId = null;
    NotificationService.clearUserId();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (ctx, state) {
            if (state is AuthAuthenticated) {
              _triggerLoad(state.user.id);
            } else if (state is AuthUnauthenticated) {
              _handleUnauthenticated();
            }
          },
        ),
      ],
      child: widget.child,
    );
  }
}
