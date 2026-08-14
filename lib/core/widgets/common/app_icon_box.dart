import 'package:flutter/material.dart';
import '../../constants/app_color.dart';

// ─── Icon box ─────────────────────────────────────────────────────────────────

class AppIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double iconSize;
  final double padding;
  final BoxShape shape;
  final double? borderRadius;

  const AppIconBox({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.iconSize = 18,
    this.padding = 8,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius ?? 10)
            : null,
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
