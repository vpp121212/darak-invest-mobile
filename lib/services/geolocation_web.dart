import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe' as jsutil;

import 'geolocation_service.dart' show GeoPoint;

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

  static Future<GeoPoint?> getCurrentPosition() async {
    final geo = _geo;
    if (geo == null) return null;

    final completer = Completer<GeoPoint?>();
    final success = (JSAny? position) {
      final coords = (position as JSObject)['coords'] as JSObject;
      final latitude = coords['latitude'] as JSNumber;
      final longitude = coords['longitude'] as JSNumber;
      var accuracy = 0.0;
      if (!coords['accuracy'].isUndefinedOrNull) {
        accuracy = (coords['accuracy'] as JSNumber).toDartDouble;
      }
      completer.complete(GeoPoint(
        latitude: latitude.toDartDouble,
        longitude: longitude.toDartDouble,
        accuracy: accuracy,
      ));
    }.toJS;

    final error = (JSAny? _) {
      completer.complete(null);
    }.toJS;

    final options = JSObject();
    options['enableHighAccuracy'] = true.toJS;
    options['timeout'] = 12000.toJS;

    geo.callMethodVarArgs<JSAny?>('getCurrentPosition'.toJS, [
      success,
      error,
      options,
    ]);
    return completer.future;
  }
}
