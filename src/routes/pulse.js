import { Router } from 'express';
import sql from '../config/database.js';

const router = Router();

router.get('/:district', async (req, res) => {
  try {
    const { district } = req.params;
    const [pulse] = await sql`SELECT * FROM neighbourhood_pulse WHERE district = ${district}`;
    if (!pulse) {
      return res.status(404).json({ success: false, error: 'لا توجد بيانات لهذا الحي' });
    }
    res.json({
      success: true,
      pulse: {
        ...pulse,
        metro_stations: JSON.parse(pulse.metro_stations || '[]'),
        nearby_projects: JSON.parse(pulse.nearby_projects || '[]'),
        green_spaces: JSON.parse(pulse.green_spaces || '[]')
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'خطأ داخلي' });
  }
});

router.get('/city/:city', async (req, res) => {
  try {
    const { city } = req.params;
    const pulse = await sql`SELECT * FROM neighbourhood_pulse WHERE city = ${city}`;
    res.json({
      success: true,
      pulse: pulse.map(p => ({
        ...p,
        metro_stations: JSON.parse(p.metro_stations || '[]'),
        nearby_projects: JSON.parse(p.nearby_projects || '[]'),
        green_spaces: JSON.parse(p.green_spaces || '[]')
      }))
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'خطأ داخلي' });
  }
});

export default router;
