import { Router } from 'express';
import multer from 'multer';
import { randomUUID } from 'crypto';
import os from 'os';
import path from 'path';
import fs from 'fs/promises';
import { protect } from '../middleware/auth.js';
import { processJob } from '../services/queue.js';

const router = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (/jpeg|jpg|png|webp/.test(file.mimetype)) cb(null, true);
    else cb(new Error('صيغة غير مدعومة'));
  }
});

async function stageImage(buffer) {
  const dir = fs.mkdtemp(path.join(os.tmpdir(), 'darak-img-'));
  const inputPath = path.join(dir, `${randomUUID()}.bin`);
  await fs.writeFile(inputPath, buffer);
  return inputPath;
}

router.post('/image', protect, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'لم يتم اختيار ملف' });
    const inputPath = await stageImage(req.file.buffer);
    const result = await processJob('image:process', {
      inputPath,
      filename: `${randomUUID()}.webp`,
      dir: 'images'
    });
    res.json({ success: true, url: result.url });
  } catch (err) { res.status(500).json({ error: 'خطأ في الرفع' }); }
});

router.post('/images', protect, upload.array('images', 20), async (req, res) => {
  try {
    if (!req.files?.length) return res.status(400).json({ error: 'لم يتم اختيار ملفات' });
    const uploads = await Promise.all(req.files.map(async (file) => {
      const inputPath = await stageImage(file.buffer);
      return processJob('image:process', {
        inputPath,
        filename: `${randomUUID()}.webp`,
        dir: 'images'
      });
    }));
    res.json({ success: true, images: uploads });
  } catch (err) { res.status(500).json({ error: 'خطأ في الرفع' }); }
});

router.post('/panoramic', protect, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'لم يتم اختيار ملف' });
    const inputPath = await stageImage(req.file.buffer);
    const result = await processJob('image:process', {
      inputPath,
      filename: `${randomUUID()}.webp`,
      dir: 'panoramic'
    });
    res.json({ success: true, url: result.url });
  } catch (err) { res.status(500).json({ error: 'خطأ في الرفع' }); }
});

export default router;
