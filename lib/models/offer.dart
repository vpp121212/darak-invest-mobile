import 'dart:convert';

/// عرض شراء مقدّم من مشترٍ على عقار معيّن.
class Offer {
  final String id;
  final String? userId;
  final String? propertyAgentUserId;
  final String propertyId;
  final String? propertyTitle;
  final String? propertyCity;
  final String? propertyDistrict;
  final List<String> images;
  final double amount;
  final String paymentMethod;
  final String note;
  final String status;
  final String? buyerName;
  final String? buyerPhone;

  const Offer({
    required this.id,
    this.userId,
    this.propertyAgentUserId,
    required this.propertyId,
    this.propertyTitle,
    this.propertyCity,
    this.propertyDistrict,
    this.images = const [],
    required this.amount,
    this.paymentMethod = 'نقدي',
    this.note = '',
    this.status = 'pending',
    this.buyerName,
    this.buyerPhone,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  String get statusLabel => switch (status) {
        'pending' => 'قيد المراجعة',
        'accepted' => 'مقبول',
        'rejected' => 'مرفوض',
        'cancelled' => 'ملغي',
        _ => status,
      };

  factory Offer.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    return Offer(
      id: id,
      userId: json['userId']?.toString(),
      propertyAgentUserId: json['propertyAgentUserId']?.toString(),
      propertyId: (json['propertyId'] ?? json['property_id'] ?? '').toString(),
      propertyTitle: json['propertyTitle']?.toString(),
      propertyCity: json['city']?.toString(),
      propertyDistrict: json['district']?.toString(),
      images: _images(json['images']),
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'نقدي',
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
      return [value];
    }
    return const [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'note': note,
      'status': status,
    };
  }
}
