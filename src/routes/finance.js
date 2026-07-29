import { Router } from 'express';
import sql from '../config/database.js';

const router = Router();

async function askAI(systemPrompt, userMessage) {
  const key = process.env.OPENAI_API_KEY;
  if (!key) return null;
  try {
    const res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${key}` },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userMessage }
        ],
        temperature: 0.3,
        max_tokens: 1000
      })
    });
    const data = await res.json();
    return data.choices?.[0]?.message?.content || null;
  } catch (e) { console.error('AI Error:', e); return null; }
}

router.post('/analysis', async (req, res) => {
  try {
    const { propertyId, purchasePrice, monthlyRent, annualExpenses, downPayment, loanRate, loanYears, city, type, area, rooms } = req.body;

    let prop = null;
    if (propertyId) {
      [prop] = await sql`SELECT * FROM properties WHERE id = ${propertyId}`;
    }

    const price = purchasePrice || prop?.price || 0;
    const rent = monthlyRent || 0;
    const expenses = annualExpenses || 0;
    const down = downPayment || price * 0.3;
    const rate = loanRate || 5;
    const years = loanYears || 20;

    const annualRent = rent * 12;
    const netIncome = annualRent - expenses;
    const roi = price > 0 ? ((netIncome / price) * 100) : 0;
    const capRate = price > 0 ? ((annualRent / price) * 100) : 0;

    const loanAmount = price - down;
    const monthlyRate = rate / 100 / 12;
    const totalPayments = years * 12;
    const monthlyMortgage = loanAmount > 0 ? (loanAmount * monthlyRate * Math.pow(1 + monthlyRate, totalPayments)) / (Math.pow(1 + monthlyRate, totalPayments) - 1) : 0;
    const monthlyCashFlow = rent - monthlyMortgage - (expenses / 12);
    const annualCashFlow = monthlyCashFlow * 12;
    const paybackYears = netIncome > 0 ? (price / netIncome) : 0;

    const grossMargin = annualRent > 0 ? (((annualRent - expenses) / annualRent) * 100) : 0;
    const netMargin = price > 0 ? ((netIncome / price) * 100) : 0;

    const [comparable] = await sql`
      SELECT AVG(price) as "avgPrice", AVG(price/area) as "avgPerSqm", COUNT(*)::int as count
      FROM properties WHERE city = ${prop?.city || city || 'الرياض'} AND status = 'active'
    `;

    let aiInsight = null;
    const systemPrompt = 'أنت محلل عقاري محترف في السعودية. حلل بيانات الاستثمار العقاري وأعطِ نصيحة مختصرة بالعربي.';
    const userMsg = `عقار: ${prop?.title || 'غير محدد'} | السعر: ${price} ر.س | الإيجار الشهري: ${rent} ر.س | المساحة: ${area || prop?.area || 0} م² | المدينة: ${prop?.city || city || 'الرياض'}
ROI: ${roi.toFixed(1)}% | Cash Flow شهري: ${monthlyCashFlow.toFixed(0)} ر.س | هامش الربح: ${grossMargin.toFixed(1)}%
متوسط الأسعار في المنطقة: ${comparable?.avgPrice?.toFixed(0) || 'غير متاح'} ر.س (${comparable?.count || 0} عقار)
التمويل: دفعة أولى ${down} ر.س، سعر فائدة ${rate}%، ${years} سنة`;

    aiInsight = await askAI(systemPrompt, userMsg);

    res.json({
      success: true,
      analysis: {
        roi: +roi.toFixed(2),
        capRate: +capRate.toFixed(2),
        annualRent,
        netIncome,
        grossMargin: +grossMargin.toFixed(2),
        netMargin: +netMargin.toFixed(2),
        cashFlow: {
          monthly: +monthlyCashFlow.toFixed(0),
          annual: +annualCashFlow.toFixed(0),
          mortgage: +monthlyMortgage.toFixed(0)
        },
        paybackYears: +paybackYears.toFixed(1),
        financing: { downPayment: down, loanAmount, monthlyMortgage: +monthlyMortgage.toFixed(0) },
        market: {
          avgPrice: comparable?.avgPrice?.toFixed(0) || 0,
          avgPerSqm: comparable?.avgPerSqm?.toFixed(0) || 0,
          comparableCount: comparable?.count || 0,
          priceVsMarket: comparable?.avgPrice ? +(((price / comparable.avgPrice) - 1) * 100).toFixed(1) : 0
        },
        aiInsight
      }
    });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/compare', async (req, res) => {
  try {
    const { properties } = req.body;
    if (!properties || !Array.isArray(properties) || properties.length < 2) {
      return res.status(400).json({ error: 'يجب اختيار عقارين على الأقل للمقارنة' });
    }

    const ids = properties.map(p => p.id || p);
    const props = await sql.unsafe(
      `SELECT * FROM properties WHERE id IN (${ids.map((_, i) => '$' + (i + 1)).join(',')})`,
      ids
    );

    const comparison = props.map(p => {
      const annualRent = (p.purpose === 'إيجار' ? p.price : p.price * 0.08);
      const expenses = annualRent * 0.15;
      const netIncome = annualRent - expenses;
      const roi = ((netIncome / p.price) * 100);
      return {
        id: p.id, title: p.title, city: p.city, type: p.type, price: p.price, area: p.area,
        pricePerSqm: +(p.price / p.area).toFixed(0),
        roi: +roi.toFixed(2), annualRent: +annualRent.toFixed(0),
        score: Math.min(100, Math.round(roi * 10 + (p.area > 200 ? 10 : 0)))
      };
    }).sort((a, b) => b.score - a.score);

    res.json({ success: true, comparison, winner: comparison[0] });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

export default router;
