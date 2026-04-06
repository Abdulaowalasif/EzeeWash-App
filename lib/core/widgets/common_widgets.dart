// lib/core/widgets/common_widgets.dart
//
// Houses small shared widgets that appear in 3+ screens:
//   • AppSectionLabel     — bold section heading
//   • AppSheetHandle      — drag handle for bottom sheets
//   • AppEmptyState       — icon + message placeholder
//   • AppLoadingIndicator — centred CircularProgressIndicator
//   • AppGradientButton   — full-width gradient ElevatedButton
//   • AppOutlinedInput    — consistent themed text field
//   • AppRatingStars      — row of star icons for a numeric rating
//
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../constants/app_color.dart';
import '../theme/app_text_styles.dart';

// ─── Section heading ──────────────────────────────────────────────────────────

class AppSectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  final double fontSize;

  const AppSectionLabel({
    super.key,
    required this.text,
    required this.isDark,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.sectionTitle(isDark).copyWith(fontSize: fontSize),
  );
}

// ─── Bottom-sheet drag handle ─────────────────────────────────────────────────

class AppSheetHandle extends StatelessWidget {
  final bool isDark;
  const AppSheetHandle({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.white24 : Colors.black12,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}

// ─── Empty-state placeholder ──────────────────────────────────────────────────

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final bool isDark;

  const AppEmptyState({
    super.key,
    this.icon = Iconsax.box_remove,
    required this.message,
    this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 64,
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.cardTitle(isDark),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(isDark),
          ),
        ],
      ],
    ),
  );
}

// ─── Loading indicator ────────────────────────────────────────────────────────

class AppLoadingIndicator extends StatelessWidget {
  final double strokeWidth;
  const AppLoadingIndicator({super.key, this.strokeWidth = 2.5});

  @override
  Widget build(BuildContext context) => Center(
    child: CircularProgressIndicator(
      color: AppColors.primary,
      strokeWidth: strokeWidth,
    ),
  );
}

// ─── Full-width gradient button ───────────────────────────────────────────────

class AppGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double verticalPadding;
  final double borderRadius;

  const AppGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.verticalPadding = 14,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: onPressed != null ? AppColors.gradient : null,
        color: onPressed == null ? Colors.grey.shade300 : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: onPressed != null
            ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppTextStyles.button),
          ],
        ),
      ),
    );
  }
}

// ─── Themed text field ────────────────────────────────────────────────────────

class AppOutlinedInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AppOutlinedInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    validator: validator,
    style: AppTextStyles.input,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.hint(isDark),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: isDark
          ? Colors.white.withOpacity(0.05)
          : AppColors.lightBackground,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),
  );
}

// ─── Rating stars ─────────────────────────────────────────────────────────────

/// A row of 5 star icons reflecting a fractional [rating].
/// Used in service cards, review sheets, and anywhere a rating is displayed.
class AppRatingStars extends StatelessWidget {
  final double rating;
  final double size;

  const AppRatingStars({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = i < rating.floor();
        final half = !full && i < rating && (rating - rating.floor()) >= 0.5;
        return Icon(
          full
              ? Icons.star_rounded
              : half
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          color: const Color(0xFFFBBF24),
          size: size,
        );
      }),
    );
  }
}