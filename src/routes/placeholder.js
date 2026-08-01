import { Router } from 'express';
const router = Router();

function villaSVG(id, title) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="800" height="500" viewBox="0 0 800 500">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#0c1445"/><stop offset="60%" stop-color="#1a2744"/><stop offset="100%" stop-color="#2d1b3d"/>
    </linearGradient>
    <linearGradient id="gnd" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#1a2a1a"/><stop offset="100%" stop-color="#0d1a0d"/>
    </linearGradient>
    <linearGradient id="w1" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#f5d47b" stop-opacity="0.9"/><stop offset="100%" stop-color="#d4af37" stop-opacity="0.6"/>
    </linearGradient>
    <filter id="glow1"><feGaussianBlur stdDeviation="3" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
  </defs>
  <rect width="800" height="500" fill="url(#sky)"/>
  <circle cx="650" cy="80" r="25" fill="#f5d47b" opacity="0.3"/><circle cx="650" cy="80" r="15" fill="#f5d47b" opacity="0.5"/>
  <circle cx="150" cy="60" r="2" fill="#fff" opacity="0.6"/><circle cx="300" cy="40" r="1.5" fill="#fff" opacity="0.4"/><circle cx="500" cy="55" r="2" fill="#fff" opacity="0.5"/><circle cx="700" cy="35" r="1.5" fill="#fff" opacity="0.3"/><circle cx="400" cy="30" r="2.5" fill="#fff" opacity="0.5"/>
  <rect x="0" y="350" width="800" height="150" fill="url(#gnd)"/>
  <rect x="50" y="348" width="700" height="4" rx="2" fill="#d4af37" opacity="0.15"/>
  <rect x="180" y="220" width="440" height="130" rx="4" fill="#1a1a2e" stroke="#d4af37" stroke-width="0.5" stroke-opacity="0.3"/>
  <rect x="200" y="200" width="400" height="25" rx="2" fill="#12121e"/>
  <polygon points="180,220 400,150 620,220" fill="#15152a" stroke="#d4af37" stroke-width="0.5" stroke-opacity="0.4"/>
  <rect x="360" y="280" width="80" height="70" rx="3" fill="#0a0a15" stroke="#d4af37" stroke-width="0.5" stroke-opacity="0.3"/>
  <rect x="365" y="285" width="30" height="30" rx="2" fill="url(#w1)" filter="url(#glow1)"/>
  <rect x="405" y="285" width="30" height="30" rx="2" fill="url(#w1)" filter="url(#glow1)"/>
  <rect x="365" y="325" width="30" height="20" rx="2" fill="url(#w1)" filter="url(#glow1)"/>
  <rect x="405" y="325" width="30" height="20" rx="2" fill="url(#w1)" filter="url(#glow1)"/>
  <rect x="230" y="240" width="50" height="40" rx="2" fill="#0a0a15" stroke="#d4af37" stroke-width="0.3" stroke-opacity="0.2"/>
  <rect x="235" y="245" width="40" height="30" rx="1" fill="url(#w1)" filter="url(#glow1)"/>
  <rect x="520" y="240" width="50" height="40" rx="2" fill="#0a0a15" stroke="#d4af37" stroke-width="0.3" stroke-opacity="0.2"/>
  <rect x="525" y="245" width="40" height="30" rx="1" fill="url(#w1)" filter="url(#glow1)"/>
  <rect x="230" y="300" width="50" height="40" rx="2" fill="#0a0a15" stroke="#d4af37" stroke-width="0.3" stroke-opacity="0.2"/>
  <rect x="235" y="305" width="40" height="30" rx="1" fill="url(#w1)" filter="url(#glow1)"/>
  <rect x="520" y="300" width="50" height="40" rx="2" fill="#0a0a15" stroke="#d4af37" stroke-width="0.3" stroke-opacity="0.2"/>
  <rect x="525" y="305" width="40" height="30" rx="1" fill="url(#w1)" filter="url(#glow1)"/>
  <ellipse cx="150" cy="340" rx="60" ry="30" fill="#1a3a1a" opacity="0.7"/>
  <ellipse cx="650" cy="345" rx="50" ry="25" fill="#1a3a1a" opacity="0.6"/>
  <rect x="120" y="330" width="4" height="20" fill="#2a2a1a" rx="1"/>
  <rect x="670" y="335" width="4" height="15" fill="#2a2a1a" rx="1"/>
  <rect x="0" y="365" width="800" height="1" fill="#d4af37" opacity="0.1"/>
  <rect x="50" y="390" width="160" height="1" rx="1" fill="#d4af37" opacity="0.08"/>
  <rect x="0" y="430" width="800" height="70" fill="#000" opacity="0.4"/>
  <text x="400" y="465" text-anchor="middle" font-family="Arial,sans-serif" font-size="18" font-weight="bold" fill="#d4af37">${title}</text>
  <text x="400" y="488" text-anchor="middle" font-family="Arial,sans-serif" font-size="11" fill="#666">دارك وحيك — #${id}</text>
</svg>`;
}

function apartmentSVG(id, title) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="800" height="500" viewBox="0 0 800 500">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#0c1445"/><stop offset="100%" stop-color="#1a2744"/>
    </linearGradient>
    <linearGradient id="win" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#60a5fa" stop-opacity="0.9"/><stop offset="100%" stop-color="#3b82f6" stop-opacity="0.5"/>
    </linearGradient>
    <filter id="gl"><feGaussianBlur stdDeviation="2"/></filter>
  </defs>
  <rect width="800" height="500" fill="url(#sky)"/>
  <circle cx="680" cy="70" r="20" fill="#f5d47b" opacity="0.2"/>
  <circle cx="150" cy="50" r="1.5" fill="#fff" opacity="0.5"/><circle cx="400" cy="35" r="2" fill="#fff" opacity="0.4"/><circle cx="600" cy="45" r="1.5" fill="#fff" opacity="0.3"/>
  <rect x="250" y="80" width="300" height="290" rx="4" fill="#141428" stroke="#60a5fa" stroke-width="0.5" stroke-opacity="0.2"/>
  <rect x="260" y="90" width="40" height="35" rx="2" fill="url(#win)"/><rect x="310" y="90" width="40" height="35" rx="2" fill="url(#win)"/><rect x="360" y="90" width="40" height="35" rx="2" fill="url(#win)"/>
  <rect x="260" y="140" width="40" height="35" rx="2" fill="url(#win)"/><rect x="310" y="140" width="40" height="35" rx="2" fill="#1a1a2e" stroke="#60a5fa" stroke-width="0.3" stroke-opacity="0.2"/><rect x="360" y="140" width="40" height="35" rx="2" fill="url(#win)"/>
  <rect x="260" y="190" width="40" height="35" rx="2" fill="#1a1a2e" stroke="#60a5fa" stroke-width="0.3" stroke-opacity="0.2"/><rect x="310" y="190" width="40" height="35" rx="2" fill="url(#win)"/><rect x="360" y="190" width="40" height="35" rx="2" fill="url(#win)"/>
  <rect x="260" y="240" width="40" height="35" rx="2" fill="url(#win)"/><rect x="310" y="240" width="40" height="35" rx="2" fill="url(#win)"/><rect x="360" y="240" width="40" height="35" rx="2" fill="#1a1a2e" stroke="#60a5fa" stroke-width="0.3" stroke-opacity="0.2"/>
  <rect x="260" y="290" width="40" height="35" rx="2" fill="url(#win)"/><rect x="310" y="290" width="40" height="35" rx="2" fill="#1a1a2e" stroke="#60a5fa" stroke-width="0.3" stroke-opacity="0.2"/><rect x="360" y="290" width="40" height="35" rx="2" fill="url(#win)"/>
  <rect x="440" y="90" width="40" height="35" rx="2" fill="url(#win)"/><rect x="490" y="90" width="40" height="35" rx="2" fill="url(#win)"/>
  <rect x="440" y="140" width="40" height="35" rx="2" fill="url(#win)"/><rect x="490" y="140" width="40" height="35" rx="2" fill="#1a1a2e" stroke="#60a5fa" stroke-width="0.3" stroke-opacity="0.2"/>
  <rect x="440" y="190" width="40" height="35" rx="2" fill="#1a1a2e" stroke="#60a5fa" stroke-width="0.3" stroke-opacity="0.2"/><rect x="490" y="190" width="40" height="35" rx="2" fill="url(#win)"/>
  <rect x="440" y="240" width="40" height="35" rx="2" fill="url(#win)"/><rect x="490" y="240" width="40" height="35" rx="2" fill="url(#win)"/>
  <rect x="440" y="290" width="40" height="35" rx="2" fill="url(#win)"/><rect x="490" y="290" width="40" height="35" rx="2" fill="#1a1a2e" stroke="#60a5fa" stroke-width="0.3" stroke-opacity="0.2"/>
  <rect x="350" y="340" width="100" height="30" rx="3" fill="#60a5fa" opacity="0.3"/>
  <rect x="0" y="370" width="800" height="130" fill="#0d1a0d"/>
  <rect x="250" y="370" width="300" height="3" fill="#60a5fa" opacity="0.1"/>
  <rect x="200" y="390" width="80" height="8" rx="2" fill="#1a3a1a" opacity="0.5"/>
  <rect x="520" y="395" width="60" height="6" rx="2" fill="#1a3a1a" opacity="0.4"/>
  <rect x="0" y="430" width="800" height="70" fill="#000" opacity="0.4"/>
  <text x="400" y="465" text-anchor="middle" font-family="Arial,sans-serif" font-size="18" font-weight="bold" fill="#60a5fa">${title}</text>
  <text x="400" y="488" text-anchor="middle" font-family="Arial,sans-serif" font-size="11" fill="#666">دارك وحيك — #${id}</text>
</svg>`;
}

function landSVG(id, title) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="800" height="500" viewBox="0 0 800 500">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#0c4530"/><stop offset="100%" stop-color="#1a3a20"/>
    </linearGradient>
  </defs>
  <rect width="800" height="500" fill="url(#sky)"/>
  <circle cx="600" cy="80" r="25" fill="#f5d47b" opacity="0.3"/>
  <circle cx="200" cy="55" r="1.5" fill="#fff" opacity="0.4"/><circle cx="400" cy="40" r="2" fill="#fff" opacity="0.5"/>
  <rect x="0" y="280" width="800" height="220" fill="#1a2a10"/>
  <rect x="100" y="300" width="250" height="150" rx="0" fill="none" stroke="#34d399" stroke-width="2" stroke-dasharray="8,4" opacity="0.4"/>
  <text x="225" y="380" text-anchor="middle" font-family="Arial,sans-serif" font-size="16" fill="#34d399" opacity="0.6">750 م²</text>
  <rect x="90" y="290" width="10" height="10" fill="#34d399" opacity="0.3"/><rect x="340" y="290" width="10" height="10" fill="#34d399" opacity="0.3"/>
  <rect x="90" y="440" width="10" height="10" fill="#34d399" opacity="0.3"/><rect x="340" y="440" width="10" height="10" fill="#34d399" opacity="0.3"/>
  <rect x="100" y="295" width="250" height="2" fill="#34d399" opacity="0.15"/>
  <line x1="100" y1="375" x2="350" y2="375" stroke="#34d399" stroke-width="0.5" opacity="0.2"/>
  <line x1="225" y1="300" x2="225" y2="450" stroke="#34d399" stroke-width="0.5" opacity="0.2"/>
  <rect x="500" y="310" width="80" height="60" rx="2" fill="#1a2a15" stroke="#34d399" stroke-width="0.3" opacity="0.3"/>
  <rect x="600" y="330" width="60" height="40" rx="2" fill="#1a2a15" stroke="#34d399" stroke-width="0.3" opacity="0.2"/>
  <rect x="0" y="430" width="800" height="70" fill="#000" opacity="0.4"/>
  <text x="400" y="465" text-anchor="middle" font-family="Arial,sans-serif" font-size="18" font-weight="bold" fill="#34d399">${title}</text>
  <text x="400" y="488" text-anchor="middle" font-family="Arial,sans-serif" font-size="11" fill="#666">دارك وحيك — #${id}</text>
</svg>`;
}

function officeSVG(id, title) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="800" height="500" viewBox="0 0 800 500">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#1a1030"/><stop offset="100%" stop-color="#2a1540"/>
    </linearGradient>
    <linearGradient id="gw" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#f59e0b" stop-opacity="0.9"/><stop offset="100%" stop-color="#d97706" stop-opacity="0.5"/>
    </linearGradient>
    <filter id="gl"><feGaussianBlur stdDeviation="2"/></filter>
  </defs>
  <rect width="800" height="500" fill="url(#sky)"/>
  <circle cx="680" cy="60" r="18" fill="#f5d47b" opacity="0.2"/>
  <rect x="0" y="370" width="800" height="130" fill="#0d0d1a"/>
  <rect x="300" y="50" width="200" height="320" rx="3" fill="#141428" stroke="#f59e0b" stroke-width="0.5" stroke-opacity="0.2"/>
  <rect x="280" y="80" width="240" height="290" rx="2" fill="#111122" stroke="#f59e0b" stroke-width="0.3" stroke-opacity="0.15"/>
  ${[0,1,2,3,4,5].map(r => [0,1,2,3].map(c => {
    const lit = Math.random() > 0.3;
    return lit ? `<rect x="${310+c*50}" y="${100+r*45}" width="35" height="30" rx="1" fill="url(#gw)" opacity="${0.4+Math.random()*0.5}" filter="url(#gl)"/>` :
    `<rect x="${310+c*50}" y="${100+r*45}" width="35" height="30" rx="1" fill="#1a1a2e" stroke="#f59e0b" stroke-width="0.2" stroke-opacity="0.1"/>`;
  }).join('')).join('')}
  <rect x="375" y="340" width="50" height="30" rx="2" fill="#0a0a15" stroke="#f59e0b" stroke-width="0.3" stroke-opacity="0.3"/>
  <rect x="250" y="380" width="100" height="8" rx="2" fill="#1a3a1a" opacity="0.3"/>
  <rect x="450" y="385" width="80" height="6" rx="2" fill="#1a3a1a" opacity="0.2"/>
  <rect x="0" y="430" width="800" height="70" fill="#000" opacity="0.4"/>
  <text x="400" y="465" text-anchor="middle" font-family="Arial,sans-serif" font-size="18" font-weight="bold" fill="#f59e0b">${title}</text>
  <text x="400" y="488" text-anchor="middle" font-family="Arial,sans-serif" font-size="11" fill="#666">دارك وحيك — #${id}</text>
</svg>`;
}

function beachSVG(id, title) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="800" height="500" viewBox="0 0 800 500">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#0c2d45"/><stop offset="50%" stop-color="#1a4060"/><stop offset="100%" stop-color="#2d6080"/>
    </linearGradient>
    <linearGradient id="sea" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#22d3ee" stop-opacity="0.3"/><stop offset="100%" stop-color="#0891b2" stop-opacity="0.5"/>
    </linearGradient>
    <linearGradient id="sand" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#92700a"/><stop offset="100%" stop-color="#6b5010"/>
    </linearGradient>
    <filter id="gl"><feGaussianBlur stdDeviation="3"/></filter>
  </defs>
  <rect width="800" height="500" fill="url(#sky)"/>
  <circle cx="650" cy="80" r="22" fill="#f5d47b" opacity="0.4"/>
  <circle cx="200" cy="50" r="1.5" fill="#fff" opacity="0.4"/>
  <rect x="0" y="250" width="800" height="80" fill="url(#sea)"/>
  <path d="M0,260 Q100,250 200,260 T400,258 T600,262 T800,255" fill="none" stroke="#22d3ee" stroke-width="1" opacity="0.3"/>
  <path d="M0,275 Q150,268 300,275 T600,272 T800,278" fill="none" stroke="#22d3ee" stroke-width="0.8" opacity="0.2"/>
  <rect x="0" y="330" width="800" height="170" fill="url(#sand)"/>
  <rect x="200" y="260" width="180" height="80" rx="4" fill="#1a2535" stroke="#22d3ee" stroke-width="0.5" stroke-opacity="0.3"/>
  <polygon points="200,260 290,220 380,260" fill="#152030" stroke="#22d3ee" stroke-width="0.3" stroke-opacity="0.3"/>
  <rect x="260" y="300" width="60" height="40" rx="2" fill="url(#gl)"/><rect x="265" y="305" width="50" height="30" rx="1" fill="#22d3ee" opacity="0.4"/>
  <rect x="320" y="300" width="40" height="25" rx="2" fill="#22d3ee" opacity="0.3"/>
  <ellipse cx="450" cy="370" rx="30" ry="20" fill="#1a3a1a" opacity="0.5"/>
  <rect x="100" y="380" width="3" height="30" fill="#4a3a10" rx="1"/>
  <polygon points="100,370 100,395 75,385" fill="#22d3ee" opacity="0.15"/>
  <rect x="0" y="430" width="800" height="70" fill="#000" opacity="0.4"/>
  <text x="400" y="465" text-anchor="middle" font-family="Arial,sans-serif" font-size="18" font-weight="bold" fill="#22d3ee">${title}</text>
  <text x="400" y="488" text-anchor="middle" font-family="Arial,sans-serif" font-size="11" fill="#666">دارك وحيك — #${id}</text>
</svg>`;
}

function palaceSVG(id, title) {
  return villaSVG(id, title).replace('#d4af37', '#d4af37').replace('font-size="18"', 'font-size="18"');
}

const TYPE_MAP = {
  'فيلا': villaSVG, 'شقة': apartmentSVG, 'بنتهاوس': apartmentSVG,
  'أرض': landSVG, 'مكتب': officeSVG, 'محل': officeSVG,
  'شاليه': beachSVG, 'قصر': palaceSVG, 'دوبلكس': villaSVG, 'مزرعة': landSVG,
};

const TYPE_COLORS = {
  'فيلا': '#d4af37', 'شقة': '#60a5fa', 'بنتهاوس': '#a78bfa', 'أرض': '#34d399',
  'مكتب': '#f59e0b', 'محل': '#f472b6', 'شاليه': '#22d3ee', 'قصر': '#d4af37',
  'دوبلكس': '#fb923c', 'مزرعة': '#4ade80',
};

router.get('/:type/:id', (req, res) => {
  const type = decodeURIComponent(req.params.type || 'عقار');
  const id = req.params.id || '0';
  const title = decodeURIComponent(req.query.title || type);
  const gen = TYPE_MAP[type] || villaSVG;

  res.setHeader('Content-Type', 'image/svg+xml');
  res.setHeader('Cache-Control', 'public, max-age=86400');
  res.send(gen(id, title));
});

export default router;
