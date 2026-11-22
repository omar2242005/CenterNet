// اختبارات Rules قسم الطلاب (خطوة 3.1).
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
  writeBatch, serverTimestamp,
} = require('firebase/firestore');

const A = 'centerA';
const B = 'centerB';

let env;
const as = (uid) => env.authenticatedContext(uid).firestore();

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (p, data) => setDoc(doc(db, p), data);
    await put(`centers/${A}`, { name: 'مركز النور', year: 2026, createdBy: 'adminA', lateAfterMinutes: 15 });
    await put(`centers/${A}/members/adminA`, { role: 'admin', name: 'Admin A', active: true, createdBy: 'adminA' });
    await put(`centers/${A}/members/teacherA`, { role: 'teacher', name: 'Teacher A', active: true, createdBy: 'teacherA' });
    await put(`centers/${A}/members/assistantA`, { role: 'assistant', name: 'Assistant A', active: true, createdBy: 'assistantA' });
    await put(`centers/${B}`, { name: 'مركز تاني', year: 2026, createdBy: 'adminB', lateAfterMinutes: 15 });
    await put(`centers/${B}/members/adminB`, { role: 'admin', name: 'Admin B', active: true, createdBy: 'adminB' });
  });
}

const studentData = (no, over = {}) => ({
  centerId: A, studentNo: no, fullName: 'أحمد علي', searchKey: 'احمد علي',
  phone: '01012345678', grade: 'الصف الأول', groupIds: [], status: 'active',
  createdAt: serverTimestamp(), createdBy: 'adminA', ...over,
});

/** نفس اللي الـ Repository بيعمله: الطالب + العدّاد في Batch واحد. */
function addStudent(db, id, no, { student = {}, counter } = {}) {
  const b = writeBatch(db);
  b.set(doc(db, `centers/${A}/students/${id}`), studentData(no, student));
  b.set(doc(db, `centers/${A}/counters/students`), counter ?? { next: no + 1 });
  return b.commit();
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

describe('students — الإنشاء', () => {
  it('الأدمن يضيف أول طالب برقم 1 والعدّاد يبقى 2', async () => {
    const db = as('adminA');
    await assertSucceeds(addStudent(db, 's1', 1));
    const counter = await getDoc(doc(db, `centers/${A}/counters/students`));
    if (counter.data().next !== 2) throw new Error('العدّاد لازم يبقى 2');
  });

  it('الطالب التاني برقم 2 والعدّاد يبقى 3', async () => {
    const db = as('adminA');
    await assertSucceeds(addStudent(db, 's1', 1));
    await assertSucceeds(addStudent(db, 's2', 2));
  });

  it('رقم مكرر مرفوض', async () => {
    const db = as('adminA');
    await assertSucceeds(addStudent(db, 's1', 1));
    await assertFails(addStudent(db, 's2', 1, { counter: { next: 2 } }));
  });

  it('رقم بيقفز مرفوض', async () => {
    await assertFails(addStudent(as('adminA'), 's1', 5));
  });

  it('طالب من غير تحديث العدّاد مرفوض', async () => {
    await assertFails(setDoc(doc(as('adminA'), `centers/${A}/students/s1`), studentData(1)));
  });

  it('العدّاد مينفعش يزيد أكتر من 1', async () => {
    await assertFails(addStudent(as('adminA'), 's1', 1, { counter: { next: 9 } }));
  });

  it('المعلم والمساعد ما يضيفوش طلاب', async () => {
    await assertFails(addStudent(as('teacherA'), 's1', 1));
    await assertFails(addStudent(as('assistantA'), 's1', 1));
  });

  it('أدمن سنتر تاني ما يضيفش في سنتر A', async () => {
    await assertFails(addStudent(as('adminB'), 's1', 1));
  });

  it('مستخدم من غير عضوية مرفوض', async () => {
    await assertFails(addStudent(as('stranger'), 's1', 1));
  });

  it('createdBy غير uid مرفوض', async () => {
    await assertFails(addStudent(as('adminA'), 's1', 1, { student: { createdBy: 'someoneElse' } }));
  });

  it('طالب بحالة archived من البداية مرفوض', async () => {
    await assertFails(addStudent(as('adminA'), 's1', 1, { student: { status: 'archived' } }));
  });

  it('حقل غريب مرفوض', async () => {
    await assertFails(addStudent(as('adminA'), 's1', 1, { student: { isPaid: true } }));
  });

  it('centerId مختلف عن المسار مرفوض', async () => {
    await assertFails(addStudent(as('adminA'), 's1', 1, { student: { centerId: B } }));
  });

  it('اسم فاضي مرفوض', async () => {
    await assertFails(addStudent(as('adminA'), 's1', 1, { student: { fullName: '' } }));
  });
});

describe('students — القراءة', () => {
  beforeEach(async () => {
    await addStudent(as('adminA'), 's1', 1);
  });

  it('الأدمن يقرا ويعمل list', async () => {
    const db = as('adminA');
    await assertSucceeds(getDoc(doc(db, `centers/${A}/students/s1`)));
    await assertSucceeds(getDocs(collection(db, `centers/${A}/students`)));
  });

  it('أدمن سنتر تاني ما يقراش', async () => {
    const db = as('adminB');
    await assertFails(getDoc(doc(db, `centers/${A}/students/s1`)));
    await assertFails(getDocs(collection(db, `centers/${A}/students`)));
  });

  it('المعلم والمساعد النشطين يقروا، والمعطّل وسنتر تاني لا', async () => {
    await assertSucceeds(getDoc(doc(as('teacherA'), `centers/${A}/students/s1`)));
    await assertSucceeds(getDoc(doc(as('assistantA'), `centers/${A}/students/s1`)));
    await assertFails(getDoc(doc(as('adminB'), `centers/${A}/students/s1`)));
  });
});

describe('students — التعديل والأرشفة', () => {
  beforeEach(async () => {
    await addStudent(as('adminA'), 's1', 1);
  });

  const ref = (db) => doc(db, `centers/${A}/students/s1`);

  it('الأدمن يعدّل البيانات', async () => {
    await assertSucceeds(updateDoc(ref(as('adminA')), {
      fullName: 'أحمد محمد', searchKey: 'احمد محمد', phone: '01112345678', grade: 'الصف الثاني',
    }));
  });

  it('الأدمن يأرشف ويسترجع', async () => {
    const db = as('adminA');
    await assertSucceeds(updateDoc(ref(db), { status: 'archived' }));
    await assertSucceeds(updateDoc(ref(db), { status: 'active' }));
  });

  it('حالة غير معروفة مرفوضة', async () => {
    await assertFails(updateDoc(ref(as('adminA')), { status: 'deleted' }));
  });

  it('الرقم التسلسلي ما يتغيّرش', async () => {
    await assertFails(updateDoc(ref(as('adminA')), { studentNo: 99 }));
  });

  it('centerId و createdBy ما يتغيّروش', async () => {
    const db = as('adminA');
    await assertFails(updateDoc(ref(db), { centerId: B }));
    await assertFails(updateDoc(ref(db), { createdBy: 'x' }));
  });

  it('المعلم والمساعد ما يعدّلوش', async () => {
    await assertFails(updateDoc(ref(as('teacherA')), { grade: 'x' }));
    await assertFails(updateDoc(ref(as('assistantA')), { status: 'archived' }));
  });

  it('أدمن سنتر تاني ما يعدّلش', async () => {
    await assertFails(updateDoc(ref(as('adminB')), { grade: 'x' }));
  });

  it('delete ممنوع حتى على الأدمن', async () => {
    await assertFails(deleteDoc(ref(as('adminA'))));
  });
});

describe('counters', () => {
  it('delete ممنوع', async () => {
    const db = as('adminA');
    await addStudent(db, 's1', 1);
    await assertFails(deleteDoc(doc(db, `centers/${A}/counters/students`)));
  });

  it('مفيش كتابة مباشرة من غير الأدمن', async () => {
    await assertFails(setDoc(doc(as('teacherA'), `centers/${A}/counters/students`), { next: 2 }));
  });
});
