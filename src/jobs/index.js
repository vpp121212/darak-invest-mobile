import { registerHandler } from '../services/queue.js';
import sharp from 'sharp';
import { execFile } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import os from 'os';
import path from 'path';
import crypto from 'crypto';

const run = promisify(execFile);

registerHandler('image:process', async (data) => {
  const { inputPath, filename, dir } = data;
  const max = dir === 'panoramic' ? { w: 4000, h: 2000, q: 90 } : { w: 1200, h: 800, q: 85 };
  await sharp(inputPath)
    .resize(max.w, max.h, { fit: 'cover' })
    .webp({ quality: max.q })
    .toFile(`src/uploads/${dir}/${filename}`);
  await fs.rm(inputPath, { force: true });
  return { url: `/uploads/${dir}/${filename}` };
});

registerHandler('skill:convert', async (data, progress) => {
  const { inputPath, originalname, workDir } = data;
  const ext = path.extname(originalname).toLowerCase();
  const allowed = ['.pdf', '.epub', '.docx', '.rtf', '.txt', '.md', '.html', '.mobi', '.azw3', '.azw'];
  if (!allowed.includes(ext)) throw new Error('صيغة غير مدعومة. المدعومة: PDF, EPUB, DOCX, RTF, TXT, MD, HTML, MOBI');

  progress?.(10);
  const bookPath = path.join(workDir, `book${ext}`);
  await fs.copyFile(inputPath, bookPath);

  progress?.(20);
  await run('python3', ['-m', 'book_to_skill', bookPath, '--install-missing', 'no'], {
    env: { ...process.env, BOOK_SKILL_WORKDIR: workDir },
    cwd: process.cwd(),
    timeout: 180000
  });

  progress?.(70);
  const text = await fs.readFile(path.join(workDir, 'full_text.txt'), 'utf-8');
  const meta = JSON.parse(await fs.readFile(path.join(workDir, 'metadata.json'), 'utf-8'));

  const id = crypto.randomUUID();
  const publicDir = path.join(process.cwd(), 'public', 'skills', id);
  await fs.mkdir(publicDir, { recursive: true });
  await fs.writeFile(path.join(publicDir, 'full_text.txt'), text);
  await fs.writeFile(path.join(publicDir, 'metadata.json'), JSON.stringify(meta, null, 2));

  progress?.(85);
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

  progress?.(100);
  return {
    skillId: id,
    metadata: meta,
    downloadUrl: `/skills/${id}/full_text.txt`,
    skill: hasSkill ? `/skills/${id}/skill/SKILL.md` : null
  };
});
