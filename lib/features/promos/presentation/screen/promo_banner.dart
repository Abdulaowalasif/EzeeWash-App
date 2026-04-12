// lib/features/promos/presentation/screen/promo_banner.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/promo_entity.dart';

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

class _PromoBannerSliderState extends State<PromoBannerSlider>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _shimmerController;
  int _currentPage = 0;
  Timer? _timer;
  List<PromoEntity> _validPromos = [];

  @override
  void initState() {
    super.initState();
    _filterPromos();
    _pageController = PageController(viewportFraction: 0.92);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant PromoBannerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.promos != widget.promos) {
      _filterPromos();
      _startTimer();
    }
  }

  void _filterPromos() {
    final now = DateTime.now();
    _validPromos = widget.promos.where((promo) {
      if (promo.validUntil == null) return true;
      return promo.validUntil!.isAfter(now);
    }).toList();

    if (_currentPage >= _validPromos.length && _validPromos.isNotEmpty) {
      _currentPage = math.max(0, _validPromos.length - 1);
    } else if (_validPromos.isEmpty) {
      _currentPage = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_validPromos.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_pageController.hasClients) {
          final next = (_currentPage + 1) % _validPromos.length;
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_validPromos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.95, // Dynamically maintains the perfect ratio on all screens
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _validPromos.length,
            itemBuilder: (ctx, i) => _PromoCard(
              promo: _validPromos[i],
              isDark: widget.isDark,
              shimmerController: _shimmerController,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _DotsIndicator(
          count: _validPromos.length,
          current: _currentPage,
          isDark: widget.isDark,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dots
// ─────────────────────────────────────────────────────────────
class _DotsIndicator extends StatelessWidget {
  final int count, current;
  final bool isDark;

  const _DotsIndicator(
      {required this.count, required this.current, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 22 : 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: active
                ? AppColors.primary
                : (isDark
                ? Colors.white.withOpacity(0.18)
                : Colors.black.withOpacity(0.12)),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Card
// ─────────────────────────────────────────────────────────────
class _PromoCard extends StatefulWidget {
  final PromoEntity promo;
  final bool isDark;
  final AnimationController shimmerController;

  const _PromoCard({
    required this.promo,
    required this.isDark,
    required this.shimmerController,
  });

  @override
  State<_PromoCard> createState() => _PromoCardState();
}

class _PromoCardState extends State<_PromoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _codeCopied = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.promo.code));
    setState(() => _codeCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _codeCopied = false);
  }

  @override
  Widget build(BuildContext context) {
    final promo = widget.promo;
    final isDark = widget.isDark;

    final discountLabel = promo.discountType == 'percentage'
        ? '${promo.discountValue.toInt()}%'
        : '৳${promo.discountValue.toInt()}';

    final serviceName = (promo.targetServiceName?.isNotEmpty ?? false)
        ? promo.targetServiceName!.toUpperCase()
        : 'SPECIAL OFFER';

    final hasImage = promo.bannerUrl != null && promo.bannerUrl!.isNotEmpty;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.40 : 0.14),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // ── Background layer ──
                _Background(
                  hasImage: hasImage,
                  bannerUrl: promo.bannerUrl,
                  isDark: isDark,
                ),

                // ── Geometric accents ──
                _GeometricAccents(isDark: isDark),

                // ── Shimmer sweep ──
                _ShimmerSweep(controller: widget.shimmerController),

                // ── Content ──
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: text block
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Service chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.30),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      serviceName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.6,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Discount hero
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          discountLabel,
                                          style: TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            height: 1.0,
                                            shadows: [
                                              Shadow(
                                                color: AppColors.primary
                                                    .withOpacity(0.5),
                                                blurRadius: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Padding(
                                          padding:
                                          const EdgeInsets.only(bottom: 8),
                                          child: Text(
                                            'OFF',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white.withOpacity(0.85),
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // Description
                                  Text(
                                    promo.description ?? 'Limited time offer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.72),
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  // Min order hint
                                  if (promo.minOrderAmount != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 11,
                                          color: Colors.white.withOpacity(0.45),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Min. order ৳${promo.minOrderAmount!.toInt()}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white.withOpacity(0.45),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Right: code pill
                        _CodePill(
                          code: promo.code,
                          copied: _codeCopied,
                          onTap: _copyCode,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Validity badge (top-right corner) ──
                if (promo.validUntil != null)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _ValidityBadge(
                        validUntil: promo.validUntil!, isDark: isDark),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────
class _Background extends StatelessWidget {
  final bool hasImage;
  final String? bannerUrl;
  final bool isDark;

  const _Background(
      {required this.hasImage, required this.bannerUrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-bleed banner image (primary background) ──
          if (hasImage)
            AppNetworkImage(
              url: bannerUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          else
          // Fallback gradient when no image provided
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                    const Color(0xFF0D1B6B),
                    const Color(0xFF1D4BC7),
                    const Color(0xFF162E8A),
                  ]
                      : [
                    const Color(0xFF1A3FA8),
                    const Color(0xFF1D4BC7),
                    const Color(0xFF2F2E98),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),

          // ── Scrim: left-to-right so text on the left is always legible ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.72),
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.10),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── Bottom vignette for depth ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Geometric accent circles
// ─────────────────────────────────────────────────────────────
class _GeometricAccents extends StatelessWidget {
  final bool isDark;

  const _GeometricAccents({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _CirclesPainter()),
    );
  }
}

class _CirclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Large decorative circle (top-right)
    canvas.drawCircle(
      Offset(size.width * 0.9, -size.height * 0.15),
      size.height * 1.0,
      paint,
    );

    // Medium circle
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.9),
      size.height * 0.55,
      paint..color = Colors.white.withOpacity(0.04),
    );

    // Small arc (bottom-left)
    final fillPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addArc(
        Rect.fromCircle(
          center: Offset(0, size.height),
          radius: size.height * 0.42,
        ),
        -math.pi / 2,
        math.pi / 2,
      )
      ..close();

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// Shimmer sweep
// ─────────────────────────────────────────────────────────────
class _ShimmerSweep extends StatelessWidget {
  final AnimationController controller;

  const _ShimmerSweep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final t = controller.value;
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment(-1.5 + t * 3.5, 0),
              end: Alignment(-0.5 + t * 3.5, 0),
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.06),
                Colors.transparent,
              ],
            ).createShader(bounds),
            child: Container(color: Colors.white),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Code pill button
// ─────────────────────────────────────────────────────────────
class _CodePill extends StatelessWidget {
  final String code;
  final bool copied;
  final VoidCallback onTap;
  final bool isDark;

  const _CodePill({
    required this.code,
    required this.copied,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: copied
              ? Colors.white.withOpacity(0.22)
              : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: copied
                ? Colors.white.withOpacity(0.6)
                : Colors.white.withOpacity(0.25),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: copied
                  ? const Icon(Icons.check_rounded,
                  key: ValueKey('check'),
                  color: Colors.white,
                  size: 18)
                  : const Icon(Icons.copy_rounded,
                  key: ValueKey('copy'),
                  color: Colors.white54,
                  size: 14),
            ),
            const SizedBox(height: 6),
            Text(
              copied ? 'COPIED' : 'USE CODE',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Validity badge
// ─────────────────────────────────────────────────────────────
class _ValidityBadge extends StatelessWidget {
  final DateTime validUntil;
  final bool isDark;

  const _ValidityBadge({required this.validUntil, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final diff = validUntil.difference(DateTime.now());
    final daysLeft = diff.inDays;
    final isExpiringSoon = daysLeft <= 3;

    final label = diff.isNegative
        ? 'Expired'
        : daysLeft == 0
        ? 'Expires today!'
        : daysLeft == 1
        ? 'Last day!'
        : '$daysLeft days left';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isExpiringSoon
            ? const Color(0xFFF59E0B).withOpacity(0.22)
            : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: isExpiringSoon
              ? const Color(0xFFF59E0B).withOpacity(0.55)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpiringSoon ? Icons.timer_outlined : Icons.calendar_today_rounded,
            size: 9,
            color: isExpiringSoon
                ? const Color(0xFFF59E0B)
                : Colors.white.withOpacity(0.65),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isExpiringSoon
                  ? const Color(0xFFF59E0B)
                  : Colors.white.withOpacity(0.65),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}