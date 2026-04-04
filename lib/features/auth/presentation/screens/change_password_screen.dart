// lib/features/auth/presentation/screens/change_password_screen.dart
//
// Change-Password screen
//   • Verifies the current password by re-authenticating with Supabase
//   • Validates new password strength and confirmation match
//   • Calls supabase.auth.updateUser() to persist the change
//   • Uses GradientAppBar, AppGradientButton, AppSnackBar, AppColors & Alexandria font
//

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/constants/app_color.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/gradient_app_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // ── Keys & controllers ──────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // ── UI state ────────────────────────────────────────────────────────────────
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _currentPasswordError;

  // ── Supabase ─────────────────────────────────────────────────────────────────
  final _client = supa.Supabase.instance.client;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Password strength ────────────────────────────────────────────────────────

  int _strengthScore(String pw) {
    int score = 0;
    if (pw.length >= 8) score++;
    if (pw.contains(RegExp(r'[A-Z]'))) score++;
    if (pw.contains(RegExp(r'[0-9]'))) score++;
    if (pw.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  Color _strengthColor(int score) {
    switch (score) {
      case 1: return AppColors.error;
      case 2: return AppColors.warning;
      case 3: return AppColors.info;
      case 4: return AppColors.success;
      default: return AppColors.error;
    }
  }

  String _strengthLabel(int score) {
    switch (score) {
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Strong';
      default: return 'Weak';
    }
  }

  // ── Verify current password by re-authenticating ─────────────────────────────

  Future<bool> _verifyCurrentPassword(String current) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) return false;
    try {
      await _client.auth.signInWithPassword(email: email, password: current);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Clear previous server-side error before re-validating
    setState(() => _currentPasswordError = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      // 1. Re-authenticate with current password
      final valid = await _verifyCurrentPassword(_currentCtrl.text);
      if (!valid) {
        setState(() => _currentPasswordError = 'Current password is incorrect.');
        _formKey.currentState?.validate(); // re-trigger to show inline error
        return;
      }

      // 2. Update to new password via Supabase
      await _client.auth.updateUser(
        supa.UserAttributes(password: _newCtrl.text),
      );

      if (!mounted) return;

      AppSnackBar.show(context, 'Password changed successfully!');
      Navigator.of(context).pop();
    } on supa.AuthApiException catch (e) {
      if (mounted) AppSnackBar.show(context, _friendly(e.message), isError: true);
    } catch (e) {
      if (mounted) AppSnackBar.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Error messages ───────────────────────────────────────────────────────────

  String _friendly(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('password should be at least')) {
      return 'Password must be at least 8 characters.';
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'Too many attempts. Please wait a moment.';
    }
    if (m.contains('network') || m.contains('socket')) {
      return 'Network error. Check your connection.';
    }
    return msg;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pw = _newCtrl.text;
    final score = pw.isNotEmpty ? _strengthScore(pw) : 0;

    return Scaffold(
      appBar: const GradientAppBar(title: 'Change Password'),
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Security header card ─────────────────────────────────────────
              _SecurityCard(isDark: isDark),

              const SizedBox(height: 28),

              // ── Section: Current password ────────────────────────────────────
              _SectionLabel(label: 'Current Password', isDark: isDark),
              const SizedBox(height: 10),

              _PasswordField(
                controller: _currentCtrl,
                hint: 'Enter current password',
                icon: Iconsax.lock,
                isDark: isDark,
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                onChanged: (_) =>
                    setState(() => _currentPasswordError = null),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Current password is required';
                  if (_currentPasswordError != null) return _currentPasswordError;
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // ── Divider ──────────────────────────────────────────────────────
              _DashedDivider(isDark: isDark),

              const SizedBox(height: 24),

              // ── Section: New password ────────────────────────────────────────
              _SectionLabel(label: 'New Password', isDark: isDark),
              const SizedBox(height: 10),

              _PasswordField(
                controller: _newCtrl,
                hint: 'Enter new password',
                icon: Iconsax.lock_1,
                isDark: isDark,
                obscure: _obscureNew,
                onToggle: () =>
                    setState(() => _obscureNew = !_obscureNew),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'New password is required';
                  if (v.length < 8) return 'Minimum 8 characters';
                  if (v == _currentCtrl.text) {
                    return 'New password must differ from current password';
                  }
                  return null;
                },
              ),

              // ── Strength bar ─────────────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                child: pw.isNotEmpty
                    ? _StrengthBar(
                  score: score,
                  color: _strengthColor(score),
                  label: _strengthLabel(score),
                )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // ── Confirm password ─────────────────────────────────────────────
              _PasswordField(
                controller: _confirmCtrl,
                hint: 'Confirm new password',
                icon: Iconsax.lock_slash,
                isDark: isDark,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (v != _newCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),

              // ── Match indicator ──────────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                child: _confirmCtrl.text.isNotEmpty
                    ? _MatchIndicator(
                  matches: _confirmCtrl.text == _newCtrl.text,
                  isDark: isDark,
                )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 28),

              // ── Requirements checklist ───────────────────────────────────────
              _RequirementsCard(password: pw, isDark: isDark),

              const SizedBox(height: 32),

              // ── Submit button ────────────────────────────────────────────────
              AppGradientButton(
                label: 'Update Password',
                onPressed: _isLoading ? null : _submit,
                isLoading: _isLoading,
                icon: Iconsax.shield_tick,
                verticalPadding: 15,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Security header card
// ─────────────────────────────────────────────────────────────────────────────

class _SecurityCard extends StatelessWidget {
  final bool isDark;
  const _SecurityCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(isDark ? 0.25 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Iconsax.shield_security, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Your Password',
                  style: GoogleFonts.alexandria(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Choose a strong, unique password you haven\'t used before.',
                  style: GoogleFonts.alexandria(
                    fontSize: 12,
                    height: 1.5,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: GoogleFonts.alexandria(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
      letterSpacing: 0.3,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Password text field
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final bool obscure;
  final VoidCallback onToggle;
  final void Function(String) onChanged;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.alexandria(
        fontSize: 14,
        color: isDark ? Colors.white : AppColors.lightText,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          fontSize: 14,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: Colors.grey.shade400, size: 20),
        ),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Icon(
              obscure ? Iconsax.eye_slash : Iconsax.eye,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : AppColors.lightBackground,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Strength bar
// ─────────────────────────────────────────────────────────────────────────────

class _StrengthBar extends StatelessWidget {
  final int score;
  final Color color;
  final String label;

  const _StrengthBar({
    required this.score,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) {
              final active = i < score;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  height: 5,
                  decoration: BoxDecoration(
                    color: active ? color : color.withOpacity(0.15),
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
                score >= 3 ? Iconsax.tick_circle : Iconsax.info_circle,
                size: 13,
                color: color,
              ),
              const SizedBox(width: 5),
              Text(
                'Password strength: $label',
                style: GoogleFonts.alexandria(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Match indicator
// ─────────────────────────────────────────────────────────────────────────────

class _MatchIndicator extends StatelessWidget {
  final bool matches;
  final bool isDark;
  const _MatchIndicator({required this.matches, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = matches ? AppColors.success : AppColors.error;
    final icon = matches ? Iconsax.tick_circle : Iconsax.close_circle;
    final text = matches ? 'Passwords match' : 'Passwords do not match';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.alexandria(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Requirements checklist card
// ─────────────────────────────────────────────────────────────────────────────

class _RequirementsCard extends StatelessWidget {
  final String password;
  final bool isDark;
  const _RequirementsCard({required this.password, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rules = [
      _Rule('At least 8 characters', password.length >= 8),
      _Rule('One uppercase letter', password.contains(RegExp(r'[A-Z]'))),
      _Rule('One number', password.contains(RegExp(r'[0-9]'))),
      _Rule(
        'One special character',
        password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
      ),
    ];

    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final labelColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.clipboard_text, size: 15, color: labelColor),
              const SizedBox(width: 7),
              Text(
                'Password Requirements',
                style: GoogleFonts.alexandria(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rules.map((r) => _RuleRow(rule: r, isDark: isDark)),
        ],
      ),
    );
  }
}

class _Rule {
  final String label;
  final bool met;
  const _Rule(this.label, this.met);
}

class _RuleRow extends StatelessWidget {
  final _Rule rule;
  final bool isDark;
  const _RuleRow({required this.rule, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = rule.met ? AppColors.success : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              rule.met ? Iconsax.tick_circle : Iconsax.minus_cirlce,
              key: ValueKey(rule.met),
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rule.label,
            style: GoogleFonts.alexandria(
              fontSize: 13,
              color: color,
              fontWeight: rule.met ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed divider
// ─────────────────────────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  final bool isDark;
  const _DashedDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        40,
            (i) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 1,
            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                .withOpacity(i.isEven ? 1 : 0),
          ),
        ),
      ),
    );
  }
}