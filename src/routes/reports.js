import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { z } from 'zod';
import { Errors } from '../utils/errors.js';

const router = Router();

const reportSchema = z.object({
  propertyId: z.number().int().positive(),
  reason: z.string().min(1).max(200),
  description: z.string().max(1000).optional().default(''),
});

router.post('/', protect, validate.body(reportSchema), async (req, res) => {
  try {
    const { propertyId, reason, description } = req.body;

    const [exists] = await sql`SELECT id FROM properties WHERE id = ${propertyId}`;
    if (!exists) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'العقار غير موجود' });
    }

    const [existingReport] = await sql`
      SELECT id FROM reports WHERE "userId" = ${req.user.id} AND "propertyId" = ${propertyId} AND status = 'pending'
    `;
    if (existingReport) {
      return res.status(409).json({ code: 'DUPLICATE', message: 'لقد أبلغت عن هذا العقار مسبقًا' });
    }

    const [report] = await sql`
      INSERT INTO reports ("userId", "propertyId", reason, description)
      VALUES (${req.user.id}, ${propertyId}, ${reason}, ${description})
      RETURNING id, reason, status, "createdAt"
    `;

    res.status(201).json({ message: 'تم استلام البلاغ بنجاح', report });
  } catch (error) {
    console.error('Report Error:', error);
    res.status(500).json(Errors.internal().toJSON());
  }
});

export default router;
