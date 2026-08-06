import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_panels.dart';

enum _AuthView { signIn, signUp, forgotPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  _AuthView _view = _AuthView.signIn;

  // Form Keys
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _forgotFormKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _signInEmailCtrl = TextEditingController();
  final _signInPassCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _forgotEmailCtrl = TextEditingController();

  // Animations
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
    final order = {
      _AuthView.signIn: 0,
      _AuthView.signUp: 1,
      _AuthView.forgotPassword: 2
    };
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

  // ─── Logic Handlers ────────────────────────────────────────────────────────

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
                
              ),
              child: const Icon(Icons.mark_email_read_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Check Your Email',
                style: AppTextStyles.heading(false).copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              'We sent a confirmation link to\n$email\n\nPlease check your inbox and click the link to activate your account.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLong(false).copyWith(fontSize: 13),
            ),
            const SizedBox(height: 24),
            AppGradientButton(
              label: 'Got it, Sign In',
              onPressed: () {
                Navigator.pop(context);
                _switchTo(_AuthView.signIn);
              },
              borderRadius: 16,
              verticalPadding: 16,
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
            AppSnackBar.show(ctx,
                'Account created successfully! Welcome to EzeeWash 🎉');
          }
          return;
        }
        if (state is AuthSignedUp) {
          _showEmailConfirmDialog(state.email);
          return;
        }
        if (state is AuthPasswordResetSent) {
          AppSnackBar.show(
              ctx, 'Password reset email sent! Check your inbox.');
          _forgotEmailCtrl.clear();
          _switchTo(_AuthView.signIn);
          return;
        }
        if (state is AuthError) {
          AppSnackBar.show(ctx, state.message, type: SnackBarType.error);
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
                      _HeaderSection(isDark: isDark, view: _view),
                      const SizedBox(height: 32),
                      _AuthCard(
                        isDark: isDark,
                        view: _view,
                        isLoading: isLoading,
                        isAnimating: _isAnimating,
                        outgoingView: _outgoingView,
                        slideIn: _slideIn,
                        slideOut: _slideOut,
                        fadeIn: _fadeIn,
                        fadeOut: _fadeOut,
                        onSwitchTo: _switchTo,
                        buildPanel: _buildPanel,
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

  Widget _buildPanel(_AuthView view, bool isDark, bool isLoading) {
    switch (view) {
      case _AuthView.signIn:
        return AuthSignInPanel(
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
        return AuthSignUpPanel(
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
        return AuthForgotPanel(
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

// ─── Extracted Components ─────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final bool isDark;
  final _AuthView view;

  const _HeaderSection({required this.isDark, required this.view});

  @override
  Widget build(BuildContext context) {
    return Column(
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
            key: ValueKey(view),
            view == _AuthView.signIn
                ? 'Welcome back! Sign in to continue.'
                : view == _AuthView.signUp
                ? 'Create an account to get started.'
                : 'Enter your email to reset your password.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle(isDark).copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _AuthCard extends StatelessWidget {
  final bool isDark;
  final _AuthView view;
  final bool isLoading;
  final bool isAnimating;
  final _AuthView? outgoingView;
  final Animation<Offset> slideIn;
  final Animation<Offset> slideOut;
  final Animation<double> fadeIn;
  final Animation<double> fadeOut;
  final Function(_AuthView) onSwitchTo;
  final Widget Function(_AuthView, bool, bool) buildPanel;

  const _AuthCard({
    required this.isDark,
    required this.view,
    required this.isLoading,
    required this.isAnimating,
    required this.outgoingView,
    required this.slideIn,
    required this.slideOut,
    required this.fadeIn,
    required this.fadeOut,
    required this.onSwitchTo,
    required this.buildPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE8EAF0),
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
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: view == _AuthView.forgotPassword
                ? const SizedBox(width: double.infinity, height: 0)
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthTabToggle(
                  isDark: isDark,
                  isSignIn: view == _AuthView.signIn,
                  onSignIn: () => onSwitchTo(_AuthView.signIn),
                  onSignUp: () => onSwitchTo(_AuthView.signUp),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildAnimatedContent(),
        ],
      ),
    );
  }

  Widget _buildAnimatedContent() {
    if (isAnimating && outgoingView != null) {
      return Stack(
        children: [
          SlideTransition(
            position: slideOut,
            child: FadeTransition(
              opacity: fadeOut,
              child: buildPanel(outgoingView!, isDark, isLoading),
            ),
          ),
          SlideTransition(
            position: slideIn,
            child: FadeTransition(
              opacity: fadeIn,
              child: buildPanel(view, isDark, isLoading),
            ),
          ),
        ],
      );
    }
    return buildPanel(view, isDark, isLoading);
  }
}