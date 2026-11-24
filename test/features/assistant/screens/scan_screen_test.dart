import 'package:center_net/features/assistant/models/scan_setup.dart';
import 'package:center_net/features/assistant/screens/scan_screen.dart';
import 'package:center_net/features/assistant/services/scan_recorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  late MemoryScanRecorder recorder;
  late ValueChanged<String> sendCode;

  ScanSetup setup() => ScanSetup(
        centerId: 'c1',
        sessionId: 'g1_20261120_1700',
        sessionStart: DateTime.now().subtract(const Duration(minutes: 1)),
        groupStudentIds: {'s1', 's2'},
      );

  Future<void> open(WidgetTester tester) async {
    recorder = MemoryScanRecorder();
    await tester.pumpApp(
      ScanScreen(
        setup: setup(),
        recorder: recorder,
        showManualEntry: true,
        // كاميرا وهمية: بنخزّن الـ callback ونستدعيه بإيدينا.
        cameraBuilder: (context, onCode) {
          sendCode = onCode;
          return const SizedBox.expand();
        },
      ),
    );
    await tester.pump();
  }

  testWidgets('بيبدأ بحالة الانتظار', (tester) async {
    await open(tester);
    expect(find.text(arL10n.scanWaiting), findsOneWidget);
  });

  testWidgets('رمز صالح من الكاميرا بيظهر رسالة نجاح والعدّاد', (tester) async {
    await open(tester);

    sendCode('c1:s1');
    await tester.pumpAndSettle();

    expect(find.text(arL10n.scanRecordedPresent('s1')), findsOneWidget);
    expect(find.text(arL10n.scanCountPresent(1)), findsOneWidget);
    expect(recorder.scans, hasLength(1));
  });

  testWidgets('رمز سنتر تاني بيظهر رفض', (tester) async {
    await open(tester);

    sendCode('c2:s1');
    await tester.pumpAndSettle();

    expect(find.text(arL10n.scanOtherCenter), findsOneWidget);
    expect(find.text(arL10n.scanCountRejected(1)), findsOneWidget);
    expect(recorder.scans, isEmpty);
  });

  testWidgets('الإدخال اليدوي بيشتغل زي الكاميرا', (tester) async {
    await open(tester);

    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'garbage');
    await tester.ensureVisible(find.text(arL10n.scanManualSubmit));
    await tester.tap(find.text(arL10n.scanManualSubmit));
    await tester.pump();

    expect(find.text(arL10n.scanInvalidCode), findsOneWidget);
  });
}
