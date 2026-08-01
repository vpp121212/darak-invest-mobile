import { Router } from 'express';
import multer from 'multer';
import { execFile } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import os from 'os';
import path from 'path';
import crypto from 'crypto';

const run = promisify(execFile);
const router = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 }
});

router.post('/convert', upload.single('file'), async (req, res) => {
  let workDir = null;
  try {
    if (!req.file) return res.status(400).json({ error: 'يرجى رفع ملف' });

    const ext = path.extname(req.file.originalname).toLowerCase();
    const allowed = ['.pdf', '.epub', '.docx', '.rtf', '.txt', '.md', '.html', '.mobi', '.azw3', '.azw'];
    if (!allowed.includes(ext)) {
      return res.status(400).json({ error: 'صيغة غير مدعومة. المدعومة: PDF, EPUB, DOCX, RTF, TXT, MD, HTML, MOBI' });
    }

    workDir = fs.mkdtemp(path.join(os.tmpdir(), 'book-skill-'));
    const inputPath = path.join(workDir, `book${ext}`);
    await fs.writeFile(inputPath, req.file.buffer);

    await run('python3', ['-m', 'book_to_skill', inputPath, '--install-missing', 'no'], {
      env: { ...process.env, BOOK_SKILL_WORKDIR: workDir },
      cwd: process.cwd(),
      timeout: 180000
    });

    const text = await fs.readFile(path.join(workDir, 'full_text.txt'), 'utf-8');
    const metaRaw = await fs.readFile(path.join(workDir, 'metadata.json'), 'utf-8');
    const meta = JSON.parse(metaRaw);

    const id = crypto.randomUUID();
    const publicDir = path.join(process.cwd(), 'public', 'skills', id);
    await fs.mkdir(publicDir, { recursive: true });
    await fs.writeFile(path.join(publicDir, 'full_text.txt'), text);
    await fs.writeFile(path.join(publicDir, 'metadata.json'), JSON.stringify(meta, null, 2));

    const script = path.join(process.cwd(), 'scripts', 'generate_skill.py');
    const skillOut = path.join(publicDir, 'skill');
    try {
      await run('python3', [script, workDir, '--output', skillOut], {
        env: { ...process.env },
        cwd: process.cwd(),
        timeout: 60000
      });
    } catch (genErr) {
      console.error('Skill generation failed (non-fatal):', genErr.message);
    }

    const hasSkill = await fs.stat(path.join(skillOut, 'SKILL.md')).then(() => true).catch(() => false);

    res.json({
      success: true,
      skillId: id,
      metadata: meta,
      downloadUrl: `/skills/${id}/full_text.txt`,
      skill: hasSkill ? `/skills/${id}/skill/SKILL.md` : null
    });
  } catch (err) {
    console.error('Skill conversion error:', err);
    res.status(500).json({ error: 'فشل استخراج النص. تأكد من الملف وحاول مجدداً' });
  } finally {
    if (workDir) fs.rm(workDir, { recursive: true, force: true }).catch(() => {});
  }
});

export default router;
