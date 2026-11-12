'use strict';
process.env.NODE_ENV = 'test';
process.env.REQUIRE_FIREBASE_AUTH = 'false';
process.env.GEMINI_API_KEY = '';
process.env.USDA_API_KEY = '';

const { test, after } = require('node:test');
const assert = require('node:assert/strict');
const { app } = require('../src/server');

let server;
let baseUrl;
async function start() {
  if (server) return;
  server = app.listen(0, '127.0.0.1');
  await new Promise((resolve, reject) => {
    server.once('listening', resolve);
    server.once('error', reject);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}`;
}
after(async () => { if (server) await new Promise((resolve) => server.close(resolve)); });

test('health endpoint reports service status without exposing secrets', async () => {
  await start();
  const response = await fetch(`${baseUrl}/api/health`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'ok', service: 'nutrivision-api' });
});

test('nutrition endpoint rejects unknown task and unexpected fields', async () => {
  await start();
  const response = await fetch(`${baseUrl}/api/nutrition`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ task: 'do_something', extra: 'not allowed' }) });
  assert.equal(response.status, 400);
  assert.equal((await response.json()).error, 'invalid_request');
});

test('nutrition endpoint validates task-specific required fields', async () => {
  await start();
  const response = await fetch(`${baseUrl}/api/nutrition`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ task: 'meal_analysis' }) });
  assert.equal(response.status, 400);
  assert.equal((await response.json()).error, 'meal_description_required');
});

test('valid AI requests fail safely when provider credentials are absent', async () => {
  await start();
  const response = await fetch(`${baseUrl}/api/nutrition`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ task: 'meal_analysis', meal_description: 'شوفان بالحليب' }) });
  assert.equal(response.status, 503);
  assert.equal((await response.json()).error, 'service_unavailable');
});

test('food search rejects short queries before calling USDA', async () => {
  await start();
  const response = await fetch(`${baseUrl}/api/foods/search?q=a`);
  assert.equal(response.status, 400);
  assert.equal((await response.json()).error, 'query_must_be_2_to_100_chars');
});


test('protected API routes reject requests without a Firebase token when auth is enabled', async () => {
  await start();
  process.env.REQUIRE_FIREBASE_AUTH = 'true';
  try {
    const response = await fetch(`${baseUrl}/api/foods/search?q=apple`);
    assert.equal(response.status, 401);
    assert.equal((await response.json()).error, 'unauthorized');
  } finally {
    process.env.REQUIRE_FIREBASE_AUTH = 'false';
  }
});

test('local development mode can reach protected routes without a token', async () => {
  await start();
  process.env.REQUIRE_FIREBASE_AUTH = 'false';
  const response = await fetch(`${baseUrl}/api/foods/search?q=apple`);
  assert.equal(response.status, 503);
  assert.equal((await response.json()).error, 'food_data_not_configured');
});

test('development CORS accepts Flutter Web localhost ports', async () => {
  await start();
  const response = await fetch(`${baseUrl}/api/health`, { headers: { origin: 'http://localhost:52135' } });
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('access-control-allow-origin'), 'http://localhost:52135');
});
