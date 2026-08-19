// ignore_for_file: use_build_context_synchronously
// lib/features/orders/presentation/widgets/order_screen/order_reorder_sheet.dart
//
// Bottom sheet for scheduling a re-order: pickup date/time + delivery date/time.
// Returns a Map<String,dynamic> with pickupDate, pickupTime, deliveryDate, deliveryTime.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/business_utils_logic.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/entities/order_entity.dart';

class OrderReorderSheet extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;

  const OrderReorderSheet({
    super.key,
    required this.order,
    required this.isDark,
  });

  @override
  State<OrderReorderSheet> createState() => _OrderReorderSheetState();
}

class _OrderReorderSheetState extends State<OrderReorderSheet> {
  late DateTime _pickupDate;
  late String _pickupTime;
  late DateTime _deliveryDate;
  late String _deliveryTime;
  List<String> _pickupTimeSlots = [];
  List<String> _deliveryTimeSlots = [];
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _pickupDate = BusinessLogicUtils.getMinPickupDate();
    _pickupTime = 'Select time';
    _deliveryDate = _pickupDate;
    _deliveryTime = 'Select time';
    _refreshPickupLogic();
  }

  Future<void> _refreshPickupLogic() async {
    setState(() => _isChecking = true);
    List<String> slots = await BusinessLogicUtils.getAvailableSlotsFiltered(
      widget.order.storeId,
      _pickupDate,
      isPickup: true,
      categories: [widget.order.serviceName],
    );
    while (slots.isEmpty) {
      _pickupDate = BusinessLogicUtils.getNextBusinessDay(_pickupDate);
      slots = await BusinessLogicUtils.getAvailableSlotsFiltered(
        widget.order.storeId,
        _pickupDate,
        isPickup: true,
        categories: [widget.order.serviceName],
      );
    }
    setState(() {
      _pickupTimeSlots = slots;
      _pickupTime = _pickupTimeSlots.isNotEmpty
          ? _pickupTimeSlots.first
          : 'Select time';
      _isChecking = false;
    });
    await _syncDeliveryLogic();
  }

  Future<void> _syncDeliveryLogic() async {
    if (_pickupTime == 'Select time') return;
    final minRequired = BusinessLogicUtils.getMinDeliveryDate(
      _pickupDate,
      _pickupTime,
      widget.order.serviceName,
      totalItems: widget.order.itemCount,
    );
    if (_deliveryDate.isBefore(minRequired)) _deliveryDate = minRequired;
    List<String> slots = await BusinessLogicUtils.getDeliverySlotsFiltered(
      widget.order.storeId,
      _deliveryDate,
      pickupDate: _pickupDate,
      pickupTime: _pickupTime,
      serviceName: widget.order.serviceName,
      totalItems: widget.order.itemCount,
    );
    while (slots.isEmpty) {
      _deliveryDate = _deliveryDate.add(const Duration(days: 1));
      while (BusinessLogicUtils.isClosedDay(_deliveryDate)) {
        _deliveryDate = _deliveryDate.add(const Duration(days: 1));
      }
      slots = await BusinessLogicUtils.getDeliverySlotsFiltered(
        widget.order.storeId,
        _deliveryDate,
        pickupDate: _pickupDate,
        pickupTime: _pickupTime,
        serviceName: widget.order.serviceName,
        totalItems: widget.order.itemCount,
      );
    }
    setState(() {
      _deliveryTimeSlots = slots;
      _deliveryTime = _deliveryTimeSlots.isNotEmpty
          ? _deliveryTimeSlots.first
          : 'Select time';
    });
  }

  Future<void> _handleConfirm() async {
    if (_pickupTime == 'Select time' || _deliveryTime == 'Select time') {
      AppSnackBar.show(
        context,
        'Please select both dates and times',
        type: SnackBarType.error,
      );
      return;
    }
    if (!BusinessLogicUtils.isSubmissionStillValid(_pickupDate, _pickupTime)) {
      AppSnackBar.show(
        context,
        'Selected pickup time is within the 2-hour no-change window. Please choose a later slot.',
        type: SnackBarType.error,
      );
      return;
    }
    setState(() => _isChecking = true);
    final isAvailable = await BusinessLogicUtils.isSlotAvailable(
      widget.order.storeId,
      _pickupDate,
      _pickupTime,
      orderValue: widget.order.totalPrice,
      orderItemCount: widget.order.itemCount,
    );
    setState(() => _isChecking = false);
    if (!context.mounted) return;
    if (!context.mounted) return;
    if (!isAvailable) {
      AppSnackBar.show(
        context,
        'This slot has reached capacity. Please pick another time.',
        type: SnackBarType.error,
      );
      return;
    }
    Navigator.pop(context, {
      'pickupDate': _pickupDate,
      'pickupTime': _pickupTime,
      'deliveryDate': _deliveryDate,
      'deliveryTime': _deliveryTime,
    });
  }

  @override
  Widget build(BuildContext context) {
    final canProceed =
        _pickupTime != 'Select time' &&
        _deliveryTime != 'Select time' &&
        !_isChecking;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: AppSheetHandle(isDark: widget.isDark)),
          const SizedBox(height: 20),
          Text(
            'Reschedule Reorder',
            style: AppTextStyles.heading(widget.isDark).copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            'Set your preferred pickup and delivery slots.',
            style: AppTextStyles.subtitle(widget.isDark),
          ),
          const SizedBox(height: 24),

          // ── Pickup ─────────────────────────────────────────────────────
          _SectionTitle(title: 'Pickup Schedule', isDark: widget.isDark),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: 'Pickup Date',
                  date: _pickupDate,
                  isDark: widget.isDark,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _pickupDate,
                      firstDate: BusinessLogicUtils.getMinPickupDate(),
                      lastDate: BusinessLogicUtils.getMaxPickupDate(),
                      selectableDayPredicate: (val) =>
                          !BusinessLogicUtils.isClosedDay(val) &&
                          BusinessLogicUtils.getAvailableSlots(
                            val,
                            isPickup: true,
                            categories: [widget.order.serviceName],
                          ).isNotEmpty,
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(
                        () => _pickupDate =
                            BusinessLogicUtils.clampToMinPickupDate(picked),
                      );
                      await _refreshPickupLogic();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeDropdown(
                  value: _pickupTime,
                  items: _pickupTimeSlots,
                  isDark: widget.isDark,
                  onChanged: (val) async {
                    if (val != null) {
                      setState(() => _pickupTime = val);
                      await _syncDeliveryLogic();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Delivery ────────────────────────────────────────────────────
          _SectionTitle(title: 'Delivery Schedule', isDark: widget.isDark),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: 'Delivery Date',
                  date: _deliveryDate,
                  isDark: widget.isDark,
                  onTap: () async {
                    final minDate = BusinessLogicUtils.getMinDeliveryDate(
                      _pickupDate,
                      _pickupTime,
                      widget.order.serviceName,
                    );
                    final maxDate = BusinessLogicUtils.getMaxPickupDate().add(
                      Duration(
                        days: BusinessLogicUtils.kStandardHours ~/ 8 + 2,
                      ),
                    );
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _deliveryDate,
                      firstDate: minDate,
                      lastDate: maxDate,
                      selectableDayPredicate: (val) =>
                          !BusinessLogicUtils.isClosedDay(val) &&
                          BusinessLogicUtils.getDeliverySlots(
                            val,
                            pickupDate: _pickupDate,
                            pickupTime: _pickupTime,
                            serviceName: widget.order.serviceName,
                          ).isNotEmpty,
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _deliveryDate = picked;
                        while (BusinessLogicUtils.isClosedDay(_deliveryDate)) {
                          _deliveryDate = _deliveryDate.add(
                            const Duration(days: 1),
                          );
                        }
                      });
                      await _syncDeliveryLogic();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeDropdown(
                  value: _deliveryTime,
                  items: _deliveryTimeSlots,
                  isDark: widget.isDark,
                  onChanged: (val) {
                    if (val != null) setState(() => _deliveryTime = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          AppGradientButton(
            label: 'Confirm & Place Order',
            onPressed: canProceed ? _handleConfirm : null,
            isLoading: _isChecking,
            verticalPadding: 16,
            borderRadius: 16,
          ),
        ],
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: AppTextStyles.body(isDark).copyWith(fontWeight: FontWeight.w600),
  );
}

// ─── Date tile ────────────────────────────────────────────────────────────────

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool isDark;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.date,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: AppTextStyles.body(isDark).copyWith(fontSize: 13),
            ),
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Time dropdown ────────────────────────────────────────────────────────────

class _TimeDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final bool isDark;
  final ValueChanged<String?> onChanged;

  const _TimeDropdown({
    required this.value,
    required this.items,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      hint: Text('Time', style: AppTextStyles.subtitle(isDark)),
      items: items
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Text(
                t,
                style: AppTextStyles.body(isDark).copyWith(fontSize: 13),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
