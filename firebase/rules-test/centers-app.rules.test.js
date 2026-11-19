// يختبر الـ Batch بنفس الشكل اللي التطبيق بيبعته (CentersRepository):
// إنشاء سنتر = centers/{id} + members/{uid} (admin) + users/{uid}.centerId، وتعديل الإعدادات.
// الفرق عن identity.rules.test.js: هنا createdAt و updatedAt بـ serverTimestamp زي التطبيق بالظبط.
// projectId مختلف عشان الملفين يشتغلوا مع بعض في node --test من غير ما clearFirestore يتخانقوا.

const { describe, it, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, setDoc, updateDoc, writeBatch, serverTimestamp,
} = require('firebase/firestore');

let env;
const as = (uid) => env.authenticatedContext(uid).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-centernet-centers-app',
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
});

// مستند المستخدم زي ما AuthRepository.register بيكتبه (من غير centerId).
const registerUser = (db, uid, name = 'أحمد') =>
  setDoc(doc(db, `users/${uid}`), {
    name, email: `${uid}@x.com`, phone: '01012345678',
    accountType: 'admin', createdAt: serverTimestamp(), createdBy: uid,
  });

// نفس الـ Batch في CentersRepository.createCenter.
const appCreateCenter = (db, uid, centerId, over = {}) => {
  const b = writeBatch(db);
  b.set(doc(db, `centers/${centerId}`), {
    name: 'مركز النور', year: 2026, createdBy: uid,
    createdAt: serverTimestamp(), lateAfterMinutes: 15, ...over.center,
  });
  b.set(doc(db, `centers/${centerId}/members/${uid}`), {
    role: 'admin', name: 'أحمد', active: true,
    createdAt: serverTimestamp(), createdBy: uid, ...over.member,
  });
  b.update(doc(db, `users/${uid}`), {
    centerId, updatedAt: serverTimestamp(), ...over.user,
  });
  return b.commit();
};

describe('إنشاء سنتر بنفس شكل الـ Batch في التطبيق', () => {
  it('ينجح، والأدمن يقرا سنتره وعضويته', async () => {
    const db = as('owner');
    await registerUser(db, 'owner');
    await assertSucceeds(appCreateCenter(db, 'owner', 'cNew1'));
    await assertSucceeds(getDoc(doc(db, 'centers/cNew1')));
    await assertSucceeds(getDoc(doc(db, 'centers/cNew1/members/owner')));
    await assertSucceeds(getDoc(doc(db, 'users/owner')));
  });

  it('مرفوض لو الـ Batch من غير عضوية الأدمن', async () => {
    const db = as('owner');
    await registerUser(db, 'owner');
    const b = writeBatch(db);
    b.set(doc(db, 'centers/cNew2'), {
      name: 'س', year: 2026, createdBy: 'owner',
      createdAt: serverTimestamp(), lateAfterMinutes: 15,
    });
    b.update(doc(db, 'users/owner'), { centerId: 'cNew2', updatedAt: serverTimestamp() });
    await assertFails(b.commit());
  });

  it('مرفوض لو ضفنا حقل غريب في السنتر', async () => {
    const db = as('owner');
    await registerUser(db, 'owner');
    await assertFails(appCreateCenter(db, 'owner', 'cNew3', { center: { isFree: true } }));
  });

  it('مرفوض لو العضوية بدور تاني غير admin', async () => {
    const db = as('owner');
    await registerUser(db, 'owner');
    await assertFails(appCreateCenter(db, 'owner', 'cNew4', { member: { role: 'teacher' } }));
  });

  it('مرفوض لو بنكتب فوق سنتر موجود لشخص تاني', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'centers/taken'), {
        name: 'مركز حد تاني', year: 2026, createdBy: 'other', lateAfterMinutes: 15,
      });
    });
    const db = as('owner');
    await registerUser(db, 'owner');
    await assertFails(appCreateCenter(db, 'owner', 'taken'));
  });
});

describe('إعدادات السنتر بنفس شكل التعديل في التطبيق', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'centers/cA'), {
        name: 'مركز النور', year: 2026, createdBy: 'adminA', lateAfterMinutes: 15,
      });
      await setDoc(doc(db, 'centers/cA/members/adminA'), {
        role: 'admin', name: 'أدمن', active: true, createdBy: 'adminA',
      });
      await setDoc(doc(db, 'centers/cA/members/teacherA'), {
        role: 'teacher', name: 'معلم', active: true, createdBy: 'teacherA',
      });
      await setDoc(doc(db, 'centers/cB'), {
        name: 'مركز تاني', year: 2026, createdBy: 'adminB', lateAfterMinutes: 15,
      });
      await setDoc(doc(db, 'centers/cB/members/adminB'), {
        role: 'admin', name: 'أدمن ب', active: true, createdBy: 'adminB',
      });
    });
  });

  const settings = { name: 'مركز الأمل', year: 2027, lateAfterMinutes: 30 };

  it('الأدمن يعدّل الاسم والسنة ومدة التأخير', async () => {
    await assertSucceeds(updateDoc(doc(as('adminA'), 'centers/cA'), settings));
  });

  it('المعلم مينفعش يعدّل', async () => {
    await assertFails(updateDoc(doc(as('teacherA'), 'centers/cA'), settings));
  });

  it('أدمن سنتر تاني مينفعش يعدّل سنتر A', async () => {
    await assertFails(updateDoc(doc(as('adminB'), 'centers/cA'), settings));
  });

  it('مدة تأخير 181 مرفوضة', async () => {
    await assertFails(updateDoc(doc(as('adminA'), 'centers/cA'), { ...settings, lateAfterMinutes: 181 }));
  });

  it('مينفعش الأدمن يغيّر createdBy ضمن التعديل', async () => {
    await assertFails(updateDoc(doc(as('adminA'), 'centers/cA'), { ...settings, createdBy: 'adminB' }));
  });
});
