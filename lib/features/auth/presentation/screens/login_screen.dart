// lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/responsive.dart';
import '../bloc/auth_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Password validation — single source of truth used by all screens
// ─────────────────────────────────────────────────────────────────────────────

class PasswordValidator {
  PasswordValidator._();

  static const int minLength = 8;

  static bool hasMinLength(String pw)   => pw.length >= minLength;
  static bool hasUppercase(String pw)   => pw.contains(RegExp(r'[A-Z]'));
  static bool hasLowercase(String pw)   => pw.contains(RegExp(r'[a-z]'));
  static bool hasDigit(String pw)       => pw.contains(RegExp(r'[0-9]'));
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

  /// Returns a user-friendly error string, or null if valid.
  /// [isSignIn]: only checks presence — lets Supabase return the real error.
  static String? validate(String? value, {bool isSignIn = false}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (isSignIn) return null;
    if (!hasMinLength(value)) return 'Must be at least $minLength characters';
    if (!hasUppercase(value)) return 'Add at least one uppercase letter (A–Z)';
    if (!hasLowercase(value)) return 'Add at least one lowercase letter (a–z)';
    if (!hasDigit(value))     return 'Add at least one number (0–9)';
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live password field with strength bar + animated rule checklist (Sign-Up)
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordStrengthField extends StatefulWidget {
  final TextEditingController ctrl;
  final bool isDark;
  final String label;
  final String hint;

  const _PasswordStrengthField({
    super.key,
    required this.ctrl,
    required this.isDark,
    this.label = 'Password',
    this.hint = 'Create a strong password',
  });

  @override
  State<_PasswordStrengthField> createState() => _PasswordStrengthFieldState();
}

class _PasswordStrengthFieldState extends State<_PasswordStrengthField> {
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  Widget build(BuildContext context) {
    final pw = widget.ctrl.text;
    final score = PasswordValidator.score(pw);
    final show = pw.isNotEmpty;

    final rules = [
      _PwRule('At least 8 characters',         PasswordValidator.hasMinLength(pw)),
      _PwRule('One uppercase letter (A–Z)',     PasswordValidator.hasUppercase(pw)),
      _PwRule('One lowercase letter (a–z)',     PasswordValidator.hasLowercase(pw)),
      _PwRule('One number (0–9)',               PasswordValidator.hasDigit(pw)),
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
              fontWeight: FontWeight.w600, fontSize: 12,
              color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
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
          validator: (v) => PasswordValidator.validate(v),
          decoration: _fieldDecoration(
            isDark: widget.isDark,
            hint: widget.hint,
            prefixIcon: Iconsax.lock,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Iconsax.eye_slash : Iconsax.eye,
                  size: 17, color: Colors.grey),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        // Strength bar (animated in/out)
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
                          color: filled ? c : c.withOpacity(0.15),
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
                      color: PasswordValidator.strengthColor(score),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Strength: ${PasswordValidator.strengthLabel(score)}',
                      style: GoogleFonts.alexandria(
                        fontSize: 12, fontWeight: FontWeight.w600,
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
        // Rule checklist (animated in/out)
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          child: show
              ? Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  .map((r) => _PwRuleRow(rule: r, isDark: widget.isDark))
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

class _PwRule {
  final String label;
  final bool met;
  const _PwRule(this.label, this.met);
}

class _PwRuleRow extends StatelessWidget {
  final _PwRule rule;
  final bool isDark;
  const _PwRuleRow({required this.rule, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = rule.met
        ? AppColors.success
        : (isDark ? AppColors.darkSubtext : const Color(0xFF94A3B8));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              rule.met ? Iconsax.tick_circle : Iconsax.minus_cirlce,
              key: ValueKey(rule.met),
              size: 14, color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rule.label,
            style: GoogleFonts.alexandria(
              fontSize: 12, color: color,
              fontWeight: rule.met ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared InputDecoration builder (keeps all field styling DRY)
// ─────────────────────────────────────────────────────────────────────────────

InputDecoration _fieldDecoration({
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
      fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF7F8FC),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );

enum _AuthView { signIn, signUp, forgotPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  _AuthView _view = _AuthView.signIn;

  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _forgotFormKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();

  final _signInEmailCtrl = TextEditingController();
  final _signInPassCtrl  = TextEditingController();

  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _forgotEmailCtrl = TextEditingController();

  late final AnimationController _slideCtrl;
  late Animation<Offset> _slideIn;
  late Animation<Offset> _slideOut;
  late Animation<double> _fadeIn;
  late Animation<double> _fadeOut;

  _AuthView? _outgoingView;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _buildAnimations(fromRight: true);
  }

  void _buildAnimations({required bool fromRight}) {
    final inBegin = fromRight ? const Offset(1.0, 0) : const Offset(-1.0, 0);
    final outEnd = fromRight ? const Offset(-1.0, 0) : const Offset(1.0, 0);

    _slideIn = Tween(begin: inBegin, end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_slideCtrl);
    _slideOut = Tween(begin: Offset.zero, end: outEnd)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_slideCtrl);
    _fadeIn = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: const Interval(0.0, 0.5)))
        .animate(_slideCtrl);
    _fadeOut = Tween(begin: 1.0, end: 0.0)
        .chain(CurveTween(curve: const Interval(0.0, 0.5)))
        .animate(_slideCtrl);
  }

  void _switchTo(_AuthView next) {
    if (_isAnimating || _view == next) return;
    final order = {_AuthView.signIn: 0, _AuthView.signUp: 1, _AuthView.forgotPassword: 2};
    final fromRight = (order[next] ?? 0) > (order[_view] ?? 0);
    _outgoingView = _view;
    _isAnimating = true;
    _buildAnimations(fromRight: fromRight);
    _slideCtrl.value = 0;
    setState(() => _view = next);
    _slideCtrl.forward().then((_) {
      setState(() {
        _outgoingView = null;
        _isAnimating = false;
      });
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _signInEmailCtrl.dispose();
    _signInPassCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _forgotEmailCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _submitSignIn() {
    if (!_signInFormKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthSignInRequested(
      email: _signInEmailCtrl.text.trim(),
      password: _signInPassCtrl.text,
    ));
  }

  void _submitSignUp() {
    if (!_signUpFormKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthSignUpRequested(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    ));
  }

  void _submitForgotPassword() {
    if (!_forgotFormKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthForgotPasswordRequested(email: _forgotEmailCtrl.text.trim()),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.alexandria(fontSize: 13)),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: error ? 4 : 3),
      ),
    );
  }

  void _showEmailConfirmDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.mark_email_read_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Check Your Email',
                style: GoogleFonts.alexandria(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              'We sent a confirmation link to\n$email\n\nPlease check your inbox and click the link to activate your account.',
              textAlign: TextAlign.center,
              style: GoogleFonts.alexandria(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 24),
            _GradientButton(
              label: 'Got it, Sign In',
              loading: false,
              onTap: () {
                Navigator.pop(context);
                _switchTo(_AuthView.signIn);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, curr) =>
      curr is AuthError ||
          curr is AuthAuthenticated ||
          curr is AuthSignedUp ||
          curr is AuthPasswordResetSent ||
          curr is AuthUnauthenticated,
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          if (state.fromSignUp) {
            _snack('Account created successfully! Welcome to EzeeWash 🎉');
          }
          return;
        }
        if (state is AuthSignedUp) {
          _showEmailConfirmDialog(state.email);
          return;
        }
        if (state is AuthPasswordResetSent) {
          _snack('Password reset email sent! Check your inbox.');
          _forgotEmailCtrl.clear();
          _switchTo(_AuthView.signIn);
          return;
        }
        if (state is AuthError) {
          _snack(state.message, error: true);
        }
      },
      builder: (ctx, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      Image.asset('assets/logo/logo.png',
                          height: 80, width: 80, fit: BoxFit.contain),
                      const SizedBox(height: 20),
                      Text(
                        'Ezze Wash',
                        style: GoogleFonts.pacifico(
                          fontSize: 34,
                          color: isDark ? Colors.white : AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          key: ValueKey(_view),
                          _view == _AuthView.signIn
                              ? 'Welcome back! Sign in to continue.'
                              : _view == _AuthView.signUp
                              ? 'Create an account to get started.'
                              : 'Enter your email to reset your password.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.alexandria(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE8EAF0),
                          ),
                          boxShadow: isDark
                              ? []
                              : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // The smoothly sliding toggle bar detached from the forms
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              alignment: Alignment.topCenter,
                              child: _view == _AuthView.forgotPassword
                                  ? const SizedBox(width: double.infinity, height: 0)
                                  : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _TabToggle(
                                    isDark: isDark,
                                    isSignIn: _view == _AuthView.signIn,
                                    onSignIn: () => _switchTo(_AuthView.signIn),
                                    onSignUp: () => _switchTo(_AuthView.signUp),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                            _buildCardContent(isDark, isLoading),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(bool isDark, bool isLoading) {
    if (_isAnimating && _outgoingView != null) {
      return Stack(
        children: [
          SlideTransition(
            position: _slideOut,
            child: FadeTransition(
              opacity: _fadeOut,
              child: _buildPanel(_outgoingView!, isDark, isLoading),
            ),
          ),
          SlideTransition(
            position: _slideIn,
            child: FadeTransition(
              opacity: _fadeIn,
              child: _buildPanel(_view, isDark, isLoading),
            ),
          ),
        ],
      );
    }
    return _buildPanel(_view, isDark, isLoading);
  }

  Widget _buildPanel(_AuthView view, bool isDark, bool isLoading) {
    switch (view) {
      case _AuthView.signIn:
        return _SignInPanel(
          key: const ValueKey('signIn'),
          formKey: _signInFormKey,
          emailCtrl: _signInEmailCtrl,
          passCtrl: _signInPassCtrl,
          isDark: isDark,
          loading: isLoading,
          onSubmit: _submitSignIn,
          onForgotPassword: () => _switchTo(_AuthView.forgotPassword),
        );
      case _AuthView.signUp:
        return _SignUpPanel(
          key: const ValueKey('signUp'),
          formKey: _signUpFormKey,
          nameCtrl: _nameCtrl,
          emailCtrl: _emailCtrl,
          passCtrl: _passCtrl,
          confirmCtrl: _confirmCtrl,
          isDark: isDark,
          loading: isLoading,
          onSubmit: _submitSignUp,
        );
      case _AuthView.forgotPassword:
        return _ForgotPasswordPanel(
          key: const ValueKey('forgot'),
          formKey: _forgotFormKey,
          emailCtrl: _forgotEmailCtrl,
          isDark: isDark,
          loading: isLoading,
          onSubmit: _submitForgotPassword,
          onBack: () => _switchTo(_AuthView.signIn),
        );
    }
  }
}

// ─── Sign In Panel ────────────────────────────────────────────────────────────

class _SignInPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool isDark;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;

  const _SignInPanel({
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
        _Field(
          key: const ValueKey('si_email'),
          ctrl: emailCtrl,
          label: 'Email',
          hint: 'you@example.com',
          icon: Iconsax.sms,
          isDark: isDark,
          obscure: false,
          type: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.\w+').hasMatch(v.trim())) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        _Field(
          key: const ValueKey('si_pass'),
          ctrl: passCtrl,
          label: 'Password',
          hint: 'Enter your password',
          icon: Iconsax.lock,
          isDark: isDark,
          obscure: true,
          validator: (v) => PasswordValidator.validate(v, isSignIn: true),
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
        _GradientButton(
          label: 'Sign In',
          loading: loading,
          onTap: loading ? null : onSubmit,
        ),
        const SizedBox(height: 20),
        _OrDivider(isDark: isDark),
        const SizedBox(height: 18),
        _GoogleButton(isDark: isDark, loading: loading),
      ],
    ),
  );
}

// ─── Sign Up Panel ────────────────────────────────────────────────────────────

class _SignUpPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final bool isDark;
  final bool loading;
  final VoidCallback onSubmit;

  const _SignUpPanel({
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
        _Field(
          key: const ValueKey('su_name'),
          ctrl: nameCtrl,
          label: 'Full Name',
          hint: 'John Doe',
          icon: Iconsax.user,
          isDark: isDark,
          validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
        ),
        _Field(
          key: const ValueKey('su_email'),
          ctrl: emailCtrl,
          label: 'Email',
          hint: 'you@example.com',
          icon: Iconsax.sms,
          isDark: isDark,
          obscure: false,
          type: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.\w+').hasMatch(v.trim())) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        _PasswordStrengthField(
          key: const ValueKey('su_pass'),
          ctrl: passCtrl,
          isDark: isDark,
          label: 'Password',
          hint: 'Create a strong password',
        ),
        _Field(
          key: const ValueKey('su_confirm'),
          ctrl: confirmCtrl,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          icon: Iconsax.lock,
          isDark: isDark,
          obscure: true,
          autovalidate: true,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your password';
            if (v != passCtrl.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 4),
        _GradientButton(
          label: 'Create Account',
          loading: loading,
          onTap: loading ? null : onSubmit,
        ),
        const SizedBox(height: 20),
        _OrDivider(isDark: isDark),
        const SizedBox(height: 18),
        _GoogleButton(isDark: isDark, loading: loading),
      ],
    ),
  );
}

// ─── Forgot Password Panel ────────────────────────────────────────────────────

class _ForgotPasswordPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool isDark;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _ForgotPasswordPanel({
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
              Text(
                'Back to Sign In',
                style: GoogleFonts.alexandria(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
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
          child: Text(
            'Reset Password',
            style: GoogleFonts.alexandria(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            "Enter your email and we'll send you a link to reset your password.",
            textAlign: TextAlign.center,
            style: GoogleFonts.alexandria(
              fontSize: 12,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _Field(
          key: const ValueKey('fp_email'),
          ctrl: emailCtrl,
          label: 'Email Address',
          hint: 'you@example.com',
          icon: Iconsax.sms,
          isDark: isDark,
          obscure: false,
          type: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.\w+').hasMatch(v.trim())) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        _GradientButton(
          label: 'Send Reset Link',
          loading: loading,
          onTap: loading ? null : onSubmit,
        ),
      ],
    ),
  );
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _TabToggle extends StatelessWidget {
  final bool isDark;
  final bool isSignIn;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  const _TabToggle({
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
        color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: isSignIn ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSignIn,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: GoogleFonts.alexandria(
                        fontWeight: FontWeight.w600, // Fixed weight to prevent layout stutter
                        fontSize: 13,
                        color: isSignIn ? Colors.white : (isDark ? AppColors.darkSubtext : Colors.grey.shade600),
                      ),
                      child: const Text('Sign In'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSignUp,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: GoogleFonts.alexandria(
                        fontWeight: FontWeight.w600, // Fixed weight to prevent layout stutter
                        fontSize: 13,
                        color: !isSignIn ? Colors.white : (isDark ? AppColors.darkSubtext : Colors.grey.shade600),
                      ),
                      child: const Text('Sign Up'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  final bool isDark;
  const _OrDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
          child: Divider(
              color:
              isDark ? Colors.white12 : const Color(0xFFE8EAF0))),
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
              color:
              isDark ? Colors.white12 : const Color(0xFFE8EAF0))),
    ],
  );
}

class _GoogleButton extends StatelessWidget {
  final bool isDark;
  final bool loading;
  const _GoogleButton({required this.isDark, required this.loading});

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
            color:
            isDark ? Colors.white10 : const Color(0xFFE0E3ED)),
      ),
    ),
  );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _GradientButton(
      {required this.label, required this.loading, this.onTap});

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
                : Text(label,
                style: GoogleFonts.alexandria(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )),
          ),
        ),
      ),
    ),
  );
}

class _Field extends StatefulWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final bool isDark;
  final bool obscure;
  final bool autovalidate;
  final TextInputType? type;
  final String? Function(String?)? validator;

  const _Field({
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
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late bool _obs;

  @override
  void initState() {
    super.initState();
    _obs = widget.obscure;
  }

  @override
  void didUpdateWidget(_Field oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscure != widget.obscure) _obs = widget.obscure;
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
        keyboardType:
        widget.obscure ? TextInputType.visiblePassword : widget.type,
        style: GoogleFonts.alexandria(fontSize: 14),
        autovalidateMode: widget.autovalidate
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        validator: widget.validator ??
                (v) => (v == null || v.isEmpty) ? 'Required' : null,
        decoration: _fieldDecoration(
          isDark: widget.isDark,
          hint: widget.hint,
          prefixIcon: widget.icon,
          suffixIcon: widget.obscure
              ? IconButton(
            icon: Icon(_obs ? Iconsax.eye_slash : Iconsax.eye,
                size: 17, color: Colors.grey),
            onPressed: () => setState(() => _obs = !_obs),
          )
              : null,
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}