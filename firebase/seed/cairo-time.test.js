const { test } = require('node:test');
const assert = require('node:assert');
const { cairoWallToUtc, cairoDay, sessionId } = require('./cairo-time');

test('شتا: القاهرة = UTC+2', () => {
  assert.strictEqual(cairoWallToUtc(2026, 1, 15, 17, 0).toISOString(), '2026-01-15T15:00:00.000Z');
});

test('صيف: القاهرة = UTC+3', () => {
  assert.strictEqual(cairoWallToUtc(2026, 7, 15, 17, 0).toISOString(), '2026-07-15T14:00:00.000Z');
});

test('cairoDay بيطبّع تاريخ بعد إضافة أيام', () => {
  const now = Date.UTC(2026, 10, 20, 7, 0); // 20 نوفمبر 2026 (جمعة)
  assert.deepStrictEqual(cairoDay(0, now), { y: 2026, m: 11, d: 20, weekday: 5 });
  assert.deepStrictEqual(cairoDay(15, now), { y: 2026, m: 12, d: 5, weekday: 6 });
  assert.deepStrictEqual(cairoDay(-49, now), { y: 2026, m: 10, d: 2, weekday: 5 });
});

test('صيغة الـ ID زي Dart', () => {
  assert.strictEqual(sessionId('g1', { y: 2026, m: 11, d: 19 }, 1020), 'g1_20261119_1700');
});
