import '../../domain/entities/promo_entity.dart';

class PromoModel extends PromoEntity {
  const PromoModel({
    required super.id,
    required super.code,
    super.description,
    required super.discountType,
    required super.discountValue,
    super.maxDiscountAmount,
    super.minOrderAmount,
    super.targetUserId,
    super.usageLimit,
    required super.timesUsed,
    required super.validFrom,
    super.validUntil,
    required super.isActive,
    super.createdAt,
    super.targetServiceId,
    super.targetServiceName, // NEW
    super.bannerUrl,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    // Supabase join returns nested object: { "services": { "title": "..." } }
    final serviceTitle =
        (json['services'] as Map<String, dynamic>?)?['title'] as String?;

    return PromoModel(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      discountType: json['discount_type'] as String,
      discountValue: (json['discount_value'] as num).toDouble(),
      maxDiscountAmount: (json['max_discount_amount'] as num?)?.toDouble(),
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble(),
      targetUserId: json['target_user_id'] as String?,
      usageLimit: json['usage_limit'] as int?,
      timesUsed: json['times_used'] as int,
      validFrom: DateTime.parse(json['valid_from'] as String),
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      targetServiceId: json['target_service_id'] as String?,
      targetServiceName: serviceTitle, // NEW — resolved from join
      bannerUrl: json['banner_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    if (description != null) 'description': description,
    'discount_type': discountType,
    'discount_value': discountValue,
    if (maxDiscountAmount != null) 'max_discount_amount': maxDiscountAmount,
    if (minOrderAmount != null) 'min_order_amount': minOrderAmount,
    if (targetUserId != null) 'target_user_id': targetUserId,
    if (usageLimit != null) 'usage_limit': usageLimit,
    'times_used': timesUsed,
    'valid_from': validFrom.toIso8601String(),
    if (validUntil != null) 'valid_until': validUntil!.toIso8601String(),
    'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (targetServiceId != null) 'target_service_id': targetServiceId,
    if (bannerUrl != null) 'banner_url': bannerUrl,
  };
}
