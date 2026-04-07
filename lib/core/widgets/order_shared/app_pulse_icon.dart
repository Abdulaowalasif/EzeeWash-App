// lib/core/widgets/order_shared/app_pulse_icon.dart
//
// A pulsing animated icon used in waiting/info panels to show
// an active but pending state (e.g. "Awaiting Rider").
//
// Usage:
//   AppPulseIcon(
//     icon: Iconsax.shop,
//     color: AppColors.primary,
//     size: 48,
//   )

import 'package:flutter/material.dart';

class AppPulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double containerSize;

  const AppPulseIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
    this.containerSize = 28,
  });

  @override
  State<AppPulseIcon> createState() => _AppPulseIconState();
}

class _AppPulseIconState extends State<AppPulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, _) => Transform.scale(
      scale: 1.0 + 0.1 * _ctrl.value,
      child: Container(
        padding: EdgeInsets.all(widget.containerSize),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.15),
        ),
        child: Icon(widget.icon, color: widget.color, size: widget.size),
      ),
    ),
  );
}
