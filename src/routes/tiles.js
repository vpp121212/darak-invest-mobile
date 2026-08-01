import { Router } from 'express';
import https from 'https';
import http from 'http';

const router = Router();

router.get('/:z/:x/:y.png', (req, res) => {
  const { z, x, y } = req.params;
  const servers = ['a', 'b', 'c'];
  const server = servers[Math.floor(Math.random() * servers.length)];
  const url = `https://${server}.basemaps.cartocdn.com/dark_all/${z}/${x}/${y}@2x.png`;

  https.get(url, { headers: { 'User-Agent': 'DarakMap/1.0' } }, (upstream) => {
    if (upstream.statusCode === 301 || upstream.statusCode === 302) {
      const redirect = upstream.headers.location;
      https.get(redirect, { headers: { 'User-Agent': 'DarakMap/1.0' } }, (r2) => {
        res.setHeader('Content-Type', 'image/png');
        res.setHeader('Cache-Control', 'public, max-age=86400');
        r2.pipe(res);
      }).on('error', () => res.status(502).end());
      return;
    }
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Cache-Control', 'public, max-age=86400');
    upstream.pipe(res);
  }).on('error', () => res.status(502).end());
});

export default router;
