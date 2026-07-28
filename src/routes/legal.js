import { Router } from 'express';
import db from '../config/database.js';

const router = Router();

async function askAI(systemPrompt, userMessage) {
  const key = process.env.OPENAI_API_KEY;
  if (!key) return null;
  try {
    const res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${key}` },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userMessage }
        ],
        temperature: 0.2,
        max_tokens: 2000
      })
    });
    const data = await res.json();
    return data.choices?.[0]?.message?.content || null;
  } catch (e) { console.error('AI Error:', e); return null; }
}

router.post('/review-contract', async (req, res) => {
  try {
    const { contractType, buyerName, sellerName, propertyTitle, propertyCity, propertyDistrict, propertyArea, price, paymentTerms, handoverDate, specialConditions } = req.body;

    const systemPrompt = `أنت محامٍ عقاري متخصص في أنظمة المملكة العربية السعودية. راجع العقد وقدم ملاحظات قانونية مختصرة بالعربي.
المنصات العقارية في السعودية تخضع لنظام وسطاء العقارات الصادر من وزارة الشؤون البلدية والقروية.

أعد النتيجة بالشكل التالي:
1. ملخص العقد (سطرين)
2. ملاحظات قانونية (نقاط)
3. مخاطر محتملة (نقاط)
4. توصيات (نقاط)
5. درجة المخاطرة: منخفضة/متوسطة/عالية`;

    const userMsg = `نوع العقد: ${contractType || 'بيع عقاري'}
البائع: ${sellerName || 'غير محدد'}
المشتري: ${buyerName || 'غير محدد'}
العقار: ${propertyTitle || 'غير محدد'}
المدينة: ${propertyCity || 'الرياض'} - ${propertyDistrict || 'غير محدد'}
المساحة: ${propertyArea || 0} م²
السعر: ${price?.toLocaleString() || 0} ر.س
شروط الدفع: ${paymentTerms || 'كاش'}
تاريخ التسليم: ${handoverDate || 'غير محدد'}
شروط خاصة: ${specialConditions || 'لا توجد'}`;

    const aiReview = await askAI(systemPrompt, userMsg);

    const template = `عقد ${contractType || 'بيع عقاري'}

المادة الأولى:_SUBJECT_
بعت البائع ${sellerName || '________'} للمشتري ${buyerName || '________'} العقارlocated في ${propertyCity || '________'} - ${propertyDistrict || '________'} بمساحة ${propertyArea || '________'} م².

المادة الثانية:_PRICE_
قيمة البيع ${price?.toLocaleString() || '________'} ريال سعودي (${paymentTerms || 'كاش'}).

المادة الثالثة:_DELIVERY_
يتم التسليم في ${handoverDate || '________'}.

المادة الرابعة:_CONDITIONS_
${specialConditions || 'لا توجد شروط إضافية.'}

المادة الخامسة: governed by the laws of the Kingdom of Saudi Arabia.`;

    res.json({ success: true, review: aiReview, template });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/compliance', async (req, res) => {
  try {
    const { type, city, purpose, area, price, hasLicense, hasApproval, agentType } = req.body;

    const checks = [];

    checks.push({ item: 'نظام وسطاء العقارات', status: agentType === 'licensed' ? '✅' : '⚠️', note: 'يجب التسجيل لدى وزارة الشؤون البلدية والقروية' });
    checks.push({ item: 'رخصة المقاولات', status: hasLicense ? '✅' : '⚠️', note: hasLicense ? 'تم التحقق من الرخصة' : 'يجب التحقق من صلاحية الرخصة' });
    checks.push({ item: 'الموافقة البلدية', status: hasApproval ? '✅' : '⚠️', note: hasApproval ? 'تم Obtaining الموافقة' : 'يجب Obtaining موافقة البلدية قبل البناء' });

    if (type === 'أرض') {
      checks.push({ item: 'نظام الأراضي غير المأهولة', status: '📋', note: 'تأكد من تصنيف الأرض وصلاحيتها للبناء' });
      checks.push({ item: 'رسوم التحويل', status: '📋', note: 'قد تتطلب رسوم تحويل من أرض زراعية لسكنية' });
    }

    if (price > 1000000) {
      checks.push({ item: 'ضريبة العقارات', status: '⚠️', note: 'تحقق من الرسوم العقارية المستحقة (2.5% سنوياً)' });
    }

    checks.push({ item: 'التحقق من الملكية', status: '📋', note: 'تأكد من صحة سجل الملكية في وزارة العدل' });
    checks.push({ item: 'الرهن العقاري', status: '📋', note: 'تحقق من وجود رهن أو حظر على العقار' });
    checks.push({ item: 'النزاهة الإنشائية', status: '📋', note: 'يجب فحص العقار من مهندس معتمد' });

    const passed = checks.filter(c => c.status === '✅').length;
    const warnings = checks.filter(c => c.status === '⚠️').length;
    const info = checks.filter(c => c.status === '📋').length;
    const score = Math.round((passed / checks.length) * 100);

    res.json({
      success: true,
      compliance: {
        checks,
        summary: { passed, warnings, info, total: checks.length, score },
        recommendation: score >= 80 ? 'العقار متوافق مع الأنظمة大部分' : score >= 50 ? 'يجب مراجعة الملاحظات المعلمة بـ ⚠️' : 'يجب اتخاذ إجراءات قبل المتابعة'
      }
    });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/ai-review', async (req, res) => {
  try {
    const { text } = req.body;
    if (!text) return res.status(400).json({ error: 'أدخل نص العقد' });

    const systemPrompt = 'أنت محامٍ عقاري سعودي. راجع النص وأعطِ ملاحظات قانونية مختصرة بالعربي مع التنبيه على أي أخطاء أو نقص.';
    const aiReview = await askAI(systemPrompt, text);
    res.json({ success: true, review: aiReview });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

export default router;
