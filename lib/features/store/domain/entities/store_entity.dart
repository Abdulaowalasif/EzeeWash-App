// lib/features/store/domain/entities/store_entity.dart
import 'package:equatable/equatable.dart';

class StoreSlotBookingEntity extends Equatable {
  final String id;
  final String storeId;
  final DateTime slotDate;
  final int slotHour;
  final String slotType;
  final int orderCount;
  final int unitCount;

  const StoreSlotBookingEntity({
    required this.id,
    required this.storeId,
    required this.slotDate,
    required this.slotHour,
    required this.slotType,
    required this.orderCount,
    required this.unitCount,
  });

  @override
  List<Object?> get props => [
    id,
    storeId,
    slotDate,
    slotHour,
    slotType,
    orderCount,
    unitCount,
  ];
}

class StoreEntity extends Equatable {
  final String id;
  final String name;
  final String address;
  final String? city;
  final String? phone;
  final double distanceKm;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final String? logoUrl;

  // ── DYNAMIC BOOKING FIELDS ──
  final int openHour;
  final int closeHour;
  final int slotCapacity;
  final int slotIntervalHours;
  final int pickupBufferHours;
  final int advanceBookingDays;

  // ── NESTED SLOT BOOKINGS ──
  final List<StoreSlotBookingEntity>? bookings;

  const StoreEntity({
    required this.id,
    required this.name,
    required this.address,
    this.city,
    this.phone,
    required this.distanceKm,
    this.latitude,
    this.longitude,
    required this.isActive,
    this.logoUrl,
    required this.openHour,
    required this.closeHour,
    required this.slotCapacity,
    required this.slotIntervalHours,
    required this.pickupBufferHours,
    required this.advanceBookingDays,
    this.bookings,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    address,
    city,
    phone,
    distanceKm,
    latitude,
    longitude,
    isActive,
    logoUrl,
    openHour,
    closeHour,
    slotCapacity,
    slotIntervalHours,
    pickupBufferHours,
    advanceBookingDays,
    bookings,
  ];
}