// lib/features/auth/presentation/widgets/app_auth_field.dart
//
// Consistent InputDecoration + TextFormField wrapper for all auth screens.
// Exported as both the decoration builder (for custom fields) and the widget.
//
// Usage:
//   AppAuthField(
//     controller: _emailCtrl,
//     hint: 'Enter your email',
//     prefixIcon: Iconsax.sms,
//     isDark: isDark,
//     keyboardType: TextInputType.emailAddress,
//     validator: (v) => v!.isEmpty ? 'Required' : null,
//   )
//
//   // Just the decoration:
//   authFieldDecoration(isDark: isDark, hint: 'Email', prefixIcon: Iconsax.sms)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_color.dart';

InputDecoration authFieldDecoration({
  required bool isDark,
  required String hint,
  required IconData prefixIcon,
  Widget? suffixIcon,
  String? labelText,
}) =>
    InputDecoration(
      prefixIcon: Icon(prefixIcon,
          size: 19, color: AppColors.primary.withOpacity(0.7)),
      hintText: hint,
      labelText: labelText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor:
          isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF7F8FC),
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE8EAF0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );

class AppAuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool isDark;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final String? labelText;

  const AppAuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.isDark,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.labelText,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: GoogleFonts.alexandria(fontSize: 14),
        validator: validator,
        decoration: authFieldDecoration(
          isDark: isDark,
          hint: hint,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          labelText: labelText,
        ),
      );
}
