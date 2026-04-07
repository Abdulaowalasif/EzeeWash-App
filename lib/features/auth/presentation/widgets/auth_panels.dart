// lib/features/auth/presentation/widgets/auth_panels.dart
//
// Self-contained auth form panels extracted from login_screen.dart.
// Each panel owns its own Form + fields; the parent screen owns controllers,
// BLoC wiring, and the slide/fade animation between panels.
//
// Exports:
//   AuthSignInPanel    – email + password + forgot password link + Google
//   AuthSignUpPanel    – name + email + password (with strength) + confirm
//   AuthForgotPanel    – email + submit + back link
//   AuthTabToggle      – animated Sign In / Sign Up pill toggle
//   AuthGradientButton – full-width gradient tap button with spinner
//   AuthField          – labeled TextFormField with eye-toggle for passwords
//   AuthOrDivider      – "── OR ──" row
//   AuthGoogleButton   – "Continue with Google" outlined button

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_color.dart';
import '../bloc/auth_bloc.dart';
import 'auth_password_field.dart';

// ─── Shared field decoration ──────────────────────────────────────────────────

InputDecoration authLoginFieldDecoration({
  required bool isDark,
  required String hint,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) =>
    InputDecoration(
      prefixIcon: Icon(prefixIcon,
          size: 19, color: AppColors.primary.withOpacity(0.7)),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor:
          isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF7F8FC),
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE8EAF0)),
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

// ─── AuthField ────────────────────────────────────────────────────────────────

class AuthField extends StatefulWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final bool isDark;
  final bool obscure;
  final bool autovalidate;
  final TextInputType? type;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.obscure = false,
    this.autovalidate = false,
    this.type,
    this.validator,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _obs;

  @override
  void initState() {
    super.initState();
    _obs = widget.obscure;
  }

  @override
  void didUpdateWidget(AuthField old) {
    super.didUpdateWidget(old);
    if (old.obscure != widget.obscure) _obs = widget.obscure;
  }

  @override
  Widget build(BuildContext context) => Column(
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
            obscureText: _obs,
            keyboardType: widget.obscure
                ? TextInputType.visiblePassword
                : widget.type,
            style: GoogleFonts.alexandria(fontSize: 14),
            autovalidateMode: widget.autovalidate
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            validator: widget.validator ??
                (v) => (v == null || v.isEmpty) ? 'Required' : null,
            decoration: authLoginFieldDecoration(
              isDark: widget.isDark,
              hint: widget.hint,
              prefixIcon: widget.icon,
              suffixIcon: widget.obscure
                  ? IconButton(
                      icon: Icon(
                          _obs ? Iconsax.eye_slash : Iconsax.eye,
                          size: 17,
                          color: Colors.grey),
                      onPressed: () => setState(() => _obs = !_obs),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
}

// ─── AuthGradientButton ───────────────────────────────────────────────────────

class AuthGradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const AuthGradientButton({
    super.key,
    required this.label,
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        label,
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
      );
}

// ─── AuthOrDivider ────────────────────────────────────────────────────────────

class AuthOrDivider extends StatelessWidget {
  final bool isDark;
  const AuthOrDivider({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: Divider(
                  color: isDark
                      ? Colors.white12
                      : const Color(0xFFE8EAF0))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('OR',
                style: GoogleFonts.alexandria(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(
              child: Divider(
                  color: isDark
                      ? Colors.white12
                      : const Color(0xFFE8EAF0))),
        ],
      );
}

// ─── AuthGoogleButton ─────────────────────────────────────────────────────────

class AuthGoogleButton extends StatelessWidget {
  final bool isDark;
  final bool loading;

  const AuthGoogleButton(
      {super.key, required this.isDark, required this.loading});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: loading
              ? null
              : () => context
                  .read<AuthBloc>()
                  .add(const AuthGoogleSignInRequested()),
          icon: const Icon(Icons.g_mobiledata_rounded,
              color: AppColors.primary, size: 28),
          label: Text('Continue with Google',
              style: GoogleFonts.alexandria(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              )),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            side: BorderSide(
                color: isDark
                    ? Colors.white10
                    : const Color(0xFFE0E3ED)),
          ),
        ),
      );
}

// ─── AuthTabToggle ────────────────────────────────────────────────────────────

class AuthTabToggle extends StatelessWidget {
  final bool isDark;
  final bool isSignIn;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  const AuthTabToggle({
    super.key,
    required this.isDark,
    required this.isSignIn,
    required this.onSignIn,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.black26 : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: isSignIn
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _Tab(
                label: 'Sign In',
                active: isSignIn,
                isDark: isDark,
                onTap: onSignIn,
              ),
              _Tab(
                label: 'Sign Up',
                active: !isSignIn,
                isDark: isDark,
                onTap: onSignUp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active, isDark;
  final VoidCallback onTap;

  const _Tab(
      {required this.label,
      required this.active,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: GoogleFonts.alexandria(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: active
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkSubtext
                        : Colors.grey.shade600),
              ),
              child: Text(label),
            ),
          ),
        ),
      );
}

// ─── AuthSignInPanel ──────────────────────────────────────────────────────────

class AuthSignInPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passCtrl;
  final bool isDark, loading;
  final VoidCallback onSubmit, onForgotPassword;

  const AuthSignInPanel({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.isDark,
    required this.loading,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthField(
              key: const ValueKey('si_email'),
              ctrl: emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              icon: Iconsax.sms,
              isDark: isDark,
              type: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.\w+')
                    .hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            AuthField(
              key: const ValueKey('si_pass'),
              ctrl: passCtrl,
              label: 'Password',
              hint: 'Enter your password',
              icon: Iconsax.lock,
              isDark: isDark,
              obscure: true,
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Password is required'
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onForgotPassword,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.alexandria(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            AuthGradientButton(
                label: 'Sign In',
                loading: loading,
                onTap: loading ? null : onSubmit),
            const SizedBox(height: 20),
            AuthOrDivider(isDark: isDark),
            const SizedBox(height: 18),
            AuthGoogleButton(isDark: isDark, loading: loading),
          ],
        ),
      );
}

// ─── AuthSignUpPanel ──────────────────────────────────────────────────────────

class AuthSignUpPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, emailCtrl, passCtrl, confirmCtrl;
  final bool isDark, loading;
  final VoidCallback onSubmit;

  const AuthSignUpPanel({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.isDark,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) => Form(
        key: formKey,
        child: Column(
          children: [
            AuthField(
              key: const ValueKey('su_name'),
              ctrl: nameCtrl,
              label: 'Full Name',
              hint: 'John Doe',
              icon: Iconsax.user,
              isDark: isDark,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Name is required'
                  : null,
            ),
            AuthField(
              key: const ValueKey('su_email'),
              ctrl: emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              icon: Iconsax.sms,
              isDark: isDark,
              type: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.\w+')
                    .hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            // Strength-aware password field
            AuthPasswordStrengthField(
              key: const ValueKey('su_pass'),
              ctrl: passCtrl,
              isDark: isDark,
              label: 'Password',
              hint: 'Create a strong password',
            ),
            AuthField(
              key: const ValueKey('su_confirm'),
              ctrl: confirmCtrl,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              icon: Iconsax.lock,
              isDark: isDark,
              obscure: true,
              autovalidate: true,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Please confirm your password';
                }
                if (v != passCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 4),
            AuthGradientButton(
                label: 'Create Account',
                loading: loading,
                onTap: loading ? null : onSubmit),
            const SizedBox(height: 20),
            AuthOrDivider(isDark: isDark),
            const SizedBox(height: 18),
            AuthGoogleButton(isDark: isDark, loading: loading),
          ],
        ),
      );
}

// ─── AuthForgotPanel ──────────────────────────────────────────────────────────

class AuthForgotPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool isDark, loading;
  final VoidCallback onSubmit, onBack;

  const AuthForgotPanel({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.isDark,
    required this.loading,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Back to Sign In',
                      style: GoogleFonts.alexandria(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text('Reset Password',
                  style: GoogleFonts.alexandria(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black87,
                  )),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Enter your email and we'll send you a link to reset your password.",
                textAlign: TextAlign.center,
                style: GoogleFonts.alexandria(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),
            AuthField(
              key: const ValueKey('fp_email'),
              ctrl: emailCtrl,
              label: 'Email Address',
              hint: 'you@example.com',
              icon: Iconsax.sms,
              isDark: isDark,
              type: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.\w+')
                    .hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            AuthGradientButton(
                label: 'Send Reset Link',
                loading: loading,
                onTap: loading ? null : onSubmit),
          ],
        ),
      );
}
