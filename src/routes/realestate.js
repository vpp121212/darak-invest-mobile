import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';

const router = Router();

function genNum(prefix) {
  const n = Date.now().toString(36).toUpperCase() + Math.random().toString(36).substring(2, 5).toUpperCase();
  return `${prefix}-${n}`;
}

router.get('/licenses', protect, async (req, res) => {
  try {
    const { type, search, status } = req.query;
    let conditions = ['"userId" = $1'];
    let params = [req.userId];
    let idx = 2;
    if (type) { conditions.push(`license_type = $${idx++}`); params.push(type); }
    if (status) { conditions.push(`status = $${idx++}`); params.push(status); }
    if (search) { conditions.push(`(holder_name ILIKE $${idx++} OR license_number ILIKE $${idx++})`); params.push(`%${search}%`, `%${search}%`); }

    const licenses = await sql.unsafe(
      `SELECT * FROM realestate_licenses WHERE ${conditions.join(' AND ')} ORDER BY "createdAt" DESC`,
      params
    );
    res.json({ success: true, licenses });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.get('/licenses/all', async (req, res) => {
  try {
    const { type, city, search } = req.query;
    let conditions = ['1=1'];
    let params = [];
    let idx = 1;
    if (type) { conditions.push(`license_type = $${idx++}`); params.push(type); }
    if (city) { conditions.push(`city = $${idx++}`); params.push(city); }
    if (search) { conditions.push(`(holder_name ILIKE $${idx++} OR license_number ILIKE $${idx++})`); params.push(`%${search}%`, `%${search}%`); }

    const licenses = await sql.unsafe(
      `SELECT * FROM realestate_licenses WHERE ${conditions.join(' AND ')} AND status = 'active' ORDER BY "createdAt" DESC LIMIT 50`,
      params
    );
    res.json({ success: true, licenses });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.post('/licenses', protect, async (req, res) => {
  try {
    const { license_type, holder_name, holder_id, city, notes } = req.body;
    const license_number = genNum('LIC');
    const [{ id }] = await sql`
      INSERT INTO realestate_licenses ("userId", license_type, license_number, holder_name, holder_id, city, status, issue_date, expiry_date, notes)
      VALUES (${req.userId}, ${license_type}, ${license_number}, ${holder_name}, ${holder_id || ''}, ${city || ''}, 'pending', ${new Date().toISOString().split('T')[0]}, ${new Date(Date.now() + 365 * 86400000).toISOString().split('T')[0]}, ${notes || ''})
      RETURNING id
    `;
    res.json({ success: true, id, license_number, message: 'تم تقديم طلب الترخيص' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.put('/licenses/:id/status', protect, async (req, res) => {
  try {
    const { status } = req.body;
    const [{ id }] = await sql`
      UPDATE realestate_licenses SET status = ${status}, "updatedAt" = NOW() WHERE id = ${req.params.id} AND "userId" = ${req.userId}
      RETURNING id
    `;
    res.json({ success: true, message: 'تم تحديث حالة الترخيص' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.get('/contracts', protect, async (req, res) => {
  try {
    const { type, search, status } = req.query;
    let conditions = ['"userId" = $1'];
    let params = [req.userId];
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

router.post('/contracts', protect, async (req, res) => {
  try {
    const { contract_type, first_party, second_party, property_desc, property_city, property_district, amount, payment_terms, duration, start_date, end_date, notes } = req.body;
    const contract_number = genNum('CTR');
    const [{ id }] = await sql`
      INSERT INTO realestate_contracts ("userId", contract_type, contract_number, first_party, second_party, property_desc, property_city, property_district, amount, payment_terms, duration, start_date, end_date, notes, status)
      VALUES (${req.userId}, ${contract_type}, ${contract_number}, ${first_party}, ${second_party}, ${property_desc || ''}, ${property_city || ''}, ${property_district || ''}, ${amount || 0}, ${payment_terms || ''}, ${duration || ''}, ${start_date || null}, ${end_date || null}, ${notes || ''}, 'draft')
      RETURNING id
    `;
    res.json({ success: true, id, contract_number, message: 'تم إنشاء العقد' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.post('/contracts/:id/authenticate', protect, async (req, res) => {
  try {
    const [{ id }] = await sql`
      UPDATE realestate_contracts SET is_authenticated = 1, authenticated_at = NOW(), status = 'active', "updatedAt" = NOW() WHERE id = ${req.params.id} AND "userId" = ${req.userId}
      RETURNING id
    `;
    res.json({ success: true, message: 'تم توثيق العقد بنجاح', authenticated_at: new Date().toISOString() });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.put('/contracts/:id', protect, async (req, res) => {
  try {
    const { status, notes } = req.body;
    const updates = [];
    let params = [];
    let idx = 0;
    if (status) { updates.push(`status = $${++idx}`); params.push(status); }
    if (notes !== undefined) { updates.push(`notes = $${++idx}`); params.push(notes); }
    updates.push(`"updatedAt" = NOW()`);
    if (updates.length === 0) return res.status(400).json(Errors.custom('NO_UPDATES', 'لا توجد تحديثات').toJSON());

    params.push(req.params.id, req.userId);
    await sql.unsafe(
      `UPDATE realestate_contracts SET ${updates.join(', ')} WHERE id = $${++idx} AND "userId" = $${++idx}`,
      params
    );
    res.json({ success: true, message: 'تم تحديث العقد' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.get('/delivery-forms', protect, async (req, res) => {
  try {
    const { form_type, search } = req.query;
    let conditions = ['df."userId" = $1'];
    let params = [req.userId];
    let idx = 2;
    if (form_type) { conditions.push(`df.form_type = $${idx++}`); params.push(form_type); }
    if (search) { conditions.push(`(df.lessor_name ILIKE $${idx++} OR df.lessee_name ILIKE $${idx++} OR df.unit_desc ILIKE $${idx++})`); params.push(`%${search}%`, `%${search}%`, `%${search}%`); }

    const forms = await sql.unsafe(
      `SELECT df.*, p.title as property_title FROM realestate_delivery_forms df LEFT JOIN properties p ON df.property_id = p.id WHERE ${conditions.join(' AND ')} ORDER BY df."createdAt" DESC`,
      params
    );
    res.json({ success: true, forms });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.post('/delivery-forms', protect, async (req, res) => {
  try {
    const { form_type, property_id, unit_desc, unit_address, lessor_name, lessee_name, handover_date, condition_notes, meter_readings, keys_count, attachments } = req.body;
    const [{ id }] = await sql`
      INSERT INTO realestate_delivery_forms ("userId", property_id, form_type, unit_desc, unit_address, lessor_name, lessee_name, handover_date, condition_notes, meter_readings, keys_count, attachments)
      VALUES (${req.userId}, ${property_id || null}, ${form_type}, ${unit_desc}, ${unit_address || ''}, ${lessor_name}, ${lessee_name}, ${handover_date || null}, ${condition_notes || ''}, ${meter_readings || ''}, ${keys_count || 0}, ${attachments || '[]'})
      RETURNING id
    `;
    res.json({ success: true, id, message: 'تم حفظ النموذج' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.get('/rental-invoices', protect, async (req, res) => {
  try {
    const { status, search } = req.query;
    let conditions = ['ri."userId" = $1'];
    let params = [req.userId];
    let idx = 2;
    if (status) { conditions.push(`ri.status = $${idx++}`); params.push(status); }
    if (search) { conditions.push(`(ri.tenant_name ILIKE $${idx++} OR ri.invoice_number ILIKE $${idx++})`); params.push(`%${search}%`, `%${search}%`); }

    const invoices = await sql.unsafe(
      `SELECT ri.*, p.title as property_title FROM realestate_rental_invoices ri LEFT JOIN properties p ON ri.property_id = p.id WHERE ${conditions.join(' AND ')} ORDER BY ri."createdAt" DESC`,
      params
    );

    const [stats] = await sql.unsafe(`
      SELECT COALESCE(SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END), 0) as paid_total,
             COALESCE(SUM(CASE WHEN status = 'pending' THEN total_amount ELSE 0 END), 0) as pending_total,
             COALESCE(SUM(CASE WHEN status = 'overdue' THEN total_amount ELSE 0 END), 0) as overdue_total,
             COUNT(*)::int as count
      FROM realestate_rental_invoices WHERE "userId" = $1
    `, [req.userId]);

    res.json({ success: true, invoices, stats });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.post('/rental-invoices', protect, async (req, res) => {
  try {
    const { property_id, tenant_name, period_from, period_to, rent_amount, services_fee, tax_amount, payment_method, notes } = req.body;
    const total_amount = (rent_amount || 0) + (services_fee || 0) + (tax_amount || 0);
    const invoice_number = genNum('INV');
    const [{ id }] = await sql`
      INSERT INTO realestate_rental_invoices ("userId", invoice_number, property_id, tenant_name, period_from, period_to, rent_amount, services_fee, tax_amount, total_amount, payment_method, notes)
      VALUES (${req.userId}, ${invoice_number}, ${property_id || null}, ${tenant_name}, ${period_from || null}, ${period_to || null}, ${rent_amount}, ${services_fee || 0}, ${tax_amount || 0}, ${total_amount}, ${payment_method || 'نقدي'}, ${notes || ''})
      RETURNING id
    `;
    res.json({ success: true, id, invoice_number, total_amount, message: 'تم إصدار الفاتورة الإيجارية' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.put('/rental-invoices/:id/pay', protect, async (req, res) => {
  try {
    await sql`
      UPDATE realestate_rental_invoices SET status = 'paid', paid_at = NOW() WHERE id = ${req.params.id} AND "userId" = ${req.userId}
    `;
    res.json({ success: true, message: 'تم تسجيل الدفع' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.get('/certificates', protect, async (req, res) => {
  try {
    const { status } = req.query;
    let conditions = ['c."userId" = $1'];
    let params = [req.userId];
    let idx = 2;
    if (status) { conditions.push(`c.status = $${idx++}`); params.push(status); }

    const certificates = await sql.unsafe(
      `SELECT c.*, p.title as property_title FROM realestate_certificates c LEFT JOIN properties p ON c.property_id = p.id WHERE ${conditions.join(' AND ')} ORDER BY c."createdAt" DESC`,
      params
    );
    res.json({ success: true, certificates });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.post('/certificates', protect, async (req, res) => {
  try {
    const { certificate_type, property_id, property_desc, total_units, unit_details, engineer_name, notes } = req.body;
    const certificate_number = genNum('CERT');
    const [{ id }] = await sql`
      INSERT INTO realestate_certificates ("userId", certificate_type, property_id, property_desc, total_units, unit_details, certificate_number, engineer_name, notes)
      VALUES (${req.userId}, ${certificate_type}, ${property_id || null}, ${property_desc || ''}, ${total_units || 0}, ${unit_details || '[]'}, ${certificate_number}, ${engineer_name || ''}, ${notes || ''})
      RETURNING id
    `;
    res.json({ success: true, id, certificate_number, message: 'تم تقديم طلب الشهادة' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.get('/deeds', protect, async (req, res) => {
  try {
    const { search } = req.query;
    let conditions = ['d."userId" = $1'];
    let params = [req.userId];
    let idx = 2;
    if (search) { conditions.push(`(d.deed_number ILIKE $${idx++} OR d.owner_name ILIKE $${idx++} OR d.property_desc ILIKE $${idx++})`); params.push(`%${search}%`, `%${search}%`, `%${search}%`); }

    const deeds = await sql.unsafe(
      `SELECT d.*, p.title as property_title FROM realestate_deeds d LEFT JOIN properties p ON d.property_id = p.id WHERE ${conditions.join(' AND ')} ORDER BY d."createdAt" DESC`,
      params
    );
    res.json({ success: true, deeds });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.post('/deeds', protect, async (req, res) => {
  try {
    const { property_desc, property_city, property_district, area, boundaries, owner_name, deed_type, issuing_court, issue_date, notes } = req.body;
    const deed_number = genNum('DEED');
    const [{ id }] = await sql`
      INSERT INTO realestate_deeds ("userId", deed_number, property_desc, property_city, property_district, area, boundaries, owner_name, deed_type, issuing_court, issue_date, notes)
      VALUES (${req.userId}, ${deed_number}, ${property_desc}, ${property_city || ''}, ${property_district || ''}, ${area || 0}, ${boundaries || ''}, ${owner_name}, ${deed_type || 'صك ملكية'}, ${issuing_court || 'المحكمة العامة'}, ${issue_date || null}, ${notes || ''})
      RETURNING id
    `;
    res.json({ success: true, id, deed_number, message: 'تم تسجيل الصك' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.get('/dashboard', protect, async (req, res) => {
  try {
    const [licenseCount] = await sql`SELECT COUNT(*)::int as count FROM realestate_licenses WHERE "userId" = ${req.userId}`;
    const [contractCount] = await sql`SELECT COUNT(*)::int as count, COALESCE(SUM(CASE WHEN is_authenticated = 1 THEN 1 ELSE 0 END), 0)::int as authenticated FROM realestate_contracts WHERE "userId" = ${req.userId}`;
    const [deliveryCount] = await sql`SELECT COUNT(*)::int as count FROM realestate_delivery_forms WHERE "userId" = ${req.userId}`;
    const [invoiceStats] = await sql`SELECT COUNT(*)::int as count, COALESCE(SUM(total_amount), 0) as total FROM realestate_rental_invoices WHERE "userId" = ${req.userId}`;
    const [deedCount] = await sql`SELECT COUNT(*)::int as count FROM realestate_deeds WHERE "userId" = ${req.userId}`;

    res.json({
      success: true,
      stats: {
        licenses: licenseCount.count,
        contracts: contractCount.count,
        contracts_authenticated: contractCount.authenticated,
        delivery_forms: deliveryCount.count,
        invoices: invoiceStats.count,
        invoice_total: invoiceStats.total,
        deeds: deedCount.count
      }
    });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

export default router;
