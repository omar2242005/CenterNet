import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/centers/cubit/center_settings_cubit.dart';
import 'package:center_net/features/centers/cubit/create_center_cubit.dart';
import 'package:center_net/features/centers/models/center_info.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_centers_repository.dart';

const _center = CenterInfo(
  id: 'c1',
  name: 'مركز النور',
  year: 2026,
  createdBy: 'u1',
  lateAfterMinutes: 15,
);

void main() {
  group('CreateCenterCubit', () {
    test('نجاح: بيرجّع id السنتر الجديد', () async {
      final repo = FakeCentersRepository();
      final cubit = CreateCenterCubit(repo);
      await cubit.submit(name: 'مركز', year: 2026);
      expect(cubit.state.status, CreateCenterStatus.success);
      expect(cubit.state.centerId, 'newCenter1');
      expect(repo.calls, ['create:مركز:2026']);
      await cubit.close();
    });

    test('فشل: failure برسالة عربية', () async {
      final cubit = CreateCenterCubit(
        FakeCentersRepository(failure: const Failure.network()),
      );
      await cubit.submit(name: 'مركز', year: 2026);
      expect(cubit.state.status, CreateCenterStatus.failure);
      expect(cubit.state.failure, const Failure.network());
      await cubit.close();
    });

    test('نداء تاني أثناء التنفيذ بيتتجاهل', () async {
      final repo = FakeCentersRepository();
      final cubit = CreateCenterCubit(repo);
      final a = cubit.submit(name: 'م', year: 2026);
      final b = cubit.submit(name: 'م', year: 2026);
      await Future.wait([a, b]);
      expect(repo.calls.length, 1);
      await cubit.close();
    });
  });

  group('CenterSettingsCubit', () {
    test('load: نجاح', () async {
      final cubit = CenterSettingsCubit(FakeCentersRepository(center: _center));
      await cubit.load();
      expect(cubit.state.view, isA<ViewSuccess<CenterInfo>>());
      await cubit.close();
    });

    test('load: مفيش سنتر = فارغ', () async {
      final cubit = CenterSettingsCubit(FakeCentersRepository());
      await cubit.load();
      expect(cubit.state.view, isA<ViewEmpty<CenterInfo>>());
      await cubit.close();
    });

    test('load: فشل = خطأ مع إعادة محاولة تنجح', () async {
      final repo = FakeCentersRepository(
        center: _center,
        failure: const Failure.permission(),
      );
      final cubit = CenterSettingsCubit(repo);
      await cubit.load();
      expect(cubit.state.view, isA<ViewFailed<CenterInfo>>());
      repo.failure = null;
      await cubit.load();
      expect(cubit.state.view, isA<ViewSuccess<CenterInfo>>());
      await cubit.close();
    });

    test('save ناجح بيحدّث القيم ويعلّم saved', () async {
      final repo = FakeCentersRepository(center: _center);
      final cubit = CenterSettingsCubit(repo);
      await cubit.load();
      await cubit.save(name: ' اسم جديد ', year: 2027, lateAfterMinutes: 20);

      expect(repo.calls.last, 'update:c1: اسم جديد :2027:20');
      expect(cubit.state.saved, isTrue);
      final view = cubit.state.view as ViewSuccess<CenterInfo>;
      expect(view.data.name, 'اسم جديد');
      expect(view.data.lateAfterMinutes, 20);
      await cubit.close();
    });

    test('save فاشل بيحتفظ بالبيانات ويعرض الخطأ', () async {
      final repo = FakeCentersRepository(center: _center);
      final cubit = CenterSettingsCubit(repo);
      await cubit.load();
      repo.failure = const Failure.permission();
      await cubit.save(name: 'x', year: 2026, lateAfterMinutes: 15);

      expect(cubit.state.saved, isFalse);
      expect(cubit.state.saving, isFalse);
      expect(cubit.state.saveFailure, const Failure.permission());
      expect(cubit.state.view, isA<ViewSuccess<CenterInfo>>());
      await cubit.close();
    });

    test('save قبل التحميل بيتتجاهل', () async {
      final repo = FakeCentersRepository(center: _center);
      final cubit = CenterSettingsCubit(repo);
      await cubit.save(name: 'x', year: 2026, lateAfterMinutes: 15);
      expect(repo.calls, isEmpty);
      await cubit.close();
    });
  });
}
