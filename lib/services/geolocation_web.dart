import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe' as jsutil;

import 'geolocation_service.dart' show GeoPoint, GeoResult;

/// نسخة الويب: قراءة الموقع الجغرافي المباشر عبر Geolocation API.
class GeolocationService {
  static JSObject? get _geo {
    final navigator = globalContext['navigator'];
    if (navigator.isUndefinedOrNull) return null;
    final geo = (navigator as JSObject)['geolocation'];
    if (geo.isUndefinedOrNull) return null;
    return geo as JSObject;
  }

  static bool get isSupported => _geo != null;

  static Future<GeoResult> locate() async {
    final geo = _geo;
    if (geo == null) {
      return const GeoResult(message: 'متصفحك لا يدعم تحديد الموقع');
    }

    final completer = Completer<GeoResult>();
    final success = (JSAny? position) {
      final coords = (position as JSObject)['coords'] as JSObject;
      final latitude = coords['latitude'] as JSNumber;
      final longitude = coords['longitude'] as JSNumber;
      var accuracy = 0.0;
      if (!coords['accuracy'].isUndefinedOrNull) {
        accuracy = (coords['accuracy'] as JSNumber).toDartDouble;
      }
      completer.complete(GeoResult(
        point: GeoPoint(
          latitude: latitude.toDartDouble,
          longitude: longitude.toDartDouble,
          accuracy: accuracy,
        ),
      ));
    }.toJS;

    final error = (JSAny? err) {
      final message = _errorMessage(err);
      completer.complete(GeoResult(message: message));
    }.toJS;

    final options = JSObject();
    options['enableHighAccuracy'] = true.toJS;
    options['timeout'] = 15000.toJS;
    options['maximumAge'] = 60000.toJS;

    try {
      geo.callMethodVarArgs<JSAny?>('getCurrentPosition'.toJS, [
        success,
        error,
        options,
      ]);
    } catch (_) {
      completer.complete(const GeoResult(message: 'تعذّر تحديد الموقع — حاول مجدداً'));
    }
    return completer.future;
  }

  static String _errorMessage(JSAny? err) {
    final code = err is JSObject && !err['code'].isUndefinedOrNull
        ? ((err['code'] as JSNumber).toDartDouble).round()
        : 0;
    return switch (code) {
      1 => 'تم رفض إذن الموقع — فعّله من إعدادات المتصفح ثم أعد المحاولة',
      2 => 'تعذّر الوصول إلى موقعك حالياً',
      3 => 'انتهت مهلة تحديد الموقع — حاول مجدداً',
      _ => 'تعذّر تحديد الموقع — تحقق من إذن الموقع في المتصفح',
    };
  }
}
