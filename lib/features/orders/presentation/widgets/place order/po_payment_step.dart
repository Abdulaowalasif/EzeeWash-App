// lib/features/orders/presentation/widgets/place_order/po_payment_step.dart
//
// Step 5 of the place-order wizard: order summary, quantity adjuster,
// and payment method selection (COD + Stripe).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../../../core/widgets/form/app_quantity_selector.dart';
import '../../../domain/entities/place_orders_params.dart';

class PoPaymentStep extends StatelessWidget {
  final PaymentMethod selectedMethod;
  final double perPcsPrice, subtotal, serviceCharge, totalPrice;
  final int quantity;
  final bool cardAvailable, isDark;
  final String? stripeError, serviceName, storeName, pickupInfo, deliveryInfo;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final ValueChanged<int> onQuantityChanged;

  const PoPaymentStep({
    super.key,
    required this.selectedMethod,
    required this.perPcsPrice,
    required this.quantity,
    required this.subtotal,
    required this.serviceCharge,
    required this.totalPrice,
    required this.cardAvailable,
    required this.isDark,
    this.stripeError,
    this.serviceName,
    this.storeName,
    this.pickupInfo,
    this.deliveryInfo,
    required this.onMethodChanged,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Gradient summary card ──────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _SummaryLine('Service', serviceName ?? ''),
              _SummaryLine('Store', storeName ?? ''),
              _SummaryLine('Pickup', pickupInfo ?? ''),
              _SummaryLine('Delivery', deliveryInfo ?? ''),
              Padding(
                padding: const EdgeInsets.all(2),
                child: Divider(
                    color: Colors.white.withOpacity(0.1), thickness: 1),
              ),
              _SummaryLine(
                '$quantity pcs × ৳${perPcsPrice.toStringAsFixed(0)}',
                '৳${subtotal.toStringAsFixed(0)}',
              ),
              _SummaryLine(
                'Service Charge',
                '৳${serviceCharge.toStringAsFixed(0)}',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Divider(
                    color: Colors.white.withOpacity(0.25), thickness: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.alexandria(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '৳${totalPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.alexandria(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ── Quantity selector ──────────────────────────────────────────────
        AppQuantitySelector(
          quantity: quantity,
          isDark: isDark,
          priceLabel: '৳${perPcsPrice.toStringAsFixed(0)} per piece',
          onChanged: onQuantityChanged,
        ),
        const SizedBox(height: 24),
        // ── Payment method ────────────────────────────────────────────────
        Text(
          'Payment Method',
          style: GoogleFonts.alexandria(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 14),
        _PaymentOpt(
          method: PaymentMethod.cashOnDelivery,
          selected: selectedMethod == PaymentMethod.cashOnDelivery,
          isDark: isDark,
          icon: Iconsax.money_recive,
          title: 'Cash on Delivery',
          subtitle: 'Pay when your laundry is delivered',
          color: AppColors.success,
          onTap: () => onMethodChanged(PaymentMethod.cashOnDelivery),
        ),
        const SizedBox(height: 14),
        if (cardAvailable)
          _PaymentOpt(
            method: PaymentMethod.stripe,
            selected: selectedMethod == PaymentMethod.stripe,
            isDark: isDark,
            icon: Iconsax.card,
            title: 'Pay with Card',
            subtitle: 'Secure payment via Stripe',
            badge: 'Recommended',
            color: const Color(0xFF6772E5),
            onTap: () => onMethodChanged(PaymentMethod.stripe),
          )
        else
          _CardUnavailableTile(isDark: isDark),
        if (stripeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              stripeError!,
              style: GoogleFonts.alexandria(
                  color: AppColors.error, fontSize: 12),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label, value;
  const _SummaryLine(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.alexandria(
                    color: Colors.white70, fontSize: 12)),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.alexandria(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
}

class _PaymentOpt extends StatelessWidget {
  final PaymentMethod method;
  final bool selected, isDark;
  final IconData icon;
  final String title, subtitle;
  final String? badge;
  final Color color;
  final VoidCallback onTap;

  const _PaymentOpt({
    required this.method,
    required this.selected,
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.08)
                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? color
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected
                      ? color.withOpacity(0.12)
                      : (isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon,
                    color: selected
                        ? color
                        : (isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade500),
                    size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.alexandria(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppColors.lightText,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(badge!,
                                style: GoogleFonts.alexandria(
                                    fontSize: 10,
                                    color: color,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: GoogleFonts.alexandria(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext)),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? color : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? color
                        : (isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300),
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      );
}

class _CardUnavailableTile extends StatelessWidget {
  final bool isDark;
  const _CardUnavailableTile({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.grey.shade800.withOpacity(0.5)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(Iconsax.card, color: Colors.grey.shade400, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pay with Card',
                      style: GoogleFonts.alexandria(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade400)),
                  const SizedBox(height: 3),
                  Text('Requires ৳100 minimum.',
                      style: GoogleFonts.alexandria(
                          fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ],
        ),
      );
}
