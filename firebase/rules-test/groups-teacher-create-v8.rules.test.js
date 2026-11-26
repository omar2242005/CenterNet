// [v8] اختبارات إنشاء المعلم لمجموعته.
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
    for (let i = 1; i <= 9; i += 1) {
      await put(`centers/${A}/members/asst${i}`, { role: 'assistant', name: `Asst ${i}`, active: true, createdBy: `asst${i}` });
    }
    await put(`centers/${A}/members/offAssistant`, { role: 'assistant', name: 'Off Asst', active: false, createdBy: 'offAssistant' });
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


const mine = (over = {}) => groupData({ createdBy: 'teacherA', ...over });

describe('groups v8 — المعلم ينشئ مجموعته', () => {
  it('المعلم النشط ينشئ لنفسه (مع مساعد نشط وبدونه)', async () => {
    await assertSucceeds(setDoc(groupRef(as('teacherA'), 'g3'), mine()));
    await assertSucceeds(setDoc(groupRef(as('teacherB'), 'g4'),
      mine({ teacherId: 'teacherB', createdBy: 'teacherB', assistantIds: [] })));
  });

  it('بعد الإنشاء المعلم يقرا مجموعته (الـ get بتاع الـ repository)', async () => {
    await assertSucceeds(setDoc(groupRef(as('teacherA'), 'g3'), mine()));
    await assertSucceeds(getDoc(groupRef(as('teacherA'), 'g3')));
    await assertFails(getDoc(groupRef(as('teacherB'), 'g3')));
  });

  it('حد أقصى 6 مساعدين بيعدّي، و7 مرفوض', async () => {
    const six = ['asst1', 'asst2', 'asst3', 'asst4', 'asst5', 'asst6'];
    await assertSucceeds(setDoc(groupRef(as('teacherA'), 'g3'), mine({ assistantIds: six })));
    await assertFails(setDoc(groupRef(as('teacherA'), 'g4'), mine({ assistantIds: [...six, 'asst7'] })));
  });

  it('معلم بينشئ بـ teacherId لمعلم تاني (أو الأدمن) مرفوض', async () => {
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), mine({ teacherId: 'teacherB' })));
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), mine({ teacherId: 'adminA' })));
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), mine({ teacherId: '' })));
  });

  it('المساعد مرفوض (لنفسه أو لمعلم)', async () => {
    await assertFails(setDoc(groupRef(as('assistantA'), 'g3'),
      mine({ teacherId: 'assistantA', createdBy: 'assistantA', assistantIds: [] })));
    await assertFails(setDoc(groupRef(as('assistantA'), 'g3'),
      mine({ teacherId: 'teacherA', createdBy: 'assistantA' })));
  });

  it('المعلم المعطّل، غير العضو، السنتر التاني، وغير المسجل مرفوضين', async () => {
    await assertFails(setDoc(groupRef(as('offTeacher'), 'g3'),
      mine({ teacherId: 'offTeacher', createdBy: 'offTeacher', assistantIds: [] })));
    await assertFails(setDoc(groupRef(as('stranger'), 'g3'),
      mine({ teacherId: 'stranger', createdBy: 'stranger', assistantIds: [] })));
    await assertFails(setDoc(groupRef(as('adminB'), 'g3'), mine({ createdBy: 'adminB' })));
    await assertFails(setDoc(groupRef(env.unauthenticatedContext().firestore(), 'g3'), mine()));
  });

  it('مساعدين: معطّل، معلم، أو غير موجود مرفوضين (نفس قيود الأدمن)', async () => {
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), mine({ assistantIds: ['offAssistant'] })));
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), mine({ assistantIds: ['teacherB'] })));
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), mine({ assistantIds: ['ghost'] })));
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), mine({ assistantIds: ['teacherA'] })));
  });

  it('قيود validGroup لسه شغالة للمعلم', async () => {
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), mine({ status: 'archived' })));
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), mine({ createdBy: 'teacherB' })));
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), mine({ createdAt: Timestamp.now() })));
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), mine({ extra: 1 })));
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), mine({ centerId: B })));
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), mine({ name: '' })));
    await assertFails(setDoc(groupRef(as('teacherA'), 'g3'), mine({ monthlyFee: -1 })));
  });

  it('مفيش توسيع: المعلم لسه ميعدّلش ولا يحذف ولا يأرشف، والأدمن لسه ينشئ', async () => {
    await assertFails(updateDoc(groupRef(as('teacherA'), 'g1'), { name: 'تغيير' }));
    await assertFails(updateDoc(groupRef(as('teacherA'), 'g1'), { status: 'archived' }));
    await assertFails(updateDoc(groupRef(as('teacherA'), 'g1'), { teacherId: 'teacherB' }));
    await assertFails(deleteDoc(groupRef(as('teacherA'), 'g1')));
    await assertSucceeds(setDoc(groupRef(as('adminA'), 'g5'), groupData()));
    await assertSucceeds(setDoc(groupRef(as('adminA'), 'g6'), groupData({ teacherId: 'teacherB' })));
  });
});
