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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 10,
        currentIndex: navigationShell.currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              navigationShell.currentIndex == 0
                  ? Iconsax.home
                  : Iconsax.home_2,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              navigationShell.currentIndex == 1
                  ? Iconsax.calendar5
                  : Iconsax.calendar,
            ),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              navigationShell.currentIndex == 2
                  ? Iconsax.discover
                  : Iconsax.discover_1,
            ),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              navigationShell.currentIndex == 3
                  ? Iconsax.gift
                  : Iconsax.gift5,
            ),
            label: 'Perks',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              navigationShell.currentIndex == 4
                  ? Iconsax.user
                  : Iconsax.user4,
            ),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
