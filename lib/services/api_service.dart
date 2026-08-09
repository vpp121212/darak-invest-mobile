import '../core/network/api_client.dart';
import '../models/booking.dart';
import '../models/conversation.dart';
import '../models/notification_item.dart';
import '../models/offer.dart';
import '../models/property.dart';
import '../models/realestate.dart';
/// Data access layer for the Darak backend.
///
/// Thin, stateless wrappers over [ApiClient]. All network errors are surfaced
/// as [AppException] so UI code can render the message directly.
class ApiService {
  static final ApiClient _client = ApiClient.instance;

  static String get baseUrl => ApiClient.baseUrl;

  static String resolveImage(String pathOrUrl) => _client.resolve(pathOrUrl);

  static void setToken(String? token) => _client.token = token;

  static List<Property> _parseProperties(dynamic data) {
    final list = data is List ? data : (data['properties'] ?? data['data'] ?? []);
    return (list as List).map((e) {
      final property = Property.fromJson(e as Map<String, dynamic>);
      return property.copyWith(
        images: property.images.map(resolveImage).toList(),
        panoramicImage: resolveImage(property.panoramicImage),
        panoramicImages: property.panoramicImages.map(resolveImage).toList(),
        model3dUrl: resolveImage(property.model3dUrl),
        model3dUrls: property.model3dUrls.map(resolveImage).toList(),
      );
    }).toList();
  }

  static Future<List<Property>> getProperties({int limit = 50}) async {
    final data = await _client.get('/api/properties/all', query: {'limit': limit});
    return _parseProperties(data);
  }

  /// Publishes a property owned by the logged-in advertiser.
  ///
  /// Mirrors the web app's `POST /api/properties` payload so the same links
  /// (360 panoramas, rooms, GLB dollhouse) reach the backend unchanged.
  static Future<Map<String, dynamic>> createProperty(
      Map<String, dynamic> data) async {
    final res = await _client.post('/api/properties', body: data);
    return res is Map<String, dynamic> ? res : <String, dynamic>{};
  }

  static Future<Property> getProperty(String id) async {
    final data = await _client.get('/api/properties/$id');
    final map = data is Map<String, dynamic> ? data : data['property'];
    final property = Property.fromJson(map);
    return property.copyWith(
      images: property.images.map(resolveImage).toList(),
      panoramicImage: resolveImage(property.panoramicImage),
      panoramicImages: property.panoramicImages.map(resolveImage).toList(),
      model3dUrl: resolveImage(property.model3dUrl),
      model3dUrls: property.model3dUrls.map(resolveImage).toList(),
    );
  }

  static Future<Map<String, dynamic>> search(Map<String, dynamic> params) async {
    final query = Map<String, dynamic>.from(params)
      ..removeWhere((_, v) => v == null || v == '');
    final data = await _client.get('/api/search', query: query);
    return data is Map<String, dynamic> ? data : {'properties': data};
  }

  static Future<Map<String, dynamic>> estimate(Map<String, dynamic> data) async {
    final res = await _client.post('/api/ai/estimate', body: data);
    return res as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getNeighborhoodPulse(String district) async {
    final res =
        await _client.get('/api/pulse/neighborhood/${Uri.encodeComponent(district)}');
    return res as Map<String, dynamic>;
  }

  static Future<List<String>> getCities() async {
    final data = await _client.get('/api/search/cities');
    final list = data is Map ? (data['cities'] ?? []) : data;
    return (list as List).map((e) => e.toString()).toList();
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _client.post('/api/auth/login', body: {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    final token = res['token'] ?? res['accessToken'];
    if (token != null) _client.token = token;
    return res;
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await _client.post('/api/auth/register', body: data)
        as Map<String, dynamic>;
    final token = res['token'] ?? res['accessToken'];
    if (token != null) _client.token = token;
    return res;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await _client.get('/api/auth/me');
    return res as Map<String, dynamic>;
  }

  /// الوساطة — حجز موعد معاينة/استشارة على عقار.
  static Future<Map<String, dynamic>> createBooking({
    required String propertyId,
    required String scheduledAt,
    String type = 'معاينة',
    String note = '',
  }) async {
    final res = await _client.post('/api/bookings', body: {
      'propertyId': propertyId,
      'scheduledAt': scheduledAt,
      'type': type,
      'note': note,
    });
    return res as Map<String, dynamic>;
  }

  /// الوساطة — قائمة المواعيد (كمستخدم أو كوسيط لمواعيد عقاراته).
  static Future<List<Booking>> getBookings() async {
    final data = await _client.get('/api/bookings');
    final list = data is Map ? (data['appointments'] ?? []) : (data ?? []);
    return (list as List)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> updateBookingStatus({
    required String id,
    required String status,
  }) async {
    final res = await _client.patch('/api/bookings/$id', body: {'status': status});
    return res as Map<String, dynamic>;
  }

  /// الوساطة — تقديم عرض شراء على عقار.
  static Future<Map<String, dynamic>> createOffer({
    required String propertyId,
    required double amount,
    String paymentMethod = 'نقدي',
    String note = '',
  }) async {
    final res = await _client.post('/api/bookings/offers', body: {
      'propertyId': propertyId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'note': note,
    });
    return res as Map<String, dynamic>;
  }

  /// الوساطة — قائمة العروض (كمشترٍ أو كوسيط لعروض عقاراته).
  static Future<List<Offer>> getOffers() async {
    final data = await _client.get('/api/bookings/offers');
    final list = data is Map ? (data['offers'] ?? []) : (data ?? []);
    return (list as List)
        .map((e) => Offer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> updateOfferStatus({
    required String id,
    required String status,
  }) async {
    final res = await _client.patch('/api/bookings/offers/$id', body: {'status': status});
    return res as Map<String, dynamic>;
  }

  /// الرسائل — قائمة المحادثات.
  static Future<List<Conversation>> getConversations() async {
    final data = await _client.get('/api/messages/conversations');
    final list = data is Map ? (data['conversations'] ?? []) : (data ?? []);
    return (list as List)
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// الرسائل — بدء محادثة مع مستخدم (وعقار اختياري) أو إرجاع الموجودة.
  static Future<String> createConversation({
    required String userId,
    String? propertyId,
  }) async {
    final res = await _client.post('/api/messages/conversations', body: {
      'userId': int.tryParse(userId) ?? userId,
      if (propertyId != null) 'propertyId': int.tryParse(propertyId) ?? propertyId,
    }) as Map<String, dynamic>;
    return (res['conversationId'] ?? '').toString();
  }

  /// الرسائل — رسائل محادثة معيّنة.
  static Future<List<Message>> getMessages(String conversationId) async {
    final data = await _client.get('/api/messages/conversations/$conversationId/messages');
    final list = data is Map ? (data['messages'] ?? []) : (data ?? []);
    return (list as List)
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// الرسائل — إرسال رسالة.
  static Future<void> sendMessage({
    required String conversationId,
    required String body,
  }) async {
    await _client.post('/api/messages/conversations/$conversationId/messages', body: {
      'body': body,
    });
  }

  /// الإشعارات — قائمة آخر 50 إشعارًا.
  static Future<List<AppNotification>> getNotifications() async {
    final data = await _client.get('/api/notifications');
    final list = data is Map ? (data['notifications'] ?? []) : (data ?? []);
    return (list as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markNotificationRead(String id) async {
    await _client.put('/api/notifications/$id/read');
  }

  static Future<void> markAllNotificationsRead() async {
    await _client.post('/api/notifications/mark-all');
  }

  /// الدفع — إعدادات بوابة الدفع (وضع الاختبار/الرئيسي).
  static Future<Map<String, dynamic>> getPaymentsConfig() async {
    final res = await _client.get('/api/payments/config', auth: false);
    return res as Map<String, dynamic>;
  }

  /// الدفع — إنشاء فاتورة/نية دفع لباقة محددة.
  static Future<Map<String, dynamic>> createPaymentIntent(String packageId) async {
    final res = await _client.post('/api/payments/create-intent', body: {
      'packageId': packageId,
    });
    return res as Map<String, dynamic>;
  }

  /// الدفع — إتمام الدفع في وضع الاختبار (بدون بوابة خارجية).
  static Future<Map<String, dynamic>> completeTestPayment(String paymentId) async {
    final res = await _client.post('/api/payments/test-complete', body: {
      'paymentId': paymentId,
    });
    return res as Map<String, dynamic>;
  }

  /// الدفع — سجل دفعات المستخدم.
  static Future<List<Map<String, dynamic>>> getMyPayments() async {
    final data = await _client.get('/api/payments');
    final list = data is Map ? (data['payments'] ?? []) : (data ?? []);
    return (list as List).map((e) => e as Map<String, dynamic>).toList();
  }

  /// إدارة العقارات — إحصائيات لوحة الإدارة.
  static Future<ManagementStats> getManagementStats() async {
    final res = await _client.get('/api/realestate/dashboard') as Map<String, dynamic>;
    final stats = (res['stats'] ?? res) as Map<String, dynamic>;
    return ManagementStats.fromJson(stats);
  }

  /// إدارة العقارات — العقود.
  static Future<List<RealEstateContract>> getContracts() async {
    final data = await _client.get('/api/realestate/contracts');
    final list = data is Map ? (data['contracts'] ?? []) : (data ?? []);
    return (list as List)
        .map((e) => RealEstateContract.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> createContract(Map<String, dynamic> data) async {
    final res = await _client.post('/api/realestate/contracts', body: data);
    return res as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> authenticateContract(String id) async {
    final res = await _client.post('/api/realestate/contracts/$id/authenticate');
    return res as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateContract(String id, Map<String, dynamic> data) async {
    final res = await _client.put('/api/realestate/contracts/$id', body: data);
    return res as Map<String, dynamic>;
  }

  /// إدارة العقارات — الفواتير الإيجارية.
  static Future<(List<RentalInvoice>, InvoiceTotals)> getInvoices() async {
    final res = await _client.get('/api/realestate/rental-invoices') as Map<String, dynamic>;
    final list = (res['invoices'] ?? []) as List;
    final invoices = list
        .map((e) => RentalInvoice.fromJson(e as Map<String, dynamic>))
        .toList();
    return (invoices, InvoiceTotals.fromJson((res['stats'] ?? {}) as Map<String, dynamic>));
  }

  static Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> data) async {
    final res = await _client.post('/api/realestate/rental-invoices', body: data);
    return res as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> payInvoice(String id) async {
    final res = await _client.put('/api/realestate/rental-invoices/$id/pay');
    return res as Map<String, dynamic>;
  }

  /// إدارة العقارات — الرخص.
  static Future<List<RealEstateLicense>> getLicenses() async {
    final data = await _client.get('/api/realestate/licenses');
    final list = data is Map ? (data['licenses'] ?? []) : (data ?? []);
    return (list as List)
        .map((e) => RealEstateLicense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> createLicense(Map<String, dynamic> data) async {
    final res = await _client.post('/api/realestate/licenses', body: data);
    return res as Map<String, dynamic>;
  }

  /// إدارة العقارات — الصكوك.
  static Future<List<RealEstateDeed>> getDeeds() async {
    final data = await _client.get('/api/realestate/deeds');
    final list = data is Map ? (data['deeds'] ?? []) : (data ?? []);
    return (list as List)
        .map((e) => RealEstateDeed.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> createDeed(Map<String, dynamic> data) async {
    final res = await _client.post('/api/realestate/deeds', body: data);
    return res as Map<String, dynamic>;
  }
}
