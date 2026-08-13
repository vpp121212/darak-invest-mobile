import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// رفع صور العقارات من جهاز المستخدم وتحويلها إلى base64 data-URI.
///
/// الصور تُقلَّص وتُضغط لتوفير المساحة في التخزين المحلي (SharedPreferences)
/// قبل عرضها في قائمة العقارات دون اتصال.
class ImageUploadService {
  static const int _maxDimension = 1280;
  static const int _quality = 82;

  /// يفتح معرض الجهاز ويُرجِع صورة مضغوطة كـ data URI، أو null عند الإلغاء.
  static Future<String?> pickPropertyImage() async {
    final picker = ImagePicker();
    final XFile? file =
        await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final uri = compressToDataUri(bytes);
    return uri ?? base64Raw(bytes);
  }

  /// يفتح معرض الجهاز ويُرجِع عدّة صور مضغوطة كـ data URIs (على المنصات
  /// الداعمة للاختيار المتعدد مثل الويب)، أو صورة واحدة إن لم تتوفر.
  static Future<List<String>> pickPropertyImages() async {
    final picker = ImagePicker();
    try {
      final files = await picker.pickMultiImage(limit: 10);
      if (files.isEmpty) return const [];
      final uris = <String>[];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        uris.add(compressToDataUri(bytes) ?? base64Raw(bytes));
      }
      return uris;
    } catch (_) {
      final single = await pickPropertyImage();
      return single == null ? const [] : [single];
    }
  }

  /// يضغط الصورة إلى JPEG ≤1280 بكسل ويُرجعها كـ `data:image/jpeg;base64,...`.
  static String? compressToDataUri(Uint8List bytes) {
    try {
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;
      final longest = image.width > image.height ? image.width : image.height;
      if (longest > _maxDimension) {
        final scale = _maxDimension / longest;
        image = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
        );
      }
      final jpg = img.encodeJpg(image, quality: _quality);
      return 'data:image/jpeg;base64,${base64Encode(jpg)}';
    } catch (_) {
      return null;
    }
  }

  /// قاعدة احتياطية إذا تعذّر فك الترميز: يُمرَّر الملف الأصلي كما هو.
  static String base64Raw(Uint8List bytes) {
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }
}
