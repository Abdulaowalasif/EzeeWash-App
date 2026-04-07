// lib/features/orders/presentation/widgets/track_order_cleaning_panel.dart
//
// Animated panel shown during atStore / cleaning / ready phases.
// Shows a spinning arc, pulsing rings, floating bubbles, and a step tracker.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../domain/entities/order_entity.dart';
import 'track_order_details_card.dart';
import '../../screens/track_order_screen.dart' show OrderPhase;

class TrackOrderCleaningPanel extends StatefulWidget {
  final OrderPhase phase;
  final OrderEntity order;
  final bool isDark;

  const TrackOrderCleaningPanel({
    super.key,
    required this.phase,
    required this.order,
    required this.isDark,
  });

  @override
  State<TrackOrderCleaningPanel> createState() =>
      _TrackOrderCleaningPanelState();
}

class _TrackOrderCleaningPanelState extends State<TrackOrderCleaningPanel>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _bubbleCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    _bubbleCtrl.dispose();
    super.dispose();
  }

  List<Widget> _buildBubbles() {
    const positions = [
      Offset(-80, -60),
      Offset(75, -55),
      Offset(-65, 55),
      Offset(72, 60),
      Offset(-10, -88),
      Offset(5, 84),
    ];
    return positions.asMap().entries.map((e) {
      final phase = e.key / positions.length;
      return AnimatedBuilder(
        animation: _bubbleCtrl,
        builder: (_, _) {
          final t = (_bubbleCtrl.value + phase) % 1.0;
          final opacity =
              math.sin(t * math.pi).clamp(0.0, 1.0) * 0.65;
          final dy = -12.0 * math.sin(t * math.pi);
          return Transform.translate(
            offset: Offset(e.value.dx, e.value.dy + dy),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 10 + (e.key % 3) * 4.0,
                height: 10 + (e.key % 3) * 4.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.4),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Animation container ───────────────────────────────────────────
        Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.darkSurface
                : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.darkBorder
                  : AppColors.primary.withOpacity(0.15),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, _) => Transform.scale(
                  scale: 0.95 + 0.1 * _pulseCtrl.value,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.05),
                    ),
                  ),
                ),
              ),
              // Inner pulse ring
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, _) => Transform.scale(
                  scale: 1.0 +
                      0.07 *
                          math.sin(_pulseCtrl.value * math.pi),
                  child: Container(
                    width: 115,
                    height: 115,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.09),
                    ),
                  ),
                ),
              ),
              // Spinning arc
              AnimatedBuilder(
                animation: _spinCtrl,
                builder: (_, _) => Transform.rotate(
                  angle: _spinCtrl.value * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(90, 90),
                    painter: _ArcPainter(),
                  ),
                ),
              ),
              // Center icon
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.gradient,
                ),
                child: Icon(
                  widget.phase == OrderPhase.atStore
                      ? Iconsax.shop
                      : Iconsax.refresh,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              ..._buildBubbles(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // ── Step tracker ──────────────────────────────────────────────────
        _CleaningSteps(phase: widget.phase, isDark: widget.isDark),
        const SizedBox(height: 20),
        TrackOrderDetailsCard(
          order: widget.order,
          isDark: widget.isDark,
          phase: widget.phase,
        ),
      ],
    );
  }
}

// ─── Arc painter ──────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primary, Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2,
        ),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2,
      ),
      -math.pi / 2,
      math.pi * 1.6,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter _) => false;
}

// ─── Step tracker ─────────────────────────────────────────────────────────────

class _StepDef {
  final IconData icon;
  final String label;
  final bool done;
  final bool active;
  const _StepDef({
    required this.icon,
    required this.label,
    this.done = false,
    this.active = false,
  });
}

class _CleaningSteps extends StatelessWidget {
  final OrderPhase phase;
  final bool isDark;

  const _CleaningSteps({required this.phase, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepDef(
        icon: Iconsax.shop,
        label: 'Received',
        done: phase == OrderPhase.cleaning || phase == OrderPhase.ready,
        active: phase == OrderPhase.atStore,
      ),
      _StepDef(
        icon: Iconsax.drop,
        label: 'Washing',
        done: phase == OrderPhase.ready,
        active: phase == OrderPhase.cleaning,
      ),
      _StepDef(
        icon: Iconsax.flash_1,
        label: 'Drying',
        done: phase == OrderPhase.ready,
        active: phase == OrderPhase.cleaning,
      ),
      _StepDef(
        icon: Iconsax.box_1,
        label: 'Ready',
        done: phase == OrderPhase.ready,
        active: phase == OrderPhase.ready,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cleaning Process',
            style: GoogleFonts.alexandria(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: steps.asMap().entries.map((e) {
              final s = e.value;
              final isLast = e.key == steps.length - 1;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: s.done ? AppColors.gradient : null,
                              color: s.done
                                  ? null
                                  : s.active
                                  ? AppColors.primary.withOpacity(0.12)
                                  : (isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100),
                              border: s.active && !s.done
                                  ? Border.all(
                                color: AppColors.primary,
                                width: 2,
                              )
                                  : null,
                            ),
                            child: Icon(
                              s.done ? Icons.check_rounded : s.icon,
                              color: s.done
                                  ? Colors.white
                                  : s.active
                                  ? AppColors.primary
                                  : Colors.grey.shade400,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.label,
                            style: GoogleFonts.alexandria(
                              fontSize: 10,
                              fontWeight: s.done || s.active
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: s.done
                                  ? AppColors.primary
                                  : s.active
                                  ? (isDark
                                  ? Colors.white
                                  : AppColors.lightText)
                                  : Colors.grey.shade400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 28),
                          decoration: BoxDecoration(
                            gradient: s.done ? AppColors.gradient : null,
                            color: s.done
                                ? null
                                : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
