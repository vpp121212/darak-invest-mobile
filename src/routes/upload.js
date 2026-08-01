import { Router } from 'express';
import multer from 'multer';
import sharp from 'sharp';
import { protect } from '../middleware/auth.js';
import { randomUUID } from 'crypto';

const router = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (/jpeg|jpg|png|webp/.test(file.mimetype)) cb(null, true);
    else cb(new Error('صيغة غير مدعومة'));
  }
});

router.post('/image', protect, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'لم يتم اختيار ملف' });
    const filename = `${randomUUID()}.webp`;
    await sharp(req.file.buffer).resize(1200, 800, { fit: 'cover' }).webp({ quality: 85 }).toFile(`src/uploads/images/${filename}`);
    res.json({ success: true, url: `/uploads/images/${filename}` });
  } catch (err) { res.status(500).json({ error: 'خطأ في الرفع' }); }
});

router.post('/images', protect, upload.array('images', 20), async (req, res) => {
  try {
    if (!req.files?.length) return res.status(400).json({ error: 'لم يتم اختيار ملفات' });
    const uploads = await Promise.all(req.files.map(async (file) => {
      const filename = `${randomUUID()}.webp`;
      await sharp(file.buffer).resize(1200, 800, { fit: 'cover' }).webp({ quality: 85 }).toFile(`src/uploads/images/${filename}`);
      return { url: `/uploads/images/${filename}` };
    }));
    res.json({ success: true, images: uploads });
  } catch (err) { res.status(500).json({ error: 'خطأ في الرفع' }); }
});

router.post('/panoramic', protect, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'لم يتم اختيار ملف' });
    const filename = `${randomUUID()}.webp`;
    await sharp(req.file.buffer).resize(4000, 2000, { fit: 'cover' }).webp({ quality: 90 }).toFile(`src/uploads/panoramic/${filename}`);
    res.json({ success: true, url: `/uploads/panoramic/${filename}` });
  } catch (err) { res.status(500).json({ error: 'خطأ في الرفع' }); }
});

export default router;
