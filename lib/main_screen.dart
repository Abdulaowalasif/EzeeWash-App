import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (index) {
          final isSelected = navigationShell.currentIndex == index;

          final icons = [
            [Iconsax.home5, Iconsax.home], // filled , outline
            [Iconsax.heart5, Iconsax.heart],
            [Iconsax.truck_fast, Iconsax.truck_fast],
            [Iconsax.notification5, Iconsax.notification],
            [Iconsax.user4, Iconsax.user],
          ];

          final labels = ["Home", "Services", "Orders", "Alerts", "Profile"];

          return GestureDetector(
            onTap: () => _onTabTapped(index),
            child: SafeArea(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? icons[index][0] : icons[index][1],
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
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
