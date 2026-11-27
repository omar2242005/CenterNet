import '../../../l10n/app_localizations.dart';
import '../../grades/grade_format.dart';
import '../../grades/models/score.dart';
import '../models/child_data.dart';

/// نص درجة الطالب في امتحان: "8 من 10" أو غائب أو معفى أو لسه.
String resultScoreText(AppLocalizations l10n, ExamResult r) {
  final s = r.score;
  if (s == null) return l10n.resultsPending;
  return switch (s.state) {
    ScoreState.scored => l10n.resultsScoreOf(
        fmtScore(s.score ?? 0),
        fmtScore(r.exam.maxScore),
      ),
    ScoreState.absent => l10n.resultsAbsent,
    ScoreState.excused => l10n.resultsExcused,
  };
}
