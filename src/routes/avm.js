import { Router } from 'express';
import Joi from 'joi';
import sql from '../config/database.js';
import { validate } from '../middleware/validate.js';
import { createRateLimiter } from '../middleware/security.js';
import { evaluateAVM } from '../services/avm.js';
import { Errors } from '../utils/errors.js';

const router = Router();
const avmLimiter = createRateLimiter('basic');

const avmSchema = Joi.object({
  propertyId: Joi.number().integer().positive().optional(),
  city: Joi.string().max(60).optional(),
  district: Joi.string().max(60).optional(),
  type: Joi.string().max(30).optional(),
  purpose: Joi.string().valid('بيع', 'إيجار').optional(),
  area: Joi.number().positive().max(100000).optional(),
  rooms: Joi.number().integer().min(0).max(50).optional(),
  baths: Joi.number().integer().min(0).max(50).optional(),
  year: Joi.number().integer().min(1950).max(new Date().getFullYear() + 1).optional(),
  age: Joi.number().integer().min(0).max(200).optional(),
  price: Joi.number().positive().max(1e12).optional()
}).or('propertyId', 'city');

router.post('/evaluate', avmLimiter, validate.body(avmSchema), async (req, res) => {
  try {
    let input = { ...req.body };

    if (input.propertyId) {
      const [p] = await sql`SELECT * FROM properties WHERE id = ${input.propertyId}`;
      if (!p) return res.status(404).json(Errors.notFound('العقار').toJSON());
      input = {
        propertyId: p.id,
        city: p.city,
        district: p.district,
        type: p.type,
        purpose: p.purpose,
        area: p.area,
        rooms: p.rooms,
        baths: p.baths,
        year: p.year,
        age: p.age,
        price: p.price
      };
    }

    const required = ['city', 'district', 'type', 'purpose', 'area'];
    if (!required.every(k => input[k])) {
      return res.status(400).json(Errors.custom('MISSING_FIELDS', 'المدينة، الحي، النوع، الغرض والمساحة مطلوبة').toJSON());
    }

    const valuation = await evaluateAVM(input);

    if (input.propertyId && valuation.estimate) {
      try {
        await sql`
          UPDATE properties
          SET "expectedPrice" = ${valuation.estimate},
              "suitablePrice" = ${valuation.min},
              "maximumPrice" = ${valuation.max},
              "saleChance" = ${valuation.confidence}
          WHERE id = ${input.propertyId}
        `;
      } catch (e) { console.error('AVM persist error:', e); }
    }

    res.json({
      success: true,
      valuation,
      disclaimer: 'تقييم آلي لأغراض استرشادية مبني على الأسعار المنشورة والبيانات الرسمية للهيئة العامة للعقار، ولا يُعتبر تقريراً رسمياً لتثمين العقار.'
    });
  } catch (err) {
    console.error('AVM error:', err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

export default router;
