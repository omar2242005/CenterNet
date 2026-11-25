// اختبارات Rules ربط الطالب وولي الأمر (Person 3): studentLinks + guardianCounts + linkedUsers
// + قراءة الطالب/ولي الأمر للحضور والدرجات والجدول.
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
  doc, collection, query, where, getDoc, getDocs, setDoc, updateDoc, deleteDoc,
  writeBatch, serverTimestamp, increment, Timestamp,
} = require('firebase/firestore');

const A = 'centerA';

let env;
const as = (uid) => env.authenticatedContext(uid).firestore();

const future = (days) => Timestamp.fromMillis(Date.now() + days * 86400000);
const past = (days) => Timestamp.fromMillis(Date.now() - days * 86400000);

const linkCode = (kind, studentId, over = {}) => ({
  centerId: A, kind, studentId, usedBy: null, expiresAt: future(3), createdBy: 'adminA',
  createdAt: Timestamp.now(), ...(kind === 'guardian' ? { relation: 'أب' } : {}), ...over,
});

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (p, data) => setDoc(doc(db, p), data);
    await put(`centers/${A}`, { name: 'مركز النور', year: 2026, createdBy: 'adminA', lateAfterMinutes: 15 });
    await put(`centers/${A}/members/adminA`, { role: 'admin', name: 'Admin A', active: true, createdBy: 'adminA' });
    await put(`centers/${A}/students/s1`, {
      centerId: A, studentNo: 1, fullName: 'أحمد', searchKey: 'احمد', phone: '01011112222',
      grade: '1', groupIds: ['g1'], status: 'active', createdBy: 'adminA',
    });
    await put(`centers/${A}/students/s2`, {
      centerId: A, studentNo: 2, fullName: 'سارة', searchKey: 'سارة', phone: '01011113333',
      grade: '1', groupIds: ['g1'], status: 'active', createdBy: 'adminA',
    });
    await put(`centers/${A}/groups/g1`, {
      centerId: A, name: 'جبر', subject: 'رياضة', grade: '1', teacherId: 'teacherA',
      assistantIds: [], room: '1', capacity: 10, monthlyFee: 100, slots: [], status: 'active',
      createdBy: 'adminA',
    });
    await put(`centers/${A}/sessions/g1_20261101_1700`, {
      centerId: A, groupId: 'g1', startAt: Timestamp.now(), endAt: Timestamp.now(),
      status: 'scheduled', createdBy: 'adminA',
    });
    await put(`centers/${A}/attendance/g1_20261101_1700_s1`, {
      centerId: A, sessionId: 'g1_20261101_1700', studentId: 's1', status: 'present', method: 'manual',
      recordedBy: 'teacherA', recordedAt: Timestamp.now(), voided: false, voidedBy: null,
      voidReason: null, voidedAt: null,
    });
    await put(`centers/${A}/attendance/g1_20261101_1700_s2`, {
      centerId: A, sessionId: 'g1_20261101_1700', studentId: 's2', status: 'present', method: 'manual',
      recordedBy: 'teacherA', recordedAt: Timestamp.now(), voided: false, voidedBy: null,
      voidReason: null, voidedAt: null,
    });
    await put(`centers/${A}/exams/e1`, {
      centerId: A, groupId: 'g1', title: 'منشور', date: Timestamp.now(), maxScore: 20,
      published: true, createdBy: 'adminA',
    });
    await put(`centers/${A}/exams/e2`, {
      centerId: A, groupId: 'g1', title: 'مسودة', date: Timestamp.now(), maxScore: 20,
      published: false, createdBy: 'adminA',
    });
    for (const [e, s] of [['e1', 's1'], ['e1', 's2'], ['e2', 's1']]) {
      await put(`centers/${A}/scores/${e}_${s}`, {
        centerId: A, examId: e, studentId: s, state: 'scored', score: 15, comment: '',
        createdBy: 'teacherA',
      });
    }
    await put('inviteCodes/STUD0001', linkCode('student', 's1'));
    await put('inviteCodes/GUARD001', linkCode('guardian', 's1'));
    await put('inviteCodes/GUARD002', linkCode('guardian', 's1', { relation: 'أم' }));
    await put('inviteCodes/GUARD003', linkCode('guardian', 's1'));
    await put('inviteCodes/GUARD004', linkCode('guardian', 's1'));
    await put('inviteCodes/GUARD005', linkCode('guardian', 's1'));
    await put('inviteCodes/OLDCODE1', linkCode('guardian', 's1', { expiresAt: past(1) }));
    await put('inviteCodes/USEDCODE', linkCode('guardian', 's1', { usedBy: 'someoneElse' }));
    await put('inviteCodes/OTHERST1', linkCode('guardian', 's2'));
  });
}

/** نفس اللي الـ Repository بيعمله: استهلاك الكود + الربط + العدّادات في Batch واحد. */
function linkBatch(db, { uid, code, sid, kind, relation, link = {}, skip = {} }) {
  const b = writeBatch(db);
  if (!skip.code) b.update(doc(db, `inviteCodes/${code}`), { usedBy: uid });
  const data = {
    centerId: A, uid, studentId: sid, kind, status: 'active', inviteCode: code,
    createdAt: serverTimestamp(), createdBy: uid, ...link,
  };
  if (kind === 'guardian') data.relation = relation ?? 'أب';
  b.set(doc(db, `centers/${A}/studentLinks/${uid}_${sid}`), data);
  if (!skip.marker) b.set(doc(db, `centers/${A}/linkedUsers/${uid}`), { count: increment(1), sid }, { merge: true });
  if (kind === 'guardian' && !skip.counter) {
    b.set(doc(db, `centers/${A}/guardianCounts/${sid}`), { count: increment(1) }, { merge: true });
  }
  return b.commit();
}

function unlinkBatch(db, { uid, sid, kind, skip = {} }) {
  const b = writeBatch(db);
  b.update(doc(db, `centers/${A}/studentLinks/${uid}_${sid}`), { status: 'unlinked' });
  if (!skip.marker) b.set(doc(db, `centers/${A}/linkedUsers/${uid}`), { count: increment(-1), sid }, { merge: true });
  if (kind === 'guardian' && !skip.counter) {
    b.set(doc(db, `centers/${A}/guardianCounts/${sid}`), { count: increment(-1) }, { merge: true });
  }
  return b.commit();
}

/** يربط حساب بالـ Rules معطّلة (تجهيز حالة). */
async function presetLink({ uid, sid, kind, code = 'PRESET01', relation = 'أب' }) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `centers/${A}/studentLinks/${uid}_${sid}`), {
      centerId: A, uid, studentId: sid, kind, status: 'active', inviteCode: code,
      ...(kind === 'guardian' ? { relation } : {}), createdAt: Timestamp.now(), createdBy: uid,
    });
    const m = doc(db, `centers/${A}/linkedUsers/${uid}`);
    await setDoc(m, { count: 1, sid });
    if (kind === 'guardian') {
      const g = doc(db, `centers/${A}/guardianCounts/${sid}`);
      const cur = await getDoc(g);
      await setDoc(g, { count: (cur.exists() ? cur.data().count : 0) + 1 });
    }
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

describe('ربط الطالب بكود', () => {
  it('الطالب يربط بكود طالب صالح', async () => {
    await assertSucceeds(linkBatch(as('stu1'), { uid: 'stu1', code: 'STUD0001', sid: 's1', kind: 'student' }));
  });

  it('الكود ميتستخدمش مرتين', async () => {
    await assertSucceeds(linkBatch(as('stu1'), { uid: 'stu1', code: 'STUD0001', sid: 's1', kind: 'student' }));
    await assertFails(linkBatch(as('stu2'), { uid: 'stu2', code: 'STUD0001', sid: 's1', kind: 'student' }));
  });

  it('كود ولي أمر مينفعش يربط كطالب (نوع مختلف)', async () => {
    await assertFails(linkBatch(as('stu1'), { uid: 'stu1', code: 'GUARD001', sid: 's1', kind: 'student' }));
  });

  it('كود منتهي أو مستخدم أو لطالب تاني مرفوض', async () => {
    await assertFails(linkBatch(as('g1u'), { uid: 'g1u', code: 'OLDCODE1', sid: 's1', kind: 'guardian' }));
    await assertFails(linkBatch(as('g1u'), { uid: 'g1u', code: 'USEDCODE', sid: 's1', kind: 'guardian' }));
    await assertFails(linkBatch(as('g1u'), { uid: 'g1u', code: 'OTHERST1', sid: 's1', kind: 'guardian' }));
  });

  it('إنشاء الربط من غير استهلاك الكود مرفوض', async () => {
    await assertFails(linkBatch(as('stu1'), {
      uid: 'stu1', code: 'STUD0001', sid: 's1', kind: 'student', skip: { code: true },
    }));
  });

  it('استهلاك الكود من غير ربط مرفوض', async () => {
    await assertFails(updateDoc(doc(as('stu1'), 'inviteCodes/STUD0001'), { usedBy: 'stu1' }));
  });

  it('مينفعش تربط لحساب حد تاني', async () => {
    await assertFails(linkBatch(as('evil'), {
      uid: 'stu1', code: 'STUD0001', sid: 's1', kind: 'student',
    }));
  });

  it('createdAt لازم يبقى وقت السيرفر', async () => {
    await assertFails(linkBatch(as('stu1'), {
      uid: 'stu1', code: 'STUD0001', sid: 's1', kind: 'student', link: { createdAt: past(5) },
    }));
  });

  it('الطالب مينفعش يحط relation', async () => {
    await assertFails(linkBatch(as('stu1'), {
      uid: 'stu1', code: 'STUD0001', sid: 's1', kind: 'student', link: { relation: 'أب' },
    }));
  });

  it('من غير تحديث linkedUsers مرفوض', async () => {
    await assertFails(linkBatch(as('stu1'), {
      uid: 'stu1', code: 'STUD0001', sid: 's1', kind: 'student', skip: { marker: true },
    }));
  });
});

describe('ولي الأمر والحد الأقصى 4', () => {
  it('ولي الأمر يربط والعدّاد يبقى 1', async () => {
    const db = as('gu1');
    await assertSucceeds(linkBatch(db, { uid: 'gu1', code: 'GUARD001', sid: 's1', kind: 'guardian' }));
    await env.withSecurityRulesDisabled(async (ctx) => {
      const c = await getDoc(doc(ctx.firestore(), `centers/${A}/guardianCounts/s1`));
      if (c.data().count !== 1) throw new Error('العدّاد لازم يبقى 1');
    });
  });

  it('relation لازم تطابق اللي في الكود', async () => {
    await assertFails(linkBatch(as('gu1'), {
      uid: 'gu1', code: 'GUARD001', sid: 's1', kind: 'guardian', relation: 'عم',
    }));
  });

  it('من غير تحديث العدّاد مرفوض', async () => {
    await assertFails(linkBatch(as('gu1'), {
      uid: 'gu1', code: 'GUARD001', sid: 's1', kind: 'guardian', skip: { counter: true },
    }));
  });

  it('4 أولياء أمور ينفع، الخامس لأ', async () => {
    const users = ['gu1', 'gu2', 'gu3', 'gu4'];
    const codes = ['GUARD001', 'GUARD002', 'GUARD003', 'GUARD004'];
    for (let i = 0; i < 4; i++) {
      await assertSucceeds(linkBatch(as(users[i]), {
        uid: users[i], code: codes[i], sid: 's1', kind: 'guardian',
        relation: codes[i] === 'GUARD002' ? 'أم' : 'أب',
      }));
    }
    await assertFails(linkBatch(as('gu5'), { uid: 'gu5', code: 'GUARD005', sid: 's1', kind: 'guardian' }));
  });

  it('مينفعش يكتب عدّاد الأولياء من غير ربط', async () => {
    await assertFails(setDoc(doc(as('gu1'), `centers/${A}/guardianCounts/s1`), { count: 1 }));
  });

  it('ولي الأمر يفك الربط والعدّاد بينقص، وبعدها يقدر يربط واحد جديد', async () => {
    await assertSucceeds(linkBatch(as('gu1'), { uid: 'gu1', code: 'GUARD001', sid: 's1', kind: 'guardian' }));
    await assertSucceeds(unlinkBatch(as('gu1'), { uid: 'gu1', sid: 's1', kind: 'guardian' }));
    await env.withSecurityRulesDisabled(async (ctx) => {
      const c = await getDoc(doc(ctx.firestore(), `centers/${A}/guardianCounts/s1`));
      if (c.data().count !== 0) throw new Error('العدّاد لازم يرجع 0');
    });
  });

  it('فك الربط من غير إنقاص العدّاد مرفوض', async () => {
    await assertSucceeds(linkBatch(as('gu1'), { uid: 'gu1', code: 'GUARD001', sid: 's1', kind: 'guardian' }));
    await assertFails(unlinkBatch(as('gu1'), { uid: 'gu1', sid: 's1', kind: 'guardian', skip: { counter: true } }));
  });

  it('الأدمن يفك ربط ولي أمر وينقص العدّاد', async () => {
    await assertSucceeds(linkBatch(as('gu1'), { uid: 'gu1', code: 'GUARD001', sid: 's1', kind: 'guardian' }));
    await assertSucceeds(unlinkBatch(as('adminA'), { uid: 'gu1', sid: 's1', kind: 'guardian' }));
  });

  it('حد غريب مينفعش يفك ربط حد', async () => {
    await assertSucceeds(linkBatch(as('gu1'), { uid: 'gu1', code: 'GUARD001', sid: 's1', kind: 'guardian' }));
    await assertFails(unlinkBatch(as('evil'), { uid: 'gu1', sid: 's1', kind: 'guardian' }));
  });

  it('إعادة الربط بعد الفك بكود جديد', async () => {
    await assertSucceeds(linkBatch(as('gu1'), { uid: 'gu1', code: 'GUARD001', sid: 's1', kind: 'guardian' }));
    await assertSucceeds(unlinkBatch(as('gu1'), { uid: 'gu1', sid: 's1', kind: 'guardian' }));
    const b = writeBatch(as('gu1'));
    b.update(doc(as('gu1'), 'inviteCodes/GUARD003'), { usedBy: 'gu1' });
    b.update(doc(as('gu1'), `centers/${A}/studentLinks/gu1_s1`), {
      status: 'active', inviteCode: 'GUARD003', relation: 'أب',
    });
    b.set(doc(as('gu1'), `centers/${A}/linkedUsers/gu1`), { count: increment(1), sid: 's1' }, { merge: true });
    b.set(doc(as('gu1'), `centers/${A}/guardianCounts/s1`), { count: increment(1) }, { merge: true });
    await assertSucceeds(b.commit());
  });

  it('مفيش حذف للربط', async () => {
    await assertSucceeds(linkBatch(as('gu1'), { uid: 'gu1', code: 'GUARD001', sid: 's1', kind: 'guardian' }));
    await assertFails(deleteDoc(doc(as('gu1'), `centers/${A}/studentLinks/gu1_s1`)));
    await assertFails(deleteDoc(doc(as('adminA'), `centers/${A}/studentLinks/gu1_s1`)));
  });
});

describe('قراءة الربط', () => {
  beforeEach(async () => {
    await presetLink({ uid: 'gu1', sid: 's1', kind: 'guardian' });
  });

  it('صاحب الربط والأدمن يقروا', async () => {
    await assertSucceeds(getDoc(doc(as('gu1'), `centers/${A}/studentLinks/gu1_s1`)));
    await assertSucceeds(getDoc(doc(as('adminA'), `centers/${A}/studentLinks/gu1_s1`)));
    await assertSucceeds(getDocs(query(collection(as('gu1'), `centers/${A}/studentLinks`), where('uid', '==', 'gu1'))));
  });

  it('حد غريب لأ', async () => {
    await assertFails(getDoc(doc(as('evil'), `centers/${A}/studentLinks/gu1_s1`)));
  });
});

describe('قراءة الطالب/ولي الأمر للبيانات', () => {
  beforeEach(async () => {
    await presetLink({ uid: 'stu1', sid: 's1', kind: 'student' });
  });

  it('يقرا الطالب المربوط بيه بس', async () => {
    await assertSucceeds(getDoc(doc(as('stu1'), `centers/${A}/students/s1`)));
    await assertFails(getDoc(doc(as('stu1'), `centers/${A}/students/s2`)));
    await assertFails(getDocs(collection(as('stu1'), `centers/${A}/students`)));
  });

  it('غير المربوط ميقراش الطالب', async () => {
    await assertFails(getDoc(doc(as('evil'), `centers/${A}/students/s1`)));
  });

  it('يقرا حضوره هو بس', async () => {
    const col = collection(as('stu1'), `centers/${A}/attendance`);
    await assertSucceeds(getDocs(query(col, where('studentId', '==', 's1'))));
    await assertFails(getDocs(query(col, where('studentId', '==', 's2'))));
    await assertFails(getDocs(col));
  });

  it('يقرا درجاته في الامتحانات المنشورة بس', async () => {
    await assertSucceeds(getDoc(doc(as('stu1'), `centers/${A}/scores/e1_s1`)));
    await assertFails(getDoc(doc(as('stu1'), `centers/${A}/scores/e2_s1`)));
    await assertFails(getDoc(doc(as('stu1'), `centers/${A}/scores/e1_s2`)));
  });

  it('يقرا الامتحانات المنشورة والمجموعات والحصص، من غير المسودات', async () => {
    await assertSucceeds(getDoc(doc(as('stu1'), `centers/${A}/exams/e1`)));
    await assertFails(getDoc(doc(as('stu1'), `centers/${A}/exams/e2`)));
    await assertSucceeds(getDoc(doc(as('stu1'), `centers/${A}/groups/g1`)));
    await assertSucceeds(getDoc(doc(as('stu1'), `centers/${A}/sessions/g1_20261101_1700`)));
  });

  it('غير المربوط ميقراش المجموعات ولا الحصص ولا الامتحانات', async () => {
    await assertFails(getDoc(doc(as('evil'), `centers/${A}/groups/g1`)));
    await assertFails(getDoc(doc(as('evil'), `centers/${A}/sessions/g1_20261101_1700`)));
    await assertFails(getDoc(doc(as('evil'), `centers/${A}/exams/e1`)));
  });

  it('بعد فك الربط يفقد القراءة', async () => {
    await assertSucceeds(unlinkBatch(as('stu1'), { uid: 'stu1', sid: 's1', kind: 'student' }));
    await assertFails(getDoc(doc(as('stu1'), `centers/${A}/students/s1`)));
    await assertFails(getDoc(doc(as('stu1'), `centers/${A}/groups/g1`)));
  });

  it('مينفعش يكتب حاجة في بيانات السنتر', async () => {
    await assertFails(updateDoc(doc(as('stu1'), `centers/${A}/students/s1`), { grade: '9' }));
    await assertFails(setDoc(doc(as('stu1'), `centers/${A}/linkedUsers/stu1`), { count: 50, sid: 's1' }));
  });

  it('مينفعش يفتح linkedUsers لنفسه من غير ربط', async () => {
    await assertFails(setDoc(doc(as('evil'), `centers/${A}/linkedUsers/evil`), { count: 1, sid: 's1' }));
  });
});
