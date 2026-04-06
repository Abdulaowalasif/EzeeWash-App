// lib/core/widgets/common_widgets.dart
//
// Single source of truth for every small shared widget used across 3+ screens.
//
// Widgets:
//   AppSectionLabel        — bold section heading (also used as the "ACCOUNT" caps label)
//   AppSheetHandle         — drag handle for bottom sheets
//   AppEmptyState          — icon + message placeholder
//   AppLoadingIndicator    — centred CircularProgressIndicator
//   AppGradientButton      — full-width gradient ElevatedButton
//   AppOutlinedInput       — consistent themed text field
//   AppRatingStars         — row of star icons for a numeric rating
//   AppIconBox             — icon inside a tinted rounded container (used everywhere)
//   AppBrandFooter         — "Ezee Wash / Clean Clothes. Clear Mind." footer
//   AppContactRow          — icon + label + value row (used in help & other screens)
//   AppExpandableTile      — themed ExpansionTile (FAQ, policy items, etc.)
//   AppConfirmDialog       — reusable two-action confirm dialog
//   AppSnackBarHelper      — centralised snack bar + dialog helpers
//
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../constants/app_color.dart';
import '../theme/app_text_styles.dart';

// ─── Section heading ───────────────────────────────────────────────────────────

/// A bold section heading used throughout the app.
///
/// Pass [caps] to render in upper-case with letter-spacing (settings sections).
/// Defaults to title-case with [AppTextStyles.sectionTitle].
class AppSectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  final double fontSize;
  final bool caps;

  const AppSectionLabel({
    super.key,
    required this.text,
    required this.isDark,
    this.fontSize = 16,
    this.caps = false,
  });

  @override
  Widget build(BuildContext context) {
    if (caps) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.alexandria(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.2,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
      );
    }
    return Text(
      text,
      style: AppTextStyles.sectionTitle(isDark).copyWith(fontSize: fontSize),
    );
  }
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
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
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
        borderSide:
        const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),
  );
}

// ─── Rating stars ─────────────────────────────────────────────────────────────

/// A row of 5 star icons reflecting a fractional [rating].
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
        final half =
            !full && i < rating && (rating - rating.floor()) >= 0.5;
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

// ─── Icon box ─────────────────────────────────────────────────────────────────

/// Icon inside a tinted rounded-rectangle container.
///
/// Used in settings tiles, contact rows, hero cards, and any place
/// where an icon needs a coloured background pill. Replaces the
/// repeated `Container > BoxDecoration > Icon` pattern across the app.
///
/// Usage:
/// ```dart
/// AppIconBox(icon: Iconsax.lock, color: AppColors.primary)
/// AppIconBox(icon: Icons.phone_iphone_rounded, color: AppColors.success, size: 20)
/// AppIconBox(icon: Iconsax.message_question, padding: 14, shape: BoxShape.circle)
/// ```
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
        color: color.withOpacity(0.1),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius ?? 10)
            : null,
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

// ─── Brand footer ─────────────────────────────────────────────────────────────

/// "Ezee Wash / Clean Clothes. Clear Mind." footer used in Help and Terms screens.
class AppBrandFooter extends StatelessWidget {
  const AppBrandFooter({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        Text(
          'Ezee Wash',
          style: GoogleFonts.pacifico(
              fontSize: 18, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          'Clean Clothes. Clear Mind.',
          style: GoogleFonts.alexandria(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    ),
  );
}

// ─── Contact row ──────────────────────────────────────────────────────────────

/// An icon + label + value row used on the Help & Support screen and elsewhere.
///
/// Usage:
/// ```dart
/// AppContactRow(
///   icon: Icons.alternate_email_rounded,
///   color: AppColors.primary,
///   label: 'Email',
///   value: 'support@ezeewash.com',
///   isDark: isDark,
///   onTap: () => launchUrl(Uri.parse('mailto:...')),
/// )
/// ```
class AppContactRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback? onTap;

  const AppContactRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(children: [
        AppIconBox(icon: icon, color: color, shape: BoxShape.circle),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.caption(isDark)),
          Text(
            value,
            style: AppTextStyles.rowTitle(isDark),
          ),
        ]),
      ]),
    );
  }
}

// ─── Expandable tile ──────────────────────────────────────────────────────────

/// A themed [ExpansionTile] used for FAQ items, policy sections, etc.
///
/// Usage:
/// ```dart
/// AppExpandableTile(
///   title: 'Can I track my order?',
///   body: 'Yes! You can track from the Orders section.',
///   isDark: isDark,
/// )
/// ```
class AppExpandableTile extends StatelessWidget {
  final String title;
  final String body;
  final bool isDark;
  final EdgeInsetsGeometry margin;

  const AppExpandableTile({
    super.key,
    required this.title,
    required this.body,
    required this.isDark,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: Colors.grey,
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            title,
            style: AppTextStyles.body(isDark).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                body,
                style: AppTextStyles.bodyLong(isDark)
                    .copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Confirm dialog ───────────────────────────────────────────────────────────

/// A reusable two-action confirm dialog.
///
/// Usage:
/// ```dart
/// AppConfirmDialog.show(
///   context,
///   title: 'Sign Out?',
///   message: 'Are you sure you want to sign out?',
///   confirmLabel: 'Sign Out',
///   confirmColor: AppColors.error,
///   onConfirm: () => context.read<AuthBloc>().add(AuthSignOutRequested()),
/// );
/// ```
class AppConfirmDialog {
  AppConfirmDialog._();

  static void show(
      BuildContext context, {
        required String title,
        required String message,
        String cancelLabel = 'Cancel',
        String confirmLabel = 'Confirm',
        Color confirmColor = AppColors.primary,
        required VoidCallback onConfirm,
      }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.alexandria(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: GoogleFonts.alexandria(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              cancelLabel,
              style: GoogleFonts.alexandria(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              onConfirm();
            },
            child: Text(
              confirmLabel,
              style: GoogleFonts.alexandria(
                color: confirmColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}