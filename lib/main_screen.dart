// lib/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import 'core/constants/app_color.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_state.dart';

class MainScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index != navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // When the user logs out, AuthUnauthenticated fires and GoRouter
    // schedules a redirect to /login. During the 280ms slide transition
    // the shell is still in the tree and renders a black frame.
    // We intercept that with a BlocBuilder that shows a blank scaffold
    // the instant we're no longer authenticated.
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) =>
      (prev is AuthAuthenticated) != (curr is AuthAuthenticated),
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          // GoRouter is about to redirect to /login — show a blank
          // background-coloured screen instead of a black flash.
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          );
        }
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: _BottomNav(
            currentIndex: navigationShell.currentIndex,
            onTap: _onTap,
          ),
        );
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final icons = [
      [Iconsax.home5, Iconsax.home],
      [Iconsax.heart5, Iconsax.heart],
      [Iconsax.truck_fast, Iconsax.truck_fast],
      [Iconsax.notification5, Iconsax.notification],
      [Iconsax.user4, Iconsax.user],
    ];
    final labels = ['Home', 'Services', 'Orders', 'Alerts', 'Profile'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (i) {
            final isSelected = currentIndex == i;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.gradient : null,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge on alerts icon
                    i == 3
                        ? BlocBuilder<NotificationsBloc, NotificationsState>(
                      builder: (context, state) {
                        final unread = state is NotificationsLoaded
                            ? state.unreadCount
                            : 0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isSelected
                                  ? icons[i][0]
                                  : icons[i][1],
                              size: 22,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600),
                            ),
                            if (unread > 0)
                              Positioned(
                                top: -4,
                                right: -6,
                                child: Container(
                                  padding:
                                  const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unread > 9 ? '9+' : '$unread',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    )
                        : Icon(
                      isSelected ? icons[i][0] : icons[i][1],
                      size: 22,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: GoogleFonts.alexandria(
                        fontSize: 11,
                        letterSpacing: 0.2,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}