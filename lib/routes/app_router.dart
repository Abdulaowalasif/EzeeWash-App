// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection_container.dart';
import '../core/service/notification_service.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/notifications/presentation/screens/notification_screen.dart';
import '../features/orders/presentation/bloc/orders_bloc.dart';
import '../features/orders/presentation/screens/order_screen.dart';
import '../features/orders/presentation/screens/order_screen.dart' show ReorderParams;
import '../features/orders/presentation/screens/place_order_screen.dart';
import '../features/profile/presentation/presentation/profile_screen.dart';
import '../features/screens/address_screen.dart';
import '../features/screens/booking_confirmed_screen.dart';
import '../features/screens/chat_bot_screen.dart';
import '../features/screens/error_screen.dart';
import '../features/screens/help_support_screen.dart';
import '../features/screens/terms_policy_screen.dart';
import '../features/screens/track_order_screens.dart';
import '../features/services/presentation/screens/service_screen.dart';
import '../main_screen.dart';
import 'routes_name.dart';

GoRouter createRouter(AuthBloc authBloc) {
  final router = GoRouter(
    initialLocation: RoutesName.login,
    refreshListenable: _AuthNotifier(authBloc),

    redirect: (context, state) {
      final authState = authBloc.state;
      final isOnLogin = state.matchedLocation == RoutesName.login;

      // Do nothing while determining auth state (Native Splash is visible)
      if (authState is AuthLoading || authState is AuthInitial) return null;

      // Redirect to login if not authenticated
      if (authState is AuthUnauthenticated || authState is AuthError) {
        return isOnLogin ? null : RoutesName.login;
      }

      // Logic for authenticated users
      if (authState is AuthAuthenticated) {
        // 1. Check for pending notification deep links first
        final pending = NotificationService.consumePendingRoute();
        if (pending != null) return pending;

        // 2. If on login screen, move to main home
        if (isOnLogin) return RoutesName.main;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: RoutesName.login,
        pageBuilder: (c, s) => _fade(const LoginScreen(), s),
      ),

      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => MainScreen(navigationShell: shell),
        branches: [
          // HOME
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutesName.main,
              pageBuilder: (c, s) => _slide(const HomeScreen(), s),
            ),
          ]),

          // SERVICES
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutesName.services,
              pageBuilder: (c, s) => _slide(const ServiceScreen(), s),
            ),
          ]),

          // ORDERS
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutesName.orders,
              pageBuilder: (c, s) => _slide(const OrderScreen(), s),
              routes: [
                GoRoute(
                  path: RoutesName.placeOrders,
                  pageBuilder: (c, s) {
                    final extra = s.extra;
                    final screen = extra is ReorderParams
                        ? PlaceOrderScreen(reorderParams: extra)
                        : PlaceOrderScreen(
                      preSelectedServiceId: extra as String?,
                    );
                    return _slide(
                      BlocProvider(
                        create: (_) => sl<OrdersBloc>(),
                        child: screen,
                      ),
                      s,
                    );
                  },
                ),
                GoRoute(
                  path: RoutesName.trackOrders,
                  pageBuilder: (c, s) {
                    final orderId = s.extra as String?;
                    return _slide(TrackOrderScreen(orderId: orderId), s);
                  },
                ),
                GoRoute(
                  path: RoutesName.confirmedOrders,
                  pageBuilder: (c, s) {
                    final orderNumber = s.extra as String? ?? 'EZ000001';
                    return _slide(
                      BookingConfirmedScreen(orderNumber: orderNumber),
                      s,
                    );
                  },
                ),
              ],
            ),
          ]),

          // NOTIFICATIONS / ALERTS
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutesName.alerts,
              pageBuilder: (c, s) => _slide(const NotificationScreen(), s),
            ),
          ]),

          // PROFILE
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutesName.profile,
              pageBuilder: (c, s) => _slide(const ProfileScreen(), s),
              routes: [
                GoRoute(
                  path: RoutesName.address,
                  pageBuilder: (c, s) => _slide(const AddressScreen(), s),
                ),
                GoRoute(
                  path: RoutesName.helpSupport,
                  pageBuilder: (c, s) => _slide(const HelpSupportScreen(), s),
                ),
                GoRoute(
                  path: RoutesName.termsPolicy,
                  pageBuilder: (c, s) => _slide(const TermsPolicyScreen(), s),
                ),
                GoRoute(
                  path: RoutesName.chatBot,
                  pageBuilder: (c, s) => _slide(const ChatBotScreen(), s),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],

    errorPageBuilder: (c, s) => _fade(ErrorScreen(error: s.error), s),
  );

  // Link the service to the router for handling taps
  NotificationService.setRouter(router);

  return router;
}

CustomTransitionPage<void> _slide(Widget child, GoRouterState state) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut))
            .animate(animation),
        child: child,
      ),
    );

CustomTransitionPage<void> _fade(Widget child, GoRouterState state) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(AuthBloc authBloc) {
    authBloc.stream.listen((_) => notifyListeners());
  }
}