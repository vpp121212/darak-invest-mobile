import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { z } from 'zod';
import { Errors } from '../utils/errors.js';

const router = Router();

const addRatingSchema = z.object({
  advertiserId: z.number().int().positive(),
  score: z.number().int().min(1).max(5),
  comment: z.string().max(500).optional().default(''),
});

async function getAdvertiserRating(advertiserId) {
  const ratings = await sql`SELECT score FROM ratings WHERE "advertiserId" = ${advertiserId}`;
  if (!ratings.length) return { average: 0, count: 0 };
  const avg = ratings.reduce((sum, r) => sum + r.score, 0) / ratings.length;
  return { average: Math.round(avg * 10) / 10, count: ratings.length };
}

router.post('/', protect, validate.body(addRatingSchema), async (req, res) => {
  try {
    const { advertiserId, score, comment } = req.body;

    if (advertiserId === req.user.id) {
      return res.status(400).json({ code: 'SELF_RATING', message: 'لا يمكنك تقييم نفسك' });
    }

    const [adv] = await sql`SELECT id FROM users WHERE id = ${advertiserId}`;
    if (!adv) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'المعلن غير موجود' });
    }

    const [existing] = await sql`
      SELECT id FROM ratings WHERE "advertiserId" = ${advertiserId} AND "userId" = ${req.user.id}
    `;
    if (existing) {
      return res.status(409).json({ code: 'DUPLICATE', message: 'لقد قيّمت هذا المعلن مسبقًا' });
    }

    await sql`
      INSERT INTO ratings ("advertiserId", "userId", score, comment)
      VALUES (${advertiserId}, ${req.user.id}, ${score}, ${comment})
    `;

    res.json({ message: 'تم إضافة التقييم بنجاح' });
  } catch (err) {
    console.error('Rating Error:', err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

router.get('/advertiser/:id', async (req, res) => {
  try {
    const advertiserId = parseInt(req.params.id);
    const ratings = await sql`
      SELECT r.score, r.comment, r."createdAt", u.name as "userName"
      FROM ratings r LEFT JOIN users u ON r."userId" = u.id
      WHERE r."advertiserId" = ${advertiserId}
      ORDER BY r."createdAt" DESC
    `;
    const summary = await getAdvertiserRating(advertiserId);
    res.json({ average: summary.average, count: summary.count, ratings });
  } catch (err) {
    console.error(err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

router.get('/my-rating/:advertiserId', protect, async (req, res) => {
  try {
    const [r] = await sql`
      SELECT score, comment FROM ratings WHERE "advertiserId" = ${parseInt(req.params.advertiserId)} AND "userId" = ${req.user.id}
    `;
    res.json({ rating: r || null });
  } catch (err) {
    res.status(500).json(Errors.internal().toJSON());
  }
});

export { getAdvertiserRating };
export default router;
