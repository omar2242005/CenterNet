import 'package:center_net/app/di.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/theme/app_theme.dart';
import 'package:center_net/features/centers/repository/centers_repository.dart';
import 'package:center_net/features/centers/screens/create_center_screen.dart';
import 'package:center_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/fake_centers_repository.dart';

void main() {
  late FakeCentersRepository repo;

  setUp(() {
    repo = FakeCentersRepository();
    sl.registerSingleton<CentersRepository>(repo);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('الاسم فاضي: رسالة تحقق ومفيش نداء للـ Repository', (
    tester,
  ) async {
    await tester.pumpApp(const CreateCenterScreen(initialYear: 2026));

    await tester.tap(find.text(arL10n.centersCreateButton));
    await tester.pump();

    expect(find.text(arL10n.validationRequired), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('سنة غلط: رسالة التحقق ومفيش نداء', (tester) async {
    await tester.pumpApp(const CreateCenterScreen(initialYear: 2026));

    await tester.enterText(find.byType(TextFormField).at(0), 'مركز النور');
    await tester.enterText(find.byType(TextFormField).at(1), '26');
    await tester.tap(find.text(arL10n.centersCreateButton));
    await tester.pump();

    expect(find.text(arL10n.centersYearInvalid), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('خطأ الإنشاء بيظهر برسالة عربية', (tester) async {
    repo.failure = const Failure.alreadyExists(message: 'لديك مركز بالفعل');
    await tester.pumpApp(const CreateCenterScreen(initialYear: 2026));

    await tester.enterText(find.byType(TextFormField).at(0), 'مركز النور');
    await tester.tap(find.text(arL10n.centersCreateButton));
    await tester.pumpAndSettle();

    expect(find.text('لديك مركز بالفعل'), findsOneWidget);
    expect(repo.calls, ['create:مركز النور:2026']);
  });

  testWidgets(
    'إنشاء ناجح: بيبعت الاسم المنضّف والسنة ويرجع للشاشة اللي قبلها',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.push('/create'),
                  child: const Text('افتح'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/create',
            builder: (_, _) => const CreateCenterScreen(initialYear: 2026),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light(),
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        '  مركز   النور ',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '٢٠٢٧');
      await tester.tap(find.text(arL10n.centersCreateButton));
      await tester.pumpAndSettle();

      expect(repo.calls, ['create:مركز النور:2027']);
      // رجعنا للشاشة الأولى.
      expect(find.text('افتح'), findsOneWidget);
      expect(find.text(arL10n.centersCreateButton), findsNothing);
    },
  );
}
