// lib/routes/app_router.dart

import 'package:ezzewash/features/auth/presentation/screens/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection_container.dart';
import '../core/screens/error_screen.dart';
import '../core/service/notification_service.dart';
import '../core/utils/onboarding_prefs.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/notifications/presentation/screens/notification_screen.dart';
import '../features/onboarding/presentation/screen/onboarding_screen.dart';
import '../features/orders/presentation/bloc/orders_bloc.dart';
import '../features/orders/presentation/bloc/checkout_cubit.dart';
import '../features/orders/presentation/models/reorder_params.dart';
import '../features/orders/presentation/screens/booking_confirmed_screen.dart';
import '../features/orders/presentation/screens/order_screen.dart';
import '../features/orders/presentation/screens/place_order_screen.dart';
import '../features/orders/presentation/screens/track_order_screen.dart';
import '../features/profile/presentation/presentation/chat_bot_screen.dart';
import '../features/profile/presentation/presentation/help_support_screen.dart';
import '../features/profile/presentation/presentation/settings_screen.dart';
import '../features/profile/presentation/presentation/terms_policy_screen.dart';
import '../features/services/presentation/screens/service_screen.dart';
import '../main_screen.dart';
import '../main_screen.dart';
import 'routes_name.dart';
import '../features/splash/splash_screen.dart';

GoRouter createRouter(AuthBloc authBloc, {String initialLocation = RoutesName.splash}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) async {
      final authState = authBloc.state;
      final location = state.matchedLocation;

      final isSplash = location == RoutesName.splash;
      final isOnboarding = location == RoutesName.onboarding;
      final isLogin = location == RoutesName.login;

      if (isSplash) return null;

      if (authState is AuthInitial || authState is AuthLoading) {
        return isLogin ? null : RoutesName.login;
      }

      if (authState is AuthError) {
        return null;
      }

      if (authState is AuthAuthenticated) {
        final pendingRoute = NotificationService.consumePendingRoute();
        if (pendingRoute != null) return pendingRoute;
        if (isLogin || isOnboarding) return RoutesName.home;
        return null;
      }

      if (isOnboarding) return null;

      final seen = await OnboardingPrefs.hasSeenOnboarding();
      if (!seen) return RoutesName.onboarding;

      if (!isLogin) return RoutesName.login;
      return null;
    },
    refreshListenable: _AuthStateListenable(authBloc),

    routes: [
      GoRoute(
        path: RoutesName.splash,
        pageBuilder: (c, s) => _fade(const SplashScreen(), s),
      ),
      GoRoute(
        path: RoutesName.onboarding,
        pageBuilder: (c, s) => _fade(const OnboardingScreen(), s),
      ),
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
                // NoTransitionPage: branch switching is instant — the
                // bottom nav pill animation is the only motion needed.
                pageBuilder: (c, s) =>
                    const NoTransitionPage(child: ServiceScreen()),
              ),
            ],
          ),

          // orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesName.orders,
                pageBuilder: (c, s) =>
                    const NoTransitionPage(child: OrderScreen()),
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
                        MultiBlocProvider(
                          providers: [
                            BlocProvider.value(value: c.read<OrdersBloc>()),
                            BlocProvider(create: (_) => sl<CheckoutCubit>()),
                          ],
                          child: screen,
                        ),
                        s,
                      );
                    },
                  ),
                  GoRoute(
                    path: RoutesName.trackOrders,
                    pageBuilder: (c, s) {
                      final orderId =
                          s.extra as String? ?? s.uri.queryParameters['id'];
                      return _slide(TrackOrderScreen(orderId: orderId), s);
                    },
                  ),
                  GoRoute(
                    path: RoutesName.confirmedOrders,
                    pageBuilder: (c, s) {
                      final extraMap = s.extra as Map<String, dynamic>? ?? {};
                      final orderNumber =
                          extraMap['orderNumber'] as String? ?? 'EZ000001';
                      final orderId = extraMap['orderId'] as String? ?? '';
                      return _slide(
                        BookingConfirmedScreen(
                          orderNumber: orderNumber,
                          orderId: orderId,
                        ),
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
                pageBuilder: (c, s) =>
                    const NoTransitionPage(child: HomeScreen()),
                routes: [
                  GoRoute(
                    path: RoutesName.changePassword,
                    pageBuilder: (c, s) =>
                        _slide(const ChangePasswordScreen(), s),
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
                    path: RoutesName.settings,
                    pageBuilder: (c, s) {
                      final autoStartUpdate = s.extra as bool? ?? false;
                      return _slide(
                        SettingsScreen(autoStartUpdate: autoStartUpdate),
                        s,
                      );
                    },
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
                pageBuilder: (c, s) =>
                    const NoTransitionPage(child: ChatBotScreen()),
              ),
            ],
          ),

          // notifications
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesName.alerts,
                pageBuilder: (c, s) {
                  final tab = s.uri.queryParameters['tab'];
                  return NoTransitionPage(
                    child: NotificationScreen(initialTab: tab),
                  );
                },
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

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(AuthBloc bloc) {
    bloc.stream.listen((state) {
      if (state is AuthLoading || state is AuthInitial) return;
      notifyListeners();
    });
  }
}

/// A highly polished sliding transition for nested sub-routes.
CustomTransitionPage<void> _slide(Widget child, GoRouterState state) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 380),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutQuart,
                  reverseCurve: Curves.easeInQuart,
                ),
              ),
          child: child,
        );
      },
    );

CustomTransitionPage<void> _fade(Widget child, GoRouterState state) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 450),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
