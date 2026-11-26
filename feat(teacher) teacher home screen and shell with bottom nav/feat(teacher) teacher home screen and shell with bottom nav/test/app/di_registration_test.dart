import 'package:center_net/app/di.dart';
import 'package:center_net/app/router.dart';
import 'package:center_net/core/services/local_store.dart';
import 'package:center_net/features/assistant/repository/assistant_repository.dart';
import 'package:center_net/features/auth/repository/auth_repository.dart';
import 'package:center_net/features/linking/link_route_names.dart';
import 'package:center_net/features/linking/repository/linking_repository.dart';
import 'package:center_net/features/student_area/child_route_names.dart';
import 'package:center_net/features/student_area/repository/student_data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// رجرشن: سطر كل feature في di.dart و router.dart لازم يفضل موجود.
/// (غياب registerLinking كسر رئيسية الطالب بـ GetIt not registered.)
void main() {
  test('configureDependencies بيسجّل repositories كل الـ features', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = await LocalStore.open();
    final g = GetIt.asNewInstance();
    configureDependencies(store, g);

    expect(g.isRegistered<AuthRepository>(), isTrue);
    expect(g.isRegistered<AssistantRepository>(), isTrue);
    expect(g.isRegistered<LinkingRepository>(), isTrue);
    expect(g.isRegistered<StudentDataRepository>(), isTrue);
  });

  test('featureRoutes فيها مسارات الربط ومنطقة الطالب', () {
    final paths = featureRoutes.whereType<GoRoute>().map((r) => r.path);
    expect(paths, contains(LinkRoutes.enter));
    expect(paths, contains(ChildRoutes.schedule));
    expect(paths, contains(ChildRoutes.attendance));
    expect(paths, contains(ChildRoutes.results));
  });
}
