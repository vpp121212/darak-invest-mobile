import { Router } from 'express';
import sql from '../config/database.js';
import { protect, authorize } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';

const router = Router();

router.get('/stats', protect, authorize('admin', 'owner'), async (req, res) => {
  try {
    const [[userCount], [propCount], [agentCount], [pendingCount], [revenue]] = await Promise.all([
      sql`SELECT COUNT(*)::int as total FROM users`,
      sql`SELECT COUNT(*)::int as total FROM properties WHERE status = 'active'`,
      sql`SELECT COUNT(*)::int as total FROM agents`,
      sql`SELECT COUNT(*)::int as total FROM properties WHERE status = 'pending'`,
      sql`SELECT COALESCE(SUM(amount), 0) as total FROM payments WHERE status = 'paid'`
    ]);
    const [monthlyRevenue] = await sql`
      SELECT COALESCE(SUM(amount), 0) as total FROM payments
      WHERE status = 'paid' AND "paidAt" >= ${new Date(Date.now() - 30 * 86400000).toISOString().split('T')[0]}
    `;
    const recentUsers = await sql`
      SELECT id, name, email, role, "createdAt" FROM users ORDER BY "createdAt" DESC LIMIT 5
    `;
    const recentProperties = await sql`
      SELECT id, title, city, district, price, "createdAt" FROM properties WHERE status = 'active' ORDER BY "createdAt" DESC LIMIT 5
    `;
    const cityStats = await sql`
      SELECT city, COUNT(*)::int as count FROM properties WHERE status = 'active' GROUP BY city ORDER BY count DESC
    `;
    const roleStats = await sql`
      SELECT role, COUNT(*)::int as count FROM users GROUP BY role ORDER BY count DESC
    `;
    res.json({ success: true, stats: {
      users: userCount.total,
      properties: propCount.total,
      agents: agentCount.total,
      pending: pendingCount.total,
      totalRevenue: revenue.total,
      monthlyRevenue: monthlyRevenue.total,
      recentUsers,
      recentProperties,
      cityStats,
      roleStats,
      isOwner: req.user.role === 'owner'
    }});
  } catch (err) {
    console.error('Dashboard stats error:', err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

export default router;
