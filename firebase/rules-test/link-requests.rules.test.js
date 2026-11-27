// [v9] اختبارات طلبات الربط: centers/{c}/linkRequests/{uid_studentNo}
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
  serverTimestamp,
} = require('firebase/firestore');

const A = 'centerA';

let env;
const as = (uid) => env.authenticatedContext(uid).firestore();

const request = (uid, over = {}) => ({
  centerId: A, uid, name: 'مستخدم', studentNo: 1, kind: 'student',
  status: 'pending', createdAt: serverTimestamp(), ...over,
});

const ref = (db, id) => doc(db, `centers/${A}/linkRequests/${id}`);

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
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `centers/${A}`), { name: 'مركز', year: 2026, createdBy: 'adminA', lateAfterMinutes: 15 });
    await setDoc(doc(db, `centers/${A}/members/adminA`), { role: 'admin', name: 'Admin', active: true, createdBy: 'adminA' });
  });
});

describe('linkRequests — الإنشاء', () => {
  it('طالب ينشئ طلب لنفسه', async () => {
    await assertSucceeds(setDoc(ref(as('u1'), 'u1_1'), request('u1')));
  });

  it('ولي أمر ينشئ طلب بصلة قرابة، ومن غيرها يترفض', async () => {
    const db = as('u1');
    await assertSucceeds(setDoc(ref(db, 'u1_1'), request('u1', { kind: 'guardian', relation: 'أب' })));
    await assertFails(setDoc(ref(db, 'u1_2'), request('u1', { kind: 'guardian', studentNo: 2 })));
  });

  it('مرفوض: طلب بإسم حد تاني، أو status مش pending، أو سنتر مش موجود', async () => {
    const db = as('u1');
    await assertFails(setDoc(ref(db, 'u2_1'), request('u2')));
    await assertFails(setDoc(ref(db, 'u1_1'), request('u1', { status: 'approved' })));
    await assertFails(setDoc(doc(db, 'centers/nope/linkRequests/u1_1'), request('u1', { centerId: 'nope' })));
  });
});

describe('linkRequests — القراءة والرد', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(ref(ctx.firestore(), 'u1_1'), request('u1', { createdAt: new Date() }));
    });
  });

  it('صاحب الطلب والأدمن يقروا، وغيرهم لأ', async () => {
    await assertSucceeds(getDoc(ref(as('u1'), 'u1_1')));
    await assertSucceeds(getDoc(ref(as('adminA'), 'u1_1')));
    await assertFails(getDoc(ref(as('u2'), 'u1_1')));
    const q = query(collection(as('adminA'), `centers/${A}/linkRequests`), where('status', '==', 'pending'));
    await assertSucceeds(getDocs(q));
  });

  it('الأدمن يوافق بكود أو يرفض، والطالب مايقدرش', async () => {
    await assertFails(updateDoc(ref(as('u1'), 'u1_1'), { status: 'approved', code: 'ABCD2345' }));
    await assertFails(updateDoc(ref(as('adminA'), 'u1_1'), { status: 'approved' }));
    await assertSucceeds(updateDoc(ref(as('adminA'), 'u1_1'), { status: 'approved', code: 'ABCD2345' }));
  });

  it('صاحب الطلب بس يمسحه', async () => {
    await assertFails(deleteDoc(ref(as('u2'), 'u1_1')));
    await assertSucceeds(deleteDoc(ref(as('u1'), 'u1_1')));
  });
});
