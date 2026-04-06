// lib/core/widgets/form/app_quantity_selector.dart
//
// A +/- quantity stepper row used in the place_order payment step.
// Min/max clamped; buttons use gradient when active.
//
// Usage:
//   AppQuantitySelector(
//     quantity: _quantity,
//     priceLabel: '৳30 per piece',
//     isDark: isDark,
//     onChanged: (q) => setState(() => _quantity = q),
//   )

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_color.dart';

class AppQuantitySelector extends StatelessWidget {
  final int quantity;
  final int min;
  final int max;
  final String? title;
  final String? priceLabel;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const AppQuantitySelector({
    super.key,
    required this.quantity,
    required this.isDark,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.title = 'Number of Pieces',
    this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: GoogleFonts.alexandria(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          if (priceLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              priceLabel!,
              style: GoogleFonts.alexandria(
                  fontSize: 12, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _QtyBtn(
                icon: Icons.remove_rounded,
                enabled: quantity > min,
                isDark: isDark,
                onTap: () => onChanged(quantity - 1),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$quantity',
                    style: GoogleFonts.alexandria(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _QtyBtn(
                icon: Icons.add_rounded,
                enabled: quantity < max,
                isDark: isDark,
                onTap: () => onChanged(quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;

  const _QtyBtn({
    required this.icon,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: enabled ? AppColors.gradient : null,
            color: enabled
                ? null
                : (isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: enabled ? Colors.white : Colors.grey.shade400,
            size: 22,
          ),
        ),
      );
}
