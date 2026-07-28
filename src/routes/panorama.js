import { Router } from 'express';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const router = Router();

router.get('/:name', (req, res) => {
  const name = req.params.name.replace(/[^a-zA-Z0-9_.-]/g, '');
  const filePath = join(__dirname, '..', 'uploads', 'panorama', name);
  res.sendFile(filePath, (err) => {
    if (err) res.status(404).json({ error: 'not found' });
  });
});

export default router;
