# CenterNet

## تشغيل الـ Emulator والـ seed

```bash
# terminal 1: الـ Emulator (Auth + Firestore)
firebase emulators:start --project centernet-cbf40

# terminal 2: تعمير "مركز النور" (ممكن يتشغل أكتر من مرة، وكل مرة بيرجّع الحالة الأصلية)
cd firebase/seed
npm install
npm run seed

# تشغيل التطبيق على الـ Emulator (محاكي أندرويد)
flutter run --dart-define=USE_EMULATOR=true
```

كلمة السر لكل الحسابات التجريبية: `Test1234!`

| الحساب | الدور |
|---|---|
| admin@centernet.test | أدمن |
| sara@centernet.test / khaled@centernet.test | معلم |
| mona@centernet.test | مساعد |
| guardian@centernet.test | ولي أمر أحمد |
| ahmed@centernet.test | الطالب أحمد |

أكواد جاهزة للتجربة: `DEMOSTF2` (موظف مساعد) · `DEMOGRD3` (ولي أمر الطالب s4) · `DEMOSTD4` (الطالب s4).
