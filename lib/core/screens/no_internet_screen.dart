// lib/core/screens/no_internet_screen.dart
//
// Refactored: AppTextStyles replaces GoogleFonts inline calls.
// AppGradientButton replaces inline gradient ElevatedButton.

import 'package:flutter/material.dart';
import '../constants/app_color.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_widgets.dart';

class NoInternetScreen extends StatefulWidget {
  final bool isDarkMode;
  const NoInternetScreen({super.key, required this.isDarkMode});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
          parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          width: 1.5),
                      
                    ),
                    child: const Icon(Icons.wifi_off_rounded,
                        size: 48, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'No Connection Found',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading(isDark).copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your internet connection is currently unstable.\nPlease check your settings and try again.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLong(isDark).copyWith(fontSize: 15),
                ),
                const SizedBox(height: 48),
                AppGradientButton(
                  label: 'Try Again',
                  onPressed: _isRetrying ? null : _retry,
                  isLoading: _isRetrying,
                  verticalPadding: 16,
                  borderRadius: 16,
                ),
                const SizedBox(height: 20),
                Text(
                  'Automatically reconnecting...',
                  style: AppTextStyles.caption(isDark).copyWith(
                    fontStyle: FontStyle.italic,
                    color: (isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext)
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
