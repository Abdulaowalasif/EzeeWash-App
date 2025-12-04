import 'package:ezeewash/features/auth/screens/login_screen.dart';
import 'package:ezeewash/routes/routes_name.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/error/screen/error_screen.dart';


final GoRouter appRouter = GoRouter(
  initialLocation: RoutesName.login,
  routes: [
    // /// Initial Splash
    GoRoute(
      path: RoutesName.login,
      pageBuilder: (context, state) => _buildPage(const LoginScreen(), state),
    ),
    //
    // /// Onboarding
    // GoRoute(
    //   path: RoutesName.onboarding1,
    //   pageBuilder: (context, state) =>
    //       _buildPage(const OnboardingScreen1(), state),
    // ),
    // GoRoute(
    //   path: RoutesName.onboarding2,
    //   pageBuilder: (context, state) =>
    //       _buildPage(const OnboardingScreen2(), state),
    // ),
    // GoRoute(
    //   path: RoutesName.onboarding3,
    //   pageBuilder: (context, state) =>
    //       _buildPage(const OnboardingScreen3(), state),
    // ),
    // GoRoute(
    //   path: RoutesName.onboarding4,
    //   pageBuilder: (context, state) =>
    //       _buildPage(const OnboardingScreen4(), state),
    // ),
    //
    // /// Login
    // GoRoute(
    //   path: RoutesName.login,
    //   pageBuilder: (context, state) => _buildPage(const LoginScreen(), state),
    // ),
    //
    // /// SHELL ROUTE (Main Screen with Bottom Navigation)
    // StatefulShellRoute.indexedStack(
    //   builder: (context, state, navigationShell) =>
    //       MainScreen(navigationShell: navigationShell),
    //   branches: [
    //     /// HOME BRANCH
    //     StatefulShellBranch(
    //       routes: [
    //         GoRoute(
    //           path: RoutesName.home,
    //           pageBuilder: (context, state) =>
    //               _buildPage(const HomeScreens(), state),
    //           routes: [
    //             // GoRoute(
    //             //   path: RoutesName.details,
    //             //   pageBuilder: (context, state) =>
    //             //       _buildPage(const Details(), state),
    //             // ),
    //             // GoRoute(
    //             //   path: 'more',
    //             //   pageBuilder: (context, state) =>
    //             //       _buildPage(const More(), state),
    //             // ),
    //           ],
    //         ),
    //       ],
    //     ),
    //
    //     /// CALENDER BRANCH
    //     StatefulShellBranch(
    //       routes: [
    //         GoRoute(
    //           path: RoutesName.calender,
    //           pageBuilder: (context, state) =>
    //               _buildPage(const CalenderScreens(), state),
    //         ),
    //       ],
    //     ),
    //
    //     /// EXPLORE BRANCH
    //     StatefulShellBranch(
    //       routes: [
    //         GoRoute(
    //           path: RoutesName.explore,
    //           pageBuilder: (context, state) =>
    //               _buildPage(const ExploreScreens(), state),
    //         ),
    //       ],
    //     ),
    //
    //     /// PERKS BRANCH
    //     StatefulShellBranch(
    //       routes: [
    //         GoRoute(
    //           path: RoutesName.perks,
    //           pageBuilder: (context, state) =>
    //               _buildPage(const PerksScreens(), state),
    //         ),
    //       ],
    //     ),
    //
    //     /// ACCOUNT BRANCH
    //     StatefulShellBranch(
    //       routes: [
    //         GoRoute(
    //           path: RoutesName.account,
    //           pageBuilder: (context, state) =>
    //               _buildPage(const AccountScreens(), state),
    //           routes: [
    //             GoRoute(
    //               path: RoutesName.wellness,
    //               pageBuilder: (context, state) =>
    //                   _buildPage(const WellnessPrefScreen(), state),
    //             ),
    //             GoRoute(
    //               path: RoutesName.settings,
    //               pageBuilder: (context, state) =>
    //                   _buildPage(const SettingsScreen(), state),
    //             ),
    //             GoRoute(
    //               path: RoutesName.membership,
    //               pageBuilder: (context, state) =>
    //                   _buildPage(const MembershipScreen(), state),
    //             ),
    //           ],
    //         ),
    //       ],
    //     ),
    //   ],
    // ),
  ],

  /// Error Page
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