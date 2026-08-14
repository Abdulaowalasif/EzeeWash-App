import 'package:flutter/material.dart';
import '../../constants/app_color.dart';
import '../../theme/app_text_styles.dart';

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
          ? Colors.white.withValues(alpha: 0.05)
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
