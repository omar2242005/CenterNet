// بيعمّر الـ Emulator (Auth + Firestore) بسنتر "مركز النور" التجريبي.
//
// التشغيل (في terminal تاني والـ Emulator شغال):
//   firebase emulators:start --project centernet-cbf40
//   cd firebase/seed && npm install && npm run seed
//
// * بيشتغل على الـ Emulator بس، مستحيل يلمس Firebase الحقيقي.
// * ممكن يتشغّل أكتر من مرة: كل مرة بيمسح "مركز النور" ويكتبه من جديد
//   (يعني بيرجّع الحالة الأصلية بسرعة).
// * التواريخ نسبية للنهاردة (بتوقيت القاهرة)، فيه دايمًا جلسة النهاردة.

// لازم قبل أي require لـ firebase-admin: بنثبّت الـ Emulator ونمنع أي اتصال حقيقي.
process.env.FIRESTORE_EMULATOR_HOST ||= '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST ||= '127.0.0.1:9099';

const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp, FieldValue } = require('firebase-admin/firestore');
const { cairoWallToUtc, cairoDay, sessionId } = require('./cairo-time');

const PROJECT_ID = process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT || 'centernet-cbf40';
const CENTER = 'markazNour';
const PASSWORD = 'Test1234!';
const ADMIN = 'admin1';

// ----------------------------------------------------------------------
// المستخدمين
// ----------------------------------------------------------------------
// member: null = مش عضو في السنتر (طالب/ولي أمر بيتربطوا بـ studentLinks).
const USERS = [
  { uid: ADMIN, name: 'مدير مركز النور', email: 'admin@centernet.test', phone: '01000000001', accountType: 'admin', member: 'admin' },
  { uid: 'teacherSara', name: 'سارة أحمد', email: 'sara@centernet.test', phone: '01000000002', accountType: 'staff', member: 'teacher' },
  { uid: 'teacherKhaled', name: 'خالد عبد الله', email: 'khaled@centernet.test', phone: '01000000003', accountType: 'staff', member: 'teacher' },
  { uid: 'assistantMona', name: 'منى إبراهيم', email: 'mona@centernet.test', phone: '01000000004', accountType: 'staff', member: 'assistant' },
  { uid: 'guardianAhmed', name: 'محمود السيد (والد أحمد)', email: 'guardian@centernet.test', phone: '01000000005', accountType: 'guardian', member: null },
  { uid: 'studentAhmed', name: 'أحمد محمود', email: 'ahmed@centernet.test', phone: '01000000006', accountType: 'student', member: null },
];

// ----------------------------------------------------------------------
// الطلاب (7) والمجموعات (3)
// ----------------------------------------------------------------------
const normalize = (s) => s
  .replace(/[ً-ٰٟـ]/g, '')
  .replace(/[آأإٱ]/g, 'ا')
  .replace(/ة/g, 'ه')
  .replace(/ى/g, 'ي')
  .replace(/\s+/g, ' ').trim().toLowerCase();

const STUDENTS = [
  { id: 's1', no: 1, name: 'أحمد محمود', phone: '01011110001', groups: ['g1', 'g2'] },
  { id: 's2', no: 2, name: 'مريم خالد', phone: '01011110002', groups: ['g1'] },
  { id: 's3', no: 3, name: 'يوسف إبراهيم', phone: '01011110003', groups: ['g1'] },
  { id: 's4', no: 4, name: 'نور حسن', phone: '01011110004', groups: ['g2'] },
  { id: 's5', no: 5, name: 'عمر سعيد', phone: '01011110005', groups: ['g2', 'g3'] },
  { id: 's6', no: 6, name: 'هدى علي', phone: '01011110006', groups: ['g3'] },
  { id: 's7', no: 7, name: 'كريم طارق', phone: '01011110007', groups: ['g3'] },
];

// weekday: يوم المجموعة بالنسبة للنهاردة (g1 النهاردة، g2 بكرة، g3 بعد بكرة).
// past/future: إزاحات الأيام للجلسات (الماضية بتتحط "حضور" لها لـ g1 بس).
const GROUPS = [
  {
    id: 'g1', name: 'رياضيات - الصف الثالث الإعدادي', subject: 'رياضيات', grade: 'الصف الثالث الإعدادي',
    teacherId: 'teacherSara', room: 'قاعة 1', capacity: 20, dayShift: 0, startMinutes: 17 * 60, durationMinutes: 90,
    offsets: [-49, -42, -35, -28, -21, -14, -7, 0, 7, 14, 21],
  },
  {
    id: 'g2', name: 'علوم - الصف الثالث الإعدادي', subject: 'علوم', grade: 'الصف الثالث الإعدادي',
    teacherId: 'teacherSara', room: 'قاعة 2', capacity: null, dayShift: 1, startMinutes: 15 * 60, durationMinutes: 60,
    offsets: [-6, 1, 8, 15, 22],
  },
  {
    id: 'g3', name: 'لغة عربية - الصف الثالث الإعدادي', subject: 'لغة عربية', grade: 'الصف الثالث الإعدادي',
    teacherId: 'teacherKhaled', room: 'قاعة 1', capacity: 15, dayShift: 2, startMinutes: 18 * 60, durationMinutes: 60,
    offsets: [-5, 2, 9, 16, 23],
  },
];
const ASSISTANT_IDS = ['assistantMona'];
const MONTHLY_FEE = 45000; // 450 ج.م بالقروش

// حضور g1: index الجلسة الماضية (0..6) اللي الطالب حضرها. أحمد 6 من 7 (غاب عن الجلسة 3).
const G1_PAST_COUNT = 7;
const G1_ATTENDANCE = {
  s1: { sessions: [0, 1, 3, 4, 5, 6], lateOn: [4] },
  s2: { sessions: [0, 1, 2, 3, 4, 5, 6], lateOn: [] },
  s3: { sessions: [0, 1, 3, 5], lateOn: [] },
};

// ----------------------------------------------------------------------
function buildSessions() {
  const out = [];
  for (const g of GROUPS) {
    g.offsets.forEach((off, i) => {
      const day = cairoDay(off);
      const start = cairoWallToUtc(day.y, day.m, day.d, Math.floor(g.startMinutes / 60), g.startMinutes % 60);
      out.push({
        id: sessionId(g.id, day, g.startMinutes),
        groupId: g.id,
        startAt: start,
        endAt: new Date(start.getTime() + g.durationMinutes * 60000),
        past: off < 0,
        pastIndex: off < 0 ? i : -1,
      });
    });
  }
  return out;
}

async function assertEmulatorUp() {
  for (const [name, host] of [['Firestore', process.env.FIRESTORE_EMULATOR_HOST], ['Auth', process.env.FIREBASE_AUTH_EMULATOR_HOST]]) {
    try {
      await fetch(`http://${host}`, { signal: AbortSignal.timeout(3000) });
    } catch {
      console.error(`✗ الـ Emulator (${name}) مش شغال على ${host}.`);
      console.error(`  شغّله الأول في terminal تاني:  firebase emulators:start --project ${PROJECT_ID}`);
      process.exit(1);
    }
  }
}

async function upsertAuthUser(auth, u) {
  const props = { email: u.email, password: PASSWORD, displayName: u.name, emailVerified: true };
  try {
    await auth.getUser(u.uid);
    await auth.updateUser(u.uid, props);
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    await auth.createUser({ uid: u.uid, ...props });
  }
}

async function main() {
  await assertEmulatorUp();
  initializeApp({ projectId: PROJECT_ID });
  const auth = getAuth();
  const db = getFirestore();
  const now = FieldValue.serverTimestamp();

  console.log('• بمسح مركز النور القديم (لو موجود)...');
  await db.recursiveDelete(db.doc(`centers/${CENTER}`));
  const oldCodes = await db.collection('inviteCodes').where('centerId', '==', CENTER).get();
  await Promise.all(oldCodes.docs.map((d) => d.ref.delete()));

  console.log('• بعمل حسابات الدخول...');
  for (const u of USERS) await upsertAuthUser(auth, u);

  const bw = db.bulkWriter();
  const set = (path, data) => bw.set(db.doc(path), data);

  // المستخدمين + العضويات
  for (const u of USERS) {
    set(`users/${u.uid}`, {
      name: u.name, email: u.email, phone: u.phone, accountType: u.accountType,
      centerId: CENTER, createdAt: now, createdBy: u.uid,
    });
  }

  // السنتر
  set(`centers/${CENTER}`, { name: 'مركز النور', year: 2026, createdBy: ADMIN, lateAfterMinutes: 15, createdAt: now });
  for (const u of USERS.filter((x) => x.member)) {
    set(`centers/${CENTER}/members/${u.uid}`, {
      role: u.member, name: u.name, active: true, createdAt: now, createdBy: u.uid,
    });
  }

  // الطلاب + العدّاد
  for (const s of STUDENTS) {
    set(`centers/${CENTER}/students/${s.id}`, {
      centerId: CENTER, studentNo: s.no, fullName: s.name, searchKey: normalize(s.name),
      phone: s.phone, grade: 'الصف الثالث الإعدادي', groupIds: s.groups, status: 'active',
      createdAt: now, createdBy: ADMIN,
    });
  }
  set(`centers/${CENTER}/counters/students`, { next: STUDENTS.length + 1 });

  // المجموعات
  const dayShifts = {};
  for (const g of GROUPS) {
    const weekday = cairoDay(g.dayShift).weekday;
    dayShifts[g.id] = weekday;
    set(`centers/${CENTER}/groups/${g.id}`, {
      centerId: CENTER, name: g.name, subject: g.subject, grade: g.grade,
      teacherId: g.teacherId, assistantIds: ASSISTANT_IDS, room: g.room,
      ...(g.capacity != null ? { capacity: g.capacity } : {}),
      monthlyFee: MONTHLY_FEE,
      slots: [{ weekday, startMinutes: g.startMinutes, durationMinutes: g.durationMinutes }],
      status: 'active', createdAt: now, createdBy: ADMIN,
    });
  }

  // الجلسات
  const sessions = buildSessions();
  for (const s of sessions) {
    set(`centers/${CENTER}/sessions/${s.id}`, {
      centerId: CENTER, groupId: s.groupId,
      startAt: Timestamp.fromDate(s.startAt), endAt: Timestamp.fromDate(s.endAt),
      status: 'scheduled', createdAt: now, createdBy: ADMIN,
    });
  }

  // الحضور (g1 بس): أحمد 6 من 7
  const g1Past = sessions.filter((s) => s.groupId === 'g1' && s.past);
  if (g1Past.length !== G1_PAST_COUNT) throw new Error('عدد جلسات g1 الماضية لازم يكون 7');
  let attendanceCount = 0;
  for (const [sid, cfg] of Object.entries(G1_ATTENDANCE)) {
    for (const idx of cfg.sessions) {
      const s = g1Past[idx];
      const late = cfg.lateOn.includes(idx);
      const scannedAt = new Date(s.startAt.getTime() + (late ? 20 : 3) * 60000);
      set(`centers/${CENTER}/attendance/${s.id}_${sid}`, {
        centerId: CENTER, sessionId: s.id, studentId: sid,
        status: late ? 'late' : 'present', method: 'qr',
        scannedAt: Timestamp.fromDate(scannedAt),
        recordedBy: 'assistantMona', recordedAt: Timestamp.fromDate(scannedAt),
        voided: false, voidedBy: null, voidReason: null, voidedAt: null,
      });
      attendanceCount++;
    }
  }

  // ربط الحسابات: ولي أمر أحمد + حساب أحمد نفسه
  set(`centers/${CENTER}/studentLinks/guardianAhmed_s1`, {
    centerId: CENTER, uid: 'guardianAhmed', studentId: 's1', kind: 'guardian', status: 'active',
    relation: 'أب', createdAt: now, createdBy: ADMIN,
  });
  set(`centers/${CENTER}/studentLinks/studentAhmed_s1`, {
    centerId: CENTER, uid: 'studentAhmed', studentId: 's1', kind: 'student', status: 'active',
    createdAt: now, createdBy: ADMIN,
  });

  // امتحان الجبر (لسه مش منشور) + درجات g1
  // الشكل مطابق لـ Exam و Score في lib/features/grades/models.
  const examDay = cairoDay(-7);
  set(`centers/${CENTER}/exams/e1`, {
    centerId: CENTER, groupId: 'g1', title: 'امتحان الجبر - الوحدة الأولى',
    date: Timestamp.fromDate(cairoWallToUtc(examDay.y, examDay.m, examDay.d, 17, 0)),
    maxScore: 30, published: false, createdAt: now, createdBy: 'teacherSara',
  });
  for (const [sid, score] of Object.entries({ s1: 27, s2: 30, s3: 22.5 })) {
    set(`centers/${CENTER}/scores/e1_${sid}`, {
      centerId: CENTER, examId: 'e1', studentId: sid, state: 'scored', score, comment: '',
      createdAt: now, createdBy: 'teacherSara',
    });
  }

  // أكواد دعوة جاهزة للتجربة (7 أيام)
  const expiresAt = Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 3600 * 1000));
  const code = (id, data) => set(`inviteCodes/${id}`, {
    centerId: CENTER, expiresAt, usedBy: null, createdAt: now, createdBy: ADMIN, ...data,
  });
  code('DEMOSTF2', { kind: 'staff', role: 'assistant', name: 'مساعد جديد' });
  code('DEMOGRD3', { kind: 'guardian', studentId: 's4', relation: 'أم' });
  code('DEMOSTD4', { kind: 'student', studentId: 's4' });

  await bw.close();

  console.log('\n✓ تم تعمير الـ Emulator بمركز النور');
  console.log(`  7 طلاب · 3 مجموعات · ${sessions.length} جلسة · ${attendanceCount} سجل حضور (أحمد 6 من 7) · امتحان e1 (غير منشور)`);
  console.log(`  كلمة السر لكل الحسابات: ${PASSWORD}`);
  console.log('  ' + USERS.map((u) => `${u.email} (${u.accountType === 'staff' ? u.member : u.accountType})`).join('\n  '));
  console.log('  أكواد جاهزة: DEMOSTF2 (مساعد) · DEMOGRD3 (ولي أمر s4) · DEMOSTD4 (طالب s4)');
  console.log(`  QR أحمد: ${CENTER}:s1`);
}

main().catch((e) => {
  console.error('✗ فشل الـ seed:', e);
  process.exit(1);
});
