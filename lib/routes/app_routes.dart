import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ezeewash/routes/routes_name.dart';
import 'package:ezeewash/main_screen.dart';

import 'package:ezeewash/features/home/screens/home_screen.dart';
import 'package:ezeewash/features/services/screens/service_screen.dart';
import 'package:ezeewash/features/orders/screens/order_screen.dart';
import 'package:ezeewash/features/notification/screens/notification_screen.dart';
import 'package:ezeewash/features/profile/screens/profile_screen.dart';
import 'package:ezeewash/features/error/screen/error_screen.dart';

/// Main App Router
final GoRouter appRouter = GoRouter(
  initialLocation: RoutesName.main,
  routes: [

    /// SHELL ROUTE (Bottom Navigation with Indexed Stack)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainScreen(navigationShell: navigationShell),
      branches: [

        /// HOME BRANCH
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutesName.main,
              pageBuilder: (context, state) =>
                  _buildPage(const HomeScreen(), state),
            ),
          ],
        ),

        /// SERVICES BRANCH
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutesName.services,
              pageBuilder: (context, state) =>
                  _buildPage(const ServiceScreen(), state),
            ),
          ],
        ),

        /// ORDERS BRANCH
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutesName.orders,
              pageBuilder: (context, state) =>
                  _buildPage(const OrderScreen(), state),
            ),
          ],
        ),

        /// ALERT / NOTIFICATION BRANCH
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutesName.alerts,
              pageBuilder: (context, state) =>
                  _buildPage(const NotificationScreen(), state),
            ),
          ],
        ),

        /// PROFILE BRANCH
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutesName.profile,
              pageBuilder: (context, state) =>
                  _buildPage(const ProfileScreen(), state),
            ),
          ],
        ),
      ],
    ),
  ],

  /// Global Error Page
  errorPageBuilder: (context, state) =>
      _buildPage(ErrorScreen(error: state.error), state),
);


/// Global Custom Transition
CustomTransitionPage _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;

      final tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: Curves.easeInOut));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
