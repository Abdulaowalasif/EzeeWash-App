import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../../../core/widgets/form/app_quantity_selector.dart';
import '../../models/reorder_params.dart';
import '../../../../services/domain/entities/service_entity.dart';
import '../../../../../core/widgets/app_network_image.dart';

class PoConfirmationStep extends StatefulWidget {
  final double subtotal, serviceCharge, totalPrice;
  final bool isDark;
  final String? serviceName, storeName, pickupInfo, deliveryInfo;
  
  final List<int>? selectedIndices;
  final List<ServiceEntity>? services;
  final Map<int, int>? serviceQuantities;
  final Map<int, Map<String, int>>? comforterQuantities;
  final ReorderParams? reorderParams;

  final void Function(int, int) onQuantityChanged;
  final void Function(int, String, int)? onComforterQtyChanged;
  final ValueChanged<int>? onAddService;
  final ValueChanged<int>? onRemoveService;

  const PoConfirmationStep({
    super.key,
    required this.subtotal,
    required this.serviceCharge,
    required this.totalPrice,
    required this.isDark,
    this.serviceName,
    this.storeName,
    this.pickupInfo,
    this.deliveryInfo,
    this.selectedIndices,
    this.services,
    this.serviceQuantities,
    this.comforterQuantities,
    this.reorderParams,
    this.onAddService,
    this.onRemoveService,
    required this.onQuantityChanged,
    this.onComforterQtyChanged,
  });

  @override
  State<PoConfirmationStep> createState() => _PoConfirmationStepState();
}

class _PoConfirmationStepState extends State<PoConfirmationStep> {
  void _showAddServiceDialog(BuildContext context) {
    if (widget.services == null || widget.selectedIndices == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final unselected = <int>[];
        for (int i = 0; i < widget.services!.length; i++) {
          if (!widget.selectedIndices!.contains(i)) unselected.add(i);
        }

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Another Service',
                  style: GoogleFonts.alexandria(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 16),
                if (unselected.isEmpty)
                  Text(
                    'All services are already added.',
                    style: TextStyle(color: widget.isDark ? Colors.white70 : Colors.black54),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: unselected.length,
                      itemBuilder: (ctx, index) {
                        final idx = unselected[index];
                        final s = widget.services![idx];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            widget.onAddService?.call(idx);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.isDark ? AppColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: widget.isDark ? Colors.grey[800]! : Colors.grey[200]!,
                              ),
                              boxShadow: [
                                if (!widget.isDark)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                AppNetworkImage(
                                  url: s.imageUrl,
                                  width: 50,
                                  height: 50,
                                  radius: 12,
                                  isDark: widget.isDark,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    s.title,
                                    style: GoogleFonts.alexandria(
                                      fontSize: 15,
                                      color: widget.isDark ? Colors.white : AppColors.lightText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(Iconsax.add_circle, color: AppColors.primary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isShoeClean =
        widget.serviceName?.toLowerCase().contains('shoe') ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [


        if (widget.reorderParams != null) ...[
          AppQuantitySelector(
            quantity: widget.reorderParams!.itemCount,
            isDark: widget.isDark,
            title: isShoeClean ? 'Select Pair' : 'Number of Pieces',
            priceLabel: '৳${(widget.reorderParams!.totalPrice / widget.reorderParams!.itemCount).toStringAsFixed(0)} per ${isShoeClean ? 'pair' : 'piece'}',
            onChanged: (q) => widget.onQuantityChanged(-1, q),
          ),
        ] else if (widget.selectedIndices != null && widget.services != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Services',
                      style: GoogleFonts.alexandria(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: widget.isDark ? Colors.white : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adjust quantities or add more services.',
                      style: GoogleFonts.alexandria(
                        fontSize: 12,
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onAddService != null)
                FilledButton.icon(
                  onPressed: () => _showAddServiceDialog(context),
                  icon: const Icon(Iconsax.add, size: 18),
                  label: Text(
                    'Add',
                    style: GoogleFonts.alexandria(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ...widget.selectedIndices!.map((idx) {
            final service = widget.services![idx];
            final bool isS = service.title.toLowerCase().contains('shoe');
            final bool isC = service.title.toLowerCase().contains('comfort');

            return _ServiceCardTile(
              idx: idx,
              service: service,
              isS: isS,
              isC: isC,
              isDark: widget.isDark,
              comforterQuantities: widget.comforterQuantities?[idx],
              serviceQuantities: widget.serviceQuantities,
              onRemoveService: widget.onRemoveService,
              onComforterQtyChanged: widget.onComforterQtyChanged,
              onQuantityChanged: widget.onQuantityChanged,
            );
          }),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool isBold;

  const _SummaryLine(
    this.label,
    this.value, {
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.alexandria(
            color: Colors.white.withValues(alpha: 0.85),
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

class _ServiceCardTile extends StatefulWidget {
  final int idx;
  final ServiceEntity service;
  final bool isS;
  final bool isC;
  final bool isDark;
  final Map<String, int>? comforterQuantities;
  final Map<int, int>? serviceQuantities;
  final Function(int)? onRemoveService;
  final Function(int, String, int)? onComforterQtyChanged;
  final Function(int, int) onQuantityChanged;

  const _ServiceCardTile({
    required this.idx,
    required this.service,
    required this.isS,
    required this.isC,
    required this.isDark,
    this.comforterQuantities,
    this.serviceQuantities,
    this.onRemoveService,
    this.onComforterQtyChanged,
    required this.onQuantityChanged,
  });

  @override
  State<_ServiceCardTile> createState() => _ServiceCardTileState();
}

class _ServiceCardTileState extends State<_ServiceCardTile> {
  bool _isExpanded = false;

  int get _totalQty {
    if (widget.isC) {
      int total = 0;
      widget.comforterQuantities?.forEach((_, q) => total += q);
      return total;
    }
    return widget.serviceQuantities?[widget.idx] ?? 1;
  }

  double get _totalServicePrice {
    if (widget.isC) {
      double total = 0;
      final multipliers = {
        'Single': 0.5,
        'Twin XL': 0.75,
        'Double': 1.0,
        'Queen': 1.5,
        'King': 2.0,
      };
      widget.comforterQuantities?.forEach((size, qty) {
        final mult = multipliers[size] ?? 1.0;
        total += (widget.service.price * mult) * qty;
      });
      return total;
    }
    final qty = widget.serviceQuantities?[widget.idx] ?? 1;
    return widget.service.price * qty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          if (!widget.isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (widget.isDark ? AppColors.darkSurface : AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AppNetworkImage(
                    url: widget.service.imageUrl,
                    width: 40,
                    height: 40,
                    radius: 8,
                    isDark: widget.isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.title,
                        style: GoogleFonts.alexandria(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : AppColors.lightText,
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox(width: double.infinity, height: 0),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$_totalQty ${widget.isS ? 'pairs' : 'pieces'} selected',
                            style: GoogleFonts.alexandria(
                              fontSize: 12,
                              color: widget.isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                        crossFadeState: _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 250),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                  color: widget.isDark ? Colors.white54 : Colors.black54,
                  size: 20,
                ),
                if (widget.onRemoveService != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => widget.onRemoveService!(widget.idx),
                      icon: const Icon(Iconsax.trash, size: 18),
                      color: AppColors.error,
                      tooltip: 'Remove',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ]
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: widget.isDark ? Colors.white10 : Colors.grey.shade100,
                  ),
                ),
                if (widget.isC) ...[
                  ...[
                    {'name': 'Single', 'dim': '50 x 80 in', 'multiplier': 0.5},
                    {'name': 'Twin XL', 'dim': '68 x 90 in', 'multiplier': 0.75},
                    {'name': 'Double', 'dim': '78 x 86 in', 'multiplier': 1.0},
                    {'name': 'Queen', 'dim': '90 x 90 in', 'multiplier': 1.5},
                    {'name': 'King', 'dim': '104 x 92 in', 'multiplier': 2.0},
                  ].map((item) {
                    final size = item['name'] as String;
                    final dim = item['dim'] as String;
                    final multiplier = item['multiplier'] as double;
                    final currentQty = widget.comforterQuantities?[size] ?? 0;
                    final sizePrice = widget.service.price * multiplier;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppQuantitySelector(
                        quantity: currentQty,
                        min: (_totalQty <= 1 && currentQty == 1) ? 1 : 0,
                        isDark: widget.isDark,
                        title: '$size ($dim)',
                        priceLabel: '৳${sizePrice.toStringAsFixed(0)} / pc',
                        onChanged: (newQty) {
                          widget.onComforterQtyChanged?.call(widget.idx, size, newQty);
                        },
                      ),
                    );
                  }),
                ] else ...[
                  AppQuantitySelector(
                    quantity: widget.serviceQuantities?[widget.idx] ?? 1,
                    min: 1,
                    isDark: widget.isDark,
                    title: widget.isS ? 'Select Pair' : 'Number of Pieces',
                    priceLabel: '৳${widget.service.price.toStringAsFixed(0)} per ${widget.isS ? 'pair' : 'piece'}',
                    onChanged: (q) => widget.onQuantityChanged(widget.idx, q),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (widget.isDark ? AppColors.darkSurface : AppColors.primary).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Service Total',
                          style: GoogleFonts.alexandria(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark ? Colors.white70 : AppColors.lightText,
                          ),
                        ),
                        Text(
                          '৳${_totalServicePrice.toStringAsFixed(0)}',
                          style: GoogleFonts.alexandria(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

