// lib/features/orders/presentation/widgets/place_order/po_schedule_step.dart
//
// Step 3 of the place-order wizard: pickup and delivery date/time pickers.
// Each half is a _PoSchCard (schedule card) with a date picker + time dropdown.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../../../core/utils/business_utils_logic.dart';

class PoScheduleStep extends StatelessWidget {
  final DateTime pickupDate, deliveryDate;
  final DateTime minDeliveryDate, minPickupDate, maxPickupDate;
  final String pickupTime, deliveryTime;
  final bool isDark, isExpress;
  final List<String> pickupTimeSlots, deliveryTimeSlots;
  final ValueChanged<DateTime> onPickupDate, onDeliveryDate;
  final ValueChanged<String> onPickupTime, onDeliveryTime;
  final bool Function(DateTime) isClosedDay;
  final String processingLabel;

  const PoScheduleStep({
    super.key,
    required this.minPickupDate,
    required this.maxPickupDate,
    required this.pickupDate,
    required this.deliveryDate,
    required this.pickupTime,
    required this.deliveryTime,
    required this.isDark,
    required this.isExpress,
    required this.pickupTimeSlots,
    required this.deliveryTimeSlots,
    required this.onPickupDate,
    required this.onDeliveryDate,
    required this.onPickupTime,
    required this.onDeliveryTime,
    required this.minDeliveryDate,
    required this.isClosedDay,
    required this.processingLabel,
  });

  static String _fmt(DateTime? d) =>
      d == null ? '' : BusinessLogicUtils.formatDate(d);

  static InputDecoration _deco(String label, Color accent, bool isDark) =>
      InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        labelStyle: GoogleFonts.alexandria(
          fontSize: 12,
          color: accent.withValues(alpha: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PoSchCard(
          title: 'Pickup Schedule',
          icon: Iconsax.arrow_up_3,
          gradient: AppColors.gradient,
          accent: AppColors.primary,
          date: pickupDate,
          time: pickupTime,
          times: pickupTimeSlots,
          isDark: isDark,
          fmt: _fmt,
          deco: _deco,
          onDate: onPickupDate,
          onTime: onPickupTime,
          minDate: minPickupDate,
          maxDate: maxPickupDate,
          isClosedDay: isClosedDay,
          noSlotsMessage: BusinessLogicUtils.noSlotsReason(pickupDate),
        ),
        const SizedBox(height: 12),
        _PoSchCard(
          title: 'Delivery Schedule',
          icon: Iconsax.arrow_down_2,
          gradient: const LinearGradient(
            colors: [AppColors.success, Color(0xFF059669)],
          ),
          accent: AppColors.success,
          date: deliveryDate,
          time: deliveryTime,
          times: deliveryTimeSlots,
          isDark: isDark,
          fmt: _fmt,
          deco: _deco,
          onDate: onDeliveryDate,
          onTime: onDeliveryTime,
          minDate: minDeliveryDate,
          maxDate: BusinessLogicUtils.getMaxPickupDate().add(
            const Duration(days: 7),
          ),
          isClosedDay: isClosedDay,
          noSlotsMessage: BusinessLogicUtils.noSlotsReason(deliveryDate),
        ),
      ],
    );
  }
}

class _PoSchCard extends StatelessWidget {
  final String title, noSlotsMessage;
  final IconData icon;
  final Gradient gradient;
  final Color accent;
  final DateTime? date, minDate, maxDate;
  final String time;
  final List<String> times;
  final bool isDark;
  final String Function(DateTime?) fmt;
  final InputDecoration Function(String, Color, bool) deco;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<String> onTime;
  final bool Function(DateTime) isClosedDay;

  const _PoSchCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.accent,
    required this.date,
    required this.time,
    required this.times,
    required this.isDark,
    required this.fmt,
    required this.deco,
    required this.onDate,
    required this.onTime,
    required this.noSlotsMessage,
    required this.isClosedDay,
    this.minDate,
    this.maxDate,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSlots = times.isNotEmpty;
    final String? currentDisplayTime = times.contains(time) ? time : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.alexandria(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.lightText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Date picker
          TextFormField(
            controller: TextEditingController(text: fmt(date)),
            readOnly: true,
            style: GoogleFonts.alexandria(fontSize: 14),
            decoration: deco('Date', accent, isDark).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.calendar_today_rounded,
                  color: accent,
                  size: 20,
                ),
                onPressed: () async {
                  final firstDate =
                      minDate ?? BusinessLogicUtils.getMinPickupDate();
                  final lastDate =
                      maxDate ?? BusinessLogicUtils.getMaxPickupDate();
                  DateTime initial =
                      (date != null && !date!.isBefore(firstDate))
                      ? date!
                      : firstDate;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    selectableDayPredicate: (v) => !isClosedDay(v),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: ColorScheme.light(primary: accent),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) onDate(picked);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          // UPDATED: Removed the "no slots" error notice.
          // Users will now only see available slots in the dropdown.
          DropdownButtonFormField<String>(
            initialValue: currentDisplayTime,
            hint: Text(
              'Select time',
              style: GoogleFonts.alexandria(fontSize: 14, color: Colors.grey),
            ),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: accent),
            decoration: deco('Time', accent, isDark),
            items: times
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t, style: GoogleFonts.alexandria(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: hasSlots
                ? (v) {
                    if (v != null) onTime(v);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
