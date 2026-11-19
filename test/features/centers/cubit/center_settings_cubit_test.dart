import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/centers/cubit/center_settings_cubit.dart';
import 'package:center_net/features/centers/models/center_info.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_centers_repository.dart';

void main() {
  test('load: نجاح / فارغ / خطأ', () async {
    final repo = FakeCentersRepository(mine: sampleContext());
    final cubit = CenterSettingsCubit(repo);
    await cubit.load();
    expect(cubit.state.view, isA<ViewSuccess>());

    repo.mine = null;
    await cubit.load();
    expect(cubit.state.view, isA<ViewEmpty>());

    repo.failure = const Failure.network();
    await cubit.load();
    expect(cubit.state.view, isA<ViewFailed>());
  });

  test(
    'save ناجح: بيكتب التعديلات ويحدّث السنتر المعروض ويزوّد savedTick',
    () async {
      final repo = FakeCentersRepository(mine: sampleContext());
      final cubit = CenterSettingsCubit(repo);
      await cubit.load();

      await cubit.save(name: 'مركز الأمل', year: 2027, lateAfterMinutes: 30);

      expect(repo.calls.last, 'update:c1:مركز الأمل:2027:30');
      expect(cubit.state.saving, isFalse);
      expect(cubit.state.saveFailure, isNull);
      expect(cubit.state.savedTick, 1);
      final view = cubit.state.view as ViewSuccess<CenterContext>;
      expect(view.data.center.name, 'مركز الأمل');
      expect(view.data.center.year, 2027);
      expect(view.data.center.lateAfterMinutes, 30);
      // العضوية زي ما هي.
      expect(view.data.membership.isAdmin, isTrue);
    },
  );

  test('save فاشل: saveFailure والسنتر المعروض مبيتغيّرش', () async {
    final repo = FakeCentersRepository(mine: sampleContext());
    final cubit = CenterSettingsCubit(repo);
    await cubit.load();

    repo.failure = const Failure.permission();
    await cubit.save(name: 'مركز الأمل', year: 2027, lateAfterMinutes: 30);

    expect(cubit.state.saving, isFalse);
    expect(cubit.state.saveFailure, const Failure.permission());
    expect(cubit.state.savedTick, 0);
    final view = cubit.state.view as ViewSuccess<CenterContext>;
    expect(view.data.center.name, 'مركز النور');
  });

  test('save قبل ما السنتر يتحمّل: مبيعملش حاجة', () async {
    final repo = FakeCentersRepository(mine: sampleContext());
    final cubit = CenterSettingsCubit(repo);
    await cubit.save(name: 'س', year: 2026, lateAfterMinutes: 15);
    expect(repo.calls, isEmpty);
  });

  test('save بعد فشل: بيمسح الخطأ القديم', () async {
    final repo = FakeCentersRepository(mine: sampleContext());
    final cubit = CenterSettingsCubit(repo);
    await cubit.load();

    repo.failure = const Failure.permission();
    await cubit.save(name: 'أ', year: 2026, lateAfterMinutes: 15);
    expect(cubit.state.saveFailure, isNotNull);

    repo.failure = null;
    await cubit.save(name: 'أ', year: 2026, lateAfterMinutes: 15);
    expect(cubit.state.saveFailure, isNull);
    expect(cubit.state.savedTick, 1);
  });
}
