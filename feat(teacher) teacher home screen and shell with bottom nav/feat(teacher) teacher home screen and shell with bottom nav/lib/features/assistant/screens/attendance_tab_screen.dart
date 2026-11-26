import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../../core/widgets/async_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../sessions/models/session.dart';
import '../assistant_route_names.dart';
import '../models/session_time_status.dart';
import '../repository/assistant_repository.dart';
import '../widgets/assistant_shell.dart';

/// تبويب "الحضور" في شريط التنقل السفلي: قائمة الحضور مربوطة بجلسة، فالتبويب
/// بيحوّل لحصة النهارده الجارية (أو آخر حصة بدأت لو مفيش جارية). مفيش حصص
/// النهارده = حالة فاضية.
class AttendanceTabScreen extends StatefulWidget {
  const AttendanceTabScreen({super.key});

  @override
  State<AttendanceTabScreen> createState() => _AttendanceTabScreenState();
}

class _AttendanceTabScreenState extends State<AttendanceTabScreen> {
  ViewState<List<Session>> _state = const ViewLoading();

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    setState(() => _state = const ViewLoading());
    try {
      final sessions = await sl<AssistantRepository>().todaySessions();
      if (!mounted) return;
      final target = _pick(sessions, DateTime.now());
      if (target == null) {
        setState(() => _state = const ViewEmpty());
        return;
      }
      // التحويل بيبدل التبويب بشاشة قائمة حضور الجلسة المختارة.
      context.go('/${AssistantRouteNames.sessions}/${target.id}/attendance');
    } on Failure catch (failure) {
      if (mounted) setState(() => _state = ViewFailed(failure));
    }
  }

  /// الحصة الجارية أولًا؛ لو مفيش، آخر حصة بدأت النهارده؛ لو لسه مفيش
  /// ولا حصة بدأت، أول حصة جاية. null لو مفيش حصص أصلًا.
  static Session? _pick(List<Session> sessions, DateTime now) {
    if (sessions.isEmpty) return null;
    for (final session in sessions) {
      if (sessionTimeStatus(session, now) == SessionTimeStatus.current) {
        return session;
      }
    }
    final started = sessions
        .where((s) => !s.startAt.isAfter(now))
        .toList();
    if (started.isNotEmpty) return started.last;
    return sessions.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AssistantShell(
      current: AssistantTab.attendance,
      title: l10n.assistantNavAttendance,
      body: AsyncView<List<Session>>(
        state: _state,
        onRetry: _open,
        emptyMessage: l10n.assistantAttendanceNoSessions,
        builder: (context, _) => const SizedBox.shrink(),
      ),
    );
  }
}
