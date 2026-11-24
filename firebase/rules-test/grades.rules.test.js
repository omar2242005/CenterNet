// اختبارات Rules الامتحانات والدرجات (الشخص 4).
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

describe('exams — الإنشاء', () => {
  it('الأدمن ومعلم المجموعة ينشئوا امتحان', async () => {
    await assertSucceeds(setDoc(examRef(as('adminA'), 'e3'), examData({ createdBy: 'adminA' })));
    await assertSucceeds(setDoc(examRef(as('teacherA'), 'e4'), examData()));
  });

  it('مساعد، معلم مجموعة تانية، معطّل، وأدمن سنتر تاني مرفوضين', async () => {
    await assertFails(setDoc(examRef(as('assistantA'), 'e3'), examData({ createdBy: 'assistantA' })));
    await assertFails(setDoc(examRef(as('teacherB'), 'e3'), examData({ createdBy: 'teacherB' })));
    await assertFails(setDoc(examRef(as('offTeacher'), 'e3'), examData({ createdBy: 'offTeacher' })));
    await assertFails(setDoc(examRef(as('adminB'), 'e3'), examData({ createdBy: 'adminB' })));
  });

  it('منشور من البداية مرفوض', async () => {
    await assertFails(setDoc(examRef(as('teacherA'), 'e3'), examData({ published: true })));
  });

  it('درجة نهائية صفر أو سالبة أو نص مرفوضة', async () => {
    await assertFails(setDoc(examRef(as('teacherA'), 'e3'), examData({ maxScore: 0 })));
    await assertFails(setDoc(examRef(as('teacherA'), 'e3'), examData({ maxScore: -5 })));
    await assertFails(setDoc(examRef(as('teacherA'), 'e3'), examData({ maxScore: '100' })));
  });

  it('عنوان فاضي أو طويل مرفوض', async () => {
    await assertFails(setDoc(examRef(as('teacherA'), 'e3'), examData({ title: '' })));
    await assertFails(setDoc(examRef(as('teacherA'), 'e3'), examData({ title: 'x'.repeat(121) })));
  });

  it('مجموعة مش موجودة، centerId مختلف، حقل غريب، أو createdBy لحد تاني مرفوضين', async () => {
    await assertFails(setDoc(examRef(as('adminA'), 'e3'), examData({ groupId: 'gX', createdBy: 'adminA' })));
    await assertFails(setDoc(examRef(as('teacherA'), 'e3'), examData({ centerId: B })));
    await assertFails(setDoc(examRef(as('teacherA'), 'e3'), examData({ extra: 1 })));
    await assertFails(setDoc(examRef(as('teacherA'), 'e3'), examData({ createdBy: 'adminA' })));
  });
});

describe('exams — النشر', () => {
  it('معلم المجموعة والأدمن ينشروا ويلغوا النشر', async () => {
    await assertSucceeds(updateDoc(examRef(as('teacherA'), 'e1'), { published: true }));
    await assertSucceeds(updateDoc(examRef(as('teacherA'), 'e1'), { published: false }));
    await assertSucceeds(updateDoc(examRef(as('adminA'), 'e1'), { published: true }));
  });

  it('مساعد ومعلم مجموعة تانية مرفوضين', async () => {
    await assertFails(updateDoc(examRef(as('assistantA'), 'e1'), { published: true }));
    await assertFails(updateDoc(examRef(as('teacherB'), 'e1'), { published: true }));
  });

  it('تعديل أي حقل غير published مرفوض، والحذف ممنوع', async () => {
    await assertFails(updateDoc(examRef(as('teacherA'), 'e1'), { title: 'جديد' }));
    await assertFails(updateDoc(examRef(as('teacherA'), 'e1'), { published: true, maxScore: 10 }));
    await assertFails(updateDoc(examRef(as('teacherA'), 'e1'), { groupId: 'g2' }));
    await assertFails(deleteDoc(examRef(as('adminA'), 'e1')));
    await assertFails(deleteDoc(examRef(as('teacherA'), 'e1')));
  });
});

describe('exams — القراءة', () => {
  it('المعلم والمساعد يقروا امتحانات مجموعتهم بس', async () => {
    await assertSucceeds(getDoc(examRef(as('teacherA'), 'e1')));
    await assertSucceeds(getDoc(examRef(as('assistantA'), 'e1')));
    await assertFails(getDoc(examRef(as('teacherA'), 'e2')));
    await assertFails(getDoc(examRef(as('assistantA'), 'e2')));
  });

  it('الأدمن يقرا الكل، ومعطّل أو سنتر تاني أو غير مسجل لأ', async () => {
    await assertSucceeds(getDoc(examRef(as('adminA'), 'e2')));
    await assertFails(getDoc(examRef(as('offTeacher'), 'e1')));
    await assertFails(getDoc(examRef(as('adminB'), 'e1')));
    await assertFails(getDoc(examRef(env.unauthenticatedContext().firestore(), 'e1')));
  });

  it('list بفلتر groupId: مجموعتي تنجح وحد تاني لأ', async () => {
    const q = (db, g) => query(collection(db, `centers/${A}/exams`), where('groupId', '==', g));
    await assertSucceeds(getDocs(q(as('teacherA'), 'g1')));
    await assertSucceeds(getDocs(q(as('assistantA'), 'g1')));
    await assertFails(getDocs(q(as('teacherA'), 'g2')));
    await assertSucceeds(getDocs(collection(as('adminA'), `centers/${A}/exams`)));
  });
});

describe('scores — الرصد', () => {
  it('معلم المجموعة والأدمن يرصدوا درجة', async () => {
    await assertSucceeds(setDoc(scoreRef(as('teacherA'), scId('e1', 'st1')), scoreData()));
    await assertSucceeds(setDoc(scoreRef(as('adminA'), scId('e1', 'st3')),
      scoreData({ studentId: 'st3', createdBy: 'adminA' })));
  });

  it('الصفر والدرجة النهائية والغائب والمعفى مقبولين', async () => {
    await assertSucceeds(setDoc(scoreRef(as('teacherA'), scId('e1', 'st1')), scoreData({ score: 0 })));
    await assertSucceeds(setDoc(scoreRef(as('teacherA'), scId('e1', 'st3')),
      scoreData({ studentId: 'st3', score: 100 })));
    await env.clearFirestore(); await seed();
    await assertSucceeds(setDoc(scoreRef(as('teacherA'), scId('e1', 'st1')), scoreData({ state: 'absent', score: null })));
    await assertSucceeds(setDoc(scoreRef(as('teacherA'), scId('e1', 'st3')),
      scoreData({ studentId: 'st3', state: 'excused', score: null })));
  });

  it('مساعد ومعلم مجموعة تانية مرفوضين', async () => {
    await assertFails(setDoc(scoreRef(as('assistantA'), scId('e1', 'st1')), scoreData({ createdBy: 'assistantA' })));
    await assertFails(setDoc(scoreRef(as('teacherB'), scId('e1', 'st1')), scoreData({ createdBy: 'teacherB' })));
  });

  it('درجة أكبر من النهائية أو سالبة أو مش بخطوة 0.5 مرفوضة', async () => {
    await assertFails(setDoc(scoreRef(as('teacherA'), scId('e1', 'st1')), scoreData({ score: 101 })));
    await assertFails(setDoc(scoreRef(as('teacherA'), scId('e1', 'st1')), scoreData({ score: -1 })));
    await assertFails(setDoc(scoreRef(as('teacherA'), scId('e1', 'st1')), scoreData({ score: 85.3 })));
  });

  it('scored من غير درجة، وغائب أو معفى معاه درجة مرفوضين', async () => {
    await assertFails(setDoc(scoreRef(as('teacherA'), scId('e1', 'st1')), scoreData({ score: null })));
    await assertFails(setDoc(scoreRef(as('teacherA'), scId('e1', 'st1')), scoreData({ state: 'absent', score: 5 })));
    await assertFails(setDoc(scoreRef(as('teacherA'), scId('e1', 'st1')), scoreData({ state: 'excused', score: 0 })));
  });

  it('طالب من مجموعة تانية، طالب أو امتحان مش موجود مرفوضين', async () => {
    await assertFails(setDoc(scoreRef(as('teacherA'), scId('e1', 'st2')), scoreData({ studentId: 'st2' })));
    await assertFails(setDoc(scoreRef(as('adminA'), scId('e1', 'ghost')),
      scoreData({ studentId: 'ghost', createdBy: 'adminA' })));
    await assertFails(setDoc(scoreRef(as('adminA'), scId('eX', 'st1')),
      scoreData({ examId: 'eX', createdBy: 'adminA' })));
  });

  it('id غلط، تعليق طويل، حقل غريب، وcreatedBy لحد تاني مرفوضين', async () => {
    await assertFails(setDoc(scoreRef(as('teacherA'), 'whatever'), scoreData()));
    await assertFails(setDoc(scoreRef(as('teacherA'), scId('e1', 'st1')), scoreData({ comment: 'x'.repeat(301) })));
    await assertFails(setDoc(scoreRef(as('teacherA'), scId('e1', 'st1')), scoreData({ extra: 1 })));
    await assertFails(setDoc(scoreRef(as('teacherA'), scId('e1', 'st1')), scoreData({ createdBy: 'adminA' })));
  });

  it('set كامل فوق درجة موجودة مرفوض (لازم update)', async () => {
    await assertFails(setDoc(scoreRef(as('teacherA'), scId('e1', 'st4')), scoreData({ studentId: 'st4', score: 70 })));
  });
});

describe('scores — التعديل', () => {
  const id4 = scId('e1', 'st4');

  it('معلم المجموعة والأدمن يعدّلوا الدرجة والحالة والتعليق', async () => {
    await assertSucceeds(updateDoc(scoreRef(as('teacherA'), id4), { score: 60, comment: 'ممتاز' }));
    await assertSucceeds(updateDoc(scoreRef(as('adminA'), id4), { state: 'absent', score: null }));
  });

  it('درجة بره النطاق أو حالة غلط مرفوضة', async () => {
    await assertFails(updateDoc(scoreRef(as('teacherA'), id4), { score: 101 }));
    await assertFails(updateDoc(scoreRef(as('teacherA'), id4), { score: 50.2 }));
    await assertFails(updateDoc(scoreRef(as('teacherA'), id4), { state: 'absent' }));
    await assertFails(updateDoc(scoreRef(as('teacherA'), id4), { state: 'weird' }));
  });

  it('تغيير الطالب أو الامتحان أو المنشئ مرفوض', async () => {
    await assertFails(updateDoc(scoreRef(as('teacherA'), id4), { studentId: 'st1' }));
    await assertFails(updateDoc(scoreRef(as('teacherA'), id4), { examId: 'e2' }));
    await assertFails(updateDoc(scoreRef(as('teacherA'), id4), { createdBy: 'adminA' }));
  });

  it('مساعد ومعلم مجموعة تانية مرفوضين، والحذف ممنوع', async () => {
    await assertFails(updateDoc(scoreRef(as('assistantA'), id4), { score: 60 }));
    await assertFails(updateDoc(scoreRef(as('teacherB'), id4), { score: 60 }));
    await assertFails(deleteDoc(scoreRef(as('adminA'), id4)));
    await assertFails(deleteDoc(scoreRef(as('teacherA'), id4)));
  });
});

describe('scores — القراءة', () => {
  const id4 = scId('e1', 'st4');

  it('معلم ومساعد المجموعة يقروا، ومعلم مجموعة تانية لأ', async () => {
    await assertSucceeds(getDoc(scoreRef(as('teacherA'), id4)));
    await assertSucceeds(getDoc(scoreRef(as('assistantA'), id4)));
    await assertFails(getDoc(scoreRef(as('teacherB'), id4)));
  });

  it('الأدمن يقرا، ومعطّل أو سنتر تاني أو غير مسجل لأ', async () => {
    await assertSucceeds(getDoc(scoreRef(as('adminA'), id4)));
    await assertFails(getDoc(scoreRef(as('offTeacher'), id4)));
    await assertFails(getDoc(scoreRef(as('adminB'), id4)));
    await assertFails(getDoc(scoreRef(env.unauthenticatedContext().firestore(), id4)));
  });

  it('list بفلتر examId: امتحان مجموعتي تنجح وحد تاني لأ', async () => {
    const q = (db, e) => query(collection(db, `centers/${A}/scores`), where('examId', '==', e));
    await assertSucceeds(getDocs(q(as('teacherA'), 'e1')));
    await assertSucceeds(getDocs(q(as('assistantA'), 'e1')));
    await assertFails(getDocs(q(as('teacherA'), 'e2')));
    await assertSucceeds(getDocs(collection(as('adminA'), `centers/${A}/scores`)));
  });
});