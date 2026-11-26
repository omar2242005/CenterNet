import 'package:center_net/app/di.dart';
import 'package:center_net/core/theme/app_theme.dart';
import 'package:center_net/features/grades/repositories/exams_repository.dart';
import 'package:center_net/features/grades/repositories/scores_repository.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/groups/repository/groups_repository.dart';
import 'package:center_net/features/students/repository/students_repository.dart';
import 'package:center_net/features/teacher/cubit/teacher_exams_cubit.dart';
import 'package:center_net/features/teacher/models/exam_summary.dart';
import 'package:center_net/features/teacher/screens/teacher_exam_details_screen.dart';
import 'package:center_net/features/teacher/screens/teacher_exam_form_screen.dart';
import 'package:center_net/features/teacher/screens/teacher_exam_scores_screen.dart';
import 'package:center_net/features/teacher/screens/teacher_exams_screen.dart';
import 'package:center_net/features/teacher/teacher_route_names.dart';
import 'package:center_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../groups/helpers/fake_groups_repository.dart';
import '../../students/helpers/fake_students_repository.dart';
import '../helpers/fake_grades_repositories.dart';
import '../helpers/teacher_fixtures.dart';

void main() {
  tzdata.initializeTimeZones();

  final g1 = fakeGroup('g1');
  final g2 = fakeGroup('g2', subject: 'علوم');
  final past = DateTime.now().subtract(const Duration(days: 5));
  final future = DateTime.now().add(const Duration(days: 5));
  final examA = fakeExam('e1', 'g1', past, title: 'اختبار الجبر');
  final examB = fakeExam('e2', 'g1', future, title: 'اختبار الهندسة');
  final examC = fakeExam('e3', 'g2', past, title: 'اختبار الخلايا');

  late FakeScoresRepository scores;
  late FakeExamsRepository exams;

  Future<void> pump(WidgetTester tester, Widget home, {String? at}) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(path: '/start', builder: (_, _) => home),
        GoRoute(
          path: '/form',
          builder: (_, _) => const TeacherExamFormScreen(),
        ),
        GoRoute(
          path: TeacherRoutes.examCreate,
          builder: (_, _) => const Scaffold(body: Text('CREATE')),
        ),
        GoRoute(
          path: TeacherRoutes.examDetails,
          builder: (_, _) => const Scaffold(body: Text('DETAILS')),
        ),
        GoRoute(
          path: TeacherRoutes.examScores,
          builder: (_, s) =>
              TeacherExamScoresScreen(args: s.extra! as TeacherExamArgs),
        ),
        GoRoute(
          path: TeacherRoutes.groups,
          builder: (_, _) => const Scaffold(body: Text('GROUPS')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    scores = FakeScoresRepository(
      scores: [fakeScore('e1', 's1', 18), fakeScore('e1', 's2', 16)],
    );
    exams = FakeExamsRepository();
    sl.registerSingleton<ScoresRepository>(scores);
    sl.registerSingleton<ExamsRepository>(exams);
    sl.registerSingleton<StudentsRepository>(
      FakeStudentsRepository(
        students: [
          fakeStudent('s1', 1, ['g1']),
          fakeStudent('s2', 2, ['g1']),
          fakeStudent('s3', 3, ['g1']),
        ],
      ),
    );
    sl.registerSingleton<GroupsRepository>(
      FakeGroupsRepository(groups: [g1, g2]),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('قايمة الاختبارات: أقسام المواد والحالات والملخص', (
    tester,
  ) async {
    final repo = FakeTeacherExamsRepository(
      items: [
        ExamSummary(exam: examA, group: g1, studentCount: 3, recordedCount: 2),
        ExamSummary(exam: examB, group: g1, studentCount: 3, recordedCount: 0),
        ExamSummary(exam: examC, group: g2, studentCount: 1, recordedCount: 1),
      ],
    );
    sl.registerFactory<TeacherExamsCubit>(() => TeacherExamsCubit(repo));
    await pump(tester, const TeacherExamsScreen());

    expect(find.text('قائمة الاختبارات'), findsOneWidget);
    expect(find.text('اختبارات رياضيات'), findsOneWidget);
    expect(find.text('اختبارات علوم'), findsOneWidget);
    expect(find.text('قيد الرصد'), findsOneWidget);
    expect(find.text('قادم'), findsOneWidget);
    expect(find.text('تم الرصد'), findsOneWidget);
    expect(find.text('2 من 3 درجة مسجلة · من 20'), findsOneWidget);
    expect(find.text('إنشاء اختبار جديد'), findsOneWidget);
    // التبويبات الأربعة.
    final nav = find.byType(NavigationBar);
    for (final t in ['الرئيسية', 'مجموعاتي', 'الامتحانات', 'حسابي']) {
      expect(
        find.descendant(of: nav, matching: find.text(t)),
        findsOneWidget,
        reason: t,
      );
    }

    await tester.tap(find.text('اختبار الجبر'));
    await tester.pumpAndSettle();
    expect(find.text('DETAILS'), findsOneWidget);
  });

  testWidgets('قايمة فاضية: رسالة وزر الإنشاء', (tester) async {
    final repo = FakeTeacherExamsRepository();
    sl.registerFactory<TeacherExamsCubit>(() => TeacherExamsCubit(repo));
    await pump(tester, const TeacherExamsScreen());
    expect(find.text('لسه مفيش اختبارات. أنشئ أول اختبار.'), findsOneWidget);
    expect(find.text('إنشاء اختبار جديد'), findsOneWidget);
  });

  testWidgets(
    'إنشاء اختبار: لازم مجموعة، وبعدها بيحفظ بوقت البداية بتوقيت القاهرة',
    (tester) async {
      await pump(tester, const SizedBox());
      GoRouter.of(tester.element(find.byType(SizedBox).first)).push('/form');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'اختبار جديد');
      await tester.tap(find.text('حفظ الامتحان'));
      await tester.pumpAndSettle();
      expect(find.text('اختر المجموعة'), findsOneWidget);
      expect(exams.created, isEmpty);

      await tester.tap(find.byType(DropdownButtonFormField<Group>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('علوم · مجموعة g2').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ الامتحان'));
      await tester.pumpAndSettle();

      expect(exams.created, ['g2:اختبار جديد:100.0']);
      final cairo = tz.getLocation('Africa/Cairo');
      final start = tz.TZDateTime.from(exams.createdDates.single, cairo);
      expect((start.hour, start.minute), (16, 0));
    },
  );

  testWidgets('تفاصيل الاختبار: المتوسط وكروت الطلاب', (tester) async {
    await pump(
      tester,
      TeacherExamDetailsScreen(args: TeacherExamArgs(g1, examA)),
    );
    expect(find.text('اختبار الجبر'), findsWidgets);
    expect(find.text('17 من 20'), findsOneWidget);
    expect(find.text('تم رصد 2 من 3'), findsNothing); // النص متركّب مع المتوسط
    expect(find.textContaining('تم رصد 2 من 3'), findsOneWidget);
    expect(find.text('18 من 20'), findsOneWidget);
    expect(find.text('16 من 20'), findsOneWidget);
    expect(find.text('لسه'), findsOneWidget); // الطالب التالت
    expect(find.text('رصد الدرجات'), findsOneWidget);
    expect(find.text('نشر الدرجات'), findsOneWidget);
    await tester.tap(find.text('نشر الدرجات'));
    await tester.pumpAndSettle();
    expect(find.text('إلغاء النشر'), findsOneWidget);
  });

  testWidgets('رصد الدرجات: بحث، رفض أكبر من النهائية، وحفظ واحد للكل', (
    tester,
  ) async {
    await pump(
      tester,
      Builder(
        builder: (context) =>
            TeacherExamScoresScreen(args: TeacherExamArgs(g1, examA)),
      ),
    );
    expect(find.text('رصد الدرجات'), findsWidgets);
    expect(find.text('الدرجة النهائية: 20'), findsOneWidget);
    // الدرجات الموجودة متعبّية.
    expect(find.widgetWithText(TextFormField, '18'), findsOneWidget);

    // بحث بالرقم.
    await tester.enterText(find.byType(TextField).first, '3');
    await tester.pumpAndSettle();
    expect(find.textContaining('طالب s3'), findsOneWidget);
    expect(find.textContaining('طالب s1'), findsNothing);

    // درجة غلط تتحفظ بخطأ، ومفيش حفظ.
    await tester.enterText(find.widgetWithText(TextFormField, '').last, '25');
    await tester.tap(find.text('حفظ الدرجات'));
    await tester.pumpAndSettle();
    expect(scores.saved, isEmpty);
    expect(find.text('الدرجة أكبر من الدرجة النهائية (20)'), findsOneWidget);

    // تصحيح وحفظ.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '25'), '19');
    await tester.ensureVisible(find.text('حفظ الدرجات'));
    await tester.tap(find.text('حفظ الدرجات'));
    await tester.pumpAndSettle();
    expect(scores.saved, ['s3:19.0']);
    expect(find.text('تم حفظ 1 درجة'), findsOneWidget);
  });
}
