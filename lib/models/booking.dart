import 'dart:convert';

/// موعد معاينة/استشارة مع الوسيط على عقار معين.
class Booking {
  final String id;
  final String? userId;
  final String? agentUserId;
  final String propertyId;
  final String? propertyTitle;
  final String? propertyCity;
  final String? propertyDistrict;
  final List<String> images;
  final String type;
  final DateTime scheduledAt;
  final String note;
  final String status;
  final String? buyerName;
  final String? buyerPhone;

  const Booking({
    required this.id,
    this.userId,
    this.agentUserId,
    required this.propertyId,
    this.propertyTitle,
    this.propertyCity,
    this.propertyDistrict,
    this.images = const [],
    required this.type,
    required this.scheduledAt,
    this.note = '',
    this.status = 'pending',
    this.buyerName,
    this.buyerPhone,
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusLabel => switch (status) {
        'pending' => 'بانتظار التأكيد',
        'confirmed' => 'مؤكد',
        'completed' => 'منجز',
        'cancelled' => 'ملغي',
        _ => status,
      };

  factory Booking.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    return Booking(
      id: id,
      userId: json['userId']?.toString(),
      agentUserId: json['agentUserId']?.toString(),
      propertyId: (json['propertyId'] ?? json['property_id'] ?? '').toString(),
      propertyTitle: json['propertyTitle']?.toString(),
      propertyCity: json['city']?.toString(),
      propertyDistrict: json['district']?.toString(),
      images: _images(json['images']),
      type: json['type'] ?? 'معاينة',
      scheduledAt: DateTime.tryParse(json['scheduledAt'] ?? '') ??
          DateTime.tryParse(json['scheduled_at'] ?? '') ??
          DateTime.now(),
      note: json['note'] ?? '',
      status: json['status'] ?? 'pending',
      buyerName: json['buyerName']?.toString(),
      buyerPhone: json['buyerPhone']?.toString(),
    );
  }

  /// Postgres يُرجع صور العقار كـ JSON نصي أو كمصفوفة — نقبل الشكلين.
  static List<String> _images(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
      return value.isEmpty ? const [] : [value];
    }
    return const [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'type': type,
      'scheduledAt': scheduledAt.toIso8601String(),
      'note': note,
      'status': status,
    };
  }
}
