import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/auth/cubit/auth_form_cubit.dart';
import 'package:center_net/features/auth/models/account_type.dart';
import 'package:center_net/features/auth/models/register_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  const draft = RegisterDraft(
    name: 'أحمد',
    email: 'a@b.com',
    phone: '01012345678',
    password: '12345678',
  );

  Future<List<AuthFormState>> collect(
    AuthFormCubit cubit,
    Future<void> Function() action,
  ) async {
    final states = <AuthFormState>[];
    final sub = cubit.stream.listen(states.add);
    await action();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    return states;
  }

  test('login ناجح: submitting ثم success مع emailVerified', () async {
    final repo = FakeAuthRepository(verified: true);
    final cubit = AuthFormCubit(repo);
    final states = await collect(
      cubit,
      () => cubit.login(email: 'a@b.com', password: 'x'),
    );
    expect(states.map((s) => s.status),
        [AuthFormStatus.submitting, AuthFormStatus.success]);
    expect(states.last.emailVerified, isTrue);
    expect(states.last.action, AuthFormAction.login);
    expect(repo.calls, ['signIn:a@b.com']);
    await cubit.close();
  });

  test('login فاشل: failure برسالة عربية', () async {
    final repo = FakeAuthRepository(failure: const Failure.network());
    final cubit = AuthFormCubit(repo);
    final states = await collect(
      cubit,
      () => cubit.login(email: 'a@b.com', password: 'x'),
    );
    expect(states.last.status, AuthFormStatus.failure);
    expect(states.last.failure, const Failure.network());
    await cubit.close();
  });

  test('register بيبعت نوع الحساب المختار', () async {
    final repo = FakeAuthRepository();
    final cubit = AuthFormCubit(repo);
    await cubit.register(draft: draft, accountType: AccountType.guardian);
    expect(repo.calls, ['register:a@b.com:guardian']);
    expect(cubit.state.status, AuthFormStatus.success);
    expect(cubit.state.emailVerified, isFalse);
    await cubit.close();
  });

  test('checkVerified: لسه مش متأكد = success و emailVerified=false', () async {
    final cubit = AuthFormCubit(FakeAuthRepository(verified: false));
    await cubit.checkVerified();
    expect(cubit.state.action, AuthFormAction.checkVerified);
    expect(cubit.state.status, AuthFormStatus.success);
    expect(cubit.state.emailVerified, isFalse);
    await cubit.close();
  });

  test('resetPassword و resendVerification بينادوا الـ Repository', () async {
    final repo = FakeAuthRepository();
    final cubit = AuthFormCubit(repo);
    await cubit.resetPassword('a@b.com');
    await cubit.resendVerification();
    expect(repo.calls, ['reset:a@b.com', 'resend']);
    await cubit.close();
  });

  test('نداء تاني وأول واحد شغال بيتتجاهل', () async {
    final repo = FakeAuthRepository();
    final cubit = AuthFormCubit(repo);
    final first = cubit.login(email: 'a@b.com', password: 'x');
    final second = cubit.login(email: 'a@b.com', password: 'x');
    await Future.wait([first, second]);
    expect(repo.calls.length, 1);
    await cubit.close();
  });
}
