import 'package:darak_wa_hayk/models/booking.dart';
import 'package:darak_wa_hayk/models/offer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Booking', () {
    test('parses the brokerage API shape', () {
      final booking = Booking.fromJson(const {
        'id': 7,
        'userId': 3,
        'agentUserId': 12,
        'propertyId': 41,
        'propertyTitle': 'فيلا في حي الملقا',
        'city': 'الرياض',
        'district': 'الملقا',
        'images': '[]',
        'type': 'معاينة',
        'scheduledAt': '2026-08-20T17:00:00.000Z',
        'note': 'أرغب بمعاينة العصر',
        'status': 'pending',
      });
      expect(booking.id, '7');
      expect(booking.userId, '3');
      expect(booking.agentUserId, '12');
      expect(booking.propertyId, '41');
      expect(booking.propertyTitle, 'فيلا في حي الملقا');
      expect(booking.type, 'معاينة');
      expect(booking.scheduledAt, DateTime.parse('2026-08-20T17:00:00.000Z'));
      expect(booking.statusLabel, 'بانتظار التأكيد');
      expect(booking.isPending, isTrue);
      expect(booking.isConfirmed, isFalse);
    });

    test('status helpers reflect lifecycle', () {
      Booking at(String status) => Booking.fromJson({
            'id': 1,
            'propertyId': 1,
            'scheduledAt': '2026-08-20T17:00:00.000Z',
            'status': status,
          });
      expect(at('confirmed').isConfirmed, isTrue);
      expect(at('completed').isCompleted, isTrue);
      expect(at('cancelled').isCancelled, isTrue);
      expect(at('confirmed').statusLabel, 'مؤكد');
      expect(at('completed').statusLabel, 'منجز');
      expect(at('cancelled').statusLabel, 'ملغي');
    });

    test('toJson round-trips the payload sent to the API', () {
      final booking = Booking(
        id: '9',
        propertyId: '5',
        type: 'استشارة',
        scheduledAt: DateTime(2026, 8, 22, 18, 30),
        note: 'استشارة تمويل',
      );
      final json = booking.toJson();
      expect(json['propertyId'], '5');
      expect(json['type'], 'استشارة');
      expect(json['status'], 'pending');
      expect(json['scheduledAt'], '2026-08-22T18:30:00.000');
    });
  });

  group('Offer', () {
    test('parses the brokerage API shape', () {
      final offer = Offer.fromJson(const {
        'id': 21,
        'userId': 3,
        'propertyAgentUserId': 12,
        'propertyId': 41,
        'propertyTitle': 'شقة في حي النرجس',
        'city': 'الرياض',
        'district': 'النرجس',
        'images': '[]',
        'amount': 1850000,
        'paymentMethod': 'تمويل بنكي',
        'note': 'الدفعة الأولى 20%',
        'status': 'pending',
        'buyerName': 'محمد الأحمد',
        'buyerPhone': '+966501234567',
      });
      expect(offer.id, '21');
      expect(offer.userId, '3');
      expect(offer.propertyAgentUserId, '12');
      expect(offer.amount, 1850000);
      expect(offer.paymentMethod, 'تمويل بنكي');
      expect(offer.buyerName, 'محمد الأحمد');
      expect(offer.isPending, isTrue);
      expect(offer.statusLabel, 'قيد المراجعة');
    });

    test('status helpers reflect lifecycle', () {
      Offer at(String status) => Offer.fromJson({
            'id': 1,
            'propertyId': 1,
            'amount': 1000000,
            'status': status,
          });
      expect(at('accepted').isAccepted, isTrue);
      expect(at('rejected').isRejected, isTrue);
      expect(at('cancelled').isCancelled, isTrue);
      expect(at('accepted').statusLabel, 'مقبول');
      expect(at('rejected').statusLabel, 'مرفوض');
    });

    test('toJson round-trips the payload sent to the API', () {
      const offer = Offer(
        id: '3',
        propertyId: '8',
        amount: 900000,
        paymentMethod: 'نقدي',
        note: '',
      );
      final json = offer.toJson();
      expect(json['propertyId'], '8');
      expect(json['amount'], 900000);
      expect(json['paymentMethod'], 'نقدي');
      expect(json['status'], 'pending');
    });
  });
}
