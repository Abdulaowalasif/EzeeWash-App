import 'package:ezeewash/features/orders/screens/place_order_screen.dart';
import 'package:ezeewash/features/profile/screens/settings/address_screen.dart';
import 'package:ezeewash/features/profile/screens/settings/chat_bot_screen.dart';
import 'package:ezeewash/features/profile/screens/settings/help_support_screen.dart';
import 'package:ezeewash/features/profile/screens/settings/terms_policy_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ezeewash/features/auth/screens/login_screen.dart';
import 'package:ezeewash/features/home/screens/home_screen.dart';
import 'package:ezeewash/features/services/screens/service_screen.dart';
import 'package:ezeewash/features/orders/screens/order_screen.dart';
import 'package:ezeewash/features/orders/screens/place_order_screen.dart';
import 'package:ezeewash/features/orders/screens/track_order_screen.dart';
import 'package:ezeewash/features/notification/screens/notification_screen.dart';
import 'package:ezeewash/features/profile/screens/profile_screen.dart';
import 'package:ezeewash/features/error/screen/error_screen.dart';

import 'package:ezeewash/main_screen.dart';
import 'package:ezeewash/routes/routes_name.dart';

import '../features/orders/screens/booking_confirmed_screen.dart';
import '../features/orders/screens/track_order_screen.dart';

/// Main App Router
final GoRouter appRouter = GoRouter(
  initialLocation: RoutesName.login,
  routes: [
    /// LOGIN ROUTE
    GoRoute(
      path: RoutesName.login,
      pageBuilder: (context, state) => _buildPage(const LoginScreen(), state),
    ),

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
              routes: [
                GoRoute(
                  path: RoutesName.trackOrders,
                  pageBuilder: (context, state) =>
                      _buildPage(TrackOrderScreen(), state),
                ),
                GoRoute(
                  path: RoutesName.placeOrders,
                  pageBuilder: (context, state) =>
                      _buildPage(const PlaceOrderScreen(), state),
                ),
                GoRoute(
                  path: RoutesName.confirmedOrders,
                  pageBuilder: (context, state) =>
                      _buildPage(const BookingConfirmedScreen(), state),
                ),
              ],
            ),
          ],
        ),

        /// ALERTS / NOTIFICATIONS BRANCH
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
              routes: [
                GoRoute(
                  path: RoutesName.address,
                  pageBuilder: (context, state) =>
                      _buildPage(AddressScreen(), state),
                ),
                GoRoute(
                  path: RoutesName.helpSupport,
                  pageBuilder: (context, state) =>
                      _buildPage(HelpSupportScreen(), state),
                ),
                GoRoute(
                  path: RoutesName.termsPolicy,
                  pageBuilder: (context, state) =>
                      _buildPage(TermsPolicyScreen(), state),
                ),
                GoRoute(
                  path: RoutesName.chatBot,
                  pageBuilder: (context, state) => _buildPage(ChatBotScreen(), state),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],

  /// GLOBAL ERROR PAGE
  errorPageBuilder: (context, state) =>
      _buildPage(ErrorScreen(error: state.error), state),
);

/// Transition builder for all pages
CustomTransitionPage _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      final tween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: Curves.easeInOut));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
