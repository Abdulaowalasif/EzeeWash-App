import 'package:equatable/equatable.dart';

class PromoEntity extends Equatable {
  final String id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double? maxDiscountAmount;
  final double? minOrderAmount;
  final String? targetUserId;
  final int? usageLimit;
  final int timesUsed;
  final DateTime validFrom;
  final DateTime? validUntil;
  final bool isActive;
  final DateTime? createdAt;
  final String? targetServiceId;
  final String? targetServiceName; // NEW
  final String? bannerUrl;

  const PromoEntity({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    this.minOrderAmount,
    this.targetUserId,
    this.usageLimit,
    required this.timesUsed,
    required this.validFrom,
    this.validUntil,
    required this.isActive,
    this.createdAt,
    this.targetServiceId,
    this.targetServiceName, // NEW
    this.bannerUrl,
  });

  @override
  List<Object?> get props => [
    id, code, description, discountType, discountValue,
    maxDiscountAmount, minOrderAmount, targetUserId, usageLimit,
    timesUsed, validFrom, validUntil, isActive, createdAt,
    targetServiceId, targetServiceName, bannerUrl,
  ];
}