// اختبارات Rules قسم الهوية والسنتر.
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
  writeBatch, Timestamp, serverTimestamp,
} = require('firebase/firestore');

const A = 'centerA';
const B = 'centerB';

const DAY = 24 * 60 * 60 * 1000;
const future = (days) => Timestamp.fromMillis(Date.now() + days * DAY);
const past = (days) => Timestamp.fromMillis(Date.now() - days * DAY);

let env;

const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

const staffCode = (over = {}) => ({
  centerId: A, kind: 'staff', role: 'teacher', name: 'Sara',
  expiresAt: future(3), usedBy: null, createdBy: 'adminA', ...over,
});

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (p, data) => setDoc(doc(db, p), data);

    await put(`centers/${A}`, { name: 'مركز النور', year: 2026, createdBy: 'adminA', lateAfterMinutes: 15 });
    await put(`centers/${A}/members/adminA`, { role: 'admin', name: 'Admin A', active: true, createdBy: 'adminA' });
    await put(`centers/${A}/members/teacherA`, { role: 'teacher', name: 'Teacher A', active: true, createdBy: 'teacherA' });
    await put(`centers/${A}/members/assistantA`, { role: 'assistant', name: 'Assistant A', active: true, createdBy: 'assistantA' });
    await put(`centers/${A}/members/offA`, { role: 'assistant', name: 'Disabled A', active: false, createdBy: 'offA' });
    await put(`centers/${A}/students/s1`, { fullName: 'أحمد' });

    await put(`centers/${B}`, { name: 'مركز تاني', year: 2026, createdBy: 'adminB', lateAfterMinutes: 15 });
    await put(`centers/${B}/members/adminB`, { role: 'admin', name: 'Admin B', active: true, createdBy: 'adminB' });

    await put('inviteCodes/STAFFOK1', staffCode());
    await put('inviteCodes/ASSIST01', staffCode({ role: 'assistant' }));
    await put('inviteCodes/EXPIRED1', staffCode({ expiresAt: past(1) }));
    await put('inviteCodes/USED0001', staffCode({ usedBy: 'someoneElse' }));
    await put('inviteCodes/OTHERCTR', staffCode({ centerId: B, createdBy: 'adminB' }));
    await put('inviteCodes/STUD0001', {
      centerId: A, kind: 'student', studentId: 's1',
      expiresAt: future(3), usedBy: null, createdBy: 'adminA',
    });
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

// ---------------------------------------------------------------------
// users
// ---------------------------------------------------------------------
describe('users', () => {
  const userDoc = (uid, over = {}) => ({
    name: 'Ali', email: 'ali@example.com', phone: '01012345678',
    accountType: 'guardian', centerId: null, createdBy: uid, ...over,
  });

  it('صاحب الحساب ينشئ مستنده ويقراه', async () => {
    const db = as('u1');
    await assertSucceeds(setDoc(doc(db, 'users/u1'), userDoc('u1')));
    await assertSucceeds(getDoc(doc(db, 'users/u1')));
  });

  it('مينفعش ينشئ مستند لحد تاني', async () => {
    await assertFails(setDoc(doc(as('u1'), 'users/u2'), userDoc('u2')));
  });

  it('مينفعش يقرا مستند حد تاني', async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'users/u2'), userDoc('u2')));
    await assertFails(getDoc(doc(as('u1'), 'users/u2')));
  });

  it('list على users ممنوع', async () => {
    await assertFails(getDocs(collection(as('u1'), 'users')));
  });

  it('delete ممنوع', async () => {
    const db = as('u1');
    await setDoc(doc(db, 'users/u1'), userDoc('u1'));
    await assertFails(deleteDoc(doc(db, 'users/u1')));
  });

  it('حقل غريب مرفوض', async () => {
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), userDoc('u1', { isAdmin: true })));
  });

  it('مينفعش يبدأ بـ centerId جاهز', async () => {
    await assertFails(setDoc(doc(as('u1'), 'users/u1'), userDoc('u1', { centerId: A })));
  });

  it('تعديل centerId في users ما يدّيش أي صلاحية', async () => {
    const db = as('mallory');
    await setDoc(doc(db, 'users/mallory'), userDoc('mallory'));
    await assertSucceeds(updateDoc(doc(db, 'users/mallory'), { centerId: A }));
    await assertFails(getDoc(doc(db, `centers/${A}`)));
    await assertFails(getDocs(collection(db, `centers/${A}/members`)));
    await assertFails(updateDoc(doc(db, `centers/${A}`), { name: 'اتهكر' }));
  });
});

// ---------------------------------------------------------------------
// centers
// ---------------------------------------------------------------------
describe('centers — الإنشاء', () => {
  const createCenter = (db, uid, id = 'centerNew', over = {}) => {
    const b = writeBatch(db);
    b.set(doc(db, `centers/${id}`), {
      name: 'سنتر جديد', year: 2026, createdBy: uid, lateAfterMinutes: 15, ...over.center,
    });
    b.set(doc(db, `centers/${id}/members/${uid}`), {
      role: 'admin', name: 'Owner', active: true, createdBy: uid, ...over.member,
    });
    return b.commit();
  };

  it('Batch (سنتر + عضوية أدمن + users.centerId) ينجح', async () => {
    const db = as('owner');
    await setDoc(doc(db, 'users/owner'), {
      name: 'Owner', accountType: 'staff', centerId: null, createdBy: 'owner',
    });
    const b = writeBatch(db);
    b.set(doc(db, 'centers/centerNew'), { name: 'سنتر جديد', year: 2026, createdBy: 'owner', lateAfterMinutes: 15 });
    b.set(doc(db, 'centers/centerNew/members/owner'), { role: 'admin', name: 'Owner', active: true, createdBy: 'owner' });
    b.update(doc(db, 'users/owner'), { centerId: 'centerNew' });
    await assertSucceeds(b.commit());
    await assertSucceeds(getDoc(doc(db, 'centers/centerNew')));
  });

  it('سنتر من غير عضوية الأدمن مرفوض', async () => {
    await assertFails(setDoc(doc(as('owner'), 'centers/centerNew'), {
      name: 'x', year: 2026, createdBy: 'owner', lateAfterMinutes: 15,
    }));
  });

  it('createdBy لحد تاني مرفوض', async () => {
    await assertFails(createCenter(as('owner'), 'owner', 'centerNew', { center: { createdBy: 'adminA' } }));
  });

  it('عضوية بدور غير أدمن في السنتر الجديد مرفوضة', async () => {
    await assertFails(createCenter(as('owner'), 'owner', 'centerNew', { member: { role: 'teacher' } }));
  });

  it('أضيف نفسي أدمن في سنتر موجود (عضوية لوحدها) مرفوض', async () => {
    await assertFails(setDoc(doc(as('mallory'), `centers/${A}/members/mallory`), {
      role: 'admin', name: 'Mallory', active: true, createdBy: 'mallory',
    }));
  });

  it('أكتب فوق سنتر موجود وأحط نفسي أدمن مرفوض', async () => {
    const db = as('mallory');
    const b = writeBatch(db);
    b.set(doc(db, `centers/${A}`), { name: 'مسروق', year: 2026, createdBy: 'mallory', lateAfterMinutes: 15 });
    b.set(doc(db, `centers/${A}/members/mallory`), { role: 'admin', name: 'Mallory', active: true, createdBy: 'mallory' });
    await assertFails(b.commit());
  });

  it('lateAfterMinutes برا الحدود مرفوض', async () => {
    await assertFails(createCenter(as('owner'), 'owner', 'centerNew', { center: { lateAfterMinutes: 500 } }));
  });
});

describe('centers — القراءة والتعديل', () => {
  it('عضو نشط يقرا سنتره', async () => {
    await assertSucceeds(getDoc(doc(as('teacherA'), `centers/${A}`)));
  });

  it('أدمن سنتر تاني ميقراش ولا يكتب في سنتر A', async () => {
    const db = as('adminB');
    await assertFails(getDoc(doc(db, `centers/${A}`)));
    await assertFails(updateDoc(doc(db, `centers/${A}`), { name: 'x' }));
    await assertFails(getDocs(collection(db, `centers/${A}/members`)));
    await assertFails(setDoc(doc(db, `centers/${A}/members/adminB`), {
      role: 'admin', name: 'B', active: true, createdBy: 'adminB',
    }));
  });

  it('غير مسجل دخول مرفوض', async () => {
    await assertFails(getDoc(doc(anon(), `centers/${A}`)));
  });

  it('موظف معطّل مرفوض', async () => {
    await assertFails(getDoc(doc(as('offA'), `centers/${A}`)));
  });

  it('list على centers ممنوع', async () => {
    await assertFails(getDocs(collection(as('adminA'), 'centers')));
  });

  it('الأدمن يعدّل الإعدادات', async () => {
    await assertSucceeds(updateDoc(doc(as('adminA'), `centers/${A}`), { name: 'اسم جديد', lateAfterMinutes: 20 }));
  });

  it('المعلم مينفعش يعدّل', async () => {
    await assertFails(updateDoc(doc(as('teacherA'), `centers/${A}`), { name: 'x' }));
  });

  it('الأدمن مينفعش يغيّر createdBy', async () => {
    await assertFails(updateDoc(doc(as('adminA'), `centers/${A}`), { createdBy: 'teacherA' }));
  });

  it('lateAfterMinutes سالب مرفوض', async () => {
    await assertFails(updateDoc(doc(as('adminA'), `centers/${A}`), { lateAfterMinutes: -1 }));
  });

  it('delete ممنوع حتى للأدمن', async () => {
    await assertFails(deleteDoc(doc(as('adminA'), `centers/${A}`)));
  });
});

// ---------------------------------------------------------------------
// members
// ---------------------------------------------------------------------
describe('members', () => {
  it('عضو نشط يعمل list للأعضاء', async () => {
    await assertSucceeds(getDocs(collection(as('assistantA'), `centers/${A}/members`)));
  });

  it('موظف معطّل يقرا مستنده هو بس، ومميقراش القائمة', async () => {
    const db = as('offA');
    await assertSucceeds(getDoc(doc(db, `centers/${A}/members/offA`)));
    await assertFails(getDoc(doc(db, `centers/${A}/members/teacherA`)));
    await assertFails(getDocs(collection(db, `centers/${A}/members`)));
  });

  it('الأدمن يعطّل معلم ويغيّر دوره', async () => {
    const db = as('adminA');
    await assertSucceeds(updateDoc(doc(db, `centers/${A}/members/teacherA`), { active: false }));
    await assertSucceeds(updateDoc(doc(db, `centers/${A}/members/assistantA`), { role: 'teacher' }));
  });

  it('الأدمن مينفعش يرقّي حد لأدمن', async () => {
    await assertFails(updateDoc(doc(as('adminA'), `centers/${A}/members/teacherA`), { role: 'admin' }));
  });

  it('الأدمن مينفعش يعدّل نفسه', async () => {
    await assertFails(updateDoc(doc(as('adminA'), `centers/${A}/members/adminA`), { active: false }));
    await assertFails(updateDoc(doc(as('adminA'), `centers/${A}/members/adminA`), { role: 'teacher' }));
  });

  it('المعلم مينفعش يعدّل عضو (ولا نفسه)', async () => {
    const db = as('teacherA');
    await assertFails(updateDoc(doc(db, `centers/${A}/members/assistantA`), { active: false }));
    await assertFails(updateDoc(doc(db, `centers/${A}/members/teacherA`), { role: 'admin' }));
  });

  it('الموظف المعطّل مينفعش يفعّل نفسه', async () => {
    await assertFails(updateDoc(doc(as('offA'), `centers/${A}/members/offA`), { active: true }));
  });

  it('أدمن سنتر تاني مينفعش يعطّل موظف سنتر A', async () => {
    await assertFails(updateDoc(doc(as('adminB'), `centers/${A}/members/teacherA`), { active: false }));
  });

  it('delete ممنوع', async () => {
    await assertFails(deleteDoc(doc(as('adminA'), `centers/${A}/members/teacherA`)));
  });
});

// ---------------------------------------------------------------------
// inviteCodes — الإنشاء والقراءة والإلغاء
// ---------------------------------------------------------------------
describe('inviteCodes — إنشاء وقراءة', () => {
  const create = (uid, id, data) => setDoc(doc(as(uid), `inviteCodes/${id}`), data);

  it('الأدمن ينشئ كود موظف (معلم / مساعد)', async () => {
    await assertSucceeds(create('adminA', 'NEWT0001', staffCode()));
    await assertSucceeds(create('adminA', 'NEWA0001', staffCode({ role: 'assistant' })));
  });

  it('مفيش كود بدور أدمن', async () => {
    await assertFails(create('adminA', 'ADMN0001', staffCode({ role: 'admin' })));
  });

  it('المعلم مينفعش ينشئ كود', async () => {
    await assertFails(create('teacherA', 'T0000001', staffCode({ createdBy: 'teacherA' })));
  });

  it('أدمن سنتر B مينفعش ينشئ كود لسنتر A', async () => {
    await assertFails(create('adminB', 'X0000001', staffCode({ createdBy: 'adminB' })));
  });

  it('createdBy لازم يبقى المنشئ', async () => {
    await assertFails(create('adminA', 'X0000002', staffCode({ createdBy: 'teacherA' })));
  });

  it('صلاحية أكتر من حد السماح (9 أيام) مرفوضة', async () => {
    await assertFails(create('adminA', 'LONG0001', staffCode({ expiresAt: future(9) })));
  });

  it('تاريخ انتهاء في الماضي مرفوض', async () => {
    await assertFails(create('adminA', 'OLD00001', staffCode({ expiresAt: past(1) })));
  });

  it('كود جاي مستخدم من الأول مرفوض', async () => {
    await assertFails(create('adminA', 'PRE00001', staffCode({ usedBy: 'someone' })));
  });

  it('كود طالب بطالب موجود ينجح، وبطالب مش موجود يفشل', async () => {
    const base = { centerId: A, kind: 'student', expiresAt: future(3), usedBy: null, createdBy: 'adminA' };
    await assertSucceeds(create('adminA', 'ST000001', { ...base, studentId: 's1' }));
    await assertFails(create('adminA', 'ST000002', { ...base, studentId: 'ghost' }));
  });

  it('كود ولي أمر محتاج صلة قرابة', async () => {
    const base = { centerId: A, kind: 'guardian', studentId: 's1', expiresAt: future(3), usedBy: null, createdBy: 'adminA' };
    await assertSucceeds(create('adminA', 'GD000001', { ...base, relation: 'father' }));
    await assertFails(create('adminA', 'GD000002', base));
  });

  it('get بالكود ينجح لمسجّل الدخول، وlist وغير المسجّل ممنوعين', async () => {
    await assertSucceeds(getDoc(doc(as('anyone'), 'inviteCodes/STAFFOK1')));
    await assertFails(getDocs(collection(as('adminA'), 'inviteCodes')));
    await assertFails(getDoc(doc(anon(), 'inviteCodes/STAFFOK1')));
  });

  it('delete ممنوع', async () => {
    await assertFails(deleteDoc(doc(as('adminA'), 'inviteCodes/STAFFOK1')));
  });

  it('الأدمن يلغي كود لسه ما اتستخدمش', async () => {
    await assertSucceeds(updateDoc(doc(as('adminA'), 'inviteCodes/STAFFOK1'), { expiresAt: serverTimestamp() }));
  });

  it('المعلم أو أدمن سنتر تاني مينفعش يلغي، والكود المستخدم مينفعش يتلغى', async () => {
    await assertFails(updateDoc(doc(as('teacherA'), 'inviteCodes/STAFFOK1'), { expiresAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(as('adminB'), 'inviteCodes/STAFFOK1'), { expiresAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(as('adminA'), 'inviteCodes/USED0001'), { expiresAt: serverTimestamp() }));
  });
});

// ---------------------------------------------------------------------
// inviteCodes — قبول كود الموظف (Batch ذري: usedBy + العضوية)
// ---------------------------------------------------------------------
describe('قبول كود الموظف', () => {
  const accept = (uid, { code, center = A, role = 'teacher', memberUid = uid, usedBy = uid } = {}) => {
    const db = as(uid);
    const b = writeBatch(db);
    b.update(doc(db, `inviteCodes/${code}`), { usedBy });
    b.set(doc(db, `centers/${center}/members/${memberUid}`), {
      role, name: 'New Staff', active: true, createdBy: memberUid, inviteCode: code,
    });
    return b.commit();
  };

  it('كود صالح: الموظف يبقى عضو بالدور ده ويقرا السنتر', async () => {
    await assertSucceeds(accept('newT', { code: 'STAFFOK1' }));
    await assertSucceeds(getDoc(doc(as('newT'), `centers/${A}`)));
  });

  it('كود المساعد بيدّي مساعد', async () => {
    await assertSucceeds(accept('newA', { code: 'ASSIST01', role: 'assistant' }));
  });

  it('الكود يتستخدم مرة واحدة بس', async () => {
    await assertSucceeds(accept('first', { code: 'STAFFOK1' }));
    await assertFails(accept('second', { code: 'STAFFOK1' }));
  });

  it('كود منتهي مرفوض', async () => {
    await assertFails(accept('newT', { code: 'EXPIRED1' }));
  });

  it('كود مستخدم مرفوض', async () => {
    await assertFails(accept('newT', { code: 'USED0001' }));
  });

  it('كود من سنتر تاني مرفوض في سنتر A، وينجح في سنتره (للتأكد إن الرفض مش بسبب حاجة تانية)', async () => {
    await assertFails(accept('newT', { code: 'OTHERCTR', center: A }));
    await assertSucceeds(accept('newT2', { code: 'OTHERCTR', center: B }));
  });

  it('كود غير موجود مرفوض', async () => {
    await assertFails(accept('newT', { code: 'GHOST000' }));
  });

  it('دور مختلف عن دور الكود مرفوض (ومفيش ترقية لأدمن)', async () => {
    await assertFails(accept('newT', { code: 'STAFFOK1', role: 'assistant' }));
    await assertFails(accept('newT', { code: 'STAFFOK1', role: 'admin' }));
  });

  it('تعليم الكود مستخدم من غير عضوية مرفوض', async () => {
    await assertFails(updateDoc(doc(as('newT'), 'inviteCodes/STAFFOK1'), { usedBy: 'newT' }));
  });

  it('عضوية من غير تعليم الكود مرفوضة', async () => {
    await assertFails(setDoc(doc(as('newT'), `centers/${A}/members/newT`), {
      role: 'teacher', name: 'New', active: true, createdBy: 'newT', inviteCode: 'STAFFOK1',
    }));
  });

  it('مينفعش أكتب عضوية باسم uid تاني', async () => {
    await assertFails(accept('mallory', { code: 'STAFFOK1', memberUid: 'victim', usedBy: 'victim' }));
  });

  it('مينفعش أحط usedBy باسم حد تاني', async () => {
    await assertFails(accept('mallory', { code: 'STAFFOK1', usedBy: 'victim' }));
  });

  it('موظف معطّل مينفعش يرجّع نفسه بكود جديد', async () => {
    await assertFails(accept('offA', { code: 'ASSIST01', role: 'assistant' }));
  });

  it('كود الطالب مش بيتقبل كموظف', async () => {
    await assertFails(accept('newT', { code: 'STUD0001' }));
  });
});

// ---------------------------------------------------------------------
// TODO(C — خطوة 3.2)
// ---------------------------------------------------------------------
describe('أكواد الطالب / ولي الأمر', () => {
  it('الاستهلاك ممنوع لحد ما تتكتب rules الربط (studentLinks)', async () => {
    await assertFails(updateDoc(doc(as('guardian1'), 'inviteCodes/STUD0001'), { usedBy: 'guardian1' }));
  });
});
