import 'package:flutter/material.dart';

// ─── Rating stars ─────────────────────────────────────────────────────────────

/// A row of 5 star icons reflecting a fractional [rating].
class AppRatingStars extends StatelessWidget {
  final double rating;
  final double size;

  const AppRatingStars({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = i < rating.floor();
        final half = !full && i < rating && (rating - rating.floor()) >= 0.5;
        return Icon(
          full
              ? Icons.star_rounded
              : half
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          color: const Color(0xFFFBBF24),
          size: size,
        );
      }),
    );
  }
}
