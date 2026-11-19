import 'package:center_net/app/di.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/services/whatsapp_launcher.dart';
import 'package:center_net/features/staff/repository/staff_repository.dart';
import 'package:center_net/features/staff/screens/staff_invite_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/fake_staff_repository.dart';

void main() {
  late FakeStaffRepository repo;
  Uri? launched;

  setUp(() {
    launched = null;
    repo = FakeStaffRepository();
    sl.registerSingleton<StaffRepository>(repo);
    sl.registerSingleton<WhatsAppLauncher>(
      WhatsAppLauncher(
        launch: (uri) async {
          launched = uri;
          return true;
        },
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('فورم فاضي: بيظهر رسالة التحقق ومبينادش الـ Repository', (
    tester,
  ) async {
    await tester.pumpApp(const StaffInviteScreen());

    await tapText(tester, arL10n.staffInviteCreate);

    expect(find.text(arL10n.validationRequired), findsWidgets);
    expect(repo.calls, isEmpty);
  });

  testWidgets('موبايل غلط: بيظهر رسالة التحقق ومبينادش الـ Repository', (
    tester,
  ) async {
    await tester.pumpApp(const StaffInviteScreen());

    await tester.enterText(find.byType(TextFormField).at(0), 'سارة أحمد');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tapText(tester, arL10n.staffInviteCreate);

    expect(find.text(arL10n.validationMobileInvalid), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('نجاح بدور معلم (الافتراضي): بيعرض الكود من غير زر واتساب', (
    tester,
  ) async {
    await tester.pumpApp(const StaffInviteScreen());

    await tester.enterText(find.byType(TextFormField).at(0), 'سارة أحمد');
    await tapText(tester, arL10n.staffInviteCreate);

    expect(repo.calls, ['invite:سارة أحمد:teacher']);
    expect(find.text(FakeStaffRepository.code), findsOneWidget);
    expect(find.text(arL10n.staffInviteCopy), findsOneWidget);
    // مفيش موبايل اتكتب، فمفيش واتساب.
    expect(find.text(arL10n.staffInviteWhatsapp), findsNothing);
  });

  testWidgets('اختيار دور المساعد بيتبعت للـ Repository', (tester) async {
    await tester.pumpApp(const StaffInviteScreen());

    await tester.enterText(find.byType(TextFormField).at(0), 'سارة أحمد');
    await tapText(tester, arL10n.staffRoleAssistant);
    await tapText(tester, arL10n.staffInviteCreate);

    expect(repo.calls, ['invite:سارة أحمد:assistant']);
  });

  testWidgets('واتساب: بيفتح رابط برقم الموظف وفيه الكود', (tester) async {
    await tester.pumpApp(const StaffInviteScreen());

    await tester.enterText(find.byType(TextFormField).at(0), 'سارة أحمد');
    await tester.enterText(find.byType(TextFormField).at(1), '01012345678');
    await tapText(tester, arL10n.staffInviteCreate);
    await tapText(tester, arL10n.staffInviteWhatsapp);

    expect(launched, isNotNull);
    expect(launched.toString(), startsWith('https://wa.me/201012345678'));
    final text = Uri.decodeComponent(launched!.query);
    expect(text, contains(FakeStaffRepository.code));
    expect(text, contains('مركز النور'));
  });

  testWidgets('نسخ الكود: بيحط الكود في الـ clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpApp(const StaffInviteScreen());
    await tester.enterText(find.byType(TextFormField).at(0), 'سارة أحمد');
    await tapText(tester, arL10n.staffInviteCreate);
    await tapText(tester, arL10n.staffInviteCopy);

    expect(copied, FakeStaffRepository.code);
    expect(find.text(arL10n.staffInviteCopied), findsOneWidget);
  });

  testWidgets('إضافة موظف آخر: بيرجّع فورم فاضي', (tester) async {
    await tester.pumpApp(const StaffInviteScreen());

    await tester.enterText(find.byType(TextFormField).at(0), 'سارة أحمد');
    await tapText(tester, arL10n.staffInviteCreate);
    await tapText(tester, arL10n.staffInviteAnother);

    expect(find.text(arL10n.staffInviteCreate), findsOneWidget);
    final nameField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(0),
    );
    expect(nameField.controller?.text ?? '', isEmpty);
  });

  testWidgets('فشل: بتظهر رسالة الخطأ العربية ومفيش كود', (tester) async {
    repo.failure = const Failure.permission(message: 'غير مسموح لك بالدعوة');
    await tester.pumpApp(const StaffInviteScreen());

    await tester.enterText(find.byType(TextFormField).at(0), 'سارة أحمد');
    await tapText(tester, arL10n.staffInviteCreate);

    expect(find.text('غير مسموح لك بالدعوة'), findsOneWidget);
    expect(find.text(FakeStaffRepository.code), findsNothing);
  });
}
