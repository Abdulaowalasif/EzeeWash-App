// lib/features/onboarding/presentation/screens/onboarding_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/onboarding_prefs.dart';
import '../../../../routes/routes_name.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _bubbleController;
  late final AnimationController _entryController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      title: 'Drop it.\nWe\'ll handle\nthe rest.',
      subtitle:
      'Schedule a pickup in seconds. No queues, no hassle — just fresh, clean laundry at your door.',
      icon: Icons.local_laundry_service_rounded,
      accentAngle: -0.08,
      bubbleOffsets: [
        Offset(0.75, 0.15),
        Offset(0.1, 0.35),
        Offset(0.88, 0.55),
        Offset(0.25, 0.72),
      ],
    ),
    _OnboardingData(
      title: 'Live updates,\nevery step\nof the way.',
      subtitle:
      'Track your order in real-time — from pickup to wash to delivery. Always know where your clothes are.',
      icon: Icons.timeline_rounded,
      accentAngle: 0.06,
      bubbleOffsets: [
        Offset(0.2, 0.12),
        Offset(0.82, 0.28),
        Offset(0.05, 0.62),
        Offset(0.7, 0.75),
      ],
    ),
    _OnboardingData(
      title: 'Clean clothes.\nZero\nworries.',
      subtitle:
      'Professional care with premium detergents. Your garments treated with the attention they deserve.',
      icon: Icons.dry_cleaning_rounded,
      accentAngle: -0.05,
      bubbleOffsets: [
        Offset(0.6, 0.10),
        Offset(0.15, 0.40),
        Offset(0.85, 0.50),
        Offset(0.35, 0.80),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideUp = Tween(begin: const Offset(0, 0.12), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_entryController);

    _entryController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bubbleController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _entryController.forward(from: 0);
  }

  /// Marks the flag and navigates to login. Both Skip and Get Started call this.
  Future<void> _finishOnboarding() async {
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
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final data = _pages[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.06),
                  AppColors.lightBackground,
                  AppColors.secondary.withOpacity(0.04),
                ],
              ),
            ),
          ),

          ...data.bubbleOffsets.asMap().entries.map((entry) {
            final i = entry.key;
            final offset = entry.value;
            return _FloatingBubble(
              controller: _bubbleController,
              x: offset.dx * size.width,
              y: offset.dy * size.height,
              index: i,
            );
          }),

          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (_, index) => _PageContent(
              data: _pages[index],
              fadeIn: _fadeIn,
              slideUp: _slideUp,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomControls(
              currentPage: _currentPage,
              totalPages: _pages.length,
              onNext: _goNext,
              onSkip: _finishOnboarding,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardingData data;
  final Animation<double> fadeIn;
  final Animation<Offset> slideUp;

  const _PageContent({
    required this.data,
    required this.fadeIn,
    required this.slideUp,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: size.height * 0.12),
          FadeTransition(
            opacity: fadeIn,
            child: SlideTransition(
              position: slideUp,
              child: _IllustrationCard(data: data, size: size),
            ),
          ),
          SizedBox(height: size.height * 0.06),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: fadeIn,
            child: SlideTransition(
              position: slideUp,
              child: Text(
                data.title,
                style: GoogleFonts.alexandria(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: AppColors.lightText,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: fadeIn,
            child: SlideTransition(
              position: slideUp,
              child: Text(
                data.subtitle,
                style: GoogleFonts.alexandria(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.65,
                  color: AppColors.lightSubtext,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  final _OnboardingData data;
  final Size size;

  const _IllustrationCard({required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: data.accentAngle,
      child: Container(
        height: size.height * 0.28,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.28),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30, right: -30,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -20, left: -20,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Center(
              child: Transform.rotate(
                angle: -data.accentAngle,
                child: Icon(data.icon, size: 72, color: Colors.white.withOpacity(0.9)),
              ),
            ),
            Positioned(
              bottom: 20, right: 24,
              child: Text(
                'EzeeWash',
                style: GoogleFonts.alexandria(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.35), letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBubble extends StatelessWidget {
  final AnimationController controller;
  final double x, y;
  final int index;

  const _FloatingBubble({
    required this.controller,
    required this.x,
    required this.y,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final sizes     = [60.0, 40.0, 80.0, 50.0];
    final opacities = [0.06, 0.04, 0.05, 0.07];
    final delays    = [0.0, 0.25, 0.5, 0.75];

    final size    = sizes[index % sizes.length];
    final opacity = opacities[index % opacities.length];
    final delay   = delays[index % delays.length];

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t  = (controller.value + delay) % 1.0;
        final dy = math.sin(t * math.pi * 2) * 12;
        return Positioned(
          left: x - size / 2,
          top:  y - size / 2 + dy,
          child: Container(
            width: size, height: size,
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

class _BottomControls extends StatelessWidget {
  final int currentPage, totalPages;
  final VoidCallback onNext, onSkip;

  const _BottomControls({
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onSkip,
  });

  bool get isLast => currentPage == totalPages - 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(32, 24, 32, MediaQuery.of(context).padding.bottom + 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(totalPages, (i) {
              final isActive = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(right: 6),
                width:  isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
              );
            }),
          ),
          Row(
            children: [
              if (!isLast)
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.lightSubtext,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    textStyle: GoogleFonts.alexandria(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  child: const Text('Skip'),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isLast ? 28 : 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  elevation: 0,
                  textStyle: GoogleFonts.alexandria(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isLast ? 'Get Started' : 'Next'),
                    const SizedBox(width: 6),
                    Icon(
                      isLast ? Icons.arrow_forward_rounded : Icons.chevron_right_rounded,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String title, subtitle;
  final IconData icon;
  final double accentAngle;
  final List<Offset> bubbleOffsets;

  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentAngle,
    required this.bubbleOffsets,
  });
}