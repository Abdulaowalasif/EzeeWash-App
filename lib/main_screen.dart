// lib/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'core/constants/app_color.dart';
import 'core/theme/app_text_styles.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'routes/routes_name.dart';

class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  void _onTap(int index) {
    final isSameBranch = index == widget.navigationShell.currentIndex;

    // Check if the Orders branch is currently showing a sub-route
    // (PlaceOrderScreen or BookingConfirmedScreen).
    // When it is, always reset the Orders branch back to the base OrderScreen —
    // whether the user taps Orders directly or switches to another tab first.
    // All other tab switches preserve branch state normally.
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final ordersIsInSubRoute =
        currentLocation.startsWith(RoutesName.orders) &&
            currentLocation.length > RoutesName.orders.length;

    final shouldReset = isSameBranch || ordersIsInSubRoute;

    widget.navigationShell.goBranch(index, initialLocation: shouldReset);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) =>
      (prev is AuthAuthenticated) != (curr is AuthAuthenticated),
      builder: (context, authState) {
        return Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: authState is AuthAuthenticated
              ? _BottomNav(
            currentIndex: widget.navigationShell.currentIndex,
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
    const icons = [Iconsax.heart, Iconsax.truck_fast, Iconsax.home, Icons.smart_toy_outlined, Iconsax.notification];
    final labels = ['Services', 'Orders', 'Home', 'Bot', 'Alerts'];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 5;
              return Stack(
                children: [
                  // --- PILL DESIGN ---
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: currentIndex * tabWidth,
                    top: 6,
                    bottom: 10,
                    width: tabWidth,
                    child: Center(
                      child: Container(
                        width: tabWidth * 0.85,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradient,
                          borderRadius: BorderRadius.circular(16),
                          
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      final isSelected = currentIndex == i;
                      final contentColor = isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onTap(i),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              i == 4
                                  ? _NotificationBadge(icon: icons[i], color: contentColor)
                                  : Icon(icons[i], size: 22, color: contentColor),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: AppTextStyles.navLabel(contentColor, selected: isSelected),
                                child: Text(labels[i]),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _NotificationBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final unread = state is NotificationsLoaded ? state.unreadCount : 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 22, color: color),
            if (unread > 0)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}