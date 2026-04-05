// lib/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import 'core/constants/app_color.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';

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
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) =>
      (prev is AuthAuthenticated) != (curr is AuthAuthenticated),
      builder: (context, authState) {
        final isAuthenticated = authState is AuthAuthenticated;

        return Scaffold(
          body: Stack(
            children: [
              navigationShell,
              if (!isAuthenticated)
                Positioned.fill(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
            ],
          ),
          bottomNavigationBar: isAuthenticated
              ? _BottomNav(
            currentIndex: navigationShell.currentIndex,
            onTap: _onTap,
          )
              : null,
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

    const icons = [
      Iconsax.heart,
      Iconsax.truck_fast,
      Iconsax.home,
      Icons.smart_toy_outlined,
      Iconsax.notification,
    ];

    final labels = ['Services', 'Orders', 'Home', 'Bot', 'Alerts'];

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
                    i == 4
                        ? BlocBuilder<NotificationsBloc, NotificationsState>(
                      builder: (context, state) {
                        final unread = state is NotificationsLoaded
                            ? state.unreadCount
                            : 0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              icons[i],
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
                      icons[i],
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