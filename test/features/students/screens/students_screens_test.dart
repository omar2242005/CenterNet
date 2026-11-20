import 'package:center_net/app/di.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/students/repository/students_repository.dart';
import 'package:center_net/features/students/screens/student_form_screen.dart';
import 'package:center_net/features/students/screens/students_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/fake_students_repository.dart';

void main() {
  late FakeStudentsRepository repo;

  setUp(() {
    repo = FakeStudentsRepository(
      students: [
        makeStudent(1, 'أحمد علي'),
        makeStudent(2, 'سارة محمد'),
        makeStudent(3, 'منى حسن', archived: true),
      ],
    );
    sl.registerSingleton<StudentsRepository>(repo);
  });

  tearDown(() async {
    await sl.reset();
  });

  group('قائمة الطلاب', () {
    Future<void> openList(WidgetTester tester) async {
      await tester.pumpApp(const StudentsListScreen());
      await tester.pumpAndSettle();
    }

    testWidgets('بتعرض النشطين وتخفي المؤرشفين', (tester) async {
      await openList(tester);

      expect(find.text('أحمد علي'), findsOneWidget);
      expect(find.text('سارة محمد'), findsOneWidget);
      expect(find.text('منى حسن'), findsNothing);
    });

    testWidgets('زر الأرشيف بيظهر المؤرشفين', (tester) async {
      await openList(tester);

      await tester.tap(find.byTooltip(arL10n.studentsShowArchived));
      await tester.pumpAndSettle();

      expect(find.text('منى حسن'), findsOneWidget);
      expect(find.text(arL10n.studentArchivedBadge), findsOneWidget);
    });

    testWidgets('البحث بالتطبيع العربي', (tester) async {
      await openList(tester);

      await tester.enterText(find.byType(TextField), 'احمد');
      await tester.pumpAndSettle();

      expect(find.text('أحمد علي'), findsOneWidget);
      expect(find.text('سارة محمد'), findsNothing);
    });

    testWidgets('بحث من غير نتايج بيعرض رسالة', (tester) async {
      await openList(tester);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text(arL10n.studentsNoResults), findsOneWidget);
    });

    testWidgets('سنتر فاضي بيعرض رسالة فارغ', (tester) async {
      repo.students.clear();
      await openList(tester);

      expect(find.text(arL10n.studentsEmpty), findsOneWidget);
    });

    testWidgets('الخطأ بيظهر مع إعادة المحاولة', (tester) async {
      repo.loadFailure = const Failure.network();
      await openList(tester);

      expect(find.text(const Failure.network().message), findsOneWidget);

      repo.loadFailure = null;
      await tester.tap(find.text(arL10n.retry));
      await tester.pumpAndSettle();

      expect(find.text('أحمد علي'), findsOneWidget);
    });
  });

  group('نموذج الطالب', () {
    Future<void> openForm(WidgetTester tester) async {
      await tester.pumpApp(const StudentFormScreen());
      await tester.pumpAndSettle();
    }

    Future<void> tapSave(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, arL10n.studentSave));
      await tester.pumpAndSettle();
    }

    testWidgets('الحقول الإجبارية فاضية = رسالة مطلوب', (tester) async {
      await openForm(tester);
      await tapSave(tester);

      expect(find.text(arL10n.validationRequired), findsNWidgets(2));
      expect(repo.calls, isEmpty);
    });

    testWidgets('موبايل غلط مرفوض برسالة عربية', (tester) async {
      await openForm(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'أحمد علي');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tapSave(tester);

      expect(find.text(arL10n.validationMobileInvalid), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    testWidgets('فشل الحفظ بيظهر رسالته', (tester) async {
      repo.writeFailure = const Failure.permission();
      await openForm(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'أحمد علي');
      await tester.enterText(find.byType(TextFormField).at(1), '01012345678');
      await tapSave(tester);

      expect(repo.calls.single, startsWith('add:أحمد علي:01012345678'));
      expect(find.text(const Failure.permission().message), findsOneWidget);
    });
  });
}
