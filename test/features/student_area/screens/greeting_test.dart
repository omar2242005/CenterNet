import 'package:center_net/app/di.dart';
import 'package:center_net/app/session_role.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/auth/models/account_type.dart';
import 'package:center_net/features/auth/models/app_user.dart';
import 'package:center_net/features/auth/repository/auth_repository.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/guardian/screens/guardian_home_screen.dart';
import 'package:center_net/features/home/models/home_destination.dart';
import 'package:center_net/features/linking/models/student_link.dart';
import 'package:center_net/features/linking/repository/linking_repository.dart';
import 'package:center_net/features/student_area/models/child_data.dart';
import 'package:center_net/features/student_area/repository/student_data_repository.dart';
import 'package:center_net/features/student_area/screens/student_home_screen.dart';
import 'package:center_net/features/students/models/student.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../auth/helpers/fake_auth_repository.dart';
import '../../linking/helpers/fake_linking_repository.dart';
import '../../../helpers/pump_app.dart';

/// بيانات الطالب مش محتاجينها في التست: كفاية إنها تفشل فالشاشة تعرض
/// حالة الخطأ بدل ما تتعلق، والتحية تفضل ظاهرة فوق.
class _FailingStudentData implements StudentDataRepository {
  const _FailingStudentData();

  @override
  Future<ChildSummary> loadSummary(Student s) async =>
      throw const Failure.network();

  @override
  Future<AttendanceHistory> loadAttendance(Student s) async =>
      throw const Failure.network();

  @override
  Future<List<Group>> loadGroups(Student s) async =>
      throw const Failure.network();

  @override
  Future<List<SessionEntry>> loadSchedule(Student s) async =>
      throw const Failure.network();

  @override
  Future<ResultsData> loadResults(Student s) async =>
      throw const Failure.network();
}

/// التحية في رئيسية الطالب وولي الأمر، زي رئيسية المعلم والمساعد.
void main() {
  late FakeAuthRepository auth;

  setUp(() {
    auth = FakeAuthRepository()
      ..profile = const AppUser(
        uid: 'u1',
        name: 'أحمد',
        email: 'a@b.com',
        phone: '',
        accountType: AccountType.guardian,
        centerId: 'c1',
      );
    sl.registerSingleton<AuthRepository>(auth);
    sl.registerSingleton<StudentDataRepository>(const _FailingStudentData());
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('رئيسية الطالب بتحيّي الطالب باسمه', (tester) async {
    sl.registerSingleton<SessionRole>(
      SessionRole()..set(HomeDestination.student),
    );
    sl.registerSingleton<LinkingRepository>(
      FakeLinkingRepository(linked: [makeLinked(1, kind: LinkKind.student)]),
    );

    await tester.pumpApp(const StudentHomeScreen());
    await tester.pumpAndSettle();

    expect(find.text(arL10n.studentGreeting('طالب 1')), findsOneWidget);
  });

  testWidgets('رئيسية ولي الأمر بتحيّي صاحب الحساب باسمه', (tester) async {
    sl.registerSingleton<SessionRole>(
      SessionRole()..set(HomeDestination.guardian),
    );
    sl.registerSingleton<LinkingRepository>(
      FakeLinkingRepository(linked: [makeLinked(1)]),
    );

    await tester.pumpApp(const GuardianHomeScreen());
    await tester.pumpAndSettle();

    expect(find.text(arL10n.guardianGreeting('أحمد')), findsOneWidget);
  });

  testWidgets('لو اسم الحساب مش متاح، ولي الأمر بيفتح من غير تحية', (
    tester,
  ) async {
    auth.failure = null;
    auth.profile = null;
    sl.registerSingleton<SessionRole>(
      SessionRole()..set(HomeDestination.guardian),
    );
    sl.registerSingleton<LinkingRepository>(
      FakeLinkingRepository(linked: [makeLinked(1)]),
    );

    await tester.pumpApp(const GuardianHomeScreen());
    await tester.pumpAndSettle();

    expect(find.textContaining('أهلاً،'), findsNothing);
  });
}
