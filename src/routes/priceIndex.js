import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';

const router = Router();

async function seedFromIndicators() {
  const [countRow] = await sql`SELECT COUNT(*) AS n FROM price_index`;
  if (Number(countRow?.n || 0) > 0) return 0;

  const aggregated = await sql`
    SELECT city, district, indicator_type, year, quarter, ROUND(AVG(avg_per_m2)::numeric, 1) AS avg_per_m2
    FROM official_indicators
    WHERE city IS NOT NULL AND avg_per_m2 IS NOT NULL
    GROUP BY city, district, indicator_type, year, quarter
    ORDER BY year, quarter
  `;

  let inserted = 0;
  for (const row of aggregated) {
    const period = `${row.year}-Q${row.quarter}`;
    const result = await sql`
      INSERT INTO price_index (city, district, indicator_type, period, value, unit)
      VALUES (${row.city}, ${row.district}, ${row.indicator_type === 'sales' ? 'average_price' : 'average_rent'}, ${period}, ${row.avg_per_m2}, 'ر.س/م²')
      ON CONFLICT (city, district, indicator_type, period) DO NOTHING
    `;
    inserted += Number(result.count || 0);
  }
  return inserted;
}

// مؤشر الأسعار التاريخي مع فلترة اختيارية.
router.get('/', async (req, res) => {
  const { city, district, indicator_type, period, limit = 50 } = req.query;
  try {
    await seedFromIndicators();
    const rows = await sql`
      SELECT * FROM price_index
      WHERE (${city}::text IS NULL OR city = ${city})
        AND (${district}::text IS NULL OR district = ${district})
        AND (${indicator_type}::text IS NULL OR indicator_type = ${indicator_type})
        AND (${period}::text IS NULL OR period = ${period})
      ORDER BY period, city, district
      LIMIT ${Number(limit)}
    `;
    res.json({ success: true, points: rows });
  } catch (err) {
    if (err?.message?.includes('DATABASE_URL is required')) {
      return res.json({ success: true, points: [], source: 'unavailable' });
    }
    console.error(err); res.status(500).json(Errors.internal().toJSON());
  }
});

// إعادة توليد بيانات المؤشر من المؤشرات الرسمية.
router.post('/seed', protect, async (req, res) => {
  try {
    const inserted = await seedFromIndicators();
    res.json({ success: true, inserted });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

export default router;
