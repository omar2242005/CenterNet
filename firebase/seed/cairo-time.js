// أدوات توقيت القاهرة (بتراعي التوقيت الصيفي) من غير أي حزمة.

const TZ = 'Africa/Cairo';

const fmt = new Intl.DateTimeFormat('en-GB', {
  timeZone: TZ,
  year: 'numeric', month: '2-digit', day: '2-digit',
  hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
});

/** مكوّنات الوقت بتوقيت القاهرة للحظة [utcMs]. */
function cairoParts(utcMs) {
  const p = {};
  for (const { type, value } of fmt.formatToParts(new Date(utcMs))) {
    if (type !== 'literal') p[type] = Number(value);
  }
  return { y: p.year, m: p.month, d: p.day, h: p.hour, mi: p.minute };
}

function offsetMs(utcMs) {
  const p = cairoParts(utcMs);
  return Date.UTC(p.y, p.m - 1, p.d, p.h, p.mi) - utcMs;
}

/** وقت الحائط في القاهرة (سنة/شهر/يوم/ساعة/دقيقة) ← Date بتوقيت UTC. */
function cairoWallToUtc(y, m, d, h, mi) {
  const wall = Date.UTC(y, m - 1, d, h, mi);
  let utc = wall - offsetMs(wall);
  utc = wall - offsetMs(utc); // مرة تانية عشان حدود التوقيت الصيفي
  return new Date(utc);
}

/** تاريخ القاهرة النهاردة + [days] يوم، كـ {y, m, d, weekday} (weekday: 1=الاثنين .. 7=الأحد). */
function cairoDay(days = 0, nowMs = Date.now()) {
  const t = cairoParts(nowMs);
  const date = new Date(Date.UTC(t.y, t.m - 1, t.d + days));
  const dow = date.getUTCDay();
  return {
    y: date.getUTCFullYear(),
    m: date.getUTCMonth() + 1,
    d: date.getUTCDate(),
    weekday: dow === 0 ? 7 : dow,
  };
}

const pad = (n, w) => String(n).padStart(w, '0');

/** نفس صيغة FirestoreIds.session في Dart: gid_yyyyMMdd_HHmm */
function sessionId(groupId, day, startMinutes) {
  const h = Math.floor(startMinutes / 60);
  const mi = startMinutes % 60;
  return `${groupId}_${pad(day.y, 4)}${pad(day.m, 2)}${pad(day.d, 2)}_${pad(h, 2)}${pad(mi, 2)}`;
}

module.exports = { cairoParts, cairoWallToUtc, cairoDay, sessionId };
