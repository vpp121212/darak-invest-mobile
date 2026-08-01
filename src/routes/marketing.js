import { Router } from 'express';
import sql from '../config/database.js';

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
        temperature: 0.7,
        max_tokens: 1500
      })
    });
    const data = await res.json();
    return data.choices?.[0]?.message?.content || null;
  } catch (e) { console.error('AI Error:', e); return null; }
}

function buildFallbackDescription(data) {
  const { title, type, purpose, city, district, area, rooms, baths, cars, facing, features, price, style } = data;
  const styleLabel = style === 'عاطفي' ? 'مثالي للعائلة التي تبحث عن الدفء والراحة' : style === 'استثماري' ? 'فرصة استثمارية واعدة بعائد ممتاز' : 'بتصميم يلبي أرقى معايير الجودة والأناقة';
  const name = title || (type ? `عقار ${type}` : 'عقار');
  const lines = [];
  lines.push(`${name} في ${[district, city].filter(Boolean).join('، ')} ${styleLabel}.`);

  const specs = [];
  if (area) specs.push(`مساحة ${area} م²`);
  if (rooms) specs.push(`${rooms} غرف نوم`);
  if (baths) specs.push(`${baths} حمامات`);
  if (cars) specs.push(`${cars} مواقف`);
  if (facing) specs.push(`واجهة ${facing}`);
  if (specs.length) lines.push(`المميزات الرئيسية: ${specs.join(' · ')}.`);

  if (features && features.length) lines.push(`يتميز العقار بـ ${features.join('، ')}.`);

  if (price) lines.push(`السعر: ${price.toLocaleString('en-US')} ر.س${purpose === 'إيجار' ? ' / شهرياً' : ''}`);

  lines.push('لمزيد من التفاصيل أو لترتيب معاينة، تواصل معنا الآن — فريق دارك وحيك جاهز لخدمتكم.');
  return lines.join('\n');
}

router.post('/description', async (req, res) => {
  try {
    const { title, type, purpose, city, district, area, rooms, baths, cars, facing, features, price, description, style } = req.body;

    const systemPrompt = `أنت كاتب محتوى عقاري محترف في السعودية. اكتب وصفاً جذاباً واحترافياً للعقار بالعربي الفصحى البسيط.
المتطلبات:
- ابدأ بسطر جذاب (Hook)
- اذكر المميزات الرئيسية بتنسيق نقاط
- اختم بدعوة للتواصل
- لا تتجاوز 200 كلمة
- استخدم أسلوب ${style || 'احترافي'} (احترافي / عاطفي / استثماري)
- لا تستخدم إيموجي`;

    const userMsg = `العقار: ${title || 'فيلا'} | النوع: ${type} | الغرض: ${purpose} | المدينة: ${city} | الحي: ${district}
المساحة: ${area} م² | غرف: ${rooms} | حمامات: ${baths} | سيارات: ${cars} | الاتجاه: ${facing}
السعر: ${price?.toLocaleString()} ر.س | المميزات: ${features?.join('، ') || 'لا توجد'}
الوصف الحالي: ${description || 'لا يوجد'}`;

    const aiDescription = await askAI(systemPrompt, userMsg) || buildFallbackDescription(req.body);

    let seoAnalysis = null;
    if (aiDescription) {
      const seoPrompt = 'أنت خبير SEO عقاري. حلل الوصف و أعطِ تقييم من 100 مع نصائح مختصرة بالعربي.';
      const seoMsg = `العنوان: ${title}
الوصف: ${aiDescription}
المدينة: ${city} | النوع: ${type} | السعر: ${price}`;
      seoAnalysis = await askAI(seoPrompt, seoMsg);
    }

    const shareText = `${title || type}\n📍 ${district}، ${city}\n💰 ${price?.toLocaleString()} ر.س\n📐 ${area} م² | ${rooms} غرف\n\n${aiDescription?.substring(0, 150)}...\n\n🔗 عبر تطبيق دارك وحيك`;

    res.json({ success: true, description: aiDescription, seoAnalysis, shareText });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/seo', async (req, res) => {
  try {
    const { title, description, city, district, type, price } = req.body;
    const fullText = `${title || ''} ${description || ''} ${city || ''} ${district || ''} ${type || ''}`;

    const keywords = [];
    const cities = ['الرياض', 'جدة', 'مكة', 'المدينة', 'الدمام', 'الخبر', 'تبوك', 'أبها', 'عسير'];
    cities.forEach(c => { if (fullText.includes(c)) keywords.push(c); });

    const types = ['فيلا', 'شقة', 'أرض', 'مكتب', 'محل', 'مستودع'];
    types.forEach(t => { if (fullText.includes(t)) keywords.push(t); });

    const hasPrice = /\d/.test(description || '');
    const hasArea = /م²|متر|مساحة/.test(description || '');
    const hasContact = /هاتف|جوال|تواصل|واتساب/.test(description || '');
    const hasEmoji = /[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}]/u.test(description || '');

    let score = 0;
    if (title && title.length > 10) score += 20;
    if (description && description.length > 50) score += 20;
    if (keywords.length > 0) score += 15;
    if (hasPrice) score += 15;
    if (hasArea) score += 10;
    if (hasContact) score += 10;
    if (district) score += 10;

    const tips = [];
    if (!title || title.length < 10) tips.push('أضف عنواناً وصفياً أطول');
    if (!description || description.length < 50) tips.push('أضف وصفاً تفصيلياً للعقار (50+ كلمة)');
    if (keywords.length === 0) tips.push('اذكر اسم المدينة في العنوان والوصف');
    if (!hasPrice) tips.push('اذكر السعر في الوصف');
    if (!hasArea) tips.push('اذكر المساحة في الوصف');
    if (!hasContact) tips.push('أضف معلومات التواصل');
    if (!district) tips.push('حدد الحي أو المنطقة الدقيقة');

    const hashtags = keywords.map(k => `#${k}`).join(' ') + ` #عقارات_${type || ''} #دارك_وحيك`;

    res.json({
      success: true,
      seo: {
        score: Math.min(100, score),
        keywords,
        tips,
        hashtags,
        hasPrice,
        hasArea,
        hasContact,
        descriptionLength: (description || '').length
      }
    });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/leads', async (req, res) => {
  try {
    const { budget, city, type, rooms, minArea, maxArea } = req.body;

    let conditions = ["status = 'active'"];
    let params = [];
    let idx = 0;
    if (budget) { conditions.push(`price <= $${++idx}`); params.push(Number(budget)); }
    if (city) { conditions.push(`city = $${++idx}`); params.push(city); }
    if (type) { conditions.push(`type = $${++idx}`); params.push(type); }
    if (rooms) { conditions.push(`rooms >= $${++idx}`); params.push(Number(rooms)); }
    if (minArea) { conditions.push(`area >= $${++idx}`); params.push(Number(minArea)); }
    if (maxArea) { conditions.push(`area <= $${++idx}`); params.push(Number(maxArea)); }

    const matches = await sql.unsafe(
      `SELECT * FROM properties WHERE ${conditions.join(' AND ')} ORDER BY "createdAt" DESC LIMIT 5`,
      params
    );

    const leadText = matches.length > 0
      ? matches.map(p => `🏠 ${p.title}\n📍 ${p.district}، ${p.city}\n💰 ${p.price.toLocaleString()} ر.س\n📐 ${p.area} م²\n\n`).join('---\n')
      : 'لا توجد عقارات مطابقة حالياً';

    res.json({ success: true, matches: matches.length, properties: matches, leadText });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

export default router;
