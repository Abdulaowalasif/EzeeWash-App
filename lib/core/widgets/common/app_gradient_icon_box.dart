import 'package:flutter/material.dart';
import '../../constants/app_color.dart';

class AppGradientIconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  final double padding;
  final double borderRadius;
  const AppGradientIconBox({
    super.key,
    required this.icon,
    this.size = 26,
    this.padding = 14,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      gradient: AppColors.gradient,
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    child: Icon(icon, color: Colors.white, size: size),
  );
}
