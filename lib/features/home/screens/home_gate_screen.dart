import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/session_role.dart';
import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/async_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/sign_out_action.dart';
import '../home_route_names.dart';
import '../repository/role_repository.dart';

/// نقطة الدخول بعد تسجيل الدخول: بتحدد الدور وتوجّه للرئيسية المناسبة.
/// لو فشل التحديد (نت مثلًا) بتعرض الخطأ مع إعادة محاولة وتسجيل خروج.
class HomeGateScreen extends StatefulWidget {
  const HomeGateScreen({super.key});

  @override
  State<HomeGateScreen> createState() => _HomeGateScreenState();
}

class _HomeGateScreenState extends State<HomeGateScreen> {
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    if (_failure != null) setState(() => _failure = null);
    try {
      final destination = await sl<RoleRepository>().resolve();
      if (!mounted) return;
      sl<SessionRole>().set(destination);
      context.go(HomeRoutes.forDestination(destination));
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _failure = f);
    }
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    if (failure == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AsyncView<void>(
                state: ViewFailed<void>(failure),
                onRetry: _resolve,
                builder: (_, _) => const SizedBox.shrink(),
              ),
            ),
            Padding(
              padding: AppSpacing.screenPadding,
              child: AppButton(
                label: l10n.authSignOut,
                variant: AppButtonVariant.secondary,
                onPressed: () => confirmAndSignOut(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
