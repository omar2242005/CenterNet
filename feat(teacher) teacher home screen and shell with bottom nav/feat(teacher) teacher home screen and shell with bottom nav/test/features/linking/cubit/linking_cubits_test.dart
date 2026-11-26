import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/linking/cubit/link_code_cubit.dart';
import 'package:center_net/features/linking/cubit/my_students_cubit.dart';
import 'package:center_net/features/linking/models/student_link.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_linking_repository.dart';

void main() {
  group('LinkCodeCubit', () {
    test('نجاح الربط', () async {
      final repo = FakeLinkingRepository();
      final cubit = LinkCodeCubit(repo, LinkKind.guardian);
      addTearDown(cubit.close);

      await cubit.submit('ab3cd4ef');

      expect(repo.redeemedCodes, ['ab3cd4ef']);
      expect(cubit.state.done, isTrue);
      expect(cubit.state.failure, isNull);
    });

    test('فشل الربط بيظهر الرسالة ومبيخلّصش', () async {
      final repo = FakeLinkingRepository(
        failure: const Failure.validation('الكود ده اتستخدم قبل كده.'),
      );
      final cubit = LinkCodeCubit(repo, LinkKind.student);
      addTearDown(cubit.close);

      await cubit.submit('AB3CD4EF');

      expect(cubit.state.done, isFalse);
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.failure?.message, 'الكود ده اتستخدم قبل كده.');
    });
  });

  group('MyStudentsCubit', () {
    test('بيحمّل الطلاب المربوطين', () async {
      final repo = FakeLinkingRepository(linked: [makeLinked(1), makeLinked(2)]);
      final cubit = MyStudentsCubit(repo);
      addTearDown(cubit.close);

      await cubit.load();

      final view = cubit.state.view;
      expect(view, isA<ViewSuccess<List<dynamic>>>());
      expect((view as ViewSuccess).data, hasLength(2));
    });

    test('من غير ربط = فارغ', () async {
      final cubit = MyStudentsCubit(FakeLinkingRepository());
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.view, isA<ViewEmpty<List<dynamic>>>());
    });

    test('فك الربط بيشيل الطالب ويعيد التحميل', () async {
      final repo = FakeLinkingRepository(linked: [makeLinked(1), makeLinked(2)]);
      final cubit = MyStudentsCubit(repo);
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.unlink(repo.linked.first);

      expect(repo.unlinked, hasLength(1));
      expect((cubit.state.view as ViewSuccess).data, hasLength(1));
    });

    test('فشل التحميل', () async {
      final cubit = MyStudentsCubit(
        FakeLinkingRepository(failure: const Failure.network()),
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.view, isA<ViewFailed<List<dynamic>>>());
    });
  });
}
