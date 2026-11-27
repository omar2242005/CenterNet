// اختبارات Rules المدفوعات (P1): الأدمن بس يكتب، المساعد يقرا لعلامة المسح.
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
  Timestamp, serverTimestamp,
} = require('firebase/firestore');

const A = 'centerA';
const B = 'centerB';

let env;
const as = (uid) => env.authenticatedContext(uid).firestore();
const asAnon = () => env.unauthenticatedContext().firestore();

const payId = (s, g, m) => `${s}_${g}_${m}`;
const payRef = (db, id) => doc(db, `centers/${A}/payments/${id}`);

const paymentData = (over = {}) => ({
  centerId: A, studentId: 'st1', groupId: 'g1', month: '202611', amount: 450,
  status: 'paid', note: '', recordedBy: 'adminA', recordedAt: serverTimestamp(),
  cancelledBy: null, cancelledAt: null, cancelReason: null, ...over,
});

const cancelUpdate = (over = {}) => ({
  status: 'cancelled', cancelledBy: 'adminA', cancelledAt: serverTimestamp(),
  cancelReason: 'اتسجلت بالغلط', ...over,
});

const rerecordUpdate = (over = {}) => ({
  status: 'paid', amount: 500, note: 'تصحيح', recordedBy: 'adminA',
  recordedAt: serverTimestamp(),
  cancelledBy: null, cancelledAt: null, cancelReason: null, ...over,
});

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (p, data) => setDoc(doc(db, p), data);
    const now = Timestamp.now();

    await put(`centers/${A}`, { name: 'مركز النور', year: 2026, createdBy: 'adminA', lateAfterMinutes: 15 });
    await put(`centers/${A}/members/adminA`, { role: 'admin', name: 'Admin A', active: true, createdBy: 'adminA' });
    await put(`centers/${A}/members/teacherA`, { role: 'teacher', name: 'Teacher A', active: true, createdBy: 'teacherA' });
    await put(`centers/${A}/members/assistantA`, { role: 'assistant', name: 'Assistant A', active: true, createdBy: 'assistantA' });
    await put(`centers/${A}/members/offAssistant`, { role: 'assistant', name: 'Off', active: false, createdBy: 'offAssistant' });
    await put(`centers/${B}`, { name: 'مركز تاني', year: 2026, createdBy: 'adminB', lateAfterMinutes: 15 });
    await put(`centers/${B}/members/adminB`, { role: 'admin', name: 'Admin B', active: true, createdBy: 'adminB' });

    await put(`centers/${A}/groups/g1`, { centerId: A, name: 'g1', teacherId: 'teacherA', assistantIds: ['assistantA'], status: 'active' });
    await put(`centers/${A}/students/st1`, { centerId: A, fullName: 'st1', status: 'active', groupIds: ['g1'] });

    // دفعة مدفوعة موجودة لاختبارات القراءة والإلغاء.
    await put(`centers/${A}/payments/${payId('st1', 'g1', '202611')}`,
      paymentData({ recordedAt: now }));
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

describe('payments — الإنشاء', () => {
  it('الأدمن يسجّل دفعة', async () => {
    await assertSucceeds(setDoc(
      payRef(as('adminA'), payId('st1', 'g1', '202612')), paymentData({ month: '202612' })));
  });

  it('معلم، مساعد، معطّل، أدمن سنتر تاني، ومجهول مرفوضين', async () => {
    const id = payId('st1', 'g1', '202612');
    const data = paymentData({ month: '202612' });
    await assertFails(setDoc(payRef(as('teacherA'), id), { ...data, recordedBy: 'teacherA' }));
    await assertFails(setDoc(payRef(as('assistantA'), id), { ...data, recordedBy: 'assistantA' }));
    await assertFails(setDoc(payRef(as('offAssistant'), id), { ...data, recordedBy: 'offAssistant' }));
    await assertFails(setDoc(payRef(as('adminB'), id), { ...data, recordedBy: 'adminB' }));
    await assertFails(setDoc(payRef(asAnon(), id), data));
  });

  it('الـ id لازم يطابق studentId_groupId_month', async () => {
    await assertFails(setDoc(
      payRef(as('adminA'), 'st1_g1_202612'), paymentData({ month: '202612', studentId: 'st2' })));
    await assertFails(setDoc(
      payRef(as('adminA'), 'randomid'), paymentData({ month: '202612' })));
  });

  it('شهر بصيغة غلط مرفوض', async () => {
    const id = (m) => payId('st1', 'g1', m);
    await assertFails(setDoc(payRef(as('adminA'), id('20261')), paymentData({ month: '20261' })));
    await assertFails(setDoc(payRef(as('adminA'), id('202613')), paymentData({ month: '202613' })));
    await assertFails(setDoc(payRef(as('adminA'), id('202600')), paymentData({ month: '202600' })));
    await assertFails(setDoc(payRef(as('adminA'), id('abcdef')), paymentData({ month: 'abcdef' })));
  });

  it('مبلغ صفر أو سالب أو نص مرفوض', async () => {
    const id = payId('st1', 'g1', '202612');
    await assertFails(setDoc(payRef(as('adminA'), id), paymentData({ month: '202612', amount: 0 })));
    await assertFails(setDoc(payRef(as('adminA'), id), paymentData({ month: '202612', amount: -5 })));
    await assertFails(setDoc(payRef(as('adminA'), id), paymentData({ month: '202612', amount: '450' })));
  });

  it('ملغاة من البداية، بيانات إلغاء معمولة، حقل غريب، حقل ناقص، recordedBy لحد تاني مرفوضين', async () => {
    const id = payId('st1', 'g1', '202612');
    const d = paymentData({ month: '202612' });
    await assertFails(setDoc(payRef(as('adminA'), id), { ...d, status: 'cancelled' }));
    await assertFails(setDoc(payRef(as('adminA'), id), { ...d, cancelReason: 'x' }));
    await assertFails(setDoc(payRef(as('adminA'), id), { ...d, extra: 1 }));
    await assertFails(setDoc(payRef(as('adminA'), id), (({ note, ...rest }) => rest)(d)));
    await assertFails(setDoc(payRef(as('adminA'), id), { ...d, recordedBy: 'teacherA' }));
  });

  it('طالب أو مجموعة مش موجودين مرفوضين', async () => {
    await assertFails(setDoc(payRef(as('adminA'), payId('st9', 'g1', '202612')),
      paymentData({ month: '202612', studentId: 'st9' })));
    await assertFails(setDoc(payRef(as('adminA'), payId('st1', 'g9', '202612')),
      paymentData({ month: '202612', groupId: 'g9' })));
  });

  it('centerId مختلف أو ملاحظة طويلة مرفوضين', async () => {
    const id = payId('st1', 'g1', '202612');
    await assertFails(setDoc(payRef(as('adminA'), id), paymentData({ month: '202612', centerId: B })));
    await assertFails(setDoc(payRef(as('adminA'), id), paymentData({ month: '202612', note: 'x'.repeat(301) })));
  });
});

describe('payments — القراءة', () => {
  const id = payId('st1', 'g1', '202611');

  it('الأدمن get و list، والمساعد get (علامة المسح)', async () => {
    await assertSucceeds(getDoc(payRef(as('adminA'), id)));
    await assertSucceeds(getDocs(collection(as('adminA'), `centers/${A}/payments`)));
    await assertSucceeds(getDoc(payRef(as('assistantA'), id)));
  });

  it('معلم، معطّل، أدمن سنتر تاني، ومجهول مرفوضين', async () => {
    await assertFails(getDoc(payRef(as('teacherA'), id)));
    await assertFails(getDoc(payRef(as('offAssistant'), id)));
    await assertFails(getDoc(payRef(as('adminB'), id)));
    await assertFails(getDoc(payRef(asAnon(), id)));
  });
});

describe('payments — الإلغاء', () => {
  const id = payId('st1', 'g1', '202611');

  it('الأدمن يلغي بسبب', async () => {
    await assertSucceeds(updateDoc(payRef(as('adminA'), id), cancelUpdate()));
  });

  it('معلم أو مساعد مرفوضين حتى بسبب صحيح', async () => {
    await assertFails(updateDoc(payRef(as('teacherA'), id),
      cancelUpdate({ cancelledBy: 'teacherA' })));
    await assertFails(updateDoc(payRef(as('assistantA'), id),
      cancelUpdate({ cancelledBy: 'assistantA' })));
  });

  it('من غير سبب، أو سبب فاضي أو طويل مرفوض', async () => {
    await assertFails(updateDoc(payRef(as('adminA'), id), { status: 'cancelled' }));
    await assertFails(updateDoc(payRef(as('adminA'), id), cancelUpdate({ cancelReason: '' })));
    await assertFails(updateDoc(payRef(as('adminA'), id), cancelUpdate({ cancelReason: 'x'.repeat(301) })));
  });

  it('تغيير المبلغ أثناء الإلغاء مرفوض', async () => {
    await assertFails(updateDoc(payRef(as('adminA'), id), cancelUpdate({ amount: 1 })));
  });

  it('إلغاء دفعة ملغاة أصلًا مرفوض', async () => {
    const db = as('adminA');
    await assertSucceeds(updateDoc(payRef(db, id), cancelUpdate()));
    await assertFails(updateDoc(payRef(db, id), cancelUpdate({ cancelReason: 'تاني' })));
  });
});

describe('payments — إعادة التسجيل بعد الإلغاء', () => {
  const id = payId('st1', 'g1', '202611');

  it('الأدمن يعيد التسجيل بقيم جديدة', async () => {
    const db = as('adminA');
    await assertSucceeds(updateDoc(payRef(db, id), cancelUpdate()));
    await assertSucceeds(updateDoc(payRef(db, id), rerecordUpdate()));
  });

  it('على دفعة مدفوعة مرفوضة (لازم إلغاء الأول)', async () => {
    await assertFails(updateDoc(payRef(as('adminA'), id), rerecordUpdate()));
  });

  it('إعادة تسجيل سايبة سبب الإلغاء مرفوضة', async () => {
    const db = as('adminA');
    await assertSucceeds(updateDoc(payRef(db, id), cancelUpdate()));
    await assertFails(updateDoc(payRef(db, id), rerecordUpdate({ cancelReason: 'لسه' })));
  });
});

describe('payments — الحذف', () => {
  it('ممنوع حتى للأدمن', async () => {
    await assertFails(deleteDoc(payRef(as('adminA'), payId('st1', 'g1', '202611'))));
  });
});
