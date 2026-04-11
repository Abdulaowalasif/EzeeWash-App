// lib/features/onboarding/presentation/screen/onboarding_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/onboarding_prefs.dart';
import '../../../../routes/routes_name.dart';

// ─────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────
class _OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String tag;
  final List<Offset> bubbleOffsets;

  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tag,
    required this.bubbleOffsets,
  });
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _floatController;
  late final AnimationController _particleController;
  late final AnimationController _textController;
  late final AnimationController _cardController;
  late final AnimationController _rippleController;

  late Animation<double> _chipFade, _titleFade, _subtitleFade;
  late Animation<double> _chipSlide, _titleSlideY, _subtitleSlideY;
  late Animation<double> _cardScale, _cardFade;
  late Animation<double> _iconSpin, _iconScale;
  late Animation<double> _rippleRadius, _rippleOpacity;

  static const _pages = [
    _OnboardingData(
      title: 'Drop it.\nWe\'ll handle\nthe rest.',
      subtitle:
      'Schedule a pickup in seconds. No queues, no hassle — just fresh, clean laundry at your door.',
      icon: Icons.local_laundry_service_rounded,
      tag: 'PICKUP',
      bubbleOffsets: [
        Offset(0.80, 0.08),
        Offset(0.06, 0.28),
        Offset(0.88, 0.50),
        Offset(0.20, 0.68),
        Offset(0.52, 0.80),
      ],
    ),
    _OnboardingData(
      title: 'Live updates,\nevery step\nof the way.',
      subtitle:
      'Track your order in real-time — from pickup to wash to delivery. Always know where your clothes are.',
      icon: Icons.timeline_rounded,
      tag: 'TRACKING',
      bubbleOffsets: [
        Offset(0.18, 0.09),
        Offset(0.84, 0.24),
        Offset(0.03, 0.56),
        Offset(0.70, 0.70),
        Offset(0.38, 0.86),
      ],
    ),
    _OnboardingData(
      title: 'Clean clothes.\nZero\nworries.',
      subtitle:
      'Professional care with premium detergents. Your garments treated with the attention they deserve.',
      icon: Icons.dry_cleaning_rounded,
      tag: 'CARE',
      bubbleOffsets: [
        Offset(0.63, 0.07),
        Offset(0.11, 0.36),
        Offset(0.86, 0.46),
        Offset(0.28, 0.76),
        Offset(0.73, 0.87),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Text stagger intervals
    _chipFade = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textController,
            curve: const Interval(0.00, 0.45, curve: Curves.easeOut)));
    _chipSlide = Tween(begin: 18.0, end: 0.0).animate(
        CurvedAnimation(parent: _textController,
            curve: const Interval(0.00, 0.45, curve: Curves.easeOutCubic)));
    _titleFade = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textController,
            curve: const Interval(0.22, 0.68, curve: Curves.easeOut)));
    _titleSlideY = Tween(begin: 24.0, end: 0.0).animate(
        CurvedAnimation(parent: _textController,
            curve: const Interval(0.22, 0.68, curve: Curves.easeOutCubic)));
    _subtitleFade = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textController,
            curve: const Interval(0.44, 1.00, curve: Curves.easeOut)));
    _subtitleSlideY = Tween(begin: 18.0, end: 0.0).animate(
        CurvedAnimation(parent: _textController,
            curve: const Interval(0.44, 1.00, curve: Curves.easeOutCubic)));

    // Card entry
    _cardScale = Tween(begin: 0.84, end: 1.0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack));
    _cardFade = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _cardController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _iconSpin = Tween(begin: -0.25, end: 0.0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));
    _iconScale = Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack));

    // Ripple
    _rippleRadius = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _rippleController, curve: Curves.easeOut));
    _rippleOpacity = Tween(begin: 0.40, end: 0.0).animate(
        CurvedAnimation(parent: _rippleController, curve: Curves.easeIn));

    _playPageAnimations();
  }

  void _playPageAnimations() {
    _textController.forward(from: 0);
    _cardController.forward(from: 0);
    _rippleController.forward(from: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _particleController.dispose();
    _textController.dispose();
    _cardController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    HapticFeedback.selectionClick();
    _playPageAnimations();
  }

  Future<void> _finish() async {
    await OnboardingPrefs.markOnboardingSeen();
    if (mounted) context.go(RoutesName.login);
  }

  void _goNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final data = _pages[_currentPage];
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            _AmbientBackground(isDark: isDark, pageIndex: _currentPage),

            // Particle trails
            ...List.generate(8, (i) => _ParticleTrail(
              controller: _particleController,
              index: i,
              size: size,
              isDark: isDark,
            )),

            // Floating bubbles
            ...data.bubbleOffsets.asMap().entries.map((e) => _FloatingBubble(
              controller: _floatController,
              x: e.value.dx * size.width,
              y: e.value.dy * size.height,
              index: e.key,
              isDark: isDark,
            )),

            // Pages
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (_, i) => _PageContent(
                data: _pages[i],
                chipFade: _chipFade,
                chipSlide: _chipSlide,
                titleFade: _titleFade,
                titleSlideY: _titleSlideY,
                subtitleFade: _subtitleFade,
                subtitleSlideY: _subtitleSlideY,
                cardScale: _cardScale,
                cardFade: _cardFade,
                iconSpin: _iconSpin,
                iconScale: _iconScale,
                rippleRadius: _rippleRadius,
                rippleOpacity: _rippleOpacity,
                isDark: isDark,
                size: size,
              ),
            ),

            // Bottom controls
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _BottomControls(
                currentPage: _currentPage,
                totalPages: _pages.length,
                isDark: isDark,
                surfaceColor: surfaceColor,
                onNext: _goNext,
                onSkip: _finish,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Ambient background
// ─────────────────────────────────────────────────────────────
class _AmbientBackground extends StatelessWidget {
  final bool isDark;
  final int pageIndex;

  const _AmbientBackground({required this.isDark, required this.pageIndex});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.6, -0.5),
            radius: 1.2,
            colors: isDark
                ? [
              Color.lerp(AppColors.darkBackground, AppColors.primary,
                  0.08 + pageIndex * 0.03)!,
              AppColors.darkBackground,
            ]
                : [
              Color.lerp(AppColors.lightBackground, AppColors.primary,
                  0.05 + pageIndex * 0.02)!,
              AppColors.lightBackground,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Particle trail — tiny dots drifting upward
// ─────────────────────────────────────────────────────────────
class _ParticleTrail extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Size size;
  final bool isDark;

  const _ParticleTrail({
    required this.controller,
    required this.index,
    required this.size,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final phase = index / 8.0;
    final xFrac = 0.06 + (index * 0.115) % 0.88;
    final particleSize = 3.0 + (index % 3) * 2.0;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = (controller.value + phase) % 1.0;
        final y = size.height * (0.92 - t * 0.84);
        final x = size.width * xFrac +
            math.sin(t * math.pi * 2 + phase * math.pi) * 16;
        final opacity = t < 0.15
            ? (t / 0.15) * (isDark ? 0.22 : 0.13)
            : t > 0.75
            ? ((1 - t) / 0.25) * (isDark ? 0.22 : 0.13)
            : (isDark ? 0.22 : 0.13);

        return Positioned(
          left: x - particleSize / 2,
          top: y - particleSize / 2,
          child: Container(
            width: particleSize,
            height: particleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(opacity),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Floating bubbles
// ─────────────────────────────────────────────────────────────
class _FloatingBubble extends StatelessWidget {
  final AnimationController controller;
  final double x, y;
  final int index;
  final bool isDark;

  const _FloatingBubble({
    required this.controller,
    required this.x,
    required this.y,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const sizes = [58.0, 38.0, 74.0, 46.0, 30.0];
    const delays = [0.0, 0.20, 0.45, 0.65, 0.85];
    final sz = sizes[index % sizes.length];
    final delay = delays[index % delays.length];

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = (controller.value + delay) % 1.0;
        final dy = math.sin(t * math.pi * 2) * 12;
        final dx = math.cos(t * math.pi) * 5;
        return Positioned(
          left: x - sz / 2 + dx,
          top: y - sz / 2 + dy,
          child: Container(
            width: sz, height: sz,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.05),
              border: Border.all(
                color: AppColors.primary.withOpacity(isDark ? 0.14 : 0.09),
                width: 1,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Page content
// ─────────────────────────────────────────────────────────────
class _PageContent extends StatelessWidget {
  final _OnboardingData data;
  final Animation<double> chipFade, titleFade, subtitleFade;
  final Animation<double> chipSlide, titleSlideY, subtitleSlideY;
  final Animation<double> cardScale, cardFade, iconSpin, iconScale;
  final Animation<double> rippleRadius, rippleOpacity;
  final bool isDark;
  final Size size;

  const _PageContent({
    required this.data,
    required this.chipFade,
    required this.chipSlide,
    required this.titleFade,
    required this.titleSlideY,
    required this.subtitleFade,
    required this.subtitleSlideY,
    required this.cardScale,
    required this.cardFade,
    required this.iconSpin,
    required this.iconScale,
    required this.rippleRadius,
    required this.rippleOpacity,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtextColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: size.height * 0.10),

          // Illustration card
          ScaleTransition(
            scale: cardScale,
            child: FadeTransition(
              opacity: cardFade,
              child: _IllustrationCard(
                data: data,
                size: size,
                isDark: isDark,
                iconSpin: iconSpin,
                iconScale: iconScale,
                rippleRadius: rippleRadius,
                rippleOpacity: rippleOpacity,
              ),
            ),
          ),

          SizedBox(height: size.height * 0.052),

          // Tag chip
          AnimatedBuilder(
            animation: chipFade,
            builder: (_, child) => Opacity(
              opacity: chipFade.value,
              child: Transform.translate(
                offset: Offset(0, chipSlide.value),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(isDark ? 0.16 : 0.09),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: AppColors.primary.withOpacity(isDark ? 0.28 : 0.20),
                ),
              ),
              child: Text(
                data.tag,
                style: GoogleFonts.alexandria(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Title
          AnimatedBuilder(
            animation: titleFade,
            builder: (_, child) => Opacity(
              opacity: titleFade.value,
              child: Transform.translate(
                offset: Offset(0, titleSlideY.value),
                child: child,
              ),
            ),
            child: Text(
              data.title,
              style: GoogleFonts.alexandria(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 1.12,
                color: textColor,
                letterSpacing: -0.8,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          AnimatedBuilder(
            animation: subtitleFade,
            builder: (_, child) => Opacity(
              opacity: subtitleFade.value,
              child: Transform.translate(
                offset: Offset(0, subtitleSlideY.value),
                child: child,
              ),
            ),
            child: Text(
              data.subtitle,
              style: GoogleFonts.alexandria(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.68,
                color: subtextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Illustration card
// ─────────────────────────────────────────────────────────────
class _IllustrationCard extends StatelessWidget {
  final _OnboardingData data;
  final Size size;
  final bool isDark;
  final Animation<double> iconSpin, iconScale;
  final Animation<double> rippleRadius, rippleOpacity;

  const _IllustrationCard({
    required this.data,
    required this.size,
    required this.isDark,
    required this.iconSpin,
    required this.iconScale,
    required this.rippleRadius,
    required this.rippleOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size.height * 0.30,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF182FA0), AppColors.primary, AppColors.secondary]
              : [AppColors.primary, AppColors.secondary, const Color(0xFF1A2580)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isDark ? 0.45 : 0.28),
            blurRadius: 48,
            offset: const Offset(0, 20),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Mesh circles
            Positioned(
              top: -40, right: -40,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -30, left: -30,
              child: Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Grid
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),

            // Ripple burst
            AnimatedBuilder(
              animation: rippleRadius,
              builder: (_, __) => Positioned.fill(
                child: CustomPaint(
                  painter: _RipplePainter(
                    progress: rippleRadius.value,
                    opacity: rippleOpacity.value,
                  ),
                ),
              ),
            ),

            // Icon with spin + scale
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([iconSpin, iconScale]),
                builder: (_, child) => Transform.rotate(
                  angle: iconSpin.value * math.pi * 2,
                  child: Transform.scale(scale: iconScale.value, child: child),
                ),
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.20),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(data.icon, size: 52,
                      color: Colors.white.withOpacity(0.95)),
                ),
              ),
            ),

            // Tag
            Positioned(
              bottom: 16, left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: Text(data.tag,
                    style: GoogleFonts.alexandria(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 1.8,
                    )),
              ),
            ),

            // Wordmark
            Positioned(
              bottom: 18, right: 20,
              child: Text('EzeeWash',
                  style: GoogleFonts.alexandria(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.28),
                    letterSpacing: 1.0,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Ripple burst painter
// ─────────────────────────────────────────────────────────────
class _RipplePainter extends CustomPainter {
  final double progress;
  final double opacity;

  const _RipplePainter({required this.progress, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || opacity <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.sqrt(
        size.width * size.width + size.height * size.height) / 2;

    for (int i = 0; i < 3; i++) {
      final phase = (progress - i * 0.18).clamp(0.0, 1.0);
      if (phase <= 0) continue;
      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity * (1 - phase) * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, maxR * phase, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress || old.opacity != opacity;
}

// ─────────────────────────────────────────────────────────────
// Grid painter
// ─────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.8;
    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────
// Bottom controls
// ─────────────────────────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  final int currentPage, totalPages;
  final bool isDark;
  final Color surfaceColor;
  final VoidCallback onNext, onSkip;

  const _BottomControls({
    required this.currentPage,
    required this.totalPages,
    required this.isDark,
    required this.surfaceColor,
    required this.onNext,
    required this.onSkip,
  });

  bool get isLast => currentPage == totalPages - 1;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final subtextColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(isDark ? 0.85 : 0.92),
        border: Border(top: BorderSide(color: borderColor, width: 0.8)),
      ),
      padding: EdgeInsets.fromLTRB(
          28, 20, 28, MediaQuery.of(context).padding.bottom + 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: List.generate(totalPages, (i) {
              final active = i == currentPage;
              final passed = i < currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                margin: const EdgeInsets.only(right: 7),
                width: active ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : passed
                      ? AppColors.primary.withOpacity(0.40)
                      : AppColors.primary
                      .withOpacity(isDark ? 0.18 : 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLast
                    ? const SizedBox.shrink()
                    : TextButton(
                  key: const ValueKey('skip'),
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: subtextColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    textStyle: GoogleFonts.alexandria(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isLast ? 26 : 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                  elevation: isDark ? 0 : 2,
                  shadowColor: AppColors.primary.withOpacity(0.35),
                  textStyle: GoogleFonts.alexandria(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    key: ValueKey(isLast),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isLast ? 'Get Started' : 'Next'),
                      const SizedBox(width: 6),
                      Icon(
                        isLast
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        size: 16,
                      ),
                    ],
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