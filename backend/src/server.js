'use strict';
require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { z } = require('zod');

const app = express();
const port = Number(process.env.PORT || 8080);
const isProduction = process.env.NODE_ENV === 'production';
app.disable('x-powered-by');
app.use(helmet());
app.use(express.json({ limit: '24kb' }));
const allowedOrigins = (process.env.CORS_ORIGINS || 'http://localhost:3000,http://localhost:5000').split(',').map(x => x.trim()).filter(Boolean);
function isAllowedOrigin(origin) {
  if (!origin || allowedOrigins.includes(origin)) return true;
  // Flutter Web uses a random localhost port during development. Never broaden this in production.
  if (!isProduction) {
    try {
      const parsed = new URL(origin);
      return parsed.protocol === 'http:' && ['localhost', '127.0.0.1'].includes(parsed.hostname);
    } catch (_) { return false; }
  }
  return false;
}
app.use(cors({ origin(origin, callback) {
  if (isAllowedOrigin(origin)) return callback(null, true);
  return callback(new Error('Origin not allowed by CORS'));
}, methods: ['GET', 'POST', 'OPTIONS'], allowedHeaders: ['Authorization', 'Content-Type', 'X-Request-Id'] }));
app.use('/api/', rateLimit({ windowMs: 60_000, limit: 30, standardHeaders: 'draft-7', legacyHeaders: false }));

let adminAuth = null;
try {
  const admin = require('firebase-admin');
  if (!admin.apps.length) admin.initializeApp();
  adminAuth = admin.auth();
} catch (error) {
  console.warn('Firebase Admin is not configured. Protected routes will reject requests unless REQUIRE_FIREBASE_AUTH=false.');
}

async function requireUser(req, res, next) {
  if (process.env.REQUIRE_FIREBASE_AUTH === 'false' && !isProduction) {
    req.user = { uid: 'local-development-user' };
    return next();
  }
  const header = req.get('authorization') || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token || !adminAuth) return res.status(401).json({ error: 'unauthorized', message: 'A valid Firebase ID token is required.' });
  try {
    const decoded = await adminAuth.verifyIdToken(token, true);
    if (decoded.email_verified !== true) {
      return res.status(403).json({ error: 'email_not_verified', message: 'Confirm the account email before using this service.' });
    }
    req.user = decoded;
    return next();
  } catch (_) {
    return res.status(401).json({ error: 'unauthorized', message: 'The session token is invalid or expired.' });
  }
}

const adviceSchema = z.object({
  task: z.enum(['meal_analysis', 'snack_alternatives', 'recipe_generation']),
  meal_description: z.string().trim().min(2).max(1200).optional(),
  snack: z.string().trim().min(2).max(200).optional(),
  dietary_restrictions: z.string().trim().max(500).optional().default(''),
  ingredients: z.array(z.string().trim().min(1).max(100)).max(30).optional(),
}).strict();

async function askModel(task, input) {
  if (!process.env.GEMINI_API_KEY) throw Object.assign(new Error('AI provider is not configured'), { status: 503 });
  const prompts = {
    meal_analysis: `Give concise general nutrition education about this meal: ${input.meal_description}. Dietary restrictions: ${input.dietary_restrictions || 'not provided'}. Mention uncertainty due to portion sizes. Do not diagnose, prescribe, or invent precise nutrients. Respond in Arabic.`,
    snack_alternatives: `Suggest 5 practical, budget-conscious alternatives to ${input.snack}. Dietary restrictions: ${input.dietary_restrictions || 'not provided'}. Avoid any option that conflicts with restrictions. Respond in Arabic as a JSON object with an alternatives array of strings.`,
    recipe_generation: `Suggest one balanced recipe using these ingredients: ${(input.ingredients || []).join(', ')}. Dietary restrictions: ${input.dietary_restrictions || 'not provided'}. Include ingredients, simple steps, and substitutions. Respond in Arabic.`,
  };
  const model = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'x-goog-api-key': process.env.GEMINI_API_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: 'You are a cautious nutrition education assistant, not a clinician. Never diagnose or prescribe. For allergies, clearly avoid suggesting allergens. Do not claim food data is exact without quantities. Output only the requested format.' }] },
      contents: [{ role: 'user', parts: [{ text: prompts[task] }] }],
      generationConfig: { temperature: 0.4, maxOutputTokens: 1200, ...(task === 'snack_alternatives' ? { responseMimeType: 'application/json' } : {}) },
    }),
    signal: AbortSignal.timeout(25_000),
  });
  if (!response.ok) {
    const details = await response.text().catch(() => '');
    console.error('Gemini API request failed:', response.status, details.slice(0, 500));
    const status = response.status === 429 ? 503 : (response.status === 400 || response.status === 403 ? 502 : 502);
    throw Object.assign(new Error('Gemini provider request failed'), { status });
  }
  const payload = await response.json();
  const content = payload?.candidates?.[0]?.content?.parts?.map(part => part.text || '').join('').trim();
  if (typeof content !== 'string' || !content) throw Object.assign(new Error('Empty Gemini response'), { status: 502 });
  if (task === 'snack_alternatives') {
    try {
      const parsed = JSON.parse(content.replace(/^```json\s*/i, '').replace(/```$/, '').trim());
      if (Array.isArray(parsed.alternatives)) return { alternatives: parsed.alternatives.map(String).slice(0, 5) };
    } catch (_) { /* Return a safe text fallback below. */ }
    return { alternatives: content.split('\n').map(s => s.replace(/^[-*\d.)\s]+/, '').trim()).filter(Boolean).slice(0, 5) };
  }
  return task === 'meal_analysis' ? { advice: content } : { recipe: content };
}

app.get('/api/health', (_req, res) => res.json({ status: 'ok', service: 'nutrivision-api' }));
app.post('/api/nutrition', requireUser, async (req, res) => {
  const parsed = adviceSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid_request', details: parsed.error.flatten() });
  const input = parsed.data;
  if (input.task === 'meal_analysis' && !input.meal_description) return res.status(400).json({ error: 'meal_description_required' });
  if (input.task === 'snack_alternatives' && !input.snack) return res.status(400).json({ error: 'snack_required' });
  if (input.task === 'recipe_generation' && (!input.ingredients || input.ingredients.length === 0)) return res.status(400).json({ error: 'ingredients_required' });
  try { return res.json(await askModel(input.task, input)); }
  catch (error) {
    const status = Number(error.status) || 502;
    if (status >= 500) console.error('AI request failed:', error.message);
    return res.status(status).json({ error: status === 503 ? 'service_unavailable' : 'upstream_error', message: 'تعذر إكمال الطلب الآن. حاول لاحقًا.' });
  }
});

const arabicFoodAliases = new Map([
  ['تفاح', 'apple raw'], ['تفاحة', 'apple raw'], ['موز', 'banana raw'], ['موزة', 'banana raw'],
  ['برتقال', 'orange raw'], ['بيض', 'egg whole cooked'], ['بيض مسلوق', 'egg whole hard boiled'],
  ['رز', 'rice white cooked'], ['أرز', 'rice white cooked'], ['رز مطبوخ', 'rice white cooked'], ['أرز مطبوخ', 'rice white cooked'],
  ['فراخ', 'chicken meat cooked'], ['دجاج', 'chicken meat cooked'], ['صدر فراخ', 'chicken breast roasted'], ['صدر دجاج', 'chicken breast roasted'],
  ['لبن', 'milk whole'], ['حليب', 'milk whole'], ['زبادي', 'yogurt plain'], ['شوفان', 'oats'],
  ['بطاطس', 'potato cooked boiled'], ['بطاطا', 'sweet potato cooked'], ['عدس', 'lentils cooked'],
  ['فول', 'fava beans cooked'], ['تونة', 'tuna canned water drained'], ['جبنة', 'cheese'], ['جبن', 'cheese'],
  ['عيش', 'bread white'], ['خبز', 'bread'], ['لحم', 'beef cooked'], ['لحمة', 'beef cooked'],
  ['سلمون', 'salmon cooked'], ['مكرونة', 'pasta cooked'], ['معكرونة', 'pasta cooked'], ['لوز', 'almonds'],
  ['فول سوداني', 'peanuts'], ['خيار', 'cucumber raw'], ['طماطم', 'tomato raw'], ['بروكلي', 'broccoli cooked']
]);

app.get('/api/foods/search', requireUser, async (req, res) => {
  const query = typeof req.query.q === 'string' ? req.query.q.trim() : '';
  if (query.length < 2 || query.length > 100) return res.status(400).json({ error: 'query_must_be_2_to_100_chars' });
  const searchQuery = arabicFoodAliases.get(query.toLocaleLowerCase('ar')) || query;
  if (!process.env.USDA_API_KEY) return res.status(503).json({ error: 'food_data_not_configured' });
  try {
    const url = new URL('https://api.nal.usda.gov/fdc/v1/foods/search');
    url.searchParams.set('api_key', process.env.USDA_API_KEY);
    url.searchParams.set('query', searchQuery);
    url.searchParams.set('pageSize', '8');
    // Generic USDA food datasets are preferred here to avoid mixing label-serving
    // values from branded products with values normalized per 100 g.
    for (const type of ['Foundation', 'SR Legacy', 'Survey (FNDDS)']) url.searchParams.append('dataType', type);
    const upstream = await fetch(url, { signal: AbortSignal.timeout(12_000) });
    if (!upstream.ok) throw new Error(`USDA returned ${upstream.status}`);
    const data = await upstream.json();
    const foods = (data.foods || []).slice(0, 8).map(food => {
      const nutrients = food.foodNutrients || [];
      const find = (ids) => nutrients.find(n => ids.includes(n.nutrientId))?.value ?? null;
      return {
        id: food.fdcId,
        name: food.description,
        dataType: food.dataType || null,
        caloriesKcal: find([1008]),
        proteinG: find([1003]),
        carbsG: find([1005]),
        fatG: find([1004]),
        fiberG: find([1079]),
        sugarG: find([2000, 1063]),
        sodiumMg: find([1093]),
        saturatedFatG: find([1258]),
        cholesterolMg: find([1253]),
        servingNote: 'بيانات غذائية من USDA. الحساب يعرض تقديرًا متناسبًا مع الوزن المدخل؛ قد تختلف النتيجة حسب الصنف والتحضير.'
      };
    });
    return res.json({ foods });
  } catch (error) {
    console.error('USDA lookup failed:', error.message);
    return res.status(502).json({ error: 'food_data_unavailable', message: 'تعذر البحث في قاعدة الأغذية الآن.' });
  }
});

app.use((error, _req, res, _next) => {
  if (error.message === 'Origin not allowed by CORS') {
    return res.status(403).json({ error: 'origin_not_allowed' });
  }
  if (error.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'invalid_json', message: 'Request body must be valid JSON.' });
  }
  if (error.type === 'entity.too.large') {
    return res.status(413).json({ error: 'request_too_large', message: 'Request body exceeds the allowed size.' });
  }
  console.error('Unhandled API error:', error.message);
  return res.status(500).json({ error: 'internal_error' });
});
if (require.main === module) {
  const server = app.listen(port, () => {
    console.log(`NutriVision API listening on port ${port}`);
    if (process.env.REQUIRE_FIREBASE_AUTH === 'false' && !isProduction) {
      console.warn('WARNING: local development auth bypass is ENABLED. Keep this server local; never use this setting in production.');
    } else {
      console.log('Firebase ID-token verification is enabled for protected routes.');
    }
    console.log(`Gemini configured: ${Boolean(process.env.GEMINI_API_KEY)} | USDA configured: ${Boolean(process.env.USDA_API_KEY)}`);
  });
  const shutdown = (signal) => {
    console.log(`${signal} received; closing NutriVision API`);
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(1), 10_000).unref();
  };
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

module.exports = { app, adviceSchema };
