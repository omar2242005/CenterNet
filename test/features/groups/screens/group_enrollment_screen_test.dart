import 'package:center_net/app/di.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/groups/repository/groups_repository.dart';
import 'package:center_net/features/admin/screens/group_enrollment_screen.dart';
import 'package:center_net/features/students/models/student.dart';
import 'package:center_net/features/students/repository/students_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../students/helpers/fake_students_repository.dart';
import '../helpers/fake_groups_repository.dart';

void main() {
  late FakeStudentsRepository studentsRepo;
  late FakeGroupsRepository groupsRepo;

  final group = Group.fromMap('g1', <String, dynamic>{
    'centerId': 'c1',
    'name': 'مجموعة السبت',
    'teacherId': 't1',
    'createdBy': 'u1',
    'assistantIds': <String>[],
    'capacity': 2,
    'status': 'active',
  });

  Student enrolledStudent(int no, String name, {bool archived = false}) =>
      Student.fromMap('s$no', <String, dynamic>{
        'centerId': 'c1',
        'studentNo': no,
        'fullName': name,
        'searchKey': name,
        'phone': '01012345678',
        'grade': '',
        'groupIds': <String>['g1'],
        'status': archived ? 'archived' : 'active',
        'createdBy': 'u1',
      });

  setUp(() {
    studentsRepo = FakeStudentsRepository(
      students: [
        enrolledStudent(1, 'أحمد علي'),
        makeStudent(2, 'سارة محمد'),
        makeStudent(3, 'منى حسن', archived: true),
        enrolledStudent(4, 'كريم سيد', archived: true),
      ],
    );
    groupsRepo = FakeGroupsRepository();
    sl.registerSingleton<StudentsRepository>(studentsRepo);
    sl.registerSingleton<GroupsRepository>(groupsRepo);
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpApp(GroupEnrollmentScreen(group: group));
    await tester.pumpAndSettle();
  }

  testWidgets('بتعرض النشطين والمؤرشف المسجّل بس، مع عدّاد التسجيل', (tester) async {
    await open(tester);

    expect(find.text('أحمد علي'), findsOneWidget);
    expect(find.text('سارة محمد'), findsOneWidget);
    expect(find.text('منى حسن'), findsNothing); // مؤرشفة ومش مسجّلة
    expect(find.text('كريم سيد'), findsOneWidget); // مؤرشف لكنه مسجّل
    expect(find.text(arL10n.groupEnrolledCount(2)), findsOneWidget);
    expect(find.text(arL10n.groupFullBadge), findsOneWidget); // السعة 2
  });

  testWidgets('تسجيل طالب جديد بيحدّث العلامة والعدّاد', (tester) async {
    await open(tester);

    await tester.tap(find.text('سارة محمد'));
    await tester.pumpAndSettle();

    expect(groupsRepo.calls, contains('enroll:g1:s2'));
    expect(find.text(arL10n.groupEnrolledCount(3)), findsOneWidget);
  });

  testWidgets('إلغاء تسجيل طالب مسجّل', (tester) async {
    await open(tester);

    await tester.tap(find.text('أحمد علي'));
    await tester.pumpAndSettle();

    expect(groupsRepo.calls, contains('unenroll:g1:s1'));
    expect(find.text(arL10n.groupEnrolledCount(1)), findsOneWidget);
  });

  testWidgets('البحث بالاسم بالتطبيع العربي', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'احمد');
    await tester.pumpAndSettle();

    expect(find.text('أحمد علي'), findsOneWidget);
    expect(find.text('سارة محمد'), findsNothing);
  });

  testWidgets('البحث برقم الطالب', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), '2');
    await tester.pumpAndSettle();

    expect(find.text('سارة محمد'), findsOneWidget);
    expect(find.text('أحمد علي'), findsNothing);
  });

  testWidgets('فشل التسجيل بيظهر SnackBar ومايتغيرش العداد', (tester) async {
    groupsRepo.writeFailure = const Failure.permission();
    await open(tester);

    await tester.tap(find.text('سارة محمد'));
    await tester.pumpAndSettle();

    expect(find.text(const Failure.permission().message), findsOneWidget);
    expect(find.text(arL10n.groupEnrolledCount(2)), findsOneWidget);
  });
}
