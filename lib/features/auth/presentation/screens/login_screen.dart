// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/responsive.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _animCtrl.reverse().then((_) {
      setState(() {
        _isLogin = !_isLogin;
        _formKey.currentState?.reset();
        _nameCtrl.clear();
        _emailCtrl.clear();
        _passCtrl.clear();
        _confirmCtrl.clear();
      });
      _animCtrl.forward();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<AuthBloc>();
    if (_isLogin) {
      bloc.add(AuthSignInRequested(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      ));
    } else {
      if (_passCtrl.text != _confirmCtrl.text) {
        _snack('Passwords do not match.', error: true);
        return;
      }
      bloc.add(AuthSignUpRequested(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      ));
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.alexandria(fontSize: 13)),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: Duration(seconds: error ? 4 : 3),
    ));
  }

  // Shown when Supabase email confirmation is ON and signup succeeded.
  void _showEmailConfirmDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
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
            'We sent a confirmation link to\n$email\n\nPlease check your inbox (and spam folder) and click the link to activate your account.',
            textAlign: TextAlign.center,
            style: GoogleFonts.alexandria(
                fontSize: 13, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(context);
                    if (!_isLogin) _toggleMode();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text('Got it, Sign In',
                          style: GoogleFonts.alexandria(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, curr) =>
      curr is AuthError ||
          curr is AuthLoading ||
          curr is AuthAuthenticated ||
          curr is AuthSignedUp ||
          curr is AuthUnauthenticated ||
          curr is AuthInitial,
      listener: (ctx, state) {
        if (state is AuthLoading) {
          setState(() => _loading = true);
          return;
        }
        // Any terminal state (unauthenticated, error, success) clears the spinner
        setState(() => _loading = false);

        if (state is AuthAuthenticated) {
          // Email confirmation OFF — signup logged the user in directly.
          // Show success snackbar; GoRouter redirect handles navigation.
          if (!_isLogin) {
            _snack('Account created successfully! Welcome to EzeeWash 🎉');
          }
          return;
        }

        if (state is AuthSignedUp) {
          // Email confirmation ON — session not yet active.
          // Show the "check your email" dialog instead of an error.
          _showEmailConfirmDialog(state.email);
          return;
        }

        if (state is AuthError) {
          _snack(state.message, error: true);
        }
      },
      builder: (ctx, state) {
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
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(children: [
                      // ── Logo ───────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 12))
                          ],
                        ),
                        child: const Icon(Icons.local_laundry_service_rounded,
                            size: 52, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text('EzeeWash',
                          style: GoogleFonts.pacifico(
                              fontSize: 34,
                              color: isDark ? Colors.white : AppColors.primary,
                              letterSpacing: 1)),
                      const SizedBox(height: 6),
                      Text(
                        _isLogin
                            ? 'Welcome back! Sign in to continue.'
                            : 'Create an account to get started.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.alexandria(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext),
                      ),
                      const SizedBox(height: 32),

                      // ── Form card ──────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color:
                          isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFE8EAF0)),
                          boxShadow: isDark
                              ? []
                              : [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 8))
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(children: [
                            // ── Tab toggle ─────────────────────────────────────
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black26
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(children: [
                                _Tab('Sign In', _isLogin,
                                        () { if (!_isLogin) _toggleMode(); }),
                                _Tab('Sign Up', !_isLogin,
                                        () { if (_isLogin) _toggleMode(); }),
                              ]),
                            ),
                            const SizedBox(height: 24),

                            // ── Fields ─────────────────────────────────────────
                            // Each field gets a ValueKey tied to its identity so
                            // Flutter never reuses a password field's State (which
                            // has _obs = true) for the email field (obscure = false).
                            // Without keys, toggling login↔signup can cause the
                            // email field to inherit the password field's hidden state.

                            if (!_isLogin)
                              _Field(
                                key: const ValueKey('name'),
                                ctrl: _nameCtrl,
                                label: 'Full Name',
                                hint: 'John Doe',
                                icon: Iconsax.user,
                                isDark: isDark,
                                validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Name is required'
                                    : null,
                              ),

                            // ── Email — NOT obscured ───────────────────────────
                            // obscure: false + key ensures this field's _FieldState
                            // always starts with _obs = false regardless of what the
                            // password field next to it is doing.
                            _Field(
                              key: const ValueKey('email'),
                              ctrl: _emailCtrl,
                              label: 'Email',
                              hint: 'you@example.com',
                              icon: Iconsax.sms,
                              isDark: isDark,
                              obscure: false,
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

                            _Field(
                              key: const ValueKey('password'),
                              ctrl: _passCtrl,
                              label: 'Password',
                              hint: 'Min. 6 characters',
                              icon: Iconsax.lock,
                              isDark: isDark,
                              obscure: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                if (v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            if (!_isLogin)
                              _Field(
                                key: const ValueKey('confirm'),
                                ctrl: _confirmCtrl,
                                label: 'Confirm Password',
                                hint: 'Re-enter password',
                                icon: Iconsax.lock,
                                isDark: isDark,
                                obscure: true,
                                validator: (v) =>
                                (v == null || v.isEmpty)
                                    ? 'Please confirm password'
                                    : null,
                              ),

                            const SizedBox(height: 4),

                            // ── Submit ─────────────────────────────────────────
                            _GradientButton(
                              label: _isLogin ? 'Sign In' : 'Create Account',
                              loading: _loading,
                              onTap: _loading ? null : _submit,
                            ),
                            const SizedBox(height: 20),

                            // ── Divider ────────────────────────────────────────
                            Row(children: [
                              Expanded(
                                  child: Divider(
                                      color: isDark
                                          ? Colors.white12
                                          : const Color(0xFFE8EAF0))),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
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
                            ]),
                            const SizedBox(height: 18),

                            // ── Google ─────────────────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _loading
                                    ? null
                                    : () => context.read<AuthBloc>().add(
                                    const AuthGoogleSignInRequested()),
                                icon: const Icon(Icons.g_mobiledata_rounded,
                                    color: AppColors.primary, size: 28),
                                label: Text('Continue with Google',
                                    style: GoogleFonts.alexandria(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(16)),
                                  side: BorderSide(
                                      color: isDark
                                          ? Colors.white10
                                          : const Color(0xFFE0E3ED)),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab toggle ───────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: active ? AppColors.gradient : null,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.alexandria(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: active ? Colors.white : Colors.grey)),
        ),
      ),
    ),
  );
}

// ─── Gradient submit button ───────────────────────────────────────────────────

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
            offset: const Offset(0, 6))
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
                    color: Colors.white, strokeWidth: 2.5))
                : Text(label,
                style: GoogleFonts.alexandria(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ),
      ),
    ),
  );
}

// ─── Text field ───────────────────────────────────────────────────────────────

class _Field extends StatefulWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final bool isDark;
  final bool obscure;
  final TextInputType? type;
  final String? Function(String?)? validator;

  const _Field({
    super.key, // must pass key so Flutter never reuses state across fields
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.obscure = false,
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
    if (oldWidget.obscure != widget.obscure) {
      _obs = widget.obscure;
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(widget.label,
              style: GoogleFonts.alexandria(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: widget.isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext)),
        ),
        TextFormField(
          controller: widget.ctrl,
          obscureText: _obs,
          // For non-obscured fields use the provided type (e.g. emailAddress).
          // For obscured fields (password), always use visiblePassword so the
          // keyboard doesn't switch layout when the eye toggle is tapped.
          keyboardType:
          widget.obscure ? TextInputType.visiblePassword : widget.type,
          style: GoogleFonts.alexandria(fontSize: 14),
          validator: widget.validator ??
                  (v) => (v == null || v.isEmpty) ? 'Required' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(widget.icon,
                size: 19, color: AppColors.primary.withOpacity(0.7)),
            hintText: widget.hint,
            hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: widget.isDark
                ? Colors.white.withOpacity(0.04)
                : const Color(0xFFF7F8FC),
            suffixIcon: widget.obscure
                ? IconButton(
              icon: Icon(_obs ? Iconsax.eye_slash : Iconsax.eye,
                  size: 17, color: Colors.grey),
              onPressed: () => setState(() => _obs = !_obs),
            )
                : null,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: widget.isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE8EAF0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.error)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                const BorderSide(color: AppColors.error, width: 1.5)),
          ),
        ),
        const SizedBox(height: 16),
      ]);
}