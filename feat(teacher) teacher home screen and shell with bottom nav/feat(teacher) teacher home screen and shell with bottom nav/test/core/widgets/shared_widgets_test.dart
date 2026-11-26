import 'package:center_net/core/theme/app_colors.dart';
import 'package:center_net/core/widgets/app_button.dart';
import 'package:center_net/core/widgets/app_card.dart';
import 'package:center_net/core/widgets/app_text_field.dart';
import 'package:center_net/core/widgets/confirm_dialog.dart';
import 'package:center_net/core/widgets/qr_card.dart';
import 'package:center_net/core/widgets/search_field.dart';
import 'package:center_net/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppButton', () {
    testWidgets('بينفّذ onPressed', (tester) async {
      var taps = 0;
      await tester.pumpApp(AppButton(label: 'حفظ', onPressed: () => taps++));
      await tester.tap(find.text('حفظ'));
      expect(taps, 1);
    });

    testWidgets('onPressed = null: معطّل', (tester) async {
      await tester.pumpApp(const AppButton(label: 'حفظ', onPressed: null));
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('تحميل: مؤشر ظاهر والضغط متجاهل', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        AppButton(label: 'حفظ', isLoading: true, onPressed: () => taps++),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('حفظ'));
      expect(taps, 0);
    });

    testWidgets('الارتفاع 48 على الأقل', (tester) async {
      await tester.pumpApp(AppButton(label: 'حفظ', onPressed: () {}));
      final size = tester.getSize(find.byType(FilledButton));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('كل الأنواع بتترسم', (tester) async {
      for (final v in AppButtonVariant.values) {
        await tester.pumpApp(
          AppButton(label: 'زر', variant: v, onPressed: () {}),
        );
        expect(find.text('زر'), findsOneWidget, reason: '$v');
      }
    });
  });

  testWidgets('AppCard: onTap', (tester) async {
    var taps = 0;
    await tester.pumpApp(
      AppCard(onTap: () => taps++, child: const Text('كارت')),
    );
    await tester.tap(find.text('كارت'));
    expect(taps, 1);
  });

  group('AppTextField', () {
    testWidgets('بيعرض الـ label ورسالة الـ validator', (tester) async {
      final key = GlobalKey<FormState>();
      await tester.pumpApp(
        Form(
          key: key,
          child: AppTextField(
            label: 'الاسم',
            validator: (v) => (v ?? '').isEmpty ? 'مطلوب' : null,
          ),
        ),
      );
      expect(find.text('الاسم'), findsOneWidget);
      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('مطلوب'), findsOneWidget);
    });

    testWidgets('كلمة السر: زر إظهار/إخفاء', (tester) async {
      await tester.pumpApp(const AppTextField(label: 'كلمة السر', obscureText: true));
      EditableText editable() => tester.widget<EditableText>(find.byType(EditableText));
      expect(editable().obscureText, isTrue);
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(editable().obscureText, isFalse);
    });

    testWidgets('latinDigits: الأرقام الهندية بتتحول', (tester) async {
      final c = TextEditingController();
      addTearDown(c.dispose);
      await tester.pumpApp(
        AppTextField(controller: c, latinDigits: true, keyboardType: TextInputType.phone),
      );
      await tester.enterText(find.byType(TextField), '٠١٠١٢٣');
      expect(c.text, '010123');
    });
  });

  group('SearchField', () {
    testWidgets('بيبعت النص وزر المسح بيفضّي', (tester) async {
      final changes = <String>[];
      await tester.pumpApp(SearchField(onChanged: changes.add));
      expect(find.text(arL10n.searchHint), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);

      await tester.enterText(find.byType(TextField), 'احمد');
      await tester.pump();
      expect(changes.last, 'احمد');
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(changes.last, '');
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('showConfirmDialog', () {
    // بيفتح النافذة وبيرجّع قائمة بتتملي بنتيجتها بعد ما المستخدم يضغط.
    Future<List<bool>> open(WidgetTester tester, {bool destructive = false}) async {
      final results = <bool>[];
      await tester.pumpApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(
                await showConfirmDialog(
                  context,
                  title: 'إلغاء الحضور',
                  message: 'متأكد؟',
                  destructive: destructive,
                ),
              );
            },
            child: const Text('افتح'),
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      expect(find.text('إلغاء الحضور'), findsOneWidget);
      return results;
    }

    testWidgets('تأكيد ← true', (tester) async {
      final results = await open(tester);
      await tester.tap(find.text(arL10n.confirm));
      await tester.pumpAndSettle();
      expect(results, [true]);
      expect(find.text('إلغاء الحضور'), findsNothing);
    });

    testWidgets('إلغاء ← false', (tester) async {
      final results = await open(tester, destructive: true);
      await tester.tap(find.text(arL10n.cancel));
      await tester.pumpAndSettle();
      expect(results, [false]);
      expect(find.text('إلغاء الحضور'), findsNothing);
    });
  });

  testWidgets('StatusBadge: النص والأيقونة', (tester) async {
    await tester.pumpApp(
      const StatusBadge(label: 'حاضر', tone: StatusTone.success, icon: Icons.check),
    );
    expect(find.text('حاضر'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    final text = tester.widget<Text>(find.text('حاضر'));
    expect(text.style?.color, AppColors.onSuccessContainer);
  });

  testWidgets('QrCard: الاسم والرقم والـ footer', (tester) async {
    await tester.pumpApp(
      const SingleChildScrollView(
        child: QrCard(
          data: 'student1:center1',
          title: 'أحمد علي',
          subtitle: '1001',
          footer: Text('مشاركة'),
        ),
      ),
    );
    expect(find.text('أحمد علي'), findsOneWidget);
    expect(find.text('1001'), findsOneWidget);
    expect(find.text('مشاركة'), findsOneWidget);
  });
}
