// lib/core/widgets/order_shared/app_status_result_view.dart
//
// Reusable animated result view for terminal order states (delivered / cancelled).
// Renders a scale+fade entrance, a title, subtitle, a summary card, and a button.
//
// Usage:
//   AppStatusResultView(
//     isDark: isDark,
//     iconData: Icons.check_rounded,
//     gradient: AppColors.gradient,
//     glowColor: AppColors.primary,
//     title: 'Order Delivered!',
//     subtitle: 'Your laundry has been delivered.',
//     borderColor: AppColors.primary,
//     summaryRows: [...],
//     buttonLabel: 'Done',
//     buttonColor: AppColors.primary,
//     onButton: () => context.pop(),
//   )

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_color.dart';
import '../../utils/responsive.dart';

class AppStatusResultView extends StatefulWidget {
  final bool isDark;
  final IconData iconData;
  final Gradient gradient;
  final Color glowColor;
  final String title;
  final String subtitle;
  final Color borderColor;
  final List<Widget> summaryRows;
  final String buttonLabel;
  final Color buttonColor;
  final bool buttonOutlined;
  final VoidCallback onButton;
  final Duration animDuration;

  const AppStatusResultView({
    super.key,
    required this.isDark,
    required this.iconData,
    required this.gradient,
    required this.glowColor,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.summaryRows,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onButton,
    this.buttonOutlined = false,
    this.animDuration = const Duration(milliseconds: 700),
  });

  @override
  State<AppStatusResultView> createState() => _AppStatusResultViewState();
}

class _AppStatusResultViewState extends State<AppStatusResultView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.animDuration);
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 10,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.maxContentWidth(context),
          ),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Animated hero icon
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.gradient,
                      boxShadow: [
                        BoxShadow(
                          color: widget.glowColor.withValues(alpha: 0.4),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(widget.iconData, color: Colors.white, size: 60),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Title & subtitle
              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.alexandria(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark
                            ? Colors.white
                            : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alexandria(
                        fontSize: 14,
                        color: widget.isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Summary card
              if (widget.summaryRows.isNotEmpty)
                FadeTransition(
                  opacity: _fade,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: widget.borderColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.borderColor.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < widget.summaryRows.length; i++) ...[
                          widget.summaryRows[i],
                          if (i < widget.summaryRows.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // Action button
              FadeTransition(
                opacity: _fade,
                child: SizedBox(
                  width: double.infinity,
                  child: widget.buttonOutlined
                      ? ElevatedButton(
                          onPressed: widget.onButton,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isDark
                                ? AppColors.darkSurface
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: widget.buttonColor,
                                width: 1.5,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            widget.buttonLabel,
                            style: GoogleFonts.alexandria(
                              color: widget.buttonColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.gradient,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ElevatedButton(
                            onPressed: widget.onButton,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              widget.buttonLabel,
                              style: GoogleFonts.alexandria(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
