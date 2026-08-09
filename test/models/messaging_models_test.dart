import 'package:darak_wa_hayk/models/conversation.dart';
import 'package:darak_wa_hayk/models/notification_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Conversation', () {
    test('parses the conversations API shape', () {
      final c = Conversation.fromJson(const {
        'id': 3,
        'userOneId': 1,
        'userTwoId': 9,
        'otherId': 9,
        'otherName': 'م. خالد العتيبي',
        'otherPhone': '+966551234567',
        'propertyId': 41,
        'propertyTitle': 'فيلا في حي الملقا',
        'images': '["/uploads/1.jpg","/uploads/2.jpg"]',
        'lastMessage': 'بكم السعر النهائي؟',
        'lastMessageAt': '2026-08-09T10:00:00.000Z',
        'unread': 2,
      });
      expect(c.id, '3');
      expect(c.otherId, '9');
      expect(c.otherName, 'م. خالد العتيبي');
      expect(c.propertyId, '41');
      expect(c.propertyTitle, 'فيلا في حي الملقا');
      expect(c.images, ['/uploads/1.jpg', '/uploads/2.jpg']);
      expect(c.lastMessage, 'بكم السعر النهائي؟');
      expect(c.unread, 2);
    });

    test('accepts images as a list', () {
      final c = Conversation.fromJson(const {
        'id': 1,
        'otherId': 2,
        'otherName': 'أ. نورة القحطاني',
        'images': ['/uploads/1.jpg'],
        'lastMessageAt': '2026-08-09T10:00:00.000Z',
      });
      expect(c.images, ['/uploads/1.jpg']);
      expect(c.images, isNotEmpty);
    });

    test('falls back to empty state', () {
      final c = Conversation.fromJson(const {
        'id': 1,
        'otherId': 2,
        'lastMessageAt': '',
      });
      expect(c.otherName, '');
      expect(c.images, isEmpty);
      expect(c.lastMessage, '');
    });
  });

  group('Message', () {
    test('parses a message row', () {
      final m = Message.fromJson(const {
        'id': 55,
        'conversationId': 3,
        'senderId': 9,
        'body': 'مرحباً، متاح للمعاينة غداً',
        'isRead': 0,
        'createdAt': '2026-08-09T10:05:00.000Z',
      });
      expect(m.id, '55');
      expect(m.conversationId, '3');
      expect(m.senderId, '9');
      expect(m.body, 'مرحباً، متاح للمعاينة غداً');
      expect(m.isRead, isFalse);
    });

    test('reads isRead as true when 1', () {
      final m = Message.fromJson(const {
        'id': 1,
        'conversationId': 1,
        'senderId': 1,
        'body': 'تم',
        'isRead': 1,
        'createdAt': '2026-08-09T10:05:00.000Z',
      });
      expect(m.isRead, isTrue);
    });
  });

  group('AppNotification', () {
    test('parses a notification row', () {
      final n = AppNotification.fromJson(const {
        'id': 11,
        'userId': 3,
        'title': 'عرض شراء جديد',
        'message': 'وصل عرض بقيمة 1,200,000 ر.س على عقارك',
        'type': 'offer',
        'isRead': 0,
        'createdAt': '2026-08-09T09:00:00.000Z',
      });
      expect(n.id, '11');
      expect(n.title, 'عرض شراء جديد');
      expect(n.type, 'offer');
      expect(n.isRead, isFalse);
    });

    test('marks read flag from integer', () {
      final n = AppNotification.fromJson(const {
        'id': 1,
        'title': 'رسالة جديدة',
        'message': '…',
        'isRead': 1,
        'createdAt': '',
      });
      expect(n.isRead, isTrue);
    });
  });
}
