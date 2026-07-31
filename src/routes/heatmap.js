import { Router } from 'express';
import sql from '../config/database.js';

const router = Router();

const cleanDistrict = (d) => (d || '').replace(/^(حي\s+)/, '').trim();

router.get('/', async (req, res) => {
  try {
    const [officialRows, ourRows] = await Promise.all([
      sql`
        SELECT
          district,
          ROUND(AVG(avg_value) FILTER (WHERE indicator_type = 'rent' AND avg_value > 0))::int AS avg_rent,
          ROUND(AVG(avg_value) FILTER (WHERE indicator_type = 'sale' AND avg_value > 0))::int AS avg_sale,
          COALESCE(SUM(deals) FILTER (WHERE indicator_type = 'rent'), 0)::int AS rent_deals,
          COALESCE(SUM(deals) FILTER (WHERE indicator_type = 'sale'), 0)::int AS sale_deals,
          MAX(year) AS latest_year,
          MAX(quarter) AS latest_quarter
        FROM official_indicators
        WHERE district IS NOT NULL AND district <> '' AND deals > 0
        GROUP BY district
        HAVING SUM(deals) > 0
      `,
      sql`
        SELECT district, city,
          COUNT(*)::int AS count,
          ROUND(AVG(price))::int AS avg_price,
          ROUND(AVG(price / NULLIF(area, 0)))::int AS avg_price_m2,
          AVG(lat)::float8 AS lat,
          AVG(lng)::float8 AS lng,
          COUNT(*) FILTER (WHERE lat IS NOT NULL AND lng IS NOT NULL)::int AS geocoded
        FROM properties
        WHERE district IS NOT NULL AND district <> ''
        GROUP BY district, city
      `
    ]);

    const ourByDistrict = {};
    for (const row of ourRows) {
      const key = cleanDistrict(row.district);
      ourByDistrict[key] = {
        district: row.district,
        city: row.city,
        ourCount: row.count,
        ourAvgPrice: row.avg_price,
        ourAvgPriceM2: row.avg_price_m2,
        lat: row.lat,
        lng: row.lng,
        geocoded: row.geocoded
      };
    }

    const officialByDistrict = {};
    for (const row of officialRows) {
      const key = cleanDistrict(row.district);
      if (!officialByDistrict[key]) {
        officialByDistrict[key] = {
          district: row.district,
          avgRent: row.avg_rent,
          avgSale: row.avg_sale,
          rentDeals: row.rent_deals,
          saleDeals: row.sale_deals,
          deals: row.rent_deals + row.sale_deals,
          latestYear: row.latest_year,
          latestQuarter: row.latest_quarter
        };
      } else {
        const d = officialByDistrict[key];
        if (!d.avgRent && row.avg_rent) d.avgRent = row.avg_rent;
        if (!d.avgSale && row.avg_sale) d.avgSale = row.avg_sale;
        d.rentDeals += row.rent_deals;
        d.saleDeals += row.sale_deals;
        d.deals += row.deals;
      }
    }

    const keys = new Set([...Object.keys(ourByDistrict), ...Object.keys(officialByDistrict)]);
    const districts = [...keys].map((key) => {
      const o = ourByDistrict[key] || { district: key, ourCount: 0 };
      const f = officialByDistrict[key] || {};
      return {
        district: key,
        city: o.city || (f.district ? null : null),
        ourCount: o.ourCount || 0,
        ourAvgPrice: o.ourAvgPrice || null,
        ourAvgPriceM2: o.ourAvgPriceM2 || null,
        avgRent: f.avgRent || null,
        avgSale: f.avgSale || null,
        rentDeals: f.rentDeals || 0,
        saleDeals: f.saleDeals || 0,
        deals: f.deals || 0,
        latestYear: f.latestYear || null,
        latestQuarter: f.latestQuarter || null,
        lat: o.lat || null,
        lng: o.lng || null
      };
    }).filter((d) => d.ourCount > 0 || d.deals > 0);

    res.json({
      success: true,
      districts,
      total: districts.length,
      note: 'متوسط الأسعار من بيانات الهيئة العامة للعقار (الرسمية) ومن عقارات دارك. الطلب من عدد العقود المسجلة.'
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'خطأ داخلي' });
  }
});

export default router;
