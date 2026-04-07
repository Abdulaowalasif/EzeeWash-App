// lib/features/auth/presentation/widgets/auth_password_field.dart
//
// Password field with live strength bar + animated rule checklist.
// Extracted from login_screen.dart so it can be used in both SignUp
// and ChangePassword screens without duplication.
//
// Also exports PasswordValidator as the single source of truth for
// all password rules across the app.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_color.dart';
import 'auth_panels.dart' show authLoginFieldDecoration;

// ─── Validator ────────────────────────────────────────────────────────────────

class PasswordValidator {
  PasswordValidator._();

  static const int minLength = 8;

  static bool hasMinLength(String pw) => pw.length >= minLength;
  static bool hasUppercase(String pw) =>
      pw.contains(RegExp(r'[A-Z]'));
  static bool hasLowercase(String pw) =>
      pw.contains(RegExp(r'[a-z]'));
  static bool hasDigit(String pw) => pw.contains(RegExp(r'[0-9]'));
  static bool hasSpecialChar(String pw) =>
      pw.contains(RegExp(r'[^\w\s]'));

  static bool isValid(String pw) =>
      hasMinLength(pw) &&
      hasUppercase(pw) &&
      hasLowercase(pw) &&
      hasDigit(pw);

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
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  static Color strengthColor(int s) {
    switch (s) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.info;
      case 4:
        return AppColors.success;
      default:
        return AppColors.error;
    }
  }

  static String? validate(String? value, {bool isSignIn = false}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (isSignIn) return null;
    if (!hasMinLength(value)) {
      return 'Must be at least $minLength characters';
    }
    if (!hasUppercase(value)) {
      return 'Add at least one uppercase letter (A–Z)';
    }
    if (!hasLowercase(value)) {
      return 'Add at least one lowercase letter (a–z)';
    }
    if (!hasDigit(value)) return 'Add at least one number (0–9)';
    return null;
  }
}

// ─── Rule model ───────────────────────────────────────────────────────────────

class _PwRule {
  final String label;
  final bool met;
  const _PwRule(this.label, this.met);
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class AuthPasswordStrengthField extends StatefulWidget {
  final TextEditingController ctrl;
  final bool isDark;
  final String label;
  final String hint;

  const AuthPasswordStrengthField({
    super.key,
    required this.ctrl,
    required this.isDark,
    this.label = 'Password',
    this.hint = 'Create a strong password',
  });

  @override
  State<AuthPasswordStrengthField> createState() =>
      _AuthPasswordStrengthFieldState();
}

class _AuthPasswordStrengthFieldState
    extends State<AuthPasswordStrengthField> {
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
    final show = pw.isNotEmpty;

    final rules = [
      _PwRule(
          'At least 8 characters', PasswordValidator.hasMinLength(pw)),
      _PwRule('One uppercase letter (A–Z)',
          PasswordValidator.hasUppercase(pw)),
      _PwRule('One lowercase letter (a–z)',
          PasswordValidator.hasLowercase(pw)),
      _PwRule('One number (0–9)', PasswordValidator.hasDigit(pw)),
      _PwRule('One special character (!@#\$…)',
          PasswordValidator.hasSpecialChar(pw)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        TextFormField(
          controller: widget.ctrl,
          obscureText: _obscure,
          keyboardType: TextInputType.visiblePassword,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: GoogleFonts.alexandria(fontSize: 14),
          validator: (v) => PasswordValidator.validate(v),
          decoration: authLoginFieldDecoration(
            isDark: widget.isDark,
            hint: widget.hint,
            prefixIcon: Iconsax.lock,
            suffixIcon: IconButton(
              icon: Icon(
                  _obscure ? Iconsax.eye_slash : Iconsax.eye,
                  size: 17,
                  color: Colors.grey),
              onPressed: () =>
                  setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        // Strength bar
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          child: show
              ? Padding(
                  padding:
                      const EdgeInsets.only(top: 10, bottom: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(4, (i) {
                          final filled = i < score;
                          final c =
                              PasswordValidator.strengthColor(score);
                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(
                                  right: i < 3 ? 5 : 0),
                              height: 4,
                              decoration: BoxDecoration(
                                color: filled
                                    ? c
                                    : c.withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(4),
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
                            color:
                                PasswordValidator.strengthColor(
                                    score),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Strength: ${PasswordValidator.strengthLabel(score)}',
                            style: GoogleFonts.alexandria(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PasswordValidator.strengthColor(
                                  score),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // Rule checklist
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          child: show
              ? Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.04)
                        : const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFE8EAF0),
                    ),
                  ),
                  child: Column(
                    children: rules
                        .map((r) => _PwRuleRow(
                            rule: r, isDark: widget.isDark))
                        .toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PwRuleRow extends StatelessWidget {
  final _PwRule rule;
  final bool isDark;
  const _PwRuleRow({required this.rule, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = rule.met
        ? AppColors.success
        : (isDark
            ? AppColors.darkSubtext
            : const Color(0xFF94A3B8));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              rule.met
                  ? Iconsax.tick_circle
                  : Iconsax.minus_cirlce,
              key: ValueKey(rule.met),
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rule.label,
            style: GoogleFonts.alexandria(
              fontSize: 12,
              color: color,
              fontWeight: rule.met
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
