import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';

const router = Router();

function genNum(prefix) {
  const n = Date.now().toString(36).toUpperCase() + Math.random().toString(36).substring(2, 5).toUpperCase();
  return `${prefix}-${n}`;
}

// عقود المستخدم الحالي.
router.get('/', protect, async (req, res) => {
  try {
    const { type, status, search } = req.query;
    const conditions = ['"userId" = $1'];
    const params = [req.userId];
    let idx = 2;
    if (type) { conditions.push(`contract_type = $${idx++}`); params.push(type); }
    if (status) { conditions.push(`status = $${idx++}`); params.push(status); }
    if (search) { conditions.push(`(contract_number ILIKE $${idx++} OR first_party ILIKE $${idx++} OR second_party ILIKE $${idx++})`); params.push(`%${search}%`, `%${search}%`, `%${search}%`); }
    const contracts = await sql.unsafe(
      `SELECT * FROM realestate_contracts WHERE ${conditions.join(' AND ')} ORDER BY "createdAt" DESC`,
      params
    );
    res.json({ success: true, contracts });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// إنشاء عقد.
router.post('/', protect, async (req, res) => {
  try {
    const { contract_type, first_party, second_party, property_desc, property_city, property_district, amount, payment_terms, duration, start_date, end_date, notes } = req.body;
    if (!contract_type || !first_party || !second_party) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'نوع العقد والطرفان مطلوبان' });
    }
    const contract_number = genNum('CTR');
    const [{ id }] = await sql`
      INSERT INTO realestate_contracts ("userId", contract_type, contract_number, first_party, second_party, property_desc, property_city, property_district, amount, payment_terms, duration, start_date, end_date, notes, status)
      VALUES (${req.userId}, ${contract_type}, ${contract_number}, ${first_party}, ${second_party}, ${property_desc || ''}, ${property_city || ''}, ${property_district || ''}, ${amount || 0}, ${payment_terms || ''}, ${duration || ''}, ${start_date || null}, ${end_date || null}, ${notes || ''}, 'draft')
      RETURNING id
    `;
    res.json({ success: true, id, contract_number, message: 'تم إنشاء العقد' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// توثيق عقد.
router.post('/:id/authenticate', protect, async (req, res) => {
  try {
    const [{ id }] = await sql`
      UPDATE realestate_contracts SET is_authenticated = 1, authenticated_at = NOW(), status = 'active', "updatedAt" = NOW() WHERE id = ${req.params.id} AND "userId" = ${req.userId}
      RETURNING id
    `;
    res.json({ success: true, message: 'تم توثيق العقد بنجاح', authenticated_at: new Date().toISOString() });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// تحديث عقد (حالة/ملاحظات).
router.put('/:id', protect, async (req, res) => {
  try {
    const { status, notes } = req.body;
    const updates = [];
    const params = [];
    let idx = 0;
    if (status) { updates.push(`status = $${++idx}`); params.push(status); }
    if (notes !== undefined) { updates.push(`notes = $${++idx}`); params.push(notes); }
    updates.push(`"updatedAt" = NOW()`);
    if (updates.length === 1) return res.status(400).json(Errors.custom('NO_UPDATES', 'لا توجد تحديثات').toJSON());
    params.push(req.params.id, req.userId);
    await sql.unsafe(
      `UPDATE realestate_contracts SET ${updates.join(', ')} WHERE id = $${++idx} AND "userId" = $${++idx}`,
      params
    );
    res.json({ success: true, message: 'تم تحديث العقد' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

export default router;
