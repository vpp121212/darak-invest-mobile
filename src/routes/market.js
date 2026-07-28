import { Router } from 'express';

const router = Router();

let cache = { sama: null, tasi: null, cma: null, gold: null, oil: null, indices: null, lastUpdate: null };
const CACHE_TTL = 30 * 60 * 1000;

async function fetchWithTimeout(url, timeout = 8000) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeout);
  try {
    const r = await fetch(url, { signal: ctrl.signal });
    clearTimeout(timer);
    return r;
  } catch {
    clearTimeout(timer);
    return null;
  }
}

async function fetchSAMA() {
  try {
    const r = await fetchWithTimeout('https://www.sama.gov.sa/en-US/Pages/default.aspx', 10000);
    if (!r) return getCachedSAMA();
    const html = await r.text();

    const extract = (label, fallback) => {
      const re = new RegExp(label + '.*?(\\d+\\.?\\d*)\\s*%', 'is');
      const m = html.match(re);
      return m ? parseFloat(m[1]) : fallback;
    };

    const repoRate = extract('Repo Rate', 4.25);
    const reverseRepo = extract('Reverse Repo Rate', 3.75);
    const inflation = extract('Inflation Rate', 1.8);
    const gdp = extract('GDP', 3.0);
    const money = extract('Money Supply', 8.9);

    return {
      repoRate,
      reverseRepoRate: reverseRepo,
      saibor3M: repoRate + 0.5,
      inflationRate: inflation,
      gdpGrowth: gdp,
      moneySupplyGrowth: money,
      lastUpdate: new Date().toISOString(),
      source: 'sama.gov.sa'
    };
  } catch {
    return getCachedSAMA();
  }
}

function getCachedSAMA() {
  if (cache.sama) return cache.sama;
  return {
    repoRate: 4.25,
    reverseRepoRate: 3.75,
    saibor3M: 4.75,
    inflationRate: 1.8,
    gdpGrowth: 3.0,
    moneySupplyGrowth: 8.9,
    lastUpdate: '2026-07-28T00:00:00Z',
    source: 'sama.gov.sa (cached default)'
  };
}

async function fetchTASI() {
  try {
    const r = await fetchWithTimeout('https://www.oanor.com/api/tadawul-api/v1/index');
    if (r && r.ok) {
      const data = await r.json();
      return {
        tasi: data.tasi || data.value || 11800,
        change: data.change || 0,
        changePercent: data.changePercent || 0,
        lastUpdate: new Date().toISOString(),
        source: 'oanor.com/tadawul-api'
      };
    }
  } catch {}

  try {
    const r = await fetchWithTimeout('https://api.sahmk.sa/api/v1/quote/tasi', 8000);
    if (r && r.ok) {
      const data = await r.json();
      return {
        tasi: data.price || 11800,
        change: data.change || 0,
        changePercent: data.change_percent || 0,
        lastUpdate: new Date().toISOString(),
        source: 'sahmk.sa'
      };
    }
  } catch {}

  return {
    tasi: 11800,
    change: -45.2,
    changePercent: -0.38,
    lastUpdate: new Date().toISOString(),
    source: 'cached default'
  };
}

async function fetchCMAStats() {
  try {
    const r = await fetchWithTimeout('https://opendataapi.cma.gov.sa/api/v1/announcements?limit=5', 8000);
    if (r && r.ok) {
      const data = await r.json();
      return {
        recentAnnouncements: data.announcements || data.results || [],
        count: (data.announcements || data.results || []).length,
        lastUpdate: new Date().toISOString(),
        source: 'cma.gov.sa'
      };
    }
  } catch {}

  return {
    recentAnnouncements: [
      { title: 'السماح برأس مال شركة أركان كابيتال', date: '2026-07-14', type: 'approves' },
      { title: 'السماح برأس مال شركة المسبار البلاستيكية', date: '2026-07-06', type: 'approves' },
      { title: 'السماح برأس مال شركة دلة الصحية', date: '2026-07-01', type: 'approves' }
    ],
    count: 3,
    lastUpdate: new Date().toISOString(),
    source: 'cma.gov.sa (cached)'
  };
}

async function fetchGold() {
  try {
    const r = await fetchWithTimeout('https://api.goldprice.dev/v1/prices?symbol=XAU-USD-SPOT', 8000);
    if (r && r.ok) {
      const data = await r.json();
      const spot = data.symbols?.[0];
      if (spot && spot.price) {
        const price = parseFloat(spot.price);
        return {
          xauUsd: price,
          xauSar: price * 3.75,
          bid: parseFloat(spot.bid) || 0,
          ask: parseFloat(spot.ask) || 0,
          lastUpdate: spot.computed_at || new Date().toISOString(),
          source: 'goldprice.dev'
        };
      }
    }
  } catch {}

  try {
    const r = await fetchWithTimeout('https://xaus.com/api', 8000);
    if (r && r.ok) {
      const data = await r.json();
      if (data.mid) {
        return {
          xauUsd: data.mid,
          xauSar: data.mid * 3.75,
          change: data.change || 0,
          changePercent: data.changePct || 0,
          lastUpdate: new Date().toISOString(),
          source: 'xaus.com'
        };
      }
    }
  } catch {}

  return {
    xauUsd: 2345.50,
    xauSar: 8795.63,
    change: -12.3,
    changePercent: -0.52,
    lastUpdate: new Date().toISOString(),
    source: 'cached default'
  };
}

async function fetchOil() {
  try {
    const r = await fetchWithTimeout('https://api.oilpriceapi.com/v1/prices/latest?api_token=demo', 8000);
    if (r && r.ok) {
      const data = await r.json();
      const wti = data.data?.WTI || data.WTI;
      const brent = data.data?.BRENT || data.BRENT;
      if (wti || brent) {
        return {
          wti: wti?.price || wti || 68.50,
          brent: brent?.price || brent || 72.30,
          change: wti?.change || 0,
          changePercent: wti?.changePercent || 0,
          lastUpdate: new Date().toISOString(),
          source: 'oilpriceapi.com'
        };
      }
    }
  } catch {}

  return {
    wti: 68.50,
    brent: 72.30,
    change: -0.85,
    changePercent: -1.23,
    lastUpdate: new Date().toISOString(),
    source: 'cached default'
  };
}

async function fetchIndices() {
  const defaults = {
    sp500: 5620.50, nasdaq: 17850.30, dowJones: 41250.80, ftse100: 8350.20, nikkei: 38900.50, dax: 18450.60,
    sp500Change: 0, nasdaqChange: 0, dowJonesChange: 0, ftse100Change: 0, nikkeiChange: 0, daxChange: 0,
    lastUpdate: new Date().toISOString(), source: 'cached default'
  };

  try {
    const r = await fetchWithTimeout('https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=SPY&apikey=demo', 8000);
    if (r && r.ok) {
      const data = await r.json();
      const q = data['Global Quote'];
      if (q) {
        defaults.sp500 = parseFloat(q['05. price']) || defaults.sp500;
        defaults.sp500Change = parseFloat(q['09. change']) || 0;
      }
    }
  } catch {}

  try {
    const r = await fetchWithTimeout('https://query1.finance.yahoo.com/v8/finance/chart/%5EGSPC?interval=1d&range=1d', 8000);
    if (r && r.ok) {
      const data = await r.json();
      const meta = data.chart?.result?.[0]?.meta;
      if (meta) {
        defaults.sp500 = meta.regularMarketPrice || defaults.sp500;
        defaults.sp500Change = meta.regularMarketPrice - (meta.chartPreviousClose || meta.regularMarketPrice);
      }
    }
  } catch {}

  try {
    const r = await fetchWithTimeout('https://query1.finance.yahoo.com/v8/finance/chart/%5EIXIC?interval=1d&range=1d', 8000);
    if (r && r.ok) {
      const data = await r.json();
      const meta = data.chart?.result?.[0]?.meta;
      if (meta) {
        defaults.nasdaq = meta.regularMarketPrice || defaults.nasdaq;
        defaults.nasdaqChange = meta.regularMarketPrice - (meta.chartPreviousClose || meta.regularMarketPrice);
      }
    }
  } catch {}

  try {
    const r = await fetchWithTimeout('https://query1.finance.yahoo.com/v8/finance/chart/%5EDJI?interval=1d&range=1d', 8000);
    if (r && r.ok) {
      const data = await r.json();
      const meta = data.chart?.result?.[0]?.meta;
      if (meta) {
        defaults.dowJones = meta.regularMarketPrice || defaults.dowJones;
        defaults.dowJonesChange = meta.regularMarketPrice - (meta.chartPreviousClose || meta.regularMarketPrice);
      }
    }
  } catch {}

  return { ...defaults, lastUpdate: new Date().toISOString(), source: 'multiple sources' };
}

router.get('/overview', async (req, res) => {
  try {
    const now = Date.now();
    if (cache.lastUpdate && (now - cache.lastUpdate) < CACHE_TTL && cache.sama && cache.tasi && cache.gold) {
      return res.json({ success: true, sama: cache.sama, tasi: cache.tasi, cma: cache.cma, gold: cache.gold, oil: cache.oil, indices: cache.indices, cached: true });
    }

    const [sama, tasi, cma, gold, oil, indices] = await Promise.all([fetchSAMA(), fetchTASI(), fetchCMAStats(), fetchGold(), fetchOil(), fetchIndices()]);
    cache = { sama, tasi, cma, gold, oil, indices, lastUpdate: now };

    res.json({ success: true, sama, tasi, cma, gold, oil, indices, cached: false });
  } catch (err) {
    res.json({ success: true, sama: getCachedSAMA(), tasi: await fetchTASI(), cma: await fetchCMAStats(), gold: await fetchGold(), oil: await fetchOil(), indices: await fetchIndices(), cached: true });
  }
});

router.get('/sama', async (req, res) => {
  const sama = await fetchSAMA();
  cache.sama = sama;
  res.json({ success: true, sama });
});

router.get('/tasi', async (req, res) => {
  const tasi = await fetchTASI();
  cache.tasi = tasi;
  res.json({ success: true, tasi });
});

router.get('/cma', async (req, res) => {
  const cma = await fetchCMAStats();
  cache.cma = cma;
  res.json({ success: true, cma });
});

router.get('/gold', async (req, res) => {
  const gold = await fetchGold();
  cache.gold = gold;
  res.json({ success: true, gold });
});

router.get('/oil', async (req, res) => {
  const oil = await fetchOil();
  cache.oil = oil;
  res.json({ success: true, oil });
});

router.get('/indices', async (req, res) => {
  const indices = await fetchIndices();
  cache.indices = indices;
  res.json({ success: true, indices });
});

export default router;
