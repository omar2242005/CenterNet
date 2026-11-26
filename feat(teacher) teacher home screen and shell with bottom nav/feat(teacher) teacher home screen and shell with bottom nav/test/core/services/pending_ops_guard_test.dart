import 'package:center_net/core/services/pending_ops_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('الافتراضي: الخروج مسموح', () {
    final g = PendingOpsGuard();
    expect(g.canLeave, isTrue);
    expect(g.blockReason, isNull);
  });

  test('مع معلّق: الخروج ممنوع والرسالة فيها العدد', () {
    final g = PendingOpsGuard()..setPending(10);
    expect(g.canLeave, isFalse);
    expect(g.blockReason, contains('10'));
  });

  test('لما العدد يرجع صفر الخروج يتفتح', () {
    final g = PendingOpsGuard()..setPending(3);
    g.setPending(0);
    expect(g.canLeave, isTrue);
  });

  test('الـ ValueNotifier بيبلّغ المستمعين', () {
    final g = PendingOpsGuard();
    final seen = <int>[];
    g.pending.addListener(() => seen.add(g.pending.value));
    g.setPending(2);
    g.setPending(0);
    expect(seen, [2, 0]);
  });

  test('عدد سالب مرفوض', () {
    expect(() => PendingOpsGuard().setPending(-1), throwsArgumentError);
  });
}
