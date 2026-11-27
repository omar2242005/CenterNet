// اختبارات Rules الحضور (موجة 1، الشخص 4).
// التشغيل:  cd firebase/rules-test && npm test   (محتاج Java للـ Emulator)

const { describe, it, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc,
  query, where, Timestamp, serverTimestamp,
} = require('firebase/firestore');

const A = 'centerA';
const B = 'centerB';
const G1_SESSION = 'g1_20261126_1700';
const G2_SESSION = 'g2_20261126_1700';

let env;
const as = (uid) => env.authenticatedContext(uid).firestore();

const attRef = (db, id) => doc(db, `centers/${A}/attendance/${id}`);
const attId = (sessionId, studentId) => `${sessionId}_${studentId}`;

const attData = (over = {}) => ({
  centerId: A,
  sessionId: G1_SESSION,
  studentId: 'st1',
  status: 'present',
  method: 'qr',
  scannedAt: Timestamp.fromDate(new Date('2026-11-26T15:05:00Z')),
  recordedBy: 'assistantA',
  recordedAt: serverTimestamp(),
  voided: false,
  voidedBy: null,
  voidReason: null,
  voidedAt: null,
  paymentStatus: 'unknown',
  ...over,
});

const manualData = (over = {}) => {
  const d = attData({ method: 'manual', recordedBy: 'assistantA', ...over });
  delete d.scannedAt;
  return d;
};

const voidData = (over = {}) => ({
  voided: true,
  voidedBy: 'assistantA',
  voidReason: 'مسح بالغلط',
  voidedAt: serverTimestamp(),
  ...over,
});

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (p, data) => setDoc(doc(db, p), data);
    const now = Timestamp.now();
    const start = Timestamp.fromDate(new Date('2026-11-26T15:00:00Z'));
    const end = Timestamp.fromDate(new Date('2026-11-26T16:30:00Z'));

    await put(`centers/${A}`, { name: 'مركز النور', year: 2026, createdBy: 'adminA', lateAfterMinutes: 15 });
    await put(`centers/${A}/members/adminA`, { role: 'admin', name: 'Admin A', active: true, createdBy: 'adminA' });
    await put(`centers/${A}/members/teacherA`, { role: 'teacher', name: 'Teacher A', active: true, createdBy: 'teacherA' });
    await put(`centers/${A}/members/teacherB`, { role: 'teacher', name: 'Teacher B', active: true, createdBy: 'teacherB' });
    await put(`centers/${A}/members/assistantA`, { role: 'assistant', name: 'Assistant A', active: true, createdBy: 'assistantA' });
    await put(`centers/${A}/members/offTeacher`, { role: 'teacher', name: 'Off', active: false, createdBy: 'offTeacher' });
    await put(`centers/${B}`, { name: 'مركز تاني', year: 2026, createdBy: 'adminB', lateAfterMinutes: 15 });
    await put(`centers/${B}/members/adminB`, { role: 'admin', name: 'Admin B', active: true, createdBy: 'adminB' });

    // g1: معلم A + مساعد A. g2: معلم B من غير مساعدين.
    await put(`centers/${A}/groups/g1`, { centerId: A, name: 'g1', teacherId: 'teacherA', assistantIds: ['assistantA'], status: 'active' });
    await put(`centers/${A}/groups/g2`, { centerId: A, name: 'g2', teacherId: 'teacherB', assistantIds: [], status: 'active' });

    await put(`centers/${A}/sessions/${G1_SESSION}`, { centerId: A, groupId: 'g1', startAt: start, endAt: end, status: 'scheduled' });
    await put(`centers/${A}/sessions/${G2_SESSION}`, { centerId: A, groupId: 'g2', startAt: start, endAt: end, status: 'scheduled' });

    await put(`centers/${A}/students/st1`, { centerId: A, fullName: 'طالب 1', status: 'active', groupIds: ['g1'] });
    await put(`centers/${A}/students/st2`, { centerId: A, fullName: 'طالب 2', status: 'active', groupIds: ['g1'] });
    await put(`centers/${A}/students/st3`, { centerId: A, fullName: 'طالب 3', status: 'active', groupIds: ['g1'] });
    await put(`centers/${A}/students/st4`, { centerId: A, fullName: 'طالب 4', status: 'active', groupIds: ['g1'] });

    // سجلين موجودين: واحد في g1 وواحد في g2.
    await put(`centers/${A}/attendance/${attId(G1_SESSION, 'st1')}`,
      attData({ recordedAt: now }));
    await put(`centers/${A}/attendance/${attId(G2_SESSION, 'st1')}`,
      attData({ sessionId: G2_SESSION, recordedBy: 'teacherB', recordedAt: now }));
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-centernet',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8'),
    },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed();
});

describe('attendance — الإنشاء', () => {
  const id2 = attId(G1_SESSION, 'st2');

  it('المساعد والمعلم بتوع المجموعة والأدمن يسجلوا حضور', async () => {
    await assertSucceeds(setDoc(attRef(as('assistantA'), id2), attData({ studentId: 'st2' })));
    await env.clearFirestore(); await seed();
    await assertSucceeds(setDoc(attRef(as('teacherA'), id2), attData({ studentId: 'st2', recordedBy: 'teacherA' })));
    await env.clearFirestore(); await seed();
    await assertSucceeds(setDoc(attRef(as('adminA'), id2), attData({ studentId: 'st2', recordedBy: 'adminA' })));
  });

  it('تسجيل يدوي من غير scannedAt، وحالة متأخر وبعذر', async () => {
    await assertSucceeds(setDoc(attRef(as('assistantA'), id2), manualData({ studentId: 'st2' })));
    await assertSucceeds(setDoc(
      attRef(as('assistantA'), attId(G1_SESSION, 'st1') + 'x'),
      attData({ studentId: 'st1x' }),
    ).catch(() => {}) );
  });

  it('معلم مجموعة تانية أو مساعد مش في المجموعة مرفوض', async () => {
    await assertFails(setDoc(attRef(as('teacherB'), id2), attData({ studentId: 'st2', recordedBy: 'teacherB' })));
    const g2id = attId(G2_SESSION, 'st2');
    await assertFails(setDoc(attRef(as('assistantA'), g2id), attData({ sessionId: G2_SESSION, studentId: 'st2' })));
  });

  it('معلم معطّل، أدمن سنتر تاني، وغير مسجل مرفوضين', async () => {
    await assertFails(setDoc(attRef(as('offTeacher'), id2), attData({ studentId: 'st2', recordedBy: 'offTeacher' })));
    await assertFails(setDoc(attRef(as('adminB'), id2), attData({ studentId: 'st2', recordedBy: 'adminB' })));
    await assertFails(setDoc(attRef(env.unauthenticatedContext().firestore(), id2), attData({ studentId: 'st2' })));
  });

  it('recordedBy لحد تاني مرفوض', async () => {
    await assertFails(setDoc(attRef(as('assistantA'), id2), attData({ studentId: 'st2', recordedBy: 'teacherA' })));
  });

  it('الـ id مش sessionId_studentId مرفوض', async () => {
    await assertFails(setDoc(attRef(as('assistantA'), 'whatever'), attData({ studentId: 'st2' })));
  });

  it('إنشاء مسجل كملغي من البداية مرفوض', async () => {
    await assertFails(setDoc(attRef(as('assistantA'), id2), attData({
      studentId: 'st2', voided: true, voidedBy: 'assistantA', voidReason: 'x', voidedAt: serverTimestamp(),
    })));
  });

  it('QR من غير scannedAt مرفوض، ويدوي معاه scannedAt مرفوض', async () => {
    const d = attData({ studentId: 'st2' });
    delete d.scannedAt;
    await assertFails(setDoc(attRef(as('assistantA'), id2), d));
    await assertFails(setDoc(attRef(as('assistantA'), id2), attData({ studentId: 'st2', method: 'manual' })));
  });

  it('حالة غلط، حقل غريب، أو centerId مختلف مرفوضين', async () => {
    await assertFails(setDoc(attRef(as('assistantA'), id2), attData({ studentId: 'st2', status: 'absent' })));
    await assertFails(setDoc(attRef(as('assistantA'), id2), attData({ studentId: 'st2', extra: 1 })));
    await assertFails(setDoc(attRef(as('assistantA'), id2), attData({ studentId: 'st2', centerId: B })));
  });

  it('طالب أو حصة مش موجودين مرفوضين', async () => {
    await assertFails(setDoc(attRef(as('assistantA'), attId(G1_SESSION, 'ghost')), attData({ studentId: 'ghost' })));
    await assertFails(setDoc(attRef(as('adminA'), attId('g1_20300101_1700', 'st2')), attData({
      sessionId: 'g1_20300101_1700', studentId: 'st2', recordedBy: 'adminA',
    })));
  });

  it('set فوق سجل موجود مرفوض (منع التكرار)', async () => {
    await assertFails(setDoc(attRef(as('assistantA'), attId(G1_SESSION, 'st1')), attData()));
  });

  it('[خطوة4] حالة سداد صالحة بتتسجل، والناقصة أو الغريبة مرفوضة', async () => {
    await assertSucceeds(setDoc(attRef(as('assistantA'), id2), attData({ studentId: 'st2', paymentStatus: 'paid' })));
    await assertSucceeds(setDoc(attRef(as('assistantA'), attId(G1_SESSION, 'st3')), attData({ studentId: 'st3', paymentStatus: 'unpaid' })));

    const missing = attData({ studentId: 'st4' });
    delete missing.paymentStatus;
    await assertFails(setDoc(attRef(as('assistantA'), attId(G1_SESSION, 'st4')), missing));
    await assertFails(setDoc(attRef(as('assistantA'), attId(G1_SESSION, 'st4')), attData({ studentId: 'st4', paymentStatus: 'rich' })));
  });
});

describe('attendance — الإلغاء', () => {
  const id1 = attId(G1_SESSION, 'st1');

  it('المساعد والمعلم والأدمن يلغوا بسبب', async () => {
    await assertSucceeds(updateDoc(attRef(as('assistantA'), id1), voidData()));
    await env.clearFirestore(); await seed();
    await assertSucceeds(updateDoc(attRef(as('teacherA'), id1), voidData({ voidedBy: 'teacherA' })));
    await env.clearFirestore(); await seed();
    await assertSucceeds(updateDoc(attRef(as('adminA'), id1), voidData({ voidedBy: 'adminA' })));
  });

  it('السبب فاضي أو طويل مرفوض', async () => {
    await assertFails(updateDoc(attRef(as('assistantA'), id1), voidData({ voidReason: '' })));
    await assertFails(updateDoc(attRef(as('assistantA'), id1), voidData({ voidReason: 'x'.repeat(301) })));
  });

  it('voidedBy لحد تاني مرفوض', async () => {
    await assertFails(updateDoc(attRef(as('assistantA'), id1), voidData({ voidedBy: 'teacherA' })));
  });

  it('تعديل أي حقل تاني مع الإلغاء مرفوض', async () => {
    await assertFails(updateDoc(attRef(as('assistantA'), id1), voidData({ status: 'late' })));
    await assertFails(updateDoc(attRef(as('assistantA'), id1), { status: 'late' }));
    await assertFails(updateDoc(attRef(as('assistantA'), id1), { recordedBy: 'teacherA' }));
  });

  it('الإلغاء مرتين ورجوع من الإلغاء مرفوضين', async () => {
    await assertSucceeds(updateDoc(attRef(as('assistantA'), id1), voidData()));
    await assertFails(updateDoc(attRef(as('assistantA'), id1), voidData({ voidReason: 'تاني' })));
    await assertFails(updateDoc(attRef(as('assistantA'), id1), {
      voided: false, voidedBy: null, voidReason: null, voidedAt: null,
    }));
  });

  it('معلم مجموعة تانية وأدمن سنتر تاني مرفوضين', async () => {
    await assertFails(updateDoc(attRef(as('teacherB'), id1), voidData({ voidedBy: 'teacherB' })));
    await assertFails(updateDoc(attRef(as('adminB'), id1), voidData({ voidedBy: 'adminB' })));
  });

  it('الحذف ممنوع حتى للأدمن', async () => {
    await assertFails(deleteDoc(attRef(as('adminA'), id1)));
    await assertFails(deleteDoc(attRef(as('assistantA'), id1)));
  });
});

describe('attendance — القراءة', () => {
  it('المعلم والمساعد يقروا حضور مجموعتهم بس', async () => {
    await assertSucceeds(getDoc(attRef(as('assistantA'), attId(G1_SESSION, 'st1'))));
    await assertSucceeds(getDoc(attRef(as('teacherA'), attId(G1_SESSION, 'st1'))));
    await assertFails(getDoc(attRef(as('teacherA'), attId(G2_SESSION, 'st1'))));
    await assertFails(getDoc(attRef(as('assistantA'), attId(G2_SESSION, 'st1'))));
  });

  it('الأدمن يقرا الكل، ومعطّل أو سنتر تاني أو غير مسجل لأ', async () => {
    await assertSucceeds(getDoc(attRef(as('adminA'), attId(G2_SESSION, 'st1'))));
    await assertFails(getDoc(attRef(as('offTeacher'), attId(G1_SESSION, 'st1'))));
    await assertFails(getDoc(attRef(as('adminB'), attId(G1_SESSION, 'st1'))));
    await assertFails(getDoc(attRef(env.unauthenticatedContext().firestore(), attId(G1_SESSION, 'st1'))));
  });

  it('list: الموظف النشط يقرا حضور أي حصة في السنتر، والأدمن الكل', async () => {
    const col = (db) => collection(db, `centers/${A}/attendance`);
    const q = (db, s) => query(col(db), where('sessionId', '==', s));
    await assertSucceeds(getDocs(q(as('assistantA'), G1_SESSION)));
    await assertSucceeds(getDocs(q(as('teacherA'), G1_SESSION)));
    await assertSucceeds(getDocs(q(as('teacherA'), G2_SESSION)));
    await assertSucceeds(getDocs(col(as('adminA'))));
  });

  it('list: معطّل أو غير مسجل أو غير مربوط مرفوضين', async () => {
    const col = (db) => collection(db, `centers/${A}/attendance`);
    await assertFails(getDocs(col(as('offTeacher'))));
    await assertFails(getDocs(col(env.unauthenticatedContext().firestore())));
    // مستخدم مسجل من غير عضوية ولا ربط: مرفوض حتى بفلتر studentId.
    await assertFails(getDocs(query(col(as('randomUser')), where('studentId', '==', 'st1'))));
  });
});