// lib/core/widgets/app_gradient_fab.dart
//
// A gradient circular FloatingActionButton.
// Used in order_screen (add new order) and other screens.
//
// Usage:
//   floatingActionButton: AppGradientFab(
//     icon: Iconsax.add,
//     onPressed: () => context.push(RoutesName.placeOrdersNavigate),
//   )

import 'package:flutter/material.dart';
import '../constants/app_color.dart';

class AppGradientFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  const AppGradientFab({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.gradient,
          
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: size),
        ),
      ),
    );
  }
}
