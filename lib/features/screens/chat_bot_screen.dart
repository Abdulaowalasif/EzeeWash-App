// lib/features/profile/screens/settings/chat_bot_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../core/constants/app_color.dart';
import '../../core/utils/revponsive.dart';

class ChatBotScreen extends StatelessWidget {
  const ChatBotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _GradientAppBar(),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          Responsive.horizontalPadding(context), 0,
          Responsive.horizontalPadding(context), 20,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1.5),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(
                      height: 200,
                      child: Lottie.asset(
                        'assets/animations/bot.json',
                        fit: BoxFit.contain,
                        frameRate: FrameRate.composition,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradient,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('Something Exciting is Brewing!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.alexandria(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightText)),
                    const SizedBox(height: 14),
                    Text('Bubble Bot is currently being trained to provide lightning-fast support and laundry tips. We\'ll be live very soon!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.alexandria(fontSize: 14, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, height: 1.6)),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: const [
                        _FeaturePill(label: '🧺  Order Tracking'),
                        _FeaturePill(label: '❓  24/7 Support'),
                        _FeaturePill(label: '💡  Laundry Tips'),
                        _FeaturePill(label: '📦  Order Help'),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Text('Feature Coming Soon',
                          style: GoogleFonts.alexandria(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _GradientAppBar();
  @override
  Size get preferredSize => const Size.fromHeight(100);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 10, Responsive.horizontalPadding(context), 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Row(children: [
          GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 14),
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Text('Bubble Bot', style: GoogleFonts.alexandria(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.success.withOpacity(0.4))),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('Soon', style: GoogleFonts.alexandria(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String label;
  const _FeaturePill({required this.label});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Text(label, style: GoogleFonts.alexandria(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : AppColors.lightText)),
    );
  }
}