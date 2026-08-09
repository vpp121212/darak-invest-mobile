import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';

const router = Router();

function otherUserId(conversation, me) {
  return conversation.userOneId === me ? conversation.userTwoId : conversation.userOneId;
}

async function loadConversation(id, me) {
  const [conversation] = await sql`
    SELECT c.*, p.title AS "propertyTitle", p.images
    FROM conversations c
    LEFT JOIN properties p ON p.id = c."propertyId"
    WHERE c.id = ${id}
  `;
  if (!conversation) return null;
  const otherId = otherUserId(conversation, me);
  const [other] = await sql`SELECT id, name, phone FROM users WHERE id = ${otherId}`;
  return { ...conversation, otherId, otherName: other?.name || '', otherPhone: other?.phone || '' };
}

// بدء محادثة أو إرجاع الموجودة مع مستخدم معيّن (وعقار اختياري).
router.post('/conversations', protect, async (req, res) => {
  try {
    const { userId, propertyId } = req.body;
    if (!userId || Number(userId) === req.user.id) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'مستلم غير صالح' });
    }
    const [other] = await sql`SELECT id FROM users WHERE id = ${userId}`;
    if (!other) return res.status(404).json(Errors.notFound('المستخدم').toJSON());

    const a = Math.min(req.user.id, other.id);
    const b = Math.max(req.user.id, other.id);
    const property = propertyId ? Number(propertyId) : null;

    const [existing] = property
      ? await sql`SELECT * FROM conversations WHERE "userOneId"=${a} AND "userTwoId"=${b} AND "propertyId"=${property}`
      : await sql`SELECT * FROM conversations WHERE "userOneId"=${a} AND "userTwoId"=${b} AND "propertyId" IS NULL`;

    if (existing) {
      return res.status(200).json({ success: true, conversationId: existing.id });
    }

    const [result] = await sql`
      INSERT INTO conversations ("userOneId", "userTwoId", "propertyId")
      VALUES (${a}, ${b}, ${property})
      RETURNING id
    `;
    res.status(201).json({ success: true, conversationId: result.id });
  } catch (err) {
    console.error(err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

// قائمة محادثاتي مع آخر رسالة وعدد غير المقروء.
router.get('/conversations', protect, async (req, res) => {
  try {
    const rows = await sql`
      SELECT c.*, p.title AS "propertyTitle", p.images,
             u.name AS "otherName", u.phone AS "otherPhone"
      FROM conversations c
      LEFT JOIN properties p ON p.id = c."propertyId"
      LEFT JOIN users u ON u.id = CASE WHEN c."userOneId" = ${req.user.id} THEN c."userTwoId" ELSE c."userOneId" END
      WHERE c."userOneId" = ${req.user.id} OR c."userTwoId" = ${req.user.id}
      ORDER BY c."lastMessageAt" DESC
    `;
    const conversations = rows.map((r) => ({
      ...r,
      unread: r.userOneId === req.user.id ? r.unreadOne : r.unreadTwo,
      otherId: r.userOneId === req.user.id ? r.userTwoId : r.userOneId,
      otherName: r.otherName || '',
      otherPhone: r.otherPhone || '',
      images: (() => {
        try {
          const parsed = JSON.parse(r.images || '[]');
          return Array.isArray(parsed) ? parsed : [];
        } catch (_) {
          return [];
        }
      })(),
    }));
    res.json({ success: true, conversations });
  } catch (err) {
    console.error(err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

// رسائل محادثة معيّنة.
router.get('/conversations/:id/messages', protect, async (req, res) => {
  try {
    const conversation = await loadConversation(req.params.id, req.user.id);
    if (!conversation) return res.status(404).json(Errors.notFound('المحادثة').toJSON());
    const messages = await sql`
      SELECT id, "senderId", body, "isRead", "createdAt"
      FROM messages WHERE "conversationId" = ${req.params.id}
      ORDER BY "createdAt" ASC
    `;
    // تعليم رسائل الطرف الآخر كمقروءة
    await sql`UPDATE messages SET "isRead" = 1
              WHERE "conversationId" = ${req.params.id} AND "senderId" != ${req.user.id}`;
    if (req.user.id === conversation.userOneId) {
      await sql`UPDATE conversations SET "unreadOne" = 0 WHERE id = ${req.params.id}`;
    } else {
      await sql`UPDATE conversations SET "unreadTwo" = 0 WHERE id = ${req.params.id}`;
    }
    res.json({ success: true, messages });
  } catch (err) {
    console.error(err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

// إرسال رسالة في محادثة.
router.post('/conversations/:id/messages', protect, async (req, res) => {
  try {
    const { body } = req.body;
    if (!body || !body.trim()) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'نص الرسالة مطلوب' });
    }
    const conversation = await loadConversation(req.params.id, req.user.id);
    if (!conversation) return res.status(404).json(Errors.notFound('المحادثة').toJSON());

    const clean = String(body).trim().slice(0, 2000);
    const [result] = await sql`
      INSERT INTO messages ("conversationId", "senderId", body)
      VALUES (${req.params.id}, ${req.user.id}, ${clean})
      RETURNING id
    `;

    const otherUnreadField = req.user.id === conversation.userOneId ? 'unreadTwo' : 'unreadOne';
    await sql`
      UPDATE conversations
      SET "lastMessage" = ${clean}, "lastMessageAt" = NOW(),
          ${sql.unsafe(`"${otherUnreadField}"`)} = ${sql.unsafe(`"${otherUnreadField}"`)} + 1
      WHERE id = ${req.params.id}
    `;

    await notify(
      conversation.otherId,
      'رسالة جديدة',
      `${req.user.name}: ${clean.length > 60 ? clean.slice(0, 60) + '…' : clean}`,
      'message'
    );

    res.status(201).json({ success: true, id: result.id });
  } catch (err) {
    console.error(err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

async function notify(userId, title, message, type = 'info') {
  if (!userId) return;
  try {
    await sql`INSERT INTO notifications ("userId", title, message, type)
              VALUES (${userId}, ${title}, ${message}, ${type})`;
  } catch (err) {
    console.error('[notify]', err.message);
  }
}

export default router;
