# دارك وحيك — تطبيق Flutter

منصة عقارية ذكية عربية (RTL) للبيع والإيجار في السعودية، بواجهة داكنة هوية «عين القطار» (كحلي عميق + ذهبي) وكتابة Cairo.

## المزايا

- تصفح/بحث عقارات مع فلاتر (مدينة، حي، نوع، الغرض، السعر، المساحة)
- أدوات ذكية: تقدير السعر بالذكاء الاصطناعي، نبض الحي، حاسبة ROI
- جولات 360° وبيت الدمية ثلاثي الأبعاد (Pannellum / model-viewer)
- حسابات (متصفح / معلن / وسيط / مكتب) مع جلسة آمنة
- إضافة عقار (يتطلب تسجيل دخول) مع تخزين محلي دون اتصال
- Offline-first: بيانات تجريبية + كاش محلي عند فشل الخادم

## التقنيات

- Flutter + Riverpod (StateNotifier/AsyncValue)
- auto_route (توجيه نوع-آمن + كود مولّد)
- backend: Express على Render (رابط مكوّن عبر `EnvConfig`)

## التشغيل

```bash
flutter pub get
flutter run                  # يفتح النسخة التجريبية بالبيانات الحية
flutter run -d chrome
```

### متغيرات البناء (Environment)

يُمرَّر عبر `--dart-define` مع قيم افتراضية للإنتاج:

```bash
flutter run --dart-define=API_BASE_URL=https://staging.example.com
flutter build web --release --base-href=/darak-invest-mobile/
```

| المتغير | الافتراضي | الوصف |
|---|---|---|
| `API_BASE_URL` | `https://darak-invest-backend-j6hy.onrender.com` | رابط الخادم |
| `SHOW_DEMO_PROPERTY` | `false` | إظهار العقار التجريبي (360°/3D) |

## الاختبار والتحقق

```bash
flutter analyze
flutter test
```

## النشر

النسخة المنشورة تُبنى وتُنسخ إلى `public/` (يخدمها GitHub Actions عبر GitHub Pages). انظر `.github/workflows/pages.yml`.
