// lib/core/widgets/auth/app_password_strength_field.dart
//
// A TextFormField with a live strength bar + rule checklist.
// Extracted from login_screen.dart and change_password_screen.dart
// so both screens share the same implementation.
//
// Also exports PasswordValidator for use in validators across the app.
//
// Usage:
//   AppPasswordStrengthField(
//     ctrl: _passwordCtrl,
//     isDark: isDark,
//     label: 'New Password',
//     hint: 'Create a strong password',
//   )

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../constants/app_color.dart';

// ─── Validator ────────────────────────────────────────────────────────────────

class PasswordValidator {
  PasswordValidator._();

  static const int minLength = 8;

  static bool hasMinLength(String pw) => pw.length >= minLength;
  static bool hasUppercase(String pw) => pw.contains(RegExp(r'[A-Z]'));
  static bool hasLowercase(String pw) => pw.contains(RegExp(r'[a-z]'));
  static bool hasDigit(String pw) => pw.contains(RegExp(r'[0-9]'));
  static bool hasSpecialChar(String pw) =>
      pw.contains(RegExp(r'[^\w\s]'));

  static bool isValid(String pw) =>
      hasMinLength(pw) && hasUppercase(pw) && hasLowercase(pw) && hasDigit(pw);

  static int score(String pw) {
    if (pw.isEmpty) return 0;
    int s = 0;
    if (hasMinLength(pw)) s++;
    if (hasUppercase(pw) && hasLowercase(pw)) s++;
    if (hasDigit(pw)) s++;
    if (hasSpecialChar(pw)) s++;
    return s;
  }

  static String strengthLabel(int s) {
    switch (s) {
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Strong';
      default: return '';
    }
  }

  static Color strengthColor(int s) {
    switch (s) {
      case 1: return AppColors.error;
      case 2: return AppColors.warning;
      case 3: return AppColors.info;
      case 4: return AppColors.success;
      default: return AppColors.error;
    }
  }

  static String? validate(String? value, {bool isSignIn = false}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (isSignIn) return null;
    if (!hasMinLength(value)) return 'Must be at least $minLength characters';
    if (!hasUppercase(value)) return 'Add at least one uppercase letter (A–Z)';
    if (!hasLowercase(value)) return 'Add at least one lowercase letter (a–z)';
    if (!hasDigit(value)) return 'Add at least one number (0–9)';
    return null;
  }
}

// ─── Rule definition ──────────────────────────────────────────────────────────

class _PwRule {
  final String label;
  final bool met;
  const _PwRule(this.label, this.met);
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class AppPasswordStrengthField extends StatefulWidget {
  final TextEditingController ctrl;
  final bool isDark;
  final String label;
  final String hint;
  final bool isSignIn;

  const AppPasswordStrengthField({
    super.key,
    required this.ctrl,
    required this.isDark,
    this.label = 'Password',
    this.hint = 'Create a strong password',
    this.isSignIn = false,
  });

  @override
  State<AppPasswordStrengthField> createState() =>
      _AppPasswordStrengthFieldState();
}

class _AppPasswordStrengthFieldState extends State<AppPasswordStrengthField> {
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final pw = widget.ctrl.text;
    final score = PasswordValidator.score(pw);
    final show = pw.isNotEmpty && !widget.isSignIn;

    final rules = [
      _PwRule('At least 8 characters', PasswordValidator.hasMinLength(pw)),
      _PwRule('One uppercase letter (A–Z)', PasswordValidator.hasUppercase(pw)),
      _PwRule('One lowercase letter (a–z)', PasswordValidator.hasLowercase(pw)),
      _PwRule('One number (0–9)', PasswordValidator.hasDigit(pw)),
      _PwRule('One special character (!@#\$…)', PasswordValidator.hasSpecialChar(pw)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            widget.label,
            style: GoogleFonts.alexandria(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: widget.isDark
                  ? AppColors.darkSubtext
                  : AppColors.lightSubtext,
            ),
          ),
        ),
        // Input
        TextFormField(
          controller: widget.ctrl,
          obscureText: _obscure,
          keyboardType: TextInputType.visiblePassword,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: GoogleFonts.alexandria(fontSize: 14),
          validator: (v) =>
              PasswordValidator.validate(v, isSignIn: widget.isSignIn),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon:
                const Icon(Iconsax.lock, size: 17, color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Iconsax.eye_slash : Iconsax.eye,
                size: 17,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            filled: true,
            fillColor: widget.isDark
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
                color: widget.isDark ? Colors.white10 : Colors.grey.shade200,
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
        ),
        // Strength bar (sign-up only)
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          child: show
              ? Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(4, (i) {
                          final filled = i < score;
                          final c = PasswordValidator.strengthColor(score);
                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: i < 3 ? 5 : 0),
                              height: 4,
                              decoration: BoxDecoration(
                                color:
                                    filled ? c : c.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            score >= 3
                                ? Iconsax.tick_circle
                                : Iconsax.info_circle,
                            size: 13,
                            color: PasswordValidator.strengthColor(score),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Strength: ${PasswordValidator.strengthLabel(score)}',
                            style: GoogleFonts.alexandria(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PasswordValidator.strengthColor(score),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // Rule checklist (sign-up only)
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          child: show
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: rules
                        .map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    r.met
                                        ? Iconsax.tick_circle
                                        : Icons.radio_button_unchecked,
                                    size: 14,
                                    color: r.met
                                        ? AppColors.success
                                        : Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    r.label,
                                    style: GoogleFonts.alexandria(
                                      fontSize: 12,
                                      color: r.met
                                          ? (widget.isDark
                                              ? Colors.white70
                                              : AppColors.lightText)
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
