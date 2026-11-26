import 'package:center_net/app/di.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/sessions/models/session.dart';
import 'package:center_net/features/sessions/repository/sessions_repository.dart';
import 'package:center_net/features/sessions/screens/group_sessions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/pump_app.dart';
import '../helpers/fake_sessions_repository.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late FakeSessionsRepository repo;
  late final cairo = tz.getLocation('Africa/Cairo');

  final group = Group.fromMap('g1', <String, dynamic>{
    'centerId': 'c1',
    'name': 'مجموعة السبت',
    'teacherId': 't1',
    'createdBy': 'u1',
    'assistantIds': <String>[],
    'status': 'active',
  });

  Session sessionAt(int day, {bool cancelled = false}) {
    final s = Session.create(
      centerId: 'c1',
      groupId: 'g1',
      cairoStart: tz.TZDateTime(cairo, 2026, 12, day, 17),
      cairoEnd: tz.TZDateTime(cairo, 2026, 12, day, 18, 30),
      createdBy: 'u1',
    );
    if (!cancelled) return s;
    return Session.fromMap(s.id, <String, dynamic>{
      ...s.toCreateMap(createdAt: DateTime(2026)),
      'status': 'cancelled',
    });
  }

  setUp(() {
    repo = FakeSessionsRepository(
      sessions: [sessionAt(5), sessionAt(7), sessionAt(12, cancelled: true)],
    );
    sl.registerSingleton<SessionsRepository>(repo);
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpApp(GroupSessionsScreen(group: group));
    await tester.pumpAndSettle();
  }

  testWidgets('بتعرض الحصص بالتاريخ والوقت والحالة', (tester) async {
    await open(tester);

    expect(find.textContaining('5 ديسمبر 2026'), findsOneWidget);
    expect(find.textContaining('7 ديسمبر 2026'), findsOneWidget);
    expect(find.text('5:00 م - 6:30 م'), findsNWidgets(3));
    expect(find.text(arL10n.sessionScheduledBadge), findsNWidgets(2));
    expect(find.text(arL10n.sessionCancelledBadge), findsOneWidget);
  });

  testWidgets('قائمة فاضية برسالة عربية', (tester) async {
    repo.sessions.clear();
    await open(tester);

    expect(find.text(arL10n.sessionsEmpty), findsOneWidget);
  });

  testWidgets('إنشاء الأسابيع الجاية بيظهر النتيجة ويعيد التحميل', (tester) async {
    repo.generateResult = (created: 6, skipped: 2);
    await open(tester);

    await tester.tap(find.text(arL10n.sessionsGenerateButton));
    await tester.pumpAndSettle();

    expect(repo.calls.where((c) => c == 'generate'), hasLength(1));
    expect(repo.calls.where((c) => c == 'load'), hasLength(2));
    expect(find.text(arL10n.sessionsGenerateResult(6, 2)), findsOneWidget);
  });

  testWidgets('إلغاء حصة بعد التأكيد بيغيّر شارتها', (tester) async {
    await open(tester);

    await tester.tap(find.byTooltip(arL10n.sessionCancelAction).first);
    await tester.pumpAndSettle();
    expect(find.text(arL10n.sessionCancelTitle), findsOneWidget);

    await tester.tap(find.text(arL10n.sessionCancelConfirm));
    await tester.pumpAndSettle();

    final cancelledId = repo.calls
        .firstWhere((c) => c.startsWith('cancel:'))
        .split(':')[1];
    expect(cancelledId, sessionAt(5).id);
    expect(find.text(arL10n.sessionCancelledBadge), findsNWidgets(2));
  });

  testWidgets('رفض نافذة الإلغاء مبيغيرش حاجة', (tester) async {
    await open(tester);

    await tester.tap(find.byTooltip(arL10n.sessionCancelAction).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(arL10n.cancel));
    await tester.pumpAndSettle();

    expect(repo.calls.where((c) => c.startsWith('cancel:')), isEmpty);
    expect(find.text(arL10n.sessionCancelledBadge), findsOneWidget);
  });

  testWidgets('الحصة الملغاة مفيهاش زر إلغاء', (tester) async {
    await open(tester);

    // 3 حصص: 2 مجدولة بزر إلغاء لكل منها، والملغاة من غير زر.
    expect(find.byTooltip(arL10n.sessionCancelAction), findsNWidgets(2));
  });

  testWidgets('فشل التحميل بيظهر مع إعادة المحاولة', (tester) async {
    repo.failure = const Failure.network();
    await open(tester);

    expect(find.text(const Failure.network().message), findsOneWidget);
    repo.failure = null;
    await tester.tap(find.text(arL10n.retry));
    await tester.pumpAndSettle();

    expect(find.textContaining('5 ديسمبر 2026'), findsOneWidget);
  });
}
