import sql from '../config/database.js';

const clamp = (v, min, max) => Math.min(max, Math.max(min, v));

const median = (arr) => {
  if (!arr.length) return null;
  const s = [...arr].sort((a, b) => a - b);
  const mid = Math.floor(s.length / 2);
  return s.length % 2 ? s[mid] : (s[mid - 1] + s[mid]) / 2;
};

const TYPE_TOKENS = {
  شقة: ['شقة'],
  فيلا: ['فيلا'],
  أرض: ['أرض'],
  مكتب: ['مكتب'],
  محل: ['محل'],
  دور: ['دور'],
  استوديو: ['استديو'],
  استراحة: ['استراحة'],
  شاليه: ['شاليه'],
  دوبلكس: ['دوبلاكس', 'دوبلكس'],
  عمارة: ['عمارة'],
  مجمع: ['مجمع'],
  بنتهاوس: ['بنتهاوس'],
  قصر: ['قصر']
};

function roundNice(v) {
  if (!v || !isFinite(v)) return null;
  const step = v >= 100000 ? 10000 : v >= 10000 ? 1000 : v >= 1000 ? 100 : 10;
  return Math.round(v / step) * step;
}

async function fetchComparables({ city, district, type, purpose, area }) {
  const cleanDistrict = district ? district.replace(/^(حي\s+)/, '') : '';
  const variants = [cleanDistrict, district].filter(Boolean);

  const query = (extra) => `
    SELECT price, area, rooms, baths, age, district FROM properties
    WHERE status = 'active' AND purpose = $1 AND city = $2 AND type = $3
      AND area > 20 AND price > 0 ${extra}
  `;

  let rows = await sql.unsafe(query(`AND district = ANY($4)`), [purpose, city, type, variants]);
  let scope = 'district';
  if (rows.length < 3) {
    rows = await sql.unsafe(query(''), [purpose, city, type]);
    scope = 'city';
  }
  if (rows.length < 3) {
    rows = await sql.unsafe(`
      SELECT price, area, rooms, baths, age, district FROM properties
      WHERE status = 'active' AND purpose = $1 AND city = $2 AND area > 20 AND price > 0`,
      [purpose, city]);
    scope = 'city_broad';
  }

  const cleaned = rows
    .map(r => ({ ...r, perM2: r.price / r.area }))
    .filter(r => (purpose === 'إيجار' ? r.perM2 >= 5 && r.perM2 <= 200 : r.perM2 >= 50 && r.perM2 <= 150000));

  const med = median(cleaned.map(r => r.perM2));
  if (med) {
    const final = cleaned.filter(r => r.perM2 >= med * 0.25 && r.perM2 <= med * 4);
    return {
      rows: final,
      count: final.length,
      medianPerM2: median(final.map(r => r.perM2)),
      medianRooms: median(final.map(r => r.rooms).filter(r => r != null)),
      medianAge: median(final.map(r => r.age).filter(r => r != null)),
      medianArea: median(final.map(r => r.area).filter(r => r != null)),
      scope
    };
  }
  return { rows: cleaned, count: cleaned.length, medianPerM2: null, medianRooms: null, medianAge: null, medianArea: null, scope };
}

async function fetchOfficial({ city, district, type, purpose }) {
  const itype = purpose === 'بيع' ? 'sales' : 'rent';
  const cleanDistrict = district ? district.replace(/^(حي\s+)/, '') : '';
  const variants = [district, 'حي ' + cleanDistrict].filter(Boolean);
  const tokens = TYPE_TOKENS[type] || [type];

  const run = (districtClause) => {
    const where = `indicator_type = $1 AND city = $2 AND deals > 0 AND avg_per_m2 > 0 ${districtClause} AND (property_type ILIKE $4)`;
    return sql.unsafe(`
      SELECT property_type, year, quarter, deals, avg_per_m2, source
      FROM official_indicators WHERE ${where}
      ORDER BY year DESC, quarter DESC, deals DESC LIMIT 1
    `, [itype, city, variants, `%${tokens[0]}%`]);
  };

  let rows = await run(`AND district = ANY($3)`);
  let level = 'district';
  if (!rows.length) {
    rows = await sql.unsafe(`
      SELECT property_type, year, quarter, deals, avg_per_m2, source
      FROM official_indicators WHERE indicator_type = $1 AND city = $2
        AND deals > 0 AND avg_per_m2 > 0 AND (property_type ILIKE $3)
      ORDER BY year DESC, quarter DESC, deals DESC LIMIT 1
    `, [itype, city, `%${tokens[0]}%`]);
    level = 'city';
  }

  if (!rows.length) return null;
  const o = rows[0];
  const perM2 = itype === 'rent' ? o.avg_per_m2 / 12 : o.avg_per_m2;
  return {
    perM2,
    deals: o.deals,
    year: o.year,
    quarter: o.quarter,
    propertyType: o.property_type,
    source: o.source,
    level,
    rawPerM2: o.avg_per_m2
  };
}

async function fetchPulse({ city, district }) {
  const cleanDistrict = district ? district.replace(/^(حي\s+)/, '') : '';
  const variants = [cleanDistrict, district].filter(Boolean);
  const [pulse] = await sql`
    SELECT avg_sale, avg_rent, roi FROM neighbourhood_pulse
    WHERE city = ${city} AND district = ANY(${variants}) LIMIT 1
  `;
  return pulse || null;
}

export async function evaluateAVM(input) {
  const { city, district, type, purpose, area, rooms, baths, year, age, price } = input;

  const [comparables, official, pulse] = await Promise.all([
    fetchComparables({ city, district, type, purpose, area }),
    fetchOfficial({ city, district, type, purpose }),
    fetchPulse({ city, district })
  ]);

  const signals = [];
  let compWeight = 0;
  if (comparables.medianPerM2) {
    compWeight = clamp(comparables.count, 1, 10);
    signals.push({ perM2: comparables.medianPerM2, weight: compWeight });
  }
  if (official) {
    signals.push({ perM2: official.perM2, weight: clamp(official.deals / 25, 0.5, 4) });
  }

  let basePerM2 = null;
  if (signals.length) {
    const wSum = signals.reduce((s, x) => s + x.weight, 0);
    basePerM2 = signals.reduce((s, x) => s + x.perM2 * x.weight, 0) / wSum;
  }

  let pulsePerM2 = null;
  if (pulse && area) {
    const total = purpose === 'بيع' ? pulse.avg_sale : (pulse.avg_rent ? pulse.avg_rent / 12 : null);
    if (total > 0) {
      const p = total / area;
      const sane = purpose === 'إيجار' ? (p >= 5 && p <= 200) : (p >= 50 && p <= 150000);
      if (sane && (!basePerM2 || (p >= basePerM2 * 0.25 && p <= basePerM2 * 4))) {
        pulsePerM2 = p;
        signals.push({ perM2: p, weight: 1.5 });
        if (basePerM2) {
          const wSum = signals.reduce((s, x) => s + x.weight, 0);
          basePerM2 = signals.reduce((s, x) => s + x.perM2 * x.weight, 0) / wSum;
        } else {
          basePerM2 = p;
        }
      }
    }
  }

  let adjustments = [];
  if (comparables.medianRooms != null && rooms != null) {
    const roomsAdj = clamp((rooms - comparables.medianRooms) * 0.035, -0.15, 0.15);
    if (roomsAdj !== 0) adjustments.push({ label: 'تعديل عدد الغرف', detail: `${rooms} مقابل متوسط ${Math.round(comparables.medianRooms)} بالنظائر`, effect: roomsAdj, value: `${roomsAdj > 0 ? '+' : ''}${Math.round(roomsAdj * 100)}%` });
  }
  if (comparables.medianAge != null && age != null) {
    const ageAdj = clamp(-(age - comparables.medianAge) * 0.01, -0.12, 0.12);
    if (ageAdj !== 0) adjustments.push({ label: 'تعديل عمر العقار', detail: `${age} سنة مقابل متوسط ${Math.round(comparables.medianAge)} بالنظائر`, effect: ageAdj, value: `${ageAdj > 0 ? '+' : ''}${Math.round(ageAdj * 100)}%` });
  }
  if (comparables.medianArea != null && area) {
    let areaAdj = 0;
    if (area > comparables.medianArea * 1.3) areaAdj = -0.05;
    else if (area < comparables.medianArea * 0.7) areaAdj = 0.05;
    if (areaAdj !== 0) adjustments.push({ label: 'تعديل المساحة', detail: `${Math.round(area)} م² مقابل متوسط ${Math.round(comparables.medianArea)} م²`, effect: areaAdj, value: `${areaAdj > 0 ? '+' : ''}${Math.round(areaAdj * 100)}%` });
  }
  const adjFactor = 1 + adjustments.reduce((s, a) => s + a.effect, 0);

  const adjustedPerM2 = basePerM2 ? basePerM2 * adjFactor : null;
  const estimate = adjustedPerM2 ? adjustedPerM2 * area : null;

  let confidence = 30;
  if (comparables.count >= 6) confidence += 35;
  else if (comparables.count >= 3) confidence += 25;
  else if (comparables.count >= 1) confidence += 15;
  if (official) confidence += 15;
  if (pulse) confidence += 5;
  if (comparables.medianPerM2 && official) {
    const diff = Math.abs(comparables.medianPerM2 - official.perM2) / Math.max(comparables.medianPerM2, official.perM2);
    if (diff < 0.2) confidence += 10;
    else if (diff < 0.4) confidence += 5;
  }
  if (pulsePerM2 && basePerM2) {
    const diff = Math.abs(pulsePerM2 - basePerM2) / Math.max(pulsePerM2, basePerM2);
    if (diff < 0.25) confidence += 5;
  }
  if (area >= 40) confidence += 5;
  confidence = clamp(confidence, 15, 90);

  const confidenceLabel = confidence >= 70 ? 'عالية' : confidence >= 50 ? 'متوسطة' : confidence >= 30 ? 'محدودة' : 'منخفضة جداً';

  let spread = 0.15;
  if (comparables.medianPerM2 && official) {
    const cv = Math.abs(comparables.medianPerM2 - official.perM2) / Math.max(comparables.medianPerM2, official.perM2);
    spread = clamp(0.08 + cv * 0.45, 0.10, 0.35);
  }
  if (confidence < 40) spread += 0.05;

  const min = estimate ? roundNice(estimate * (1 - spread)) : null;
  const max = estimate ? roundNice(estimate * (1 + spread)) : null;

  let priceCheck = null;
  if (estimate && price) {
    const deviation = (price - estimate) / estimate;
    priceCheck = {
      inputPrice: roundNice(price),
      deviation: Math.round(deviation * 100),
      fair: deviation <= -0.05 ? 'أقل من التقدير (فرصة جيدة)' : deviation <= 0.10 ? 'قريب من التقدير' : 'أعلى من التقدير'
    };
  }

  const factors = [];
  factors.push({
    label: comparables.scope === 'district' ? `الأسعار المنشورة في ${district}` :
      comparables.scope === 'city' ? `الأسعار المنشورة في ${city} (نفس النوع)` : `الأسعار المنشورة في ${city} (جميع الأنواع)`,
    detail: comparables.count ? `${comparables.count} عقار مشابه` : 'لا توجد نظائر كافية',
    value: comparables.medianPerM2 ? `${Math.round(comparables.medianPerM2)} ر.س/م²` : null
  });
  if (official) {
    factors.push({
      label: `المؤشر الرسمي — ${official.propertyType}${official.level === 'city' ? ` (${city})` : ` (${district})`}`,
      detail: `الربع ${official.quarter} ${official.year} · ${official.deals} صفقة`,
      value: `${Math.round(official.perM2)} ر.س/م²`,
      source: official.source
    });
  }
  if (pulse) {
    const pulseVal = purpose === 'بيع' ? pulse.avg_sale : pulse.avg_rent;
    if (pulseVal) factors.push({
      label: 'متوسط الحي (نبض الأحياء)',
      detail: pulsePerM2
        ? (purpose === 'بيع' ? 'متوسط البيع بالحي' : 'متوسط الإيجار بالحي')
        : (purpose === 'بيع' ? 'متوسط صفقة البيع' : 'متوسط الإيجار'),
      value: pulsePerM2
        ? `${Math.round(pulsePerM2)} ر.س/م²`
        : `${Math.round(pulseVal)} ر.س`
    });
  }
  adjustments.forEach(a => factors.push({ label: a.label, detail: a.detail, effect: a.effect, value: a.value }));

  return {
    estimate: estimate ? roundNice(estimate) : null,
    perM2: adjustedPerM2 ? Math.round(adjustedPerM2) : null,
    basePerM2: basePerM2 ? Math.round(basePerM2) : null,
    min,
    max,
    confidence,
    confidenceLabel,
    comparablesCount: comparables.count,
    scope: comparables.scope,
    dataLimited: comparables.count === 0 && !official,
    priceCheck,
    factors,
    input: { city, district, type, purpose, area, rooms, baths, year, age }
  };
}
