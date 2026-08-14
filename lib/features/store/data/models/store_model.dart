// lib/features/store/data/models/store_model.dart
import '../../domain/entities/store_entity.dart';

class StoreSlotBookingModel extends StoreSlotBookingEntity {
  const StoreSlotBookingModel({
    required super.id,
    required super.storeId,
    required super.slotDate,
    required super.slotHour,
    required super.slotType,
    required super.orderCount,
    required super.unitCount,
  });

  factory StoreSlotBookingModel.fromJson(Map<String, dynamic> json) {
    return StoreSlotBookingModel(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      slotDate: DateTime.parse(json['slot_date'] as String),
      slotHour: json['slot_hour'] as int,
      slotType: json['slot_type'] as String,
      orderCount: json['order_count'] as int? ?? 0,
      unitCount: json['unit_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'store_id': storeId,
    'slot_date': slotDate.toIso8601String().split('T')[0],
    'slot_hour': slotHour,
    'slot_type': slotType,
    'order_count': orderCount,
    'unit_count': unitCount,
  };
}

class StoreModel extends StoreEntity {
  const StoreModel({
    required super.id,
    required super.name,
    required super.address,
    super.city,
    super.phone,
    required super.distanceKm,
    super.latitude,
    super.longitude,
    required super.isActive,
    super.logoUrl,
    required super.openHour,
    required super.closeHour,
    required super.slotCapacity,
    required super.slotIntervalHours,
    required super.pickupBufferHours,
    required super.advanceBookingDays,
    super.bookings,
  });

  factory StoreModel.fromJson(Map<String, dynamic> j) {
    return StoreModel(
      id: j['id'] as String,
      name: j['name'] as String,
      address: j['address'] as String,
      city: j['city'] as String?,
      phone: j['phone'] as String?,
      distanceKm: (j['distance_km'] as num?)?.toDouble() ?? 0.0,
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      isActive: j['is_active'] as bool? ?? true,
      logoUrl: j['logo_url'] as String?,

      // ── MAP THE DB COLUMNS ──
      openHour: j['open_hour'] as int? ?? 8,
      closeHour: j['close_hour'] as int? ?? 20,
      slotCapacity: j['slot_capacity'] as int? ?? 100,
      slotIntervalHours: j['slot_interval_hours'] as int? ?? 2,
      pickupBufferHours: j['pickup_buffer_hours'] as int? ?? 2,
      advanceBookingDays: j['advance_booking_days'] as int? ?? 7,

      // ── MAP THE JOINED SLOT BOOKINGS ──
      bookings: j['store_slot_bookings'] != null
          ? (j['store_slot_bookings'] as List)
                .map((e) => StoreSlotBookingModel.fromJson(e))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'city': city,
    'phone': phone,
    'distance_km': distanceKm,
    'latitude': latitude,
    'longitude': longitude,
    'is_active': isActive,
    'logo_url': logoUrl,
    'open_hour': openHour,
    'close_hour': closeHour,
    'slot_capacity': slotCapacity,
    'slot_interval_hours': slotIntervalHours,
    'pickup_buffer_hours': pickupBufferHours,
    'advance_booking_days': advanceBookingDays,
    'store_slot_bookings': bookings
        ?.map((e) => (e as StoreSlotBookingModel).toJson())
        .toList(),
  };
}
