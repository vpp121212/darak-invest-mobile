import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import sql from '../src/config/database.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, '..', 'data', 'rega');
const RELEVANT_CITIES = new Set(['الرياض', 'جدة', 'مكة', 'الدمام', 'الخبر', 'حائل', 'مكة المكرمة']);

function parseCSV(text) {
  const rows = [];
  let row = [], field = '', inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (text[i + 1] === '"') { field += '"'; i++; }
        else inQuotes = false;
      } else field += c;
    } else if (c === '"') {
      inQuotes = true;
    } else if (c === ',') {
      row.push(field); field = '';
    } else if (c === '\n' || c === '\r') {
      if (c === '\r' && text[i + 1] === '\n') i++;
      row.push(field); field = '';
      if (row.some(f => f.trim() !== '')) rows.push(row);
      row = [];
    } else {
      field += c;
    }
  }
  if (field !== '' || row.length) { row.push(field); if (row.some(f => f.trim() !== '')) rows.push(row); }
  return rows;
}

function toNum(v) {
  if (v == null) return null;
  const s = String(v).replace(/[٬,\s]/g, '').trim();
  if (s === '' || /^(null|NULL|nan|NaN|−|-)$/.test(s)) return null;
  const n = parseFloat(s);
  return isNaN(n) ? null : n;
}

function detectByHeader(firstRow) {
  const h = firstRow.join(',').replace(/^\uFEFF/, '');
  if (h.includes('متوسط سعر المتر')) return 'sales';
  if (h.includes('لكل متر مربع') || h.includes('لكل متر')) return 'rent_district';
  if (/year|region_ar/i.test(h)) return 'rent_english';
  return 'rent_city';
}

function cleanKey(k) { return k.replace(/^\uFEFF/, '').trim(); }

const DATASETS = [
  { file: 'riyadh_rent_city.csv', slug: 'riyadh-rent-city' },
  { file: 'riyadh_rent_q1_2026.csv', slug: 'riyadh-rent-q1-2026' },
  { file: 'riyadh_sales_q1_2026.csv', slug: 'riyadh-sales-q1-2026' },
  { file: 'makkah_rent_city.csv', slug: 'makkah-rent-city' },
  { file: 'madinah_rent_city.csv', slug: 'madinah-rent-city' },
  { file: 'qassim_rent_city.csv', slug: 'qassim-rent-city' },
  { file: 'eastern_rent_city.csv', slug: 'eastern-rent-city' },
];

let inserted = 0, skipped = 0;

async function importDataset({ file, slug }) {
  const filePath = path.join(DATA_DIR, file);
  if (!fs.existsSync(filePath)) { console.log('  skip (missing):', file); return; }
  const text = fs.readFileSync(filePath, 'utf8');
  const parsed = parseCSV(text);
  if (parsed.length < 2) { console.log('  skip (empty):', file); return; }
  const header = parsed[0].map(cleanKey);
  const kind = detectByHeader(parsed[0]);
  const idx = {};
  header.forEach((h, i) => { idx[h] = i; });

  const get = (r, names) => {
    for (const n of names) {
      const exact = idx[n];
      if (exact != null && exact < r.length) {
        const v = r[exact].replace(/^\uFEFF/, '').trim();
        if (v !== '') return v;
      }
      const matches = [];
      for (const h of header) {
        if (h.includes(n)) matches.push(h);
      }
      matches.sort((a, b) => a.length - b.length);
      for (const m of matches) {
        const v = r[idx[m]].replace(/^\uFEFF/, '').trim();
        if (v !== '') return v;
      }
    }
    return null;
  };

  const rows = parsed.slice(1);
  let inBatch = [];
  const flush = async () => {
    if (!inBatch.length) return;
    await sql`
      INSERT INTO official_indicators (indicator_type, year, quarter, region, city, district, property_type, category, deals, avg_value, avg_per_m2, source, source_url, notes)
      SELECT * FROM UNNEST(
        ${inBatch.map(r => r.indicator_type)}::text[],
        ${inBatch.map(r => r.year)}::int[],
        ${inBatch.map(r => r.quarter)}::int[],
        ${inBatch.map(r => r.region)}::text[],
        ${inBatch.map(r => r.city)}::text[],
        ${inBatch.map(r => r.district)}::text[],
        ${inBatch.map(r => r.property_type)}::text[],
        ${inBatch.map(r => r.category)}::text[],
        ${inBatch.map(r => r.deals)}::int[],
        ${inBatch.map(r => r.avg_value)}::real[],
        ${inBatch.map(r => r.avg_per_m2)}::real[],
        ${inBatch.map(r => r.source)}::text[],
        ${inBatch.map(r => r.source_url)}::text[],
        ${inBatch.map(r => r.notes)}::text[]
      )
      ON CONFLICT DO NOTHING
    `;
    inserted += inBatch.length;
    inBatch = [];
  };

  const sourceUrl = `https://open.data.gov.sa/ar/datasets/view/${slug === 'riyadh-rent-city' ? '06939867-7a5c-436d-815d-c19cb878430a' : slug === 'riyadh-rent-q1-2026' ? '2dde7e8c-db79-4aec-be4e-37cef64c1d4d' : slug === 'riyadh-sales-q1-2026' ? '05cc087e-7151-42b2-8fbe-6e41e5813201' : slug === 'makkah-rent-city' ? 'a3096049-0662-4ecb-96b1-d86628dbde1e' : slug === 'madinah-rent-city' ? '86415b9b-dd94-4bd2-a2a9-496ba0bcc250' : slug === 'qassim-rent-city' ? '75d8dd7a-88fe-4d48-b69b-485a7afb0cc4' : slug === 'baha-rent-city' ? '5841795c-c6a7-45ad-97b8-49b4533f36f6' : 'a108f1ed-0091-4264-bb82-71a4ad0989f8'}`;
  const sourceName = 'الهيئة العامة للعقار';
  const note = 'بيانات مفتوحة رسمية — open.data.gov.sa';

  for (const r of rows) {
    let rec = null;
    if (kind === 'rent_city') {
      rec = {
        indicator_type: 'rent',
        year: toNum(get(r, ['السنة'])),
        quarter: toNum(get(r, ['الربع'])),
        region: get(r, ['المنطقة']),
        city: get(r, ['المدينة']),
        district: null,
        property_type: get(r, ['نوع العقار']),
        category: null,
        deals: toNum(get(r, ['مجموع الصفقات'])),
        avg_value: toNum(get(r, ['المتوسط'])),
        avg_per_m2: null,
      };
    } else if (kind === 'rent_district') {
      rec = {
        indicator_type: 'rent',
        year: toNum(get(r, ['السنة'])),
        quarter: toNum(get(r, ['الربع'])),
        region: get(r, ['المنطقة']),
        city: get(r, ['المدينة']),
        district: get(r, ['الحي']),
        property_type: get(r, ['نوع العقار']),
        category: get(r, ['تصنيف العقار']),
        deals: toNum(get(r, ['عدد الصفقات'])),
        avg_value: toNum(get(r, ['متوسط الايجار'])),
        avg_per_m2: toNum(get(r, ['لكل متر مربع'])),
      };
    } else if (kind === 'rent_english') {
      const year = toNum(get(r, ['year']));
      if (!year || year < 2023) continue;
      const city = get(r, ['city_ar']);
      if (!RELEVANT_CITIES.has(city) && city !== 'الدمام' && city !== 'الخبر') continue;
      rec = {
        indicator_type: 'rent',
        year,
        quarter: toNum(get(r, ['quarter'])),
        region: get(r, ['region_ar']),
        city,
        district: null,
        property_type: get(r, ['Category']),
        category: null,
        deals: toNum(get(r, ['total_deals'])),
        avg_value: toNum(get(r, ['average'])),
        avg_per_m2: null,
      };
    } else if (kind === 'sales') {
      rec = {
        indicator_type: 'sales',
        year: toNum(get(r, ['السنة'])),
        quarter: toNum(get(r, ['الربع'])),
        region: get(r, ['المنطقة']),
        city: get(r, ['المدينة']),
        district: null,
        property_type: get(r, ['النوع']),
        category: get(r, ['الاستخدام']),
        deals: toNum(get(r, ['عدد الصفقات'])),
        avg_value: toNum(get(r, ['مجموع قيم الصفقات'])),
        avg_per_m2: toNum(get(r, ['متوسط سعر المتر'])),
      };
    }

    if (!rec || !rec.year || rec.deals == null) { skipped++; continue; }
    rec.source = sourceName;
    rec.source_url = sourceUrl;
    rec.notes = note;
    inBatch.push(rec);
    if (inBatch.length >= 500) await flush();
  }
  await flush();
  console.log(`  ${file}: ${inBatch.length === 0 ? 'done' : 'done'} (inserted so far ${inserted})`);
}

console.log('Importing official indicators from open.data.gov.sa (REGA)...');
await sql`TRUNCATE official_indicators`;
for (const ds of DATASETS) {
  try {
    await importDataset(ds);
  } catch (e) {
    console.error('  error:', ds.file, e.message);
  }
}
const counts = await sql`SELECT indicator_type, COUNT(*)::int AS n FROM official_indicators GROUP BY indicator_type`;
console.log('\nDone. inserted rows (including conflicts skipped silently):', inserted, '| skipped:', skipped);
console.log(counts);
process.exit(0);
