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
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 1. Background Image
            Positioned.fill(
              child: promo.bannerUrl != null && promo.bannerUrl!.isNotEmpty
                  ? AppNetworkImage(
                url: promo.bannerUrl!,
                fit: BoxFit.cover, width: double.infinity, height:200,
              )
                  : Container(color: AppColors.primary.withOpacity(0.2)),
            ),

            // 2. Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 3. Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // --- SERVICE NAME ---
                        // Showing "General Service" if the data is null/empty
                        Text(
                          (promo.targetServiceName != null && promo.targetServiceName!.isNotEmpty)
                              ? promo.targetServiceName!.toUpperCase()
                              : "GENERAL SERVICE",
                          style: TextStyle(
                            color: AppColors.primary, // Using primary color for name
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // --- DISCOUNT AMOUNT ---
                        Text(
                          promo.discountType == 'percentage'
                              ? '${promo.discountValue.toInt()}% OFF'
                              : '\$${promo.discountValue.toInt()} OFF',
                          style: const TextStyle(
                            fontSize: 32, // Increased size
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // --- DESCRIPTION ---
                        Text(
                          promo.description ?? "Limited time offer",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // --- PROMO CODE BOX ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "CODE",
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                        Text(
                          promo.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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