import sql from '../config/database.js';
import { evaluateAVM } from './avm.js';

const DIACRITICS = /[\u064B-\u065F\u0640]/g;
const ALEF = /[أإآ]/g;
const TAA_MARBUTA = /ة/g;
const ALEF_MAQSURA = /ى/g;
const NON_TOKEN = /[^\u0621-\u063A\u0641-\u064A0-9]+/g;

export function normalizeText(s = '') {
  return String(s)
    .toLowerCase()
    .replace(DIACRITICS, '')
    .replace(ALEF, 'ا')
    .replace(TAA_MARBUTA, 'ه')
    .replace(ALEF_MAQSURA, 'ي')
    .replace(NON_TOKEN, ' ')
    .trim();
}

export function tokenize(s = '') {
  const n = normalizeText(s);
  return n ? n.split(' ') : [];
}

function jaccard(a, b) {
  const A = new Set(a);
  const B = new Set(b);
  if (!A.size && !B.size) return 0;
  let inter = 0;
  for (const t of A) if (B.has(t)) inter++;
  const union = A.size + B.size - inter;
  return union ? inter / union : 0;
}

export { jaccard };

const formatNumber = (v) => Number(v || 0).toLocaleString('en-US');

const clamp = (v, min, max) => Math.min(max, Math.max(min, v));

const REQUIRED_FIELDS = [
  ['title', 'العنوان'],
  ['description', 'الوصف'],
  ['city', 'المدينة'],
  ['district', 'الحي'],
  ['type', 'النوع'],
  ['purpose', 'الغرض'],
  ['area', 'المساحة'],
  ['rooms', 'عدد الغرف'],
  ['price', 'السعر'],
  ['images', 'الصور'],
  ['features', 'المميزات']
];

async function loadProperty(input) {
  if (!input.propertyId) return { ...input };
  const [row] = await sql`SELECT * FROM properties WHERE id = ${input.propertyId}`;
  if (!row) {
    const err = new Error('عقار غير موجود');
    err.status = 404;
    throw err;
  }
  return { ...row, images: JSON.parse(row.images || '[]'), features: JSON.parse(row.features || '[]') };
}

function pricingScore(deviation) {
  const d = Math.abs(deviation);
  if (d <= 5) return 100;
  if (d <= 10) return 85;
  if (d <= 20) return 60;
  return 30;
}

export async function analyzeListing(input) {
  const p = await loadProperty(input);

  const present = [];
  const missing = [];
  for (const [key, label] of REQUIRED_FIELDS) {
    const v = p[key];
    const ok = key === 'images'
      ? Array.isArray(v) && v.length > 0
      : key === 'features'
        ? Array.isArray(v) && v.length > 0
        : v !== undefined && v !== null && String(v).trim() !== '';
    if (ok) present.push(label);
    else missing.push(label);
  }
  const completeness = Math.round((present.length / REQUIRED_FIELDS.length) * 100);

  const titleLen = (p.title || '').trim().length;
  const descLen = (p.description || '').trim().length;
  const imgCount = Array.isArray(p.images) ? p.images.length : 0;
  const featCount = Array.isArray(p.features) ? p.features.length : 0;

  let marketing = 0;
  const strengths = [];
  if (titleLen >= 30) { marketing += 25; strengths.push('عنوان تفصيلي'); }
  else if (titleLen >= 10) { marketing += 10; strengths.push('عنوان مقبول'); }
  if (descLen >= 150) { marketing += 25; strengths.push('وصف ممتاز'); }
  else if (descLen >= 60) { marketing += 15; strengths.push('وصف مقبول'); }
  if (imgCount >= 10) { marketing += 30; strengths.push('صور كثيرة'); }
  else if (imgCount >= 5) { marketing += 20; strengths.push('صور كافية'); }
  else if (imgCount >= 1) { marketing += 10; strengths.push('صور متوفرة'); }
  if (featCount >= 5) { marketing += 20; strengths.push('مميزات غنية'); }
  else if (featCount >= 2) { marketing += 10; strengths.push('مميزات متوفرة'); }

  let pricing = null;
  if (p.city && p.area && p.price) {
    try {
      const val = await evaluateAVM({
        city: p.city, district: p.district, type: p.type, purpose: p.purpose,
        area: p.area, rooms: p.rooms, baths: p.baths, year: p.year, age: p.age, price: p.price
      });
      pricing = {
        estimate: val.estimate, min: val.min, max: val.max, confidence: val.confidence,
        confidenceLabel: val.confidenceLabel, comparablesCount: val.comparablesCount,
        deviation: val.priceCheck?.deviation ?? null, fair: val.priceCheck?.fair ?? null
      };
    } catch (e) { console.error('AVM in analyzer failed:', e.message); }
  }

  const overall = pricing && pricing.deviation != null
    ? Math.round(completeness * 0.4 + marketing * 0.35 + pricingScore(pricing.deviation) * 0.25)
    : Math.round(completeness * 0.55 + marketing * 0.45);

  const recommendations = [];
  if (missing.length) recommendations.push(`أكمل الحقول الناقصة: ${missing.join('، ')}`);
  if (titleLen < 30) recommendations.push('حسّن العنوان ليكون تفصيلياً (30 حرفاً فأكثر)');
  if (descLen < 150) recommendations.push('وسّع الوصف ليتجاوز 150 حرفاً مع ذكر المزايا والموقع');
  if (imgCount < 10) recommendations.push('أضف 10 صور أو أكثر لرفع نسبة الاستجابة');
  if (featCount < 5) recommendations.push('أضف مميزات العقار (مكيف، أثاث، موقف، إطلالة ...)');
  if (pricing?.deviation != null && pricing.deviation > 10) recommendations.push(`السعر أعلى من تقدير الذكاء الاصطناعي بنحو ${pricing.deviation}% — خفض السعر يسرّع البيع`);
  if (pricing?.deviation != null && pricing.deviation < -10) recommendations.push('السعر أقل من تقدير الذكاء الاصطناعي — فرصة لرفع السعر');

  return {
    score: overall,
    verdict: overall >= 75 ? 'قائمة ممتازة' : overall >= 55 ? 'قائمة جيدة تحتاج تحسينات' : overall >= 35 ? 'قائمة ضعيفة' : 'قائمة غير مكتملة',
    completeness,
    marketing,
    pricing,
    fields: { present, missing },
    strengths,
    recommendations
  };
}

export async function duplicateCheck(input) {
  const base = await loadProperty(input);
  const { title, city, type, purpose, area, price, rooms, district } = base;
  if (!title || !city) return { success: true, normalizedTitle: '', duplicates: [] };

  const conditions = ["status = 'active'", 'city = $1', 'type = $2', 'purpose = $3'];
  const params = [city, type, purpose];
  let idx = 3;
  if (area) { conditions.push(`area BETWEEN $${++idx} AND $${++idx}`); params.push(area * 0.85, area * 1.15); }
  if (price) { conditions.push(`price BETWEEN $${++idx} AND $${++idx}`); params.push(price * 0.8, price * 1.2); }
  if (input.propertyId) { conditions.push(`id <> $${++idx}`); params.push(input.propertyId); }

  const rows = await sql.unsafe(
    `SELECT id, title, city, district, type, purpose, area, price, rooms, "createdAt", images, views FROM properties WHERE ${conditions.join(' AND ')} LIMIT 30`,
    params
  );

  const baseTokens = tokenize(title);
  const duplicates = rows
    .map((r) => {
      const titleSim = jaccard(baseTokens, tokenize(r.title));
      const areaDelta = area ? Math.abs(r.area - area) / area : 0;
      const priceDelta = price ? Math.abs(r.price - price) / price : 0;
      const districtMatch = district && r.district === district ? 1 : 0;
      const roomsMatch = rooms != null && r.rooms === Number(rooms) ? 1 : 0;
      const score = Math.round(
        titleSim * 50
        + (1 - Math.min(areaDelta, 1)) * 12
        + (1 - Math.min(priceDelta, 1)) * 12
        + districtMatch * 16
        + roomsMatch * 10
      );
      return {
        id: r.id, title: r.title, district: r.district, area: r.area, price: r.price,
        rooms: r.rooms, createdAt: r.createdAt, views: r.views,
        image: JSON.parse(r.images || '[]')[0] || null,
        duplicateScore: Math.min(100, score),
        signals: [
          titleSim >= 0.4 ? 'عنوان مشابه جداً' : titleSim >= 0.2 ? 'عنوان متشابه' : null,
          districtMatch ? 'نفس الحي' : null,
          areaDelta <= 0.05 ? 'مساحة متطابقة' : null,
          priceDelta <= 0.05 ? 'سعر متطابق' : null,
          roomsMatch ? 'نفس عدد الغرف' : null
        ].filter(Boolean)
      };
    })
    .filter((d) => d.duplicateScore >= 55)
    .sort((a, b) => b.duplicateScore - a.duplicateScore)
    .slice(0, 10);

  return { success: true, normalizedTitle: normalizeText(title), duplicates };
}

export async function recommend(input) {
  const { budget, area, rooms, baths, type, purpose, city, districts = [], features = [], limit = 10 } = input;
  const conditions = ["status = 'active'"];
  const params = [];
  let idx = 0;
  if (purpose) { conditions.push(`purpose = $${++idx}`); params.push(purpose); }
  if (city) { conditions.push(`city = $${++idx}`); params.push(city); }
  if (districts.length) { conditions.push(`district = ANY($${++idx})`); params.push(districts); }
  if (type) { conditions.push(`type = $${++idx}`); params.push(type); }
  if (budget) { conditions.push(`price <= $${++idx}`); params.push(Number(budget) * 1.15); }
  if (area) { conditions.push(`area BETWEEN $${++idx} AND $${++idx}`); params.push(area * 0.75, area * 1.25); }
  if (rooms) { conditions.push(`rooms >= $${++idx}`); params.push(Math.max(1, Number(rooms) - 1)); }
  if (baths) { conditions.push(`baths >= $${++idx}`); params.push(Number(baths)); }

  const rows = await sql.unsafe(
    `SELECT * FROM properties WHERE ${conditions.join(' AND ')} ORDER BY views DESC LIMIT 50`,
    params
  );

  const matches = rows
    .map((p) => {
      const feats = JSON.parse(p.features || '[]');
      let score = 50;
      const reasons = [];
      if (budget && p.price <= budget) { score += 20; reasons.push('ضمن الميزانية'); }
      if (budget && p.price > budget && p.price <= budget * 1.15) { score += 8; reasons.push('قريب من الميزانية'); }
      if (area && Math.abs(p.area - area) / area <= 0.1) { score += 15; reasons.push('مساحة مطابقة'); }
      if (rooms && p.rooms === Number(rooms)) { score += 10; reasons.push('نفس عدد الغرف'); }
      if (districts.length && districts.includes(p.district)) { score += 10; reasons.push('الحي المفضل'); }
      if (features.length) {
        const overlap = feats.filter((f) => features.includes(f)).length;
        if (overlap >= 3) { score += 15; reasons.push('مميزات مطابقة'); }
        else if (overlap >= 1) { score += 8; reasons.push('مميزات جزئية'); }
      }
      if (p.views > 300) { score += 5; reasons.push('طلب مرتفع'); }
      const isNew = p.createdAt && Date.now() - new Date(p.createdAt).getTime() < 7 * 86400000;
      if (isNew) { score += 5; reasons.push('إعلان جديد'); }
      return {
        id: p.id, title: p.title, city: p.city, district: p.district, type: p.type,
        purpose: p.purpose, price: p.price, area: p.area, rooms: p.rooms, baths: p.baths,
        image: JSON.parse(p.images || '[]')[0] || null, features: feats,
        matchScore: Math.min(score, 100), reasons: reasons.slice(0, 3)
      };
    })
    .sort((a, b) => b.matchScore - a.matchScore)
    .slice(0, Number(limit) || 10);

  return { success: true, matches };
}

export function parseQuery(q = '') {
  const s = normalizeText(q);
  const res = {};
  const currency = s.match(/(\d+(?:\.\d+)?)\s*(الف|مليون)?\s*(ر\s?س|ريال)/);
  if (currency) {
    let n = parseFloat(currency[1]);
    if (currency[2] === 'الف') n *= 1000;
    if (currency[2] === 'مليون') n *= 1000000;
    res.budget = Math.round(n);
  }
  const area = s.match(/(\d+(?:\.\d+)?)\s*م(?!ليون)/);
  if (area) res.area = Math.round(parseFloat(area[1]));
  const rooms = s.match(/(\d+)\s*غرف?/);
  if (rooms) res.rooms = Math.round(parseInt(rooms[1], 10));
  const typeMap = { شقة: 'شقة', شقق: 'شقة', فيلا: 'فيلا', فلل: 'فيلا', أرض: 'أرض', اراضي: 'أرض', مكتب: 'مكتب', محل: 'محل', محلات: 'محل', استوديو: 'استوديو', استديو: 'استوديو', دور: 'دور', شاليه: 'شاليه' };
  for (const [k, v] of Object.entries(typeMap)) {
    if (s.includes(normalizeText(k))) { res.type = v; break; }
  }
  return res;
}

const BUYER_TIPS = [
  'اطلب زيارة ميدانية قبل الدفع أو التوقيع.',
  'تحقق من الصك / وثيقة الملكية لدى الجهة المختصة.',
  'قارن السعر مع عقارات مشابهة في نفس الحي عبر تقدير الذكاء الاصطناعي.',
  'اسأل عن عمر العقار وحالة السباكة والكهرباء والإنشاءات.'
];

export async function buyerAssistant(input) {
  const parsed = parseQuery(input.query || '');
  const filters = {
    budget: input.budget || parsed.budget,
    area: input.area || parsed.area,
    rooms: input.rooms || parsed.rooms,
    type: input.type || parsed.type,
    city: input.city || parsed.city,
    purpose: input.purpose || 'بيع',
    districts: input.districts || [],
    features: input.features || []
  };
  const { matches } = await recommend(filters);
  const good = matches.filter((m) => m.matchScore >= 70);

  const cityTxt = filters.city ? ` في ${filters.city}` : '';
  const typeTxt = filters.type ? ` من نوع ${filters.type}` : '';
  const budgetTxt = filters.budget ? `${formatNumber(filters.budget)} ر.س` : '';

  let summary;
  if (!matches.length) {
    summary = `لم نجد عقارات تطابق معاييرك${cityTxt} حالياً. جرّب توسيع نطاق الميزانية أو المساحة.`;
  } else if (good.length) {
    const top = good[0];
    summary = `وجدنا ${good.length} عقارات واعدة${cityTxt}${typeTxt}${budgetTxt ? ` بميزانية ${budgetTxt}` : ''}. أفضل خيار: «${top.title}» بسعر ${formatNumber(top.price)} ر.س${top.district ? ` في ${top.district}` : ''}.`;
  } else {
    summary = `وجدنا ${matches.length} عقارات قريبة من معاييرك لكن بنسبة تطابق أقل من المطلوب${budgetTxt ? ` — الأقرب ضمن ${budgetTxt}` : ''}. أرفع الميزانية أو وسّع المساحة لنتائج أفضل.`;
  }

  return { success: true, summary, parsed, filters, matches, tips: BUYER_TIPS, count: matches.length };
}

export async function sellerAssistant(input) {
  const analysis = await analyzeListing(input);
  const p = await loadProperty(input);

  const guidance = [];
  const valuation = analysis.pricing;
  let recommendedPrice = null;
  if (valuation?.estimate) {
    recommendedPrice = valuation.estimate;
    const d = valuation.deviation;
    if (d != null && d > 10) guidance.push(`السعر الحالي أعلى من تقدير الذكاء الاصطناعي بنحو ${d}%. ننصح بالسعر المقترح (${formatNumber(recommendedPrice)} ر.س) لبيع أسرع.`);
    else if (d != null && d < -10) guidance.push(`السعر الحالي أقل من التقدير بـ ${Math.abs(d)}% — يمكنك رفع السعر إلى ${formatNumber(recommendedPrice)} ر.س.`);
    else guidance.push(`السعر الحالي متوافق مع تقدير الذكاء الاصطناعي (${formatNumber(recommendedPrice)} ر.س) — سعر عادل للسوق.`);
  }

  const tips = [
    'التقط صوراً بإضاءة طبيعية وبزوايا تبرز المساحات الداخلية.',
    'أضف مقطع فيديو قصير أو جولة 360° لزيادة الثقة.',
    'حدّث السعر بناءً على تقدير الذكاء الاصطناعي كل فترة.',
    'أبرز المميزات الفريدة: الإطلالة، التشطيب الفاخر، القرب من الخدمات.'
  ];

  return {
    success: true,
    score: analysis.score,
    verdict: analysis.verdict,
    analysis,
    valuation,
    recommendedPrice,
    property: p ? {
      id: p.id, title: p.title, city: p.city, district: p.district, type: p.type,
      purpose: p.purpose, price: p.price, area: p.area, rooms: p.rooms
    } : null,
    guidance,
    tips
  };
}

export async function valuationSummary(input) {
  const p = await loadProperty(input);
  const required = ['city', 'type', 'purpose', 'area'];
  if (!required.every((k) => p[k])) {
    const err = new Error('المدينة، النوع، الغرض والمساحة مطلوبة');
    err.status = 400;
    throw err;
  }
  const val = await evaluateAVM({
    city: p.city, district: p.district, type: p.type, purpose: p.purpose,
    area: p.area, rooms: p.rooms, baths: p.baths, year: p.year, age: p.age, price: p.price
  });

  let summary;
  if (val.dataLimited) {
    summary = `بيانات السوق في ${p.city} محدودة لهذا النوع — التقدير استرشادي وبدقة منخفضة.`;
  } else if (val.estimate) {
    const base = `التقدير المبدئي ${formatNumber(val.estimate)} ر.س (نطاق ${formatNumber(val.min)} – ${formatNumber(val.max)} ر.س) بدقة ${val.confidenceLabel}`;
    if (val.priceCheck) {
      summary = `${base}. السعر المدرج ${val.priceCheck.deviation > 0 ? 'أعلى' : 'أقل'} من التقدير بنحو ${Math.abs(val.priceCheck.deviation)}% (${val.priceCheck.fair}).`;
    } else {
      summary = `${base} استناداً إلى ${val.comparablesCount} عقار مشابه.`;
    }
  } else {
    summary = 'تعذّر احتساب تقدير — لا توجد بيانات كافية في هذا النطاق.';
  }

  return {
    success: true,
    valuation: val,
    summary,
    disclaimer: 'تقييم آلي لأغراض استرشادية مبني على الأسعار المنشورة والبيانات الرسمية، ولا يُعتبر تقريراً رسمياً لتثمين العقار.'
  };
}
