import 'geolocation_stub.dart'
    if (dart.library.js_interop) 'geolocation_web.dart' as impl;

/// نتيجة موقع مباشر من متصفح المستخدم.
class GeoPoint {
  final double latitude;
  final double longitude;
  final double accuracy;

  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.accuracy = 0,
  });
}

/// نتيجة عملية تحديد الموقع مع رسالة توضيحية عند الفشل.
class GeoResult {
  final GeoPoint? point;

  /// رسالة عربية تشرح سبب الفشل عندما يكون [point] فارغاً.
  final String? message;

  const GeoResult({this.point, this.message});

  bool get success => point != null;
}

/// قراءة الموقع الجغرافي المباشر من متصفح الويب عبر Geolocation API.
///
/// على الويب تُنفَّذ عبر Geolocation API مباشرة (لا توجد أذونات منصة
/// أصلية)، وعلى المنصات الأخرى تُرجع نتيجة فاشلة برسالة توضيحية.
class GeolocationService {
  static bool get isSupported => impl.GeolocationService.isSupported;

  static Future<GeoResult> locate() => impl.GeolocationService.locate();
}
