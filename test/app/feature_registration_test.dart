import 'package:center_net/app/app.dart';
import 'package:center_net/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// feature تجريبية: Repository + شاشة بتقراه من الـ DI.
class _DemoRepository {
  String hello() => 'مرحبا من الـ DI';
}

// ===== بيثبت إن الـ feature بتتسجل بسطرين =====
// سطر DI:      g.registerLazySingleton<_DemoRepository>(_DemoRepository.new);
// سطر router:  GoRoute(path: '/demo', builder: ...)

void main() {
  testWidgets('feature تجريبية بتتسجل بسطرين (DI + router) وتشتغل', (
    tester,
  ) async {
    final g = GetIt.asNewInstance();
    g.registerLazySingleton<_DemoRepository>(_DemoRepository.new);

    final router = buildRouter(
      routes: [
        GoRoute(
          path: '/demo',
          builder: (_, _) =>
              Scaffold(body: Center(child: Text(g<_DemoRepository>().hello()))),
        ),
      ],
      initialLocation: '/demo',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(CenterNetApp(router: router));
    await tester.pumpAndSettle();

    expect(find.text('مرحبا من الـ DI'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(Scaffold))),
        TextDirection.rtl);
  });
}
