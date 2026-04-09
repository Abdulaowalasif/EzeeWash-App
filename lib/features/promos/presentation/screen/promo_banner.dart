// lib/features/home/presentation/widgets/promo_banner_slider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/promo_entity.dart'; // Import your network image widget

class PromoBannerSlider extends StatefulWidget {
  final List<PromoEntity> promos;
  final bool isDark;

  const PromoBannerSlider({
    super.key,
    required this.promos,
    required this.isDark,
  });

  @override
  State<PromoBannerSlider> createState() => _PromoBannerSliderState();
}

class _PromoBannerSliderState extends State<PromoBannerSlider> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.promos.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_pageController.hasClients) {
          int nextPage = (_currentPage + 1) % widget.promos.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.fastOutSlowIn,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 170, // Slightly taller for better image visibility
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.promos.length,
            itemBuilder: (context, index) =>
                _PromoCard(promo: widget.promos[index], isDark: widget.isDark),
          ),
        ),
        const SizedBox(height: 12),
        _buildIndicators(),
      ],
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.promos.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 5,
          width: _currentPage == index ? 18 : 5,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.primary
                : (widget.isDark ? Colors.white24 : Colors.black12),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final PromoEntity promo;
  final bool isDark;

  const _PromoCard({required this.promo, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ─── BACKGROUND IMAGE ──────────────────────────────────────────
            Positioned.fill(
              child: promo.bannerUrl != null && promo.bannerUrl!.isNotEmpty
                  ? AppNetworkImage(
                      url: promo.bannerUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                    )
                  : Container(color: AppColors.primary.withOpacity(0.1)),
            ),

            // ─── DARK OVERLAY (Ensures text readability) ──────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      // Darker on the left for text
                      Colors.black.withOpacity(0.2),
                      // Lighter on the right to see image
                    ],
                  ),
                ),
              ),
            ),

            // ─── CONTENT ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "EXCLUSIVE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          promo.discountType == 'percentage'
                              ? '${promo.discountValue.toInt()}% OFF'
                              : '\$${promo.discountValue.toInt()} OFF',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          promo.description ?? "Special laundry offer",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Promo Code Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "CODE",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          promo.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
