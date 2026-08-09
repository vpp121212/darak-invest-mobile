# Darak Waheek — Revenue Model & Operations Roadmap

*Version: 1.0 — Implementation status of each monetization item and the operations plan.*

## Revenue Model

| Item | Status | Implementation |
| --- | --- | --- |
| إبراز الإعلانات (Featured) | ✅ منفّذ | `POST /api/featured/purchase` (دفع 19 ر.س/أسبوع) و`POST /api/featured/boost` (رصيد). العقارات المميزة تتصدر قوائم `/all` و`/search` و`/listings` و`/ads` حتى انتهاء `featuredExpiresAt` |
| باقات للمعلنين | ✅ منفّذ | `advertiser:starter` (149 ر.س = 5 إبرازات) و`advertiser:premium` (399 ر.س = 20 إبرازاً) عبر `POST /api/payments/create-intent`؛ الرصيد في `users.adCredits` |
| اشتراكات | ✅ منفّذ (سابقاً) | 3 باقات basic/pro/enterprise عبر `/api/payments` + `/api/packages` + شاشة الاشتراكات |
| تقييم عقاري مدفوع | ✅ منفّذ | `POST /api/valuation/purchase` (49 ر.س) → عند إتمام الدفع يُحفظ تقرير كامل في `valuation_reports` |
| إدارة عقارات | ✅ منفّذ (سابقاً) | شاشات الإدارة + `realestate/finance/maintenance` routes |
| تصوير احترافي | ✅ منفّذ | `POST /api/photography/book` (باقات 149/299 ر.س) → حجز pending يُأكد تلقائياً بعد الدفع في `photography_bookings` |

### Catalogue
`src/services/monetization.js` يُعرّف جميع المنتجات (`PRODUCTS`) ويدير:
- `createCheckout` → فاتورة Moyasar أو `paymentId` اختبار.
- `fulfill` → تطبيق أثر المنتج بعد الدفع (تفعيل إبراز/رصيد/تقرير/تأكيد حجز).
- التوافق مع `packageId` القديم (basic/pro/enterprise) محفوظ.

### Test mode (بدون Moyasar)
`POST /api/payments/create-intent` → يُرجع `paymentId`؛ ثم `POST /api/payments/test-complete {paymentId}` يطبّق `fulfill` ويُمكّن الفحص الشامل.

## Operations & Maintenance Plan

| Area | Approach | Status |
| --- | --- | --- |
| مراقبة الإعلانات | حقل `status` (pending/active/sold/expired) + `reports` table للبلاغات + فحص احتيال يدوي عبر `/api/admin` | جاهز للتفعيل |
| مراقبة الوسطاء | `agents.isVerified` + تقييمات `ratings` + سجل `realestate_licenses` | جاهز للتفعيل |
| دعم فني | نظام `notifications` للمستخدمين + قناة دردشة `/api/chat` | جاهز للتفعيل |
| تحديثات شهرية | CI/CD الحالي (GitHub Actions) + تحرير يدوي للمسار | خطة |
| تحسين الذكاء الاصطناعي | إعادة تدريب قواعد `avm.js`/`ai.js` شهرياً على بيانات `official_indicators` و`price_index` | دورة شهرية |
| تحسين الأداء | الكاش (`props:*`/`search:*`) + قوائم كسولة + Isolates + تحجيم `uploads` عبر BullMQ | منفّذ |

## Monthly AI Refresh Loop
1. تحديث `official_indicators` و`price_index` من الهيئة العامة للعقار.
2. إعادة التحقق من نطاقات `perM2` المقبولة في `src/services/avm.js`.
3. تدقيق نتائج `duplicateCheck` عيّنة أسبوعية وضبط عتبة `duplicateScore ≥ 55`.
4. مراجعة `recommendations` عبر معدلات النقر/الحفظ في `properties.views` و`favorites`.

## Suggested Cadence
- يومي: مراقبة حالة السيرفر (`/api/health`) وسجلات الأخطاء.
- أسبوعي: مراجعة البلاغات والمعلنين المعلقين.
- شهري: تحديث بيانات السوق + تقييم أداء الذكاء الاصطناعي + نشر تحسينات الأداء.
