import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/sessions/models/session.dart';
import 'package:center_net/features/sessions/repository/sessions_repository.dart';

class FakeSessionsRepository implements SessionsRepository {
  FakeSessionsRepository({List<Session>? sessions, this.failure})
      : sessions = sessions ?? <Session>[];

  /// الحصص اللي [loadGroupSessions] بترجّعها.
  final List<Session> sessions;

  /// بيفشّل أي عملية.
  Failure? failure;

  /// نتيجة [generateUpcoming] عند النجاح.
  GenerateResult generateResult = (created: 0, skipped: 0);

  /// بيفشّل المسح النهائي بس (مثلًا: الحصة عليها حضور).
  Failure? deleteFailure;

  final List<String> calls = <String>[];

  void _maybeFail() {
    final f = failure;
    if (f != null) throw f;
  }

  @override
  Future<GenerateResult> generateUpcoming(
    Group group, {
    int weeks = 4,
    DateTime? now,
  }) async {
    calls.add('generate');
    _maybeFail();
    return generateResult;
  }

  @override
  Future<List<Session>> loadGroupSessions(Group group, {DateTime? from}) async {
    calls.add('load');
    _maybeFail();
    return List<Session>.of(sessions);
  }

  @override
  Future<Session> cancelSession(Session session) async {
    calls.add('cancel:${session.id}');
    _maybeFail();
    return Session.fromMap(session.id, <String, dynamic>{
      ...session.toCreateMap(createdAt: DateTime(2026)),
      'status': 'cancelled',
    });
  }

  @override
  Future<void> deleteCancelledSession(Session session) async {
    calls.add('delete:${session.id}');
    _maybeFail();
    final f = deleteFailure;
    if (f != null) throw f;
    sessions.removeWhere((s) => s.id == session.id);
  }
}
