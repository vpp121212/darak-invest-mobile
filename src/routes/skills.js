import { Router } from 'express';
import multer from 'multer';
import fs from 'fs/promises';
import os from 'os';
import path from 'path';
import { enqueueJob, getJobStatus } from '../services/queue.js';

const router = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 }
});

router.post('/convert', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'يرجى رفع ملف' });

    const ext = path.extname(req.file.originalname).toLowerCase();
    const allowed = ['.pdf', '.epub', '.docx', '.rtf', '.txt', '.md', '.html', '.mobi', '.azw3', '.azw'];
    if (!allowed.includes(ext)) {
      return res.status(400).json({ error: 'صيغة غير مدعومة. المدعومة: PDF, EPUB, DOCX, RTF, TXT, MD, HTML, MOBI' });
    }

    const workDir = await fs.mkdtemp(path.join(os.tmpdir(), 'book-skill-'));
    const inputPath = path.join(workDir, `book${ext}`);
    await fs.writeFile(inputPath, req.file.buffer);

    const { jobId, mode } = enqueueJob('skill:convert', { inputPath, originalname: req.file.originalname, workDir });
    res.status(202).json({ success: true, jobId, mode });
  } catch (err) {
    console.error('Skill conversion error:', err);
    res.status(500).json({ error: 'فشل استخراج النص. تأكد من الملف وحاول مجدداً' });
  }
});

router.get('/:jobId/status', async (req, res) => {
  const job = getJobStatus(req.params.jobId);
  if (!job) return res.status(404).json({ error: 'وظيفة غير موجودة' });
  const base = { jobId: req.params.jobId, state: job.state, progress: job.progress };
  if (job.state === 'completed') return res.json({ ...base, success: true, result: job.result });
  if (job.state === 'failed') return res.json({ ...base, error: job.error });
  return res.json(base);
});

router.get('/health', async (req, res) => {
  res.json({ ok: true, mode: process.env.REDIS_URL ? 'redis' : 'inline' });
});

export default router;
