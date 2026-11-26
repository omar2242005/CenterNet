import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../auth_route_names.dart';
import '../repository/auth_repository.dart';

/// شاشة البداية: بتبص على المستخدم الحالي وتوجّه (الدور بيتحدد في HomeGate).
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final repo = sl<AuthRepository>();
      final String target;
      if (repo.currentUser == null) {
        target = AuthRoutes.login;
      } else if (!repo.isEmailVerified) {
        target = AuthRoutes.verifyEmail;
      } else {
        target = AuthRoutes.signedIn;
      }
      context.go(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
