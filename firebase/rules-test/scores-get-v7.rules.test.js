// [v7] اختبارات get على الدرجات: أول رصد للمعلم (get لمستند مش موجود ثم create).
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
  query, where, Timestamp, serverTimestamp, runTransaction,
} = require('firebase/firestore');

const A = 'centerA';
const B = 'centerB';

let env;
const as = (uid) => env.authenticatedContext(uid).firestore();

const examRef = (db, id) => doc(db, `centers/${A}/exams/${id}`);
const scoreRef = (db, id) => doc(db, `centers/${A}/scores/${id}`);
const scId = (e, s) => `${e}_${s}`;

const EXAM_DATE = Timestamp.fromDate(new Date('2026-11-30T10:00:00Z'));

const examData = (over = {}) => ({
  centerId: A, groupId: 'g1', title: 'امتحان الشهر', date: EXAM_DATE,
  maxScore: 100, published: false, createdAt: serverTimestamp(),
  createdBy: 'teacherA', ...over,
});

const scoreData = (over = {}) => ({
  centerId: A, examId: 'e1', studentId: 'st1', state: 'scored', score: 85.5,
  comment: '', createdAt: serverTimestamp(), createdBy: 'teacherA', ...over,
});

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

    // g1: معلم A + مساعد A. g2: معلم B.
    await put(`centers/${A}/groups/g1`, { centerId: A, name: 'g1', teacherId: 'teacherA', assistantIds: ['assistantA'], status: 'active' });
    await put(`centers/${A}/groups/g2`, { centerId: A, name: 'g2', teacherId: 'teacherB', assistantIds: [], status: 'active' });

    // st1/st3/st4 في g1، وst2 في g2.
    for (const [id, g] of [['st1', 'g1'], ['st3', 'g1'], ['st4', 'g1'], ['st2', 'g2']]) {
      await put(`centers/${A}/students/${id}`, { centerId: A, fullName: id, status: 'active', groupIds: [g] });
    }

    await put(`centers/${A}/exams/e1`, examData({ createdAt: now }));
    await put(`centers/${A}/exams/e2`, examData({ groupId: 'g2', createdBy: 'teacherB', createdAt: now }));

    // ولي أمر مربوط بـ st4 وst1. الامتحان e1 مش منشور، و e3 منشور.
    await put(`centers/${A}/studentLinks/parentA_st4`, { status: 'active' });
    await put(`centers/${A}/studentLinks/parentA_st1`, { status: 'active' });
    // درجة موجودة لـ st4 في e1.
    await put(`centers/${A}/scores/${scId('e1', 'st4')}`,
      scoreData({ studentId: 'st4', score: 50, createdAt: now }));
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


// نفس منطق ScoresRepository.saveScore: transaction بتعمل get ثم set أو update.
const saveLikeApp = (db, examId, studentId, score, uid) =>
  runTransaction(db, async (tx) => {
    const ref = scoreRef(db, scId(examId, studentId));
    const snap = await tx.get(ref);
    if (!snap.exists()) {
      tx.set(ref, scoreData({ examId, studentId, score, createdBy: uid }));
    } else {
      tx.update(ref, { state: 'scored', score, comment: '' });
    }
  });

describe('scores v7 — أول رصد وتعديل بنفس الـ transaction', () => {
  it('معلم المجموعة: أول درجة لطالب (get لمستند مش موجود ثم create) تنجح', async () => {
    await assertSucceeds(saveLikeApp(as('teacherA'), 'e1', 'st1', 90, 'teacherA'));
    const snap = await assertSucceeds(getDoc(scoreRef(as('teacherA'), scId('e1', 'st1'))));
    if (snap.data().score !== 90) throw new Error('الدرجة متحفظتش');
  });

  it('معلم المجموعة: تعديل درجة موجودة بنفس الـ transaction ينجح', async () => {
    await assertSucceeds(saveLikeApp(as('teacherA'), 'e1', 'st4', 70, 'teacherA'));
    const snap = await assertSucceeds(getDoc(scoreRef(as('teacherA'), scId('e1', 'st4'))));
    if (snap.data().score !== 70) throw new Error('التعديل متحفظش');
  });

  it('الأدمن لسه بينجح في الاتنين', async () => {
    await assertSucceeds(saveLikeApp(as('adminA'), 'e1', 'st1', 60, 'adminA'));
    await assertSucceeds(saveLikeApp(as('adminA'), 'e1', 'st4', 61, 'adminA'));
  });

  it('get لمستند مش موجود: المعلم والمساعد بتوع المجموعة والأدمن بس', async () => {
    const id = scId('e1', 'st1');
    await assertSucceeds(getDoc(scoreRef(as('teacherA'), id)));
    await assertSucceeds(getDoc(scoreRef(as('assistantA'), id)));
    await assertSucceeds(getDoc(scoreRef(as('adminA'), id)));
    await assertFails(getDoc(scoreRef(as('teacherB'), id)));      // معلم مجموعة تانية
    await assertFails(getDoc(scoreRef(as('offTeacher'), id)));    // معطّل
    await assertFails(getDoc(scoreRef(as('adminB'), id)));        // سنتر تاني
    await assertFails(getDoc(scoreRef(as('parentA'), id)));       // ولي أمر
    await assertFails(getDoc(scoreRef(as('stranger'), id)));      // مش عضو
    await assertFails(getDoc(scoreRef(env.unauthenticatedContext().firestore(), id)));
  });

  it('get لمستند مش موجود بـ id غلط أو امتحان مش موجود مرفوض', async () => {
    await assertFails(getDoc(scoreRef(as('teacherA'), 'nounderscore')));
    await assertFails(getDoc(scoreRef(as('teacherA'), 'zzz_st1')));
    await assertFails(getDoc(scoreRef(as('teacherA'), 'e1_st1_extra')));
  });

  it('الـ transaction للمساعد، معلم مجموعة تانية، ومعطّل لسه بتفشل عند الكتابة', async () => {
    await assertFails(saveLikeApp(as('assistantA'), 'e1', 'st1', 50, 'assistantA'));
    await assertFails(saveLikeApp(as('teacherB'), 'e1', 'st1', 50, 'teacherB'));
    await assertFails(saveLikeApp(as('offTeacher'), 'e1', 'st1', 50, 'offTeacher'));
    await assertFails(saveLikeApp(as('assistantA'), 'e1', 'st4', 50, 'assistantA'));
  });

  it('قيود الكتابة زي ما هي: درجة أكبر من النهائية وطالب مش في المجموعة مرفوضين', async () => {
    await assertFails(saveLikeApp(as('teacherA'), 'e1', 'st1', 101, 'teacherA'));
    await assertFails(saveLikeApp(as('teacherA'), 'e1', 'st2', 50, 'teacherA'));
  });
});

describe('scores v7 — قراءة الطالب وولي الأمر لسه للمنشور بس', () => {
  it('ولي الأمر يقرا درجة موجودة لامتحان منشور بس', async () => {
    const id = scId('e1', 'st4');
    await assertFails(getDoc(scoreRef(as('parentA'), id)));       // e1 مش منشور
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `centers/${A}/exams/e1`), { published: true });
    });
    await assertSucceeds(getDoc(scoreRef(as('parentA'), id)));    // بعد النشر
  });

  it('ولي الأمر مش بيقرا درجة طالب مش مربوط بيه حتى لو منشور', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `centers/${A}/exams/e1`), { published: true });
      await setDoc(doc(ctx.firestore(), `centers/${A}/scores/${scId('e1', 'st3')}`),
        scoreData({ studentId: 'st3', score: 40, createdAt: Timestamp.now() }));
    });
    await assertFails(getDoc(scoreRef(as('parentA'), scId('e1', 'st3'))));
  });

  it('list ما اتغيّرش: ولي الأمر والغريب مرفوضين، والمعلم بفلتر examId ينجح', async () => {
    const q = (db, e) => query(collection(db, `centers/${A}/scores`), where('examId', '==', e));
    await assertSucceeds(getDocs(q(as('teacherA'), 'e1')));
    await assertFails(getDocs(q(as('teacherA'), 'e2')));
    await assertFails(getDocs(q(as('parentA'), 'e1')));
    await assertFails(getDocs(q(as('stranger'), 'e1')));
  });

  it('مفيش delete ولا تعديل من القارئ', async () => {
    await assertFails(deleteDoc(scoreRef(as('teacherA'), scId('e1', 'st4'))));
    await assertFails(updateDoc(scoreRef(as('parentA'), scId('e1', 'st4')), { score: 99 }));
  });
});
