// lib/features/orders/presentation/widgets/place order/po_payment_step.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../../../core/widgets/form/app_quantity_selector.dart';
import '../../../domain/entities/place_orders_params.dart';

class PoPaymentStep extends StatefulWidget {
  final PaymentMethod selectedMethod;
  final double perPcsPrice, subtotal, serviceCharge, totalPrice;
  final double discountAmount;
  final int quantity;
  final bool cardAvailable, isDark;
  final String? stripeError, serviceName, storeName, pickupInfo, deliveryInfo;
  final String? appliedCoupon;
  final String? selectedSize;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String>? onSizeChanged;
  final Future<String?> Function(String code) onApplyCoupon;
  final VoidCallback onRemoveCoupon;

  const PoPaymentStep({
    super.key,
    required this.selectedMethod,
    required this.perPcsPrice,
    required this.quantity,
    required this.subtotal,
    required this.serviceCharge,
    required this.totalPrice,
    required this.discountAmount,
    required this.cardAvailable,
    required this.isDark,
    this.stripeError,
    this.serviceName,
    this.storeName,
    this.pickupInfo,
    this.deliveryInfo,
    this.appliedCoupon,
    this.selectedSize,
    required this.onMethodChanged,
    required this.onQuantityChanged,
    this.onSizeChanged,
    required this.onApplyCoupon,
    required this.onRemoveCoupon,
  });

  @override
  State<PoPaymentStep> createState() => _PoPaymentStepState();
}

class _PoPaymentStepState extends State<PoPaymentStep> {
  final _couponCtrl = TextEditingController();
  bool _couponLoading = false;
  String? _couponError;

  @override
  void initState() {
    super.initState();
    if (widget.appliedCoupon != null) {
      _couponCtrl.text = widget.appliedCoupon!;
    }
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    FocusScope.of(context).unfocus(); // Dismiss keyboard
    final code = _couponCtrl.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() => _couponError = 'Please enter a valid code.');
      return;
    }

    setState(() {
      _couponLoading = true;
      _couponError = null;
    });

    final error = await widget.onApplyCoupon(code);

    if (mounted) {
      setState(() {
        _couponLoading = false;
        _couponError = error;
      });
    }
  }

  void _remove() {
    _couponCtrl.clear();
    setState(() => _couponError = null);
    widget.onRemoveCoupon();
  }

  bool get _isApplied => widget.appliedCoupon != null;

  @override
  Widget build(BuildContext context) {
    final bool isShoeClean = widget.serviceName?.toLowerCase().contains('shoe') ?? false;
    final bool isComforterClean = widget.serviceName?.toLowerCase().contains('comfort') ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Gradient Summary Card ──────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(24),
            
          ),
          child: Column(
            children: [
              _SummaryLine('Service', widget.serviceName ?? ''),
              _SummaryLine('Store', widget.storeName ?? ''),
              _SummaryLine('Pickup', widget.pickupInfo ?? ''),
              _SummaryLine('Delivery', widget.deliveryInfo ?? ''),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Colors.white.withOpacity(0.15), thickness: 1),
              ),
              _SummaryLine(
                '${widget.quantity} ${isShoeClean ? 'pairs' : 'pcs'} × ৳${widget.perPcsPrice.toStringAsFixed(0)}',
                '৳${widget.subtotal.toStringAsFixed(0)}',
              ),
              _SummaryLine(
                'Service Charge',
                '৳${widget.serviceCharge.toStringAsFixed(0)}',
              ),
              if (_isApplied && widget.discountAmount > 0)
                _SummaryLine(
                  'Discount (${widget.appliedCoupon})',
                  '− ৳${widget.discountAmount.toStringAsFixed(0)}',
                  valueColor: const Color(0xFF2ECC71), // Vibrant Green
                  isBold: true,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Colors.white.withOpacity(0.25), thickness: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.alexandria(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '৳${widget.totalPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.alexandria(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Coupon / Promo Input ───────────────────────────────────────────
        Text(
          'Promo Code',
          style: GoogleFonts.alexandria(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.isDark ? Colors.white : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 12),

        // Animated transition between Input mode and Applied mode
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _isApplied
              ? _AppliedCouponTicket(
            key: const ValueKey('applied'),
            code: widget.appliedCoupon!,
            discountAmount: widget.discountAmount,
            isDark: widget.isDark,
            onRemove: _remove,
          )
              : _CouponInputField(
            key: const ValueKey('input'),
            controller: _couponCtrl,
            isDark: widget.isDark,
            isLoading: _couponLoading,
            hasError: _couponError != null,
            onApply: _apply,
          ),
        ),

        // Error Message display
        if (_couponError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                const Icon(Iconsax.info_circle, color: AppColors.error, size: 16),
                const SizedBox(width: 6),
                Text(
                  _couponError!,
                  style: GoogleFonts.alexandria(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 28),

        if (isComforterClean) ...[
          Text(
            'Select Size',
            style: GoogleFonts.alexandria(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              {'name': 'Single', 'dim': '50 x 80 in'},
              {'name': 'Twin XL', 'dim': '68 x 90 in'},
              {'name': 'Double', 'dim': '78 x 86 in'},
              {'name': 'Queen', 'dim': '90 x 90 in'},
              {'name': 'King', 'dim': '104 x 92 in'},
            ].map((item) {
              final size = item['name']!;
              final dim = item['dim']!;
              final isSelected = widget.selectedSize == size;
              return GestureDetector(
                onTap: () => widget.onSizeChanged?.call(size),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 20 : 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (widget.isDark ? AppColors.darkSurface : AppColors.lightSurface),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
                  child: Text(
                    isSelected ? '$size ($dim)' : size,
                    style: GoogleFonts.alexandria(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (widget.isDark ? Colors.white70 : AppColors.lightText),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
        ],

        // ── Quantity Selector ──────────────────────────────────────────────
        AppQuantitySelector(
          quantity: widget.quantity,
          isDark: widget.isDark,
          title: isShoeClean ? 'Select Pair' : 'Number of Pieces',
          priceLabel: '৳${widget.perPcsPrice.toStringAsFixed(0)} per ${isShoeClean ? 'pair' : 'piece'}',
          onChanged: widget.onQuantityChanged,
        ),

        const SizedBox(height: 28),

        // ── Payment Method ────────────────────────────────────────────────
        Text(
          'Payment Method',
          style: GoogleFonts.alexandria(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.isDark ? Colors.white : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 14),
        _PaymentOpt(
          method: PaymentMethod.cashOnDelivery,
          selected: widget.selectedMethod == PaymentMethod.cashOnDelivery,
          isDark: widget.isDark,
          icon: Iconsax.money_recive,
          title: 'Cash on Delivery',
          subtitle: 'Pay when your laundry is delivered',
          color: AppColors.success,
          onTap: () => widget.onMethodChanged(PaymentMethod.cashOnDelivery),
        ),
        const SizedBox(height: 14),

        if (widget.cardAvailable)
          _PaymentOpt(
            method: PaymentMethod.stripe,
            selected: widget.selectedMethod == PaymentMethod.stripe,
            isDark: widget.isDark,
            icon: Iconsax.card,
            title: 'Pay with Card',
            subtitle: 'Secure payment via Stripe',
            badge: 'Recommended',
            color: const Color(0xFF6772E5),
            onTap: () => widget.onMethodChanged(PaymentMethod.stripe),
          )
        else
          _CardUnavailableTile(isDark: widget.isDark),

        if (widget.stripeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                const Icon(Iconsax.warning_2, color: AppColors.error, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.stripeError!,
                    style: GoogleFonts.alexandria(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),
      ],
    );
  }
}

// ── NEW: Professional Applied Coupon Ticket ───────────────────────────────────

class _AppliedCouponTicket extends StatelessWidget {
  final String code;
  final double discountAmount;
  final bool isDark;
  final VoidCallback onRemove;

  const _AppliedCouponTicket({
    super.key,
    required this.code,
    required this.discountAmount,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    const successColor = Color(0xFF2ECC71);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: successColor.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: successColor.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: successColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.ticket_discount, color: successColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      code,
                      style: GoogleFonts.alexandria(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: successColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: successColor, size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Discount of ৳${discountAmount.toStringAsFixed(0)} applied',
                  style: GoogleFonts.alexandria(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded,
                color: isDark ? Colors.white54 : Colors.black45,
                size: 22
            ),
            tooltip: 'Remove Coupon',
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }
}

// ── NEW: Professional Input Field ─────────────────────────────────────────────

class _CouponInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark, isLoading, hasError;
  final VoidCallback onApply;

  const _CouponInputField({
    super.key,
    required this.controller,
    required this.isDark,
    required this.isLoading,
    required this.hasError,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = hasError
        ? AppColors.error
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(
                    Iconsax.discount_shape,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    size: 20,
                  ),
                ),
                Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onApply(),
              textCapitalization: TextCapitalization.characters,
              style: GoogleFonts.alexandria(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.lightText,
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                hintText: 'Enter promo code',
                hintStyle: GoogleFonts.alexandria(
                  fontSize: 13,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 0,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
  const SizedBox(width: 12),
        isLoading
            ? Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                ),
              )
            : SizedBox(
                height: 52, // Match the typical height of the input field container
                child: TextButton(
                  onPressed: onApply,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.alexandria(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

// ── Shared Helpers ────────────────────────────────────────────────────────────

class _SummaryLine extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool isBold;

  const _SummaryLine(this.label, this.value, {this.valueColor, this.isBold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.alexandria(
            color: Colors.white.withOpacity(0.85),
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.alexandria(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
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
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: selected
                  ? color
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
              size: 24,
            ),
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
                        color: isDark ? Colors.white : AppColors.lightText,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge!,
                          style: GoogleFonts.alexandria(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.alexandria(
                    fontSize: 12,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
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
                    : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
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
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(Iconsax.card_slash, color: Colors.grey.shade400, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pay with Card',
                style: GoogleFonts.alexandria(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Requires ৳100 minimum order.',
                style: GoogleFonts.alexandria(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}