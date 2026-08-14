// lib/features/auth/presentation/screens/change_password_screen.dart
//
// Refactored:
//   • AppTextStyles replaces inline GoogleFonts calls
//   • AppCard replaces raw Container+BoxDecoration for surface cards
//   • AppGradientButton replaces inline gradient button at bottom
//   • AppSnackBar replaces inline showSnackBar
//   • Duplicated _strengthScore/_strengthColor/_strengthLabel merged
//     into the shared PasswordValidator from auth_password_field.dart
//   • _SectionLabel → AppSectionLabel(caps: false)

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _currentPasswordError;

  final _client = supa.Supabase.instance.client;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _submit() async {
    setState(() => _currentPasswordError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      final valid = await _verifyCurrentPassword(_currentCtrl.text);
      if (!valid) {
        setState(
          () => _currentPasswordError = 'Current password is incorrect.',
        );
        _formKey.currentState?.validate();
        return;
      }
      await _client.auth.updateUser(
        supa.UserAttributes(password: _newCtrl.text),
      );
      if (!mounted) return;
      AppSnackBar.show(context, 'Password changed successfully!');
      Navigator.of(context).pop();
    } on supa.AuthApiException catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          _friendly(e.message),
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, e.toString(), type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pw = _newCtrl.text;
    final score = pw.isNotEmpty ? PasswordValidator.score(pw) : 0;

    return Scaffold(
      appBar: const GradientAppBar(title: 'Change Password'),
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Security header ─────────────────────────────────────
              _SecurityCard(isDark: isDark),
              const SizedBox(height: 28),

              // ── Current password ────────────────────────────────────
              AppSectionLabel(text: 'Current Password', isDark: isDark),
              const SizedBox(height: 10),
              _PasswordField(
                controller: _currentCtrl,
                hint: 'Enter current password',
                icon: Iconsax.lock,
                isDark: isDark,
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                onChanged: (_) => setState(() => _currentPasswordError = null),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Current password is required';
                  }
                  if (_currentPasswordError != null) {
                    return _currentPasswordError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _DashedDivider(isDark: isDark),
              const SizedBox(height: 24),

              // ── New password ────────────────────────────────────────
              AppSectionLabel(text: 'New Password', isDark: isDark),
              const SizedBox(height: 10),
              _PasswordField(
                controller: _newCtrl,
                hint: 'Enter new password',
                icon: Iconsax.lock_1,
                isDark: isDark,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'New password is required';
                  }
                  if (v.length < 8) return 'Minimum 8 characters';
                  if (v == _currentCtrl.text) {
                    return 'New password must differ from current password';
                  }
                  return null;
                },
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                child: pw.isNotEmpty
                    ? _StrengthBar(
                        score: score,
                        color: PasswordValidator.strengthColor(score),
                        label: PasswordValidator.strengthLabel(score),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // ── Confirm password ────────────────────────────────────
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
                  if (v != _newCtrl.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
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

              // ── Requirements ────────────────────────────────────────
              _RequirementsCard(password: pw, isDark: isDark),
              const SizedBox(height: 32),

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

// ─── Security header card ─────────────────────────────────────────────────────

class _SecurityCard extends StatelessWidget {
  final bool isDark;
  const _SecurityCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
      ),
      child: Row(
        children: [
          AppIconBox(
            icon: Iconsax.shield_security,
            iconSize: 22,
            padding: 10,
            borderRadius: 12,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Your Password',
                  style: AppTextStyles.cardTitle(isDark),
                ),
                const SizedBox(height: 3),
                Text(
                  "Choose a strong, unique password you haven't used before.",
                  style: AppTextStyles.bodyLong(isDark).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Password field ───────────────────────────────────────────────────────────

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
      style: AppTextStyles.input,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.hint(isDark),
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
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.lightBackground,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
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

// ─── Strength bar ─────────────────────────────────────────────────────────────

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
                    color: active ? color : color.withValues(alpha: 0.15),
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
                style: AppTextStyles.captionMedium(
                  false,
                ).copyWith(color: color, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Match indicator ──────────────────────────────────────────────────────────

class _MatchIndicator extends StatelessWidget {
  final bool matches;
  final bool isDark;
  const _MatchIndicator({required this.matches, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = matches ? AppColors.success : AppColors.error;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            matches ? Iconsax.tick_circle : Iconsax.close_circle,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            matches ? 'Passwords match' : 'Passwords do not match',
            style: AppTextStyles.captionMedium(isDark).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Requirements checklist ───────────────────────────────────────────────────

class _RequirementsCard extends StatelessWidget {
  final String password;
  final bool isDark;
  const _RequirementsCard({required this.password, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rules = [
      _Rule('At least 8 characters', PasswordValidator.hasMinLength(password)),
      _Rule('One uppercase letter', PasswordValidator.hasUppercase(password)),
      _Rule('One number', PasswordValidator.hasDigit(password)),
      _Rule(
        'One special character',
        PasswordValidator.hasSpecialChar(password),
      ),
    ];

    return AppCard(
      isDark: isDark,
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.clipboard_text,
                size: 15,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
              const SizedBox(width: 7),
              Text(
                'Password Requirements',
                style: AppTextStyles.body(
                  isDark,
                ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
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
    final color = rule.met
        ? AppColors.success
        : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);
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
            style: AppTextStyles.body(isDark).copyWith(
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

// ─── Dashed divider ───────────────────────────────────────────────────────────

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
                .withValues(alpha: i.isEven ? 1 : 0),
          ),
        ),
      ),
    );
  }
}
