// lib/routes/app_router.dart

import 'package:ezzewash/features/auth/presentation/screens/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection_container.dart';
import '../core/screens/error_screen.dart';
import '../core/service/notification_service.dart';
import '../core/utils/onboarding_prefs.dart'; // ← NEW
import '../features/address/presentation/screens/address_screen.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/notifications/presentation/screens/notification_screen.dart';
import '../features/onboarding/presentation/screen/onboarding_screen.dart';
import '../features/orders/presentation/bloc/orders_bloc.dart';
import '../features/orders/presentation/screens/booking_confirmed_screen.dart';
import '../features/orders/presentation/screens/order_screen.dart';
import '../features/orders/presentation/screens/order_screen.dart'
    show ReorderParams;
import '../features/orders/presentation/screens/place_order_screen.dart';
import '../features/orders/presentation/screens/track_order_screen.dart';
import '../features/profile/presentation/screens/chat_bot_screen.dart';
import '../features/profile/presentation/screens/help_support_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';
import '../features/profile/presentation/screens/terms_policy_screen.dart';
import '../features/services/presentation/screens/service_screen.dart';
import '../main_screen.dart';
import 'routes_name.dart';

GoRouter createRouter(AuthBloc authBloc) {
  final router = GoRouter(
    initialLocation: RoutesName.login,
    redirect: (context, state) async {
      final authState = authBloc.state;
      final location = state.matchedLocation;

      final isOnboarding = location == RoutesName.onboarding;
      final isLogin = location == RoutesName.login;

      // ── Still loading auth — hold on login to avoid blank screen ──────────
      // NOTE: GoRouter's refreshListenable no longer fires on AuthLoading /
      // AuthInitial, so this branch is only hit on cold-start before the first
      // AuthCheckRequested completes. It is kept as a safety net.
      if (authState is AuthInitial || authState is AuthLoading) {
        return isLogin ? null : RoutesName.login;
      }

      // ── Authenticated ─────────────────────────────────────────────────────
      if (authState is AuthAuthenticated) {
        final pendingRoute = NotificationService.consumePendingRoute();
        if (pendingRoute != null) return pendingRoute;
        if (isLogin || isOnboarding) return RoutesName.home;
        return null;
      }

      // ── Unauthenticated ───────────────────────────────────────────────────
      // If the user is on the onboarding screen, let them stay.
      if (isOnboarding) return null;

      // If the user hasn't seen onboarding yet, send them there first.
      // OnboardingPrefs caches the value in-memory (and markOnboardingSeen()
      // updates the cache immediately), so this is safe to call on every redirect.
      final seen = await OnboardingPrefs.hasSeenOnboarding();
      if (!seen) return RoutesName.onboarding;

      // Otherwise guard all non-login routes behind login.
      if (!isLogin) return RoutesName.login;
      return null;
    },
    refreshListenable: _AuthStateListenable(authBloc),

    routes: [
      // ── Onboarding (unauthenticated, shown once) ─────────────────────────
      GoRoute(
        path: RoutesName.onboarding,
        pageBuilder: (c, s) => _fade(const OnboardingScreen(), s),
      ),

      // ── Login ─────────────────────────────────────────────────────────────
      GoRoute(
        path: RoutesName.login,
        pageBuilder: (c, s) => _fade(const LoginScreen(), s),
      ),

      // ── Main shell (authenticated) ────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => MainScreen(navigationShell: shell),
        branches: [
          // services
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesName.services,
                pageBuilder: (c, s) => _slide(const ServiceScreen(), s),
              ),
            ],
          ),

          // orders
          StatefulShellBranch(
            routes: [
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
                        BlocProvider.value(
                          value: c.read<OrdersBloc>(),
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
            ],
          ),

          // home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesName.home,
                pageBuilder: (c, s) => _slide(const HomeScreen(), s),
                routes: [
                  GoRoute(
                    path: RoutesName.changePassword,
                    pageBuilder: (c, s) =>
                        _slide(const ChangePasswordScreen(), s),
                  ),
                  GoRoute(
                    path: RoutesName.address,
                    pageBuilder: (c, s) => _slide(const AddressScreen(), s),
                  ),
                  GoRoute(
                    path: RoutesName.helpSupport,
                    pageBuilder: (c, s) =>
                        _slide(const HelpSupportScreen(), s),
                  ),
                  GoRoute(
                    path: RoutesName.termsPolicy,
                    pageBuilder: (c, s) =>
                        _slide(const TermsPolicyScreen(), s),
                  ),
                  GoRoute(
                    path: RoutesName.settings,
                    pageBuilder: (c, s) => _slide(const SettingsScreen(), s),
                  ),
                ],
              ),
            ],
          ),

          // chat bot
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesName.chatBot,
                pageBuilder: (c, s) => _slide(const ChatBotScreen(), s),
              ),
            ],
          ),

          // notifications
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesName.alerts,
                pageBuilder: (c, s) =>
                    _slide(const NotificationScreen(), s),
              ),
            ],
          ),
        ],
      ),
    ],

    errorPageBuilder: (c, s) => _fade(ErrorScreen(error: s.error), s),
  );

  NotificationService.setRouter(router);
  return router;
}

// ── Bridges AuthBloc state changes into GoRouter's refresh mechanism ─────────
//
// FIX: Only notify GoRouter on *terminal* auth states — not on AuthLoading.
//
// Previously, notifyListeners() was called on every state including AuthLoading.
// GoRouter reacts by re-running redirect(), which returns null (stay on login)
// while loading, causing the login screen widget tree to be rebuilt from scratch.
// That rebuild kills the BlocConsumer listener before it can set _loading = true,
// so the button spinner never appears.
//
// By skipping AuthLoading (and AuthInitial) we let the login screen stay alive
// and handle those transient states itself via its own BlocConsumer listener.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(AuthBloc bloc) {
    bloc.stream.listen((state) {
      if (state is AuthLoading || state is AuthInitial) return;
      notifyListeners();
    });
  }
}

CustomTransitionPage<void> _slide(Widget child, GoRouterState state) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
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