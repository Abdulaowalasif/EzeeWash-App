import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  void _onTabTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index != navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _buildCustomNavBar(context),
    );
  }

  Widget _buildCustomNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = const Color(0xFF1D4BC7); // Your main blue
    final secondaryColor = const Color(0xFF2F2E98);

    final backgroundColor =
    isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final unselectedColor =
    isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (index) {
          final isSelected = navigationShell.currentIndex == index;

          final icons = [
            [Iconsax.home5, Iconsax.home],
            [Iconsax.heart5, Iconsax.heart],
            [Iconsax.truck_fast, Iconsax.truck_fast],
            [Iconsax.notification5, Iconsax.notification],
            [Iconsax.user4, Iconsax.user],
          ];

          final labels = ["Home", "Services", "Orders", "Alerts", "Profile"];

          return GestureDetector(
            onTap: () => _onTabTapped(index),
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected
                          ? icons[index][0]
                          : icons[index][1],
                      size: 22,
                      color: isSelected
                          ? Colors.white
                          : unselectedColor,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alexandria(
                        fontSize: 12,
                        letterSpacing: 0.3,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : unselectedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
