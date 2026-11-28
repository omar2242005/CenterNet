import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/scan/models/scan_setup.dart';
import 'package:center_net/features/scan/rules/scan_validator.dart';
import 'package:center_net/features/sessions/models/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Session session() => Session.create(
    centerId: 'c1',
    groupId: 'g1',
    cairoStart: DateTime(2026, 11, 25, 17),
    cairoEnd: DateTime(2026, 11, 25, 18),
    createdBy: 'u1',
  );

  group('ScanSetup.forSession', () {
    test('بيتبني من الجلسة بالحقول الصح', () {
      final s = session();
      final setup = ScanSetup.forSession(
        session: s,
        groupStudentIds: {'s1', 's2'},
        lateAfterMinutes: 10,
      );

      expect(setup.centerId, 'c1');
      expect(setup.sessionId, s.id);
      expect(setup.sessionStart, s.startAt);
      expect(setup.groupStudentIds, {'s1', 's2'});
      expect(setup.lateAfterMinutes, 10);
      expect(setup.isDemo, isFalse);
    });

    test('مدة التأخير الافتراضية من ScanValidator', () {
      final setup = ScanSetup.forSession(
        session: session(),
        groupStudentIds: {'s1'},
      );
      expect(setup.lateAfterMinutes, ScanValidator.defaultLateAfterMinutes);
    });

    test('مجموعة فاضية بترفض (Failure.validation)', () {
      expect(
        () => ScanSetup.forSession(
          session: session(),
          groupStudentIds: const <String>{},
        ),
        throwsA(
          isA<Failure>().having(
            (f) => f.type,
            'type',
            FailureType.validation,
          ),
        ),
      );
    });

    test('ids المجموعة غير قابلة للتعديل', () {
      final setup = ScanSetup.forSession(
        session: session(),
        groupStudentIds: {'s1'},
      );
      expect(() => setup.groupStudentIds.add('s2'), throwsUnsupportedError);
    });
  });
}
