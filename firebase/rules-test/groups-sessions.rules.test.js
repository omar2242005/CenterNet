// اختبارات Rules المجموعات والحصص (موجة 1، الشخص 1).
// التشغيل:  cd firebase/rules-test && npm test   (محتاج Java للـ Emulator)

const { describe, it, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc,
  query, where, orderBy, runTransaction, Timestamp, serverTimestamp,
} = require('firebase/firestore');

const A = 'centerA';
const B = 'centerB';

let env;
const as = (uid) => env.authenticatedContext(uid).firestore();

const slot = { weekday: 4, startMinutes: 1020, durationMinutes: 90 };

const groupData = (over = {}) => ({
  centerId: A, name: 'الجبر - الثالث الإعدادي', subject: 'رياضيات',
  grade: 'الصف الثالث الإعدادي', teacherId: 'teacherA', assistantIds: ['assistantA'],
  room: 'قاعة 1', monthlyFee: 45000, slots: [slot], status: 'active',
  createdAt: serverTimestamp(), createdBy: 'adminA', ...over,
});

const START = new Date('2026-11-26T15:00:00Z');
const END = new Date('2026-11-26T16:30:00Z');

const sessionData = (over = {}) => ({
  centerId: A, groupId: 'g1', startAt: Timestamp.fromDate(START),
  endAt: Timestamp.fromDate(END), status: 'scheduled',
  createdAt: serverTimestamp(), createdBy: 'adminA', ...over,
});

const G1_SESSION = 'g1_20261126_1700';
const G2_SESSION = 'g2_20261126_1700';

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (p, data) => setDoc(doc(db, p), data);
    const now = Timestamp.now();

    await put(`centers/${A}`, { name: 'مركز النور', year: 2026, createdBy: 'adminA', lateAfterMinutes: 15 });
    await put(`centers/${A}/members/adminA`, { role: 'admin', name: 'Admin A', active: true, createdBy: 'adminA' });
    await put(`centers/${A}/members/teacherA`, { role: 'teacher', name: 'Teacher A', active: true, createdBy: 'teacherA' });
    await put(`centers/${A}/members/teacherB`, { role: 'teacher', name: 'Teacher B', active: true, createdBy: 'teacherB' });
    await put(`centers/${A}/members/assistantA`, { role: 'assistant', name: 'Assistant A', active: true, createdBy: 'assistantA' });
    await put(`centers/${A}/members/offTeacher`, { role: 'teacher', name: 'Off', active: false, createdBy: 'offTeacher' });
    await put(`centers/${B}`, { name: 'مركز تاني', year: 2026, createdBy: 'adminB', lateAfterMinutes: 15 });
    await put(`centers/${B}/members/adminB`, { role: 'admin', name: 'Admin B', active: true, createdBy: 'adminB' });

    // g1: معلم A + مساعد A. g2: معلم B من غير مساعدين.
    await put(`centers/${A}/groups/g1`, groupData({ createdAt: now }));
    await put(`centers/${A}/groups/g2`, groupData({
      name: 'فيزياء', teacherId: 'teacherB', assistantIds: [], createdAt: now,
    }));

    await put(`centers/${A}/sessions/${G1_SESSION}`, sessionData({ createdAt: now }));
    await put(`centers/${A}/sessions/${G2_SESSION}`, sessionData({ groupId: 'g2', createdAt: now }));
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

const groupRef = (db, id) => doc(db, `centers/${A}/groups/${id}`);
const sessionRef = (db, id) => doc(db, `centers/${A}/sessions/${id}`);

describe('groups — الإنشاء', () => {
  it('الأدمن ينشئ مجموعة', async () => {
    await assertSucceeds(setDoc(groupRef(as('adminA'), 'g3'), groupData()));
  });

  it('المعلم والمساعد وأدمن سنتر تاني مينفعش', async () => {
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), groupData({ createdBy: 'teacherA' })));
    await assertFails(setDoc(groupRef(as('assistantA'), 'g3'), groupData({ createdBy: 'assistantA' })));
    await assertFails(setDoc(groupRef(as('adminB'), 'g3'), groupData({ createdBy: 'adminB' })));
  });

  it('حالة archived من البداية مرفوضة', async () => {
    await assertFails(setDoc(groupRef(as('adminA'), 'g3'), groupData({ status: 'archived' })));
  });

  it('المعلم نفسه مساعد في نفس المجموعة مرفوض', async () => {
    await assertFails(setDoc(groupRef(as('adminA'), 'g3'), groupData({ assistantIds: ['teacherA'] })));
  });

  it('حقل غريب أو centerId مختلف مرفوضين', async () => {
    await assertFails(setDoc(groupRef(as('adminA'), 'g3'), groupData({ extra: 1 })));
    await assertFails(setDoc(groupRef(as('adminA'), 'g3'), groupData({ centerId: B })));
  });

  it('اسم فاضي وسعر سالب وميعاد غلط مرفوضين', async () => {
    await assertFails(setDoc(groupRef(as('adminA'), 'g3'), groupData({ name: '' })));
    await assertFails(setDoc(groupRef(as('adminA'), 'g3'), groupData({ monthlyFee: -1 })));
    await assertFails(setDoc(groupRef(as('adminA'), 'g3'), groupData({
      slots: [{ weekday: 9, startMinutes: 1020, durationMinutes: 90 }],
    })));
  });

  it('createdBy لحد تاني مرفوض', async () => {
    await assertFails(setDoc(groupRef(as('adminA'), 'g3'), groupData({ createdBy: 'teacherA' })));
  });
});

describe('groups — التعديل والأرشفة', () => {
  it('الأدمن يعدّل المساعدين والمواعيد ويأرشف', async () => {
    const db = as('adminA');
    await assertSucceeds(updateDoc(groupRef(db, 'g1'), { assistantIds: [], name: 'اسم جديد' }));
    await assertSucceeds(updateDoc(groupRef(db, 'g1'), { slots: [slot, { ...slot, weekday: 6 }] }));
    await assertSucceeds(updateDoc(groupRef(db, 'g1'), { status: 'archived' }));
  });

  it('centerId و createdBy ما يتغيّروش', async () => {
    const db = as('adminA');
    await assertFails(updateDoc(groupRef(db, 'g1'), { centerId: B }));
    await assertFails(updateDoc(groupRef(db, 'g1'), { createdBy: 'teacherA' }));
  });

  it('المعلم والمساعد ما يعدّلوش، والحذف ممنوع حتى للأدمن', async () => {
    await assertFails(updateDoc(groupRef(as('teacherA'), 'g1'), { name: 'x' }));
    await assertFails(updateDoc(groupRef(as('assistantA'), 'g1'), { name: 'x' }));
    await assertFails(deleteDoc(groupRef(as('adminA'), 'g1')));
  });
});

describe('groups — القراءة', () => {
  it('المعلم يقرا مجموعته بس', async () => {
    await assertSucceeds(getDoc(groupRef(as('teacherA'), 'g1')));
    await assertFails(getDoc(groupRef(as('teacherA'), 'g2')));
  });

  it('المساعد يقرا المجموعة اللي هو فيها بس', async () => {
    await assertSucceeds(getDoc(groupRef(as('assistantA'), 'g1')));
    await assertFails(getDoc(groupRef(as('assistantA'), 'g2')));
  });

  it('list: المعلم بـ teacherId، والمساعد بـ array-contains، والأدمن الكل', async () => {
    const col = (db) => collection(db, `centers/${A}/groups`);
    await assertSucceeds(getDocs(query(col(as('teacherA')), where('teacherId', '==', 'teacherA'))));
    await assertSucceeds(getDocs(query(col(as('assistantA')), where('assistantIds', 'array-contains', 'assistantA'))));
    await assertSucceeds(getDocs(col(as('adminA'))));
  });

  it('list: الموظف النشط يقرا كل مجموعات السنتر (من غير فلتر أو بفلتر حد تاني)', async () => {
    const col = (db) => collection(db, `centers/${A}/groups`);
    await assertSucceeds(getDocs(col(as('teacherA'))));
    await assertSucceeds(getDocs(query(col(as('teacherA')), where('teacherId', '==', 'teacherB'))));
    await assertSucceeds(getDocs(col(as('assistantA'))));
  });

  it('list: معطّل أو سنتر تاني أو غير مسجل مرفوضين', async () => {
    const col = (db) => collection(db, `centers/${A}/groups`);
    await assertFails(getDocs(col(as('offTeacher'))));
    await assertFails(getDocs(col(as('adminB'))));
    await assertFails(getDocs(col(env.unauthenticatedContext().firestore())));
  });

  it('معلم معطّل أو من سنتر تاني أو غير مسجل مرفوض', async () => {
    await assertFails(getDoc(groupRef(as('offTeacher'), 'g1')));
    await assertFails(getDoc(groupRef(as('adminB'), 'g1')));
    await assertFails(getDoc(groupRef(env.unauthenticatedContext().firestore(), 'g1')));
  });
});

describe('sessions — الإنشاء والإلغاء', () => {
  it('الأدمن ينشئ جلسة لمجموعة موجودة', async () => {
    await assertSucceeds(setDoc(sessionRef(as('adminA'), 'g1_20261203_1700'), sessionData()));
  });

  it('جلسة لمجموعة مش موجودة مرفوضة', async () => {
    await assertFails(setDoc(sessionRef(as('adminA'), 'gX_20261203_1700'), sessionData({ groupId: 'gX' })));
  });

  it('نهاية قبل أو تساوي البداية مرفوضة', async () => {
    await assertFails(setDoc(sessionRef(as('adminA'), 'g1_20261203_1700'), sessionData({
      endAt: Timestamp.fromDate(START),
    })));
  });

  it('جلسة بحالة cancelled من البداية مرفوضة', async () => {
    await assertFails(setDoc(sessionRef(as('adminA'), 'g1_20261203_1700'), sessionData({ status: 'cancelled' })));
  });

  it('المعلم والمساعد وأدمن سنتر تاني مينفعش ينشئوا', async () => {
    await assertFails(setDoc(sessionRef(as('teacherA'), 'g1_20261203_1700'), sessionData({ createdBy: 'teacherA' })));
    await assertFails(setDoc(sessionRef(as('assistantA'), 'g1_20261203_1700'), sessionData({ createdBy: 'assistantA' })));
    await assertFails(setDoc(sessionRef(as('adminB'), 'g1_20261203_1700'), sessionData({ createdBy: 'adminB' })));
  });

  it('الأدمن يلغي الجلسة (status بس)، ومرتين لأ', async () => {
    const db = as('adminA');
    await assertSucceeds(updateDoc(sessionRef(db, G1_SESSION), { status: 'cancelled' }));
    await assertFails(updateDoc(sessionRef(db, G1_SESSION), { status: 'cancelled' }));
  });

  it('مفيش رجوع من cancelled، ومفيش تعديل في الوقت', async () => {
    const db = as('adminA');
    await assertFails(updateDoc(sessionRef(db, G1_SESSION), { startAt: Timestamp.fromDate(END) }));
    await assertSucceeds(updateDoc(sessionRef(db, G1_SESSION), { status: 'cancelled' }));
    await assertFails(updateDoc(sessionRef(db, G1_SESSION), { status: 'scheduled' }));
  });

  it('المعلم مينفعش يلغي، والحذف ممنوع', async () => {
    await assertFails(updateDoc(sessionRef(as('teacherA'), G1_SESSION), { status: 'cancelled' }));
    await assertFails(deleteDoc(sessionRef(as('adminA'), G1_SESSION)));
  });
});

describe('sessions — القراءة', () => {
  it('المعلم والمساعد يقروا حصص مجموعتهم بس', async () => {
    await assertSucceeds(getDoc(sessionRef(as('teacherA'), G1_SESSION)));
    await assertFails(getDoc(sessionRef(as('teacherA'), G2_SESSION)));
    await assertSucceeds(getDoc(sessionRef(as('assistantA'), G1_SESSION)));
    await assertFails(getDoc(sessionRef(as('assistantA'), G2_SESSION)));
  });

  it('list: الموظف النشط يقرا حصص أي مجموعة في السنتر، وغير المسجل لأ', async () => {
    const col = (db) => collection(db, `centers/${A}/sessions`);
    await assertSucceeds(getDocs(query(col(as('teacherA')), where('groupId', '==', 'g1'))));
    await assertSucceeds(getDocs(query(col(as('teacherA')), where('groupId', '==', 'g2'))));
    await assertSucceeds(getDocs(query(col(as('assistantA')), where('groupId', '==', 'g2'))));
    await assertSucceeds(getDocs(col(as('teacherA'))));
    await assertFails(getDocs(col(env.unauthenticatedContext().firestore())));
  });

  it('الأدمن يقرا الكل، ومعلم معطّل أو سنتر تاني لأ', async () => {
    await assertSucceeds(getDocs(collection(as('adminA'), `centers/${A}/sessions`)));
    await assertFails(getDoc(sessionRef(as('offTeacher'), G1_SESSION)));
    await assertFails(getDoc(sessionRef(as('adminB'), G1_SESSION)));
  });
});

describe('sessions — نمط SessionsRepository', () => {
  // نفس منطق generateUpcoming: يقرا الأول ويكتب الناقص بس.
  async function generate(db, ids) {
    let created = 0;
    await runTransaction(db, async (tx) => {
      const missing = [];
      for (const id of ids) {
        const snap = await tx.get(sessionRef(db, id));
        if (!snap.exists()) missing.push(id);
      }
      for (const id of missing) tx.set(sessionRef(db, id), sessionData());
      created = missing.length;
    });
    return created;
  }

  const IDS = [G1_SESSION, 'g1_20261203_1700', 'g1_20261210_1700'];

  it('set فوق حصة موجودة مرفوض (عشان كده Transaction)', async () => {
    await assertFails(setDoc(sessionRef(as('adminA'), G1_SESSION), sessionData()));
  });

  it('التوليد بيكتب الناقص بس، وإعادته بتكتب صفر', async () => {
    const db = as('adminA');
    // G1_SESSION موجودة من الـ seed، فالناقص اتنين.
    assert.equal(await generate(db, IDS), 2);
    assert.equal(await generate(db, IDS), 0);
  });

  it('الحصة الملغاة ما بترجعش تتولّد', async () => {
    const db = as('adminA');
    await updateDoc(sessionRef(db, G1_SESSION), { status: 'cancelled' });
    assert.equal(await generate(db, IDS), 2);
    const snap = await getDoc(sessionRef(db, G1_SESSION));
    assert.equal(snap.data().status, 'cancelled');
  });

  it('المعلم مينفعش يولّد', async () => {
    await assert.rejects(generate(as('teacherA'), ['g1_20261203_1700']));
  });

  it('استعلام loadGroupSessions: الأدمن والمعلم والمساعد لأي مجموعة في السنتر', async () => {
    const q = (db, g) => query(
      collection(db, `centers/${A}/sessions`),
      where('groupId', '==', g),
      where('startAt', '>=', Timestamp.fromDate(new Date('2026-11-01T00:00:00Z'))),
      orderBy('startAt'),
    );
    await assertSucceeds(getDocs(q(as('adminA'), 'g1')));
    await assertSucceeds(getDocs(q(as('teacherA'), 'g1')));
    await assertSucceeds(getDocs(q(as('assistantA'), 'g1')));
    await assertSucceeds(getDocs(q(as('teacherA'), 'g2')));
  });
});
