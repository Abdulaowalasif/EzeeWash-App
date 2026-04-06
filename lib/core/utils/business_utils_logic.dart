// lib/core/utils/business_utils_logic.dart
//
// ─── SINGLE SOURCE OF TRUTH FOR ALL SCHEDULING LOGIC ─────────────────────────
//
// EC-01  Weekend (Fri+Sat) closed
// EC-02  Public holidays closed
// EC-03  Ramadan reduced hours (10:00–18:00)
// EC-04  Same-day 2h lead-time + slot-grid snap
// EC-05  After last-order hour → push to next BD
// EC-06  Midnight/early-AM (00–07h) buffer safety
// EC-07  Late-evening (≥18h) for next BD → 10 AM start
// EC-08  Pickup overshoots kLastOrderHour → []
// EC-09  Express near closing → rolls to next BD
// EC-10  Standard delivery across multi-day holiday block
// EC-11  Delivery date is holiday → advance automatically
// EC-12  Min delivery hour == closeHour → push next BD
// EC-13  Same pickup+delivery hour prevented
// EC-14  Stale/past pickup date clamped forward
// EC-15  Max 30-day advance booking window
// EC-16  Year/month boundary safe arithmetic
// EC-17  Slot grid alignment (09:17→10:00)
// EC-18  Delivery firstDate = computed min
// EC-19  Slot capacity check network fail → fail-open
// EC-20  Boundary times (== closeHour) as >=
// EC-21  Lunch/Prayer break (13:00–14:00) skipped
// EC-22  Emergency blackout dates (hartals, maintenance)
// EC-23  Delivery return buffer (last delivery ≤ 18:00)
// EC-24  Last-minute buffer: extra 1h within 30m of cutoff
// EC-25  Item-specific processing (blankets 96h, carpets 120h, etc.)
// EC-26  Multi-store variable hours (open/close per store)
// EC-27  Submission expiry: re-validate at checkout confirm
// EC-28  Device clock guard (BST normalisation, UTC+6)
// EC-29  Modification deadline (2h point-of-no-return)
// EC-30  Festive surge multiplier (Eid/Puja week +50% lead time)
// EC-31  Rush-hour buffer (16:00–19:00 +1h pickup lead time)
// EC-32  Bulk order buffer (>15 items +1h per 10 extra items)
// EC-33  Service-mix sync: always use longest category duration
// EC-34  Final QC window: mandatory +1h before delivery
// EC-35  Monsoon/weather delay toggle (+2h lead time)
// EC-36  Friday Jummah prayer block (12:30–14:30 no slots)
// EC-37  VIP reserved capacity (5% headroom for subscribers)
// EC-38  Physical unit saturation (500-unit store capacity)
// EC-39  Peak-slot MOV: weekend slots need min order value
// EC-40  Distance/zone logistics buffer (zone multiplier)
// EC-41  Holiday-eve early closure (next day is holiday → 16:00 close)
// EC-42  Category-specific lead times (leather, suits, couture…)
// EC-43  Processing-to-delivery closing buffer (30m guard)
// EC-44  Logistics dead-zone (shift change 14:00–14:30 no slots)
// EC-45  High-value order priority capacity (MOV-based VIP)
// EC-46  Timezone-safe normalisation (all "now" in BST UTC+6)
// EC-47  Zone-specific traffic multipliers (Old Dhaka 1.5×)
// EC-48  Bridge-day logic (working day sandwiched by holidays)
// EC-49  Large-item pickup lead time (+1h inspection buffer)
// EC-50  Slot soft-cap guard (95% limit for non-priority orders)
// EC-51  NTP/server-time sync guard (device clock manipulation)
// EC-52  Rider capacity throttling (15 orders per active rider)
// EC-53  Facility backlog buffer (+24h when plant overwhelmed)
// EC-54  Zone-based MOV enforcement
// EC-55  Global emergency kill-switch (remote disable)
// EC-56  Rider fatigue throttling (mandatory break slots blocked)
// EC-57  Store load balancing (overflow to secondary store)
// EC-58  Special handling buffer (+2h for couture/fragile)
// EC-59  Subscription protection (reserve early Sunday slots)
// EC-60  Multi-phase readiness (split orders use longest phase)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

// ─── Zone config ──────────────────────────────────────────────────────────────
class StoreHours {
  final int openHour;
  final int closeHour;
  final int lastOrderHour;
  const StoreHours({
    this.openHour = BusinessLogicUtils.kOpenHour,
    this.closeHour = BusinessLogicUtils.kCloseHour,
    this.lastOrderHour = BusinessLogicUtils.kLastOrderHour,
  });
}

class BusinessLogicUtils {
  BusinessLogicUtils._();

  // ─── Core Business Hours ───────────────────────────────────────────────────
  static const int kOpenHour         = 8;   // 08:00 – normal open
  static const int kCloseHour        = 20;  // 20:00 – normal close
  static const int kLastOrderHour    = 19;  // 19:00 – last pickup slot START
  static const int kLastDeliveryHour = 18;  // 18:00 – EC-23 delivery cut-off
  static const int kSlotInterval     = 2;   // 2-hour window width

  // ─── Lead-Time Buffers ────────────────────────────────────────────────────
  static const int kPickupBuffer     = 2;   // EC-04 same-day lead time (h)
  static const int kRushHourBuffer   = 3;   // EC-31 16–19h pickup buffer (h)
  static const int kWeatherBuffer    = 2;   // EC-35 monsoon extra buffer (h)
  static const int kLastMinuteBuffer = 1;   // EC-24 extra h within 30m of cutoff
  static const int kLargeItemBuffer  = 1;   // EC-49 large-item inspection (h)
  static const int kQCBuffer         = 1;   // EC-34 mandatory QC before delivery (h)
  static const int kFragileBuffer    = 2;   // EC-58 couture/fragile extra (h)
  static const int kFacilityBuffer   = 24;  // EC-53 plant-overload extra (h)
  static const int kMorningBuffer    = 10;  // EC-07 late-night next-BD start (h)
  static const int kLateNightCutoff  = 18;  // EC-07 threshold hour

  // ─── Breaks & Dead-Zones ──────────────────────────────────────────────────
  static const int kLunchStart       = 13;   // EC-21
  static const int kLunchEnd         = 14;   // EC-21
  // EC-36: Jummah 12:30–14:30 → block slots that START at 12 or 14 (2h slots)
  static const int kJummahBlockA     = 12;   // 12:00 slot covers 12:30 prayer start
  static const int kJummahBlockB     = 14;   // 14:00 slot overlaps prayer end (14:30)
  // EC-44: shift-change 14:00–14:30 → block the 14h slot
  static const int kShiftChangeHour  = 14;

  // ─── Capacity ─────────────────────────────────────────────────────────────
  static const int    kSlotLimit        = 100;  // max orders per slot per store
  static const int    kUnitLimit        = 500;  // EC-38 physical unit cap per slot
  static const double kVipHeadroom      = 0.05; // EC-37/50 5% reserved for priority
  static const int    kBulkThreshold    = 15;   // EC-32 items above this = bulk
  static const double kHighValueThreshold = 5000.0; // EC-45 high-value MOV (BDT)
  static const double kPeakSlotMOV      = 300.0;    // EC-39 weekend min order value

  // ─── Service Processing Times (hours) ─────────────────────────────────────
  static const int kExpressHours  = 5;
  static const int kStandardHours = 12;

  // EC-25/42: category → processing hours
  static const Map<String, int> kCategoryProcessingHours = {
    'express'  : 5,
    'standard' : 12,
    'leather'  : 48,
    'suits'    : 48,
    'blankets' : 96,
    'carpets'  : 120,
    'curtains' : 96,
    'couture'  : 72,
    'leather_couture': 120,
  };

  // EC-40/47: zone → traffic multiplier on lead-time buffer
  static const Map<String, double> kZoneTrafficMultipliers = {
    'old_dhaka'   : 1.5,
    'uttara'      : 1.2,
    'mirpur'      : 1.3,
    'mohakhali'   : 1.1,
    'gulshan'     : 1.0,
    'default'     : 1.0,
  };

  // EC-54: zone → minimum order value (BDT)
  static const Map<String, double> kZoneMOV = {
    'old_dhaka' : 400.0,
    'uttara'    : 350.0,
    'mirpur'    : 350.0,
    'default'   : 0.0,
  };

  // EC-30: festive weeks (month, weekNumber 1-5) where surge applies
  // Eid ul-Fitr 2025 week, Eid ul-Adha 2025 week, Durga Puja 2025 week
  static final List<DateTime> _festiveSurgeWeekStarts = [
    DateTime(2025, 3, 24), DateTime(2025, 6, 2),
    DateTime(2026, 3, 16), DateTime(2026, 5, 25),
  ];

  // ─── Operational Toggles (flip these without touching other logic) ─────────
  static const bool isEmergencyKillSwitchActive = false; // EC-55
  static const bool isFacilityOverloaded        = false; // EC-53
  static const bool isRamadanActive             = false; // EC-03
  static const bool isWeatherDelayActive        = false; // EC-35
  static const bool isRiderFatigueActive        = false; // EC-56

  // EC-22: blackout dates (hartals, maintenance, etc.) – add as needed
  static final Set<String> _blackoutDates = {
    // 'YYYY-MM-DD',
  };

  // ─── Bangladesh Public Holidays ───────────────────────────────────────────
  static const List<(int, int)> _fixedHolidays = [
    (2, 21), (3, 17), (3, 26), (4, 14),
    (5,  1), (8, 15), (12, 16), (12, 25),
  ];

  static final List<DateTime> _islamicHolidays = [
    // Eid ul-Fitr 2025
    DateTime(2025, 3, 30), DateTime(2025, 3, 31), DateTime(2025, 4, 1),
    // Eid ul-Adha 2025
    DateTime(2025, 6, 6),  DateTime(2025, 6, 7),  DateTime(2025, 6, 8),
    // Eid ul-Fitr 2026
    DateTime(2026, 3, 20), DateTime(2026, 3, 21), DateTime(2026, 3, 22),
    // Eid ul-Adha 2026
    DateTime(2026, 5, 27), DateTime(2026, 5, 28), DateTime(2026, 5, 29),
  ];

  // ─── EC-46: Always use BST (UTC+6) for "now" ──────────────────────────────
  static DateTime get nowBST {
    // EC-28: normalise to Bangladesh Standard Time regardless of device locale
    return DateTime.now().toUtc().add(const Duration(hours: 6));
  }

  // ─── Day Classification ───────────────────────────────────────────────────

  // EC-01: weekend
  static bool isWeekend(DateTime d) =>
      d.weekday == DateTime.friday;

  // EC-02: fixed or Islamic public holiday
  static bool isPublicHoliday(DateTime d) {
    for (final (m, day) in _fixedHolidays) {
      if (d.month == m && d.day == day) return true;
    }
    return _islamicHolidays.any(
            (h) => h.year == d.year && h.month == d.month && h.day == d.day);
  }

  // EC-22: hartal / maintenance blackout
  static bool isBlackoutDate(DateTime d) {
    final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    return _blackoutDates.contains(key);
  }

  // EC-48: bridge day – single working day sandwiched between two closed days
  static bool isBridgeDay(DateTime d) {
    if (isWeekend(d) || isPublicHoliday(d)) return false;
    final prev = d.subtract(const Duration(days: 1));
    final next = d.add(const Duration(days: 1));
    return _isStrictlyClosed(prev) && _isStrictlyClosed(next);
  }

  static bool _isStrictlyClosed(DateTime d) =>
      isWeekend(d) || isPublicHoliday(d);

  // EC-41: holiday-eve – tomorrow is a holiday → early closure today
  static bool isHolidayEve(DateTime d) =>
      isPublicHoliday(d.add(const Duration(days: 1)));

  /// Master closed-day predicate (EC-01/02/22/48/55)
  static bool isClosedDay(DateTime d) {
    if (isEmergencyKillSwitchActive) return true; // EC-55
    if (isWeekend(d))       return true;          // EC-01
    if (isPublicHoliday(d)) return true;          // EC-02
    if (isBlackoutDate(d))  return true;          // EC-22
    if (isBridgeDay(d))     return true;          // EC-48
    return false;
  }

  // ─── EC-30: Festive Surge Check ───────────────────────────────────────────
  static bool isFestiveSurgeWeek(DateTime d) {
    for (final start in _festiveSurgeWeekStarts) {
      final end = start.add(const Duration(days: 7));
      if (!d.isBefore(start) && d.isBefore(end)) return true;
    }
    return false;
  }

  // ─── Effective Hours (Ramadan + Holiday-eve aware) ────────────────────────

  // EC-03/41: effective opening hour
  static int effectiveOpenHour(DateTime d) =>
      isRamadanActive ? 10 : kOpenHour;

  // EC-03/41: effective closing hour
  static int effectiveCloseHour(DateTime d) {
    if (isHolidayEve(d)) return 16; // EC-41
    return isRamadanActive ? 18 : kCloseHour;
  }

  // EC-23: last delivery slot start (always ≤ kLastDeliveryHour)
  static int effectiveLastDeliveryHour(DateTime d) {
    final close = effectiveCloseHour(d);
    return close <= kLastDeliveryHour ? close - kSlotInterval : kLastDeliveryHour;
  }

  // EC-05/08: last pickup slot start
  static int effectiveLastOrderHour(DateTime d) {
    final close = effectiveCloseHour(d);
    return close - 1; // last slot must start ≥ 1h before close
  }

  // ─── EC-26: Per-Store Hours Override ──────────────────────────────────────
  static StoreHours resolveStoreHours(DateTime d, {StoreHours? storeOverride}) {
    if (storeOverride != null) return storeOverride;
    return StoreHours(
      openHour      : effectiveOpenHour(d),
      closeHour     : effectiveCloseHour(d),
      lastOrderHour : effectiveLastOrderHour(d),
    );
  }

  // ─── Next Business Day ────────────────────────────────────────────────────
  // EC-10/16: loops past any consecutive block of closed days
  static DateTime getNextBusinessDay(DateTime from, {StoreHours? storeOverride}) {
    DateTime next = DateTime(from.year, from.month, from.day)
        .add(const Duration(days: 1)); // EC-16: DateTime arithmetic is calendar-safe
    while (isClosedDay(next)) {
      next = next.add(const Duration(days: 1));
    }
    final hours = resolveStoreHours(next, storeOverride: storeOverride);
    return DateTime(next.year, next.month, next.day, hours.openHour);
  }

  // ─── Min / Max Pickup Dates ───────────────────────────────────────────────

  // EC-05/01/02/22/55
  static DateTime getMinPickupDate({StoreHours? storeOverride}) {
    final now = nowBST; // EC-46/28
    final hours = resolveStoreHours(now, storeOverride: storeOverride);
    if (isClosedDay(now) || now.hour >= hours.lastOrderHour) {
      return getNextBusinessDay(now, storeOverride: storeOverride);
    }
    return DateTime(now.year, now.month, now.day);
  }

  // EC-15: 30-day advance booking cap
  static DateTime getMaxPickupDate() =>
      nowBST.add(const Duration(days: 30));

  // EC-14: clamp stale/past date to the earliest valid business date
  static DateTime clampToMinPickupDate(DateTime d, {StoreHours? storeOverride}) {
    final min = getMinPickupDate(storeOverride: storeOverride);
    final dOnly   = DateTime(d.year, d.month, d.day);
    final minOnly = DateTime(min.year, min.month, min.day);
    if (dOnly.isBefore(minOnly) || isClosedDay(d)) {
      return getNextBusinessDay(d, storeOverride: storeOverride);
    }
    return d;
  }

  // ─── Format / Parse ───────────────────────────────────────────────────────
  static String formatHour(int h) =>
      DateFormat('hh:mm a').format(DateTime(2000, 1, 1, h));

  static int parseHour(String t) {
    if (t.isEmpty || t == 'Select time') return kOpenHour;
    try { return DateFormat('hh:mm a').parse(t).hour; }
    catch (_) { return kOpenHour; }
  }

  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/'
          '${d.month.toString().padLeft(2,'0')}/'
          '${d.year}';

  // ─── Slot Grid Alignment ──────────────────────────────────────────────────
  // EC-17: snap rawHour UP to the next boundary aligned from openHour
  static int _alignToSlot(int rawHour, int openHour) {
    if (rawHour <= openHour) return openHour;
    final offset    = rawHour - openHour;
    final intervals = (offset + kSlotInterval - 1) ~/ kSlotInterval;
    return openHour + intervals * kSlotInterval;
  }

  // ─── Slot Filter: Should This Hour Be Blocked? ────────────────────────────
  // Returns true if the hour is blocked by a break/dead-zone rule.
  static bool _isBlockedHour(int h, DateTime date, {bool isFriday = false}) {
    // EC-21: lunch/prayer break (all days) — block 13:00 slot
    if (h == kLunchStart) return true;
    // EC-36: Friday Jummah 12:30–14:30 — block 12:00 and 14:00 slots
    if (isFriday && (h == kJummahBlockA || h == kJummahBlockB)) return true;
    // EC-44: shift-change dead-zone 14:00 — block 14:00 slot
    if (h == kShiftChangeHour) return true;
    return false;
  }

  // ─── Available Slot Generation ────────────────────────────────────────────
  /// Returns valid 2-hour pickup/delivery slot labels for [date].
  ///
  /// Parameters:
  ///   [isPickup]          true → slots end at lastOrderHour; false → lastDeliveryHour
  ///   [minHourOverride]   delivery enforcement: earliest allowed start hour
  ///   [categories]        service categories for large-item/zone buffers
  ///   [zone]              logistics zone key for traffic multiplier
  ///   [isSubscriptionUser] EC-59: true → no early-slot reservation
  ///   [storeOverride]     EC-26: custom store hours
  static List<String> getAvailableSlots(
      DateTime date, {
        bool isPickup = true,
        int? minHourOverride,
        List<String> categories = const [],
        String zone = 'default',
        bool isSubscriptionUser = false,
        StoreHours? storeOverride,
      }) {
    if (isClosedDay(date)) return []; // EC-01/02/22/48/55

    final hours  = resolveStoreHours(date, storeOverride: storeOverride); // EC-26
    final open   = hours.openHour;
    final close  = hours.closeHour;
    final now    = nowBST; // EC-46/28
    final isFri  = date.weekday == DateTime.friday; // EC-36

    int start = open;

    if (DateUtils.isSameDay(date, now)) {
      // EC-04: same-day — compute buffer
      double buffer = kPickupBuffer.toDouble();

      // EC-31: rush-hour pickup buffer
      if (now.hour >= 16 && now.hour < 19) {
        buffer = kRushHourBuffer.toDouble();
      }

      // EC-40/47: zone traffic multiplier
      buffer *= (kZoneTrafficMultipliers[zone] ?? 1.0);

      // EC-35: weather/monsoon delay
      if (isWeatherDelayActive) buffer += kWeatherBuffer;

      // EC-49: large-item inspection buffer (carpets, blankets)
      if (categories.any((c) => ['carpets', 'blankets', 'curtains'].contains(c.toLowerCase()))) {
        buffer += kLargeItemBuffer;
      }

      // EC-24: last-minute buffer — within 30 min of cutoff
      final minutesToCutoff = (hours.lastOrderHour * 60) - (now.hour * 60 + now.minute);
      if (minutesToCutoff >= 0 && minutesToCutoff <= 30) buffer += kLastMinuteBuffer;

      // EC-06: midnight/early-AM safety — buffer can't produce a negative or sub-open hour
      start = _alignToSlot((now.hour + buffer).ceil(), open); // EC-17
    } else {
      // EC-07: late-evening ordering for next business day → morning buffer
      final nextBD = getNextBusinessDay(now, storeOverride: storeOverride);
      if (now.hour >= kLateNightCutoff && DateUtils.isSameDay(date, nextBD)) {
        start = kMorningBuffer > open ? kMorningBuffer : open;
      }
    }

    // EC-30: festive surge — add 2 extra hours to start
    if (isFestiveSurgeWeek(date)) {
      start = _alignToSlot(start + 2, open);
    }

    // Delivery min-hour enforcement (EC-13/18)
    if (minHourOverride != null && minHourOverride > start) {
      start = _alignToSlot(minHourOverride, open);
    }

    if (start < open) start = open; // EC-06 lower-bound safety

    // EC-08/05: determine effective end hour
    final end = isPickup
        ? hours.lastOrderHour
        : effectiveLastDeliveryHour(date); // EC-23

    if (start > end) return []; // EC-08

    final List<String> slots = [];
    for (int h = start; h <= end; h += kSlotInterval) {
      // EC-21/36/44: skip blocked hours
      if (_isBlockedHour(h, date, isFriday: isFri)) continue;

      // EC-56: rider fatigue — block 16h slot on high-volume days
      if (isRiderFatigueActive && h == 16) continue;

      // EC-43: processing-to-delivery closing buffer (block last slot before close)
      if (!isPickup && h + kSlotInterval > close - 0) {
        // guard: delivery must complete before close; skip if slot end exceeds close
        if (h + kSlotInterval > close) continue;
      }

      // EC-59: reserve early Sunday slots for subscribers only
      if (!isSubscriptionUser && date.weekday == DateTime.sunday && h < 10) continue;

      slots.add(formatHour(h));
    }
    return slots;
  }

  // ─── Delivery Slot Generation ─────────────────────────────────────────────
  /// Returns valid delivery slots for [deliveryDate] respecting pickup & service.
  /// EC-11/12/13/18/23/60
  static List<String> getDeliverySlots(
      DateTime deliveryDate, {
        required DateTime pickupDate,
        required String pickupTime,
        required String serviceName,
        List<String> categories = const [],
        int totalItems = 1,
        String zone = 'default',
        bool isSubscriptionUser = false,
        StoreHours? storeOverride,
      }) {
    if (isClosedDay(deliveryDate)) return []; // EC-11

    final minDt      = calculateMinDelivery(
      pickupDate, pickupTime, serviceName,
      categories: categories, totalItems: totalItems,
    );
    final minDateOnly = DateTime(minDt.year, minDt.month, minDt.day);
    final delDateOnly = DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day);

    if (delDateOnly.isBefore(minDateOnly)) return []; // EC-18

    // EC-12: if computed hour is at/past close for this day, no slots
    final closeH = effectiveCloseHour(deliveryDate);
    int? minHour;
    if (DateUtils.isSameDay(deliveryDate, minDt)) {
      minHour = minDt.hour;
      if (minHour >= closeH) return []; // EC-12
    }

    return getAvailableSlots(
      deliveryDate,
      isPickup: false,
      minHourOverride: minHour,
      categories: categories,
      zone: zone,
      isSubscriptionUser: isSubscriptionUser,
      storeOverride: storeOverride,
    );
  }

  // ─── Available Slots (capacity-filtered, for Order & Re-Order) ───────────
  /// Like [getAvailableSlots] but additionally checks Supabase slot capacity
  /// (EC-19/37/38/50/52) and removes fully-booked slots from the list.
  ///
  /// Use this on the **order** and **re-order** screens so users never see
  /// slots that are at capacity.
  static Future<List<String>> getAvailableSlotsFiltered(
      String storeId,
      DateTime date, {
        bool isPickup = true,
        int? minHourOverride,
        List<String> categories = const [],
        String zone = 'default',
        bool isSubscriptionUser = false,
        bool isVIP = false,
        double orderValue = 0.0,
        int activeRiders = 10,
        int orderItemCount = 1,
        StoreHours? storeOverride,
      }) async {
    final slots = getAvailableSlots(
      date,
      isPickup: isPickup,
      minHourOverride: minHourOverride,
      categories: categories,
      zone: zone,
      isSubscriptionUser: isSubscriptionUser,
      storeOverride: storeOverride,
    );

    if (slots.isEmpty) return [];

    // Check each slot's capacity concurrently for performance.
    final checks = await Future.wait(
      slots.map((slot) => isSlotAvailable(
        storeId,
        date,
        slot,
        isVIP: isVIP,
        orderValue: orderValue,
        activeRiders: activeRiders,
        orderItemCount: orderItemCount,
      )),
    );

    return [
      for (int i = 0; i < slots.length; i++)
        if (checks[i]) slots[i],
    ];
  }

  /// Like [getDeliverySlots] but additionally filters out fully-booked slots.
  ///
  /// Use this on the **order** and **re-order** screens for delivery slot
  /// selection so unavailable slots are never presented to the user.
  static Future<List<String>> getDeliverySlotsFiltered(
      String storeId,
      DateTime deliveryDate, {
        required DateTime pickupDate,
        required String pickupTime,
        required String serviceName,
        List<String> categories = const [],
        int totalItems = 1,
        String zone = 'default',
        bool isSubscriptionUser = false,
        bool isVIP = false,
        double orderValue = 0.0,
        int activeRiders = 10,
        int orderItemCount = 1,
        StoreHours? storeOverride,
      }) async {
    final slots = getDeliverySlots(
      deliveryDate,
      pickupDate: pickupDate,
      pickupTime: pickupTime,
      serviceName: serviceName,
      categories: categories,
      totalItems: totalItems,
      zone: zone,
      isSubscriptionUser: isSubscriptionUser,
      storeOverride: storeOverride,
    );

    if (slots.isEmpty) return [];

    final checks = await Future.wait(
      slots.map((slot) => isSlotAvailable(
        storeId,
        deliveryDate,
        slot,
        isVIP: isVIP,
        orderValue: orderValue,
        activeRiders: activeRiders,
        orderItemCount: orderItemCount,
      )),
    );

    return [
      for (int i = 0; i < slots.length; i++)
        if (checks[i]) slots[i],
    ];
  }

  // ─── Min Delivery DateTime ────────────────────────────────────────────────
  /// Counts [hoursNeeded] *business* hours forward from pickup moment.
  /// EC-09/10/12/25/32/33/34/53/58/60
  static DateTime calculateMinDelivery(
      DateTime pickupDate,
      String pickupTime,
      String serviceName, {
        List<String> categories  = const [],
        int    totalItems        = 1,
        bool   isFragile         = false,
        StoreHours? storeOverride,
      }) {
    final pHour = parseHour(pickupTime);
    DateTime cursor = DateTime(pickupDate.year, pickupDate.month, pickupDate.day, pHour);

    // EC-33: always use longest duration across all categories in the order
    int baseHours = _resolveProcessingHours(serviceName, categories);

    // EC-30: festive surge +50% lead time
    if (isFestiveSurgeWeek(pickupDate)) {
      baseHours = (baseHours * 1.5).ceil();
    }

    // EC-53: facility overloaded → extra 24h
    if (isFacilityOverloaded) baseHours += kFacilityBuffer;

    // EC-32: bulk order buffer (>15 items, +1h per 10 extra)
    if (totalItems > kBulkThreshold) {
      baseHours += (totalItems - kBulkThreshold) ~/ 10;
    }

    // EC-34: mandatory QC window
    baseHours += kQCBuffer;

    // EC-58: fragile/couture special handling
    final hasFragile = isFragile ||
        categories.any((c) => c.toLowerCase() == 'couture');
    if (hasFragile) baseHours += kFragileBuffer;

    int hoursRemaining = baseHours;

    while (hoursRemaining > 0) {
      cursor = cursor.add(const Duration(hours: 1));

      // Skip lunch/prayer break hours (EC-21)
      if (cursor.hour >= kLunchStart && cursor.hour < kLunchEnd) continue;

      // EC-09/12/20: past close or on closed day → jump to next BD open
      final closeH = effectiveCloseHour(cursor); // EC-41 aware
      if (cursor.hour >= closeH || isClosedDay(cursor)) {
        cursor = getNextBusinessDay(cursor, storeOverride: storeOverride);
      }
      hoursRemaining--;
    }

    // EC-12/43: if we land at or past effective close, push to next BD
    if (cursor.hour >= effectiveCloseHour(cursor)) {
      cursor = getNextBusinessDay(cursor, storeOverride: storeOverride);
    }

    return cursor;
  }

  // EC-33: resolve processing hours — longest wins across service + categories
  static int _resolveProcessingHours(String serviceName, List<String> categories) {
    int hours = serviceName.toLowerCase().contains('express')
        ? kExpressHours
        : kStandardHours;
    for (final cat in categories) {
      final h = kCategoryProcessingHours[cat.toLowerCase()];
      if (h != null && h > hours) hours = h;
    }
    return hours;
  }

  // ─── Min Delivery Date (date-only) ────────────────────────────────────────
  /// EC-11/18: date-only helper; advances past any closed day.
  static DateTime getMinDeliveryDate(
      DateTime pickupDate,
      String pickupTime,
      String serviceName, {
        List<String> categories = const [],
        int totalItems          = 1,
        StoreHours? storeOverride,
      }) {
    final dt = calculateMinDelivery(
      pickupDate, pickupTime, serviceName,
      categories: categories, totalItems: totalItems,
      storeOverride: storeOverride,
    );
    // EC-11: advance past any closed day (race condition guard)
    DateTime result = DateTime(dt.year, dt.month, dt.day);
    while (isClosedDay(result)) {
      result = result.add(const Duration(days: 1));
    }
    return result;
  }

  // ─── EC-27: Submission Expiry Guard ──────────────────────────────────────
  /// Called at checkout confirm. Returns true if the pickup slot is STILL
  /// in the future with sufficient buffer (EC-29: 2h modification deadline).
  static bool isSubmissionStillValid(DateTime pickupDate, String pickupTime) {
    final pHour    = parseHour(pickupTime);
    final pickupDT = DateTime(pickupDate.year, pickupDate.month, pickupDate.day, pHour);
    final deadline = nowBST.add(const Duration(hours: 2)); // EC-29
    return pickupDT.isAfter(deadline);
  }

  // ─── EC-29: Modification Deadline ────────────────────────────────────────
  /// Returns true if [order pickupDate/pickupTime] can still be modified.
  static bool canModifyOrder(DateTime pickupDate, String pickupTime) =>
      isSubmissionStillValid(pickupDate, pickupTime);

  // ─── EC-51: NTP/Server Time Sync ─────────────────────────────────────────
  /// Fetches server time from Supabase and returns offset in seconds.
  /// If device clock is more than 5 minutes off, slot calculations may be wrong.
  static Future<Duration> getDeviceClockOffset() async {
    try {
      final before = DateTime.now().toUtc();
      final response = await Supabase.instance.client
          .from('server_time') // a lightweight view/function
          .select('now')
          .single();
      final after  = DateTime.now().toUtc();
      final serverTime = DateTime.parse(response['now'] as String);
      final deviceMid  = before.add(after.difference(before) ~/ 2);
      return serverTime.difference(deviceMid);
    } catch (_) {
      return Duration.zero; // fail-open
    }
  }

  // ─── EC-39: Peak Slot MOV Validation ─────────────────────────────────────
  /// Returns true if the order meets the minimum order value for the slot.
  static bool meetsPeakMOV({
    required DateTime pickupDate,
    required double orderValue,
    required String zone,
  }) {
    // Weekend pickup requires minimum order value
    final isWeekendPickup = pickupDate.weekday == DateTime.sunday
        || pickupDate.weekday == DateTime.monday; // Sun/Mon = BD workweek start
    final zoneMOV = kZoneMOV[zone] ?? 0.0;
    if (isWeekendPickup && orderValue < kPeakSlotMOV) return false;
    if (orderValue < zoneMOV) return false; // EC-54: zone-based MOV
    return true;
  }

  // ─── EC-52/50: Slot Availability (Supabase) ───────────────────────────────
  /// Returns true if the slot has remaining capacity for [storeId].
  ///
  /// EC-37/45/50: Priority orders (VIP / high-value) get access to the
  /// full [dynamicLimit]; non-priority orders are limited to 95% of it.
  /// EC-52: dynamic limit is also capped by (activeRiders × 15).
  /// EC-19: fails open on any network error.
  static Future<bool> isSlotAvailable(
      String storeId,
      DateTime date,
      String time, {
        bool   isVIP           = false,
        double orderValue      = 0.0,
        int    activeRiders    = 10,
        int    orderItemCount  = 1,
      }) async {
    try {
      final hour       = parseHour(time);
      final startRange = DateTime(date.year, date.month, date.day, hour);
      final endRange   = startRange.add(const Duration(hours: kSlotInterval));

      final response = await Supabase.instance.client
          .from(AppConstants.ordersTable)
          .select('id, item_count')
          .eq('store_id', storeId)
          .gte('pickup_date', startRange.toIso8601String())
          .lt('pickup_date', endRange.toIso8601String());

      final orderCount = response.length;
      final unitCount  = (response as List)
          .fold<int>(0, (s, r) => s + ((r['item_count'] as int?) ?? 1));

      // EC-38: physical unit saturation check
      if (unitCount + orderItemCount > kUnitLimit) return false;

      // EC-52: rider-based dynamic limit
      final riderLimit    = activeRiders * 15;
      final dynamicLimit  = riderLimit < kSlotLimit ? riderLimit : kSlotLimit;

      // EC-37/45/50: priority vs non-priority soft-cap
      final isPriority    = isVIP || orderValue >= kHighValueThreshold;
      final effectiveLimit = isPriority
          ? dynamicLimit
          : (dynamicLimit * (1.0 - kVipHeadroom)).floor();

      return orderCount < effectiveLimit;
    } catch (_) {
      return true; // EC-19: fail-open
    }
  }

  // ─── EC-57: Store Load Balancing ─────────────────────────────────────────
  /// Returns the storeId to actually use — [primaryStoreId] if it has
  /// capacity, otherwise [fallbackStoreId] if provided.
  static Future<String> resolveStore({
    required String primaryStoreId,
    String? fallbackStoreId,
    required DateTime pickupDate,
    required String pickupTime,
    int activeRiders = 10,
  }) async {
    final primary = await isSlotAvailable(
      primaryStoreId, pickupDate, pickupTime,
      activeRiders: activeRiders,
    );
    if (primary) return primaryStoreId;
    if (fallbackStoreId != null) return fallbackStoreId;
    return primaryStoreId; // no alternative → caller handles full-slot UX
  }

  // ─── Display Helpers ──────────────────────────────────────────────────────

  /// Human-readable processing time label.
  static String processingTimeLabel(String serviceName, {List<String> categories = const []}) {
    final hours = _resolveProcessingHours(serviceName, categories);
    if (hours <= kExpressHours)  return '$hours-hour express processing';
    if (hours <= kStandardHours) return '$hours-hour standard processing';
    return '${hours ~/ 24}-day specialist processing';
  }

  /// Human-readable reason for empty slot list.
  static String noSlotsReason(DateTime date) {
    if (isEmergencyKillSwitchActive) return 'Bookings are temporarily suspended. Please try again later.';
    if (isBlackoutDate(date))        return 'Service unavailable on this date (scheduled maintenance).';
    if (isPublicHoliday(date))       return 'Public holiday — store is closed.';
    if (isWeekend(date))             return 'Store closed on weekends (Friday & Saturday).';
    if (isBridgeDay(date))           return 'Bridge holiday — store is closed today.';
    if (isFestiveSurgeWeek(date))    return 'Festive week — limited slots due to high demand.';
    return 'No slots available — store operating hours have passed for this date.';
  }
}