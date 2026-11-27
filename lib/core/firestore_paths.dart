/// المكان الوحيد اللي بتتكتب فيه مسارات Firestore وصيغ الـ IDs.
/// أي صيغة مكتوبة في مكان تاني = غلط (قاعدة 7 في شجرة الخطوات).
///
/// قرارات المسارات (لازم الـ firestore.rules تمشي عليها):
///  - users و inviteCodes على مستوى الجذر.
///  - كل حاجة تانية تحت: centers/{c}/...
///    وده معناه إن studentLinks كمان تحت السنتر: centers/{c}/studentLinks/{uid_sid}
///    (عشان الـ Rules تعرف c من المسار من غير ما تقرا users.centerId).
///  - مفيش أي ملف تاني يكتب 'centers/...' نصًا، كله من هنا.
///
/// الـ IDs حتمية (من نفس المدخلات تطلع نفس النتيجة) عشان منع التكرار من غير كود
/// إضافي، والفاصل `_` آمن لأن أي معرّف جوّا الـ ID لازم يكون حروف وأرقام بس.
library;

final RegExp _alnum = RegExp(r'^[A-Za-z0-9]+$');

/// بيرمي ArgumentError لو القيمة فاضية أو فيها غير حروف/أرقام ASCII.
/// ده اللي بيضمن إن `_` و `:` مش ممكن يظهروا جوه جزء من ID فيتلخبط الفصل بينهم.
String _part(String value, String name) {
  if (!_alnum.hasMatch(value)) {
    throw ArgumentError.value(
      value,
      name,
      'لازم يكون حروف إنجليزية وأرقام بس (من غير _ أو : أو مسافات)',
    );
  }
  return value;
}

String _pad(int n, int width) => n.toString().padLeft(width, '0');

/// مسارات المستندات والمجموعات (بدون `/` في الأول).
abstract final class FirestorePaths {
  // الجذر
  static const String users = 'users';
  static const String inviteCodes = 'inviteCodes';
  static const String centers = 'centers';

  static String user(String uid) => '$users/${_part(uid, 'uid')}';
  static String inviteCode(String code) =>
      '$inviteCodes/${_part(code, 'code')}';
  static String center(String centerId) =>
      '$centers/${_part(centerId, 'centerId')}';

  // تحت السنتر
  static String members(String centerId) => '${center(centerId)}/members';
  static String member(String centerId, String uid) =>
      '${members(centerId)}/${_part(uid, 'uid')}';

  static String students(String centerId) => '${center(centerId)}/students';
  static String student(String centerId, String studentId) =>
      '${students(centerId)}/${_part(studentId, 'studentId')}';

  /// عدّاد الرقم التسلسلي للطلاب: مستند واحد `{next: int}` بيتحدّث في نفس
  /// الـ Transaction بتاعة إضافة الطالب (خطوة 3.1).
  static String studentCounter(String centerId) =>
      '${center(centerId)}/counters/students';

  static String studentLinks(String centerId) =>
      '${center(centerId)}/studentLinks';
  static String studentLink(String centerId, String uid, String studentId) =>
      '${studentLinks(centerId)}/${FirestoreIds.studentLink(uid, studentId)}';

  /// طلبات الربط (الطالب/ولي الأمر يطلب من الأدمن): `uid_studentNo`.
  static String linkRequests(String centerId) =>
      '${center(centerId)}/linkRequests';
  static String linkRequest(String centerId, String uid, int studentNo) =>
      '${linkRequests(centerId)}/${FirestoreIds.linkRequest(uid, studentNo)}';

  /// عدّاد أولياء الأمور النشطين للطالب (حد أقصى 4): `{count: int}`.
  static String guardianCount(String centerId, String studentId) =>
      '${center(centerId)}/guardianCounts/${_part(studentId, 'studentId')}';

  /// عدّاد ربط المستخدم النشط: `{count: int, sid: String}`.
  static String linkedUser(String centerId, String uid) =>
      '${center(centerId)}/linkedUsers/${_part(uid, 'uid')}';

  static String groups(String centerId) => '${center(centerId)}/groups';
  static String group(String centerId, String groupId) =>
      '${groups(centerId)}/${_part(groupId, 'groupId')}';

  static String sessions(String centerId) => '${center(centerId)}/sessions';
  static String session(String centerId, String sessionId) =>
      '${sessions(centerId)}/${_composite(sessionId, 'sessionId')}';

  static String attendance(String centerId) =>
      '${center(centerId)}/attendance';
  static String attendanceDoc(String centerId, String attendanceId) =>
      '${attendance(centerId)}/${_composite(attendanceId, 'attendanceId')}';

  static String exams(String centerId) => '${center(centerId)}/exams';
  static String exam(String centerId, String examId) =>
      '${exams(centerId)}/${_part(examId, 'examId')}';

  static String scores(String centerId) => '${center(centerId)}/scores';
  static String score(String centerId, String scoreId) =>
      '${scores(centerId)}/${_composite(scoreId, 'scoreId')}';

  // P1
  static String payments(String centerId) => '${center(centerId)}/payments';
  static String payment(String centerId, String paymentId) =>
      '${payments(centerId)}/${_composite(paymentId, 'paymentId')}';
}

/// بيقبل ID مركّب (حروف وأرقام و `_`) بس من غير فواصل غريبة. بنستخدمه لما
/// الـ ID جاهز أصلًا من FirestoreIds.
String _composite(String value, String name) {
  if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(value)) {
    throw ArgumentError.value(value, name, 'ID غير صالح');
  }
  return value;
}

/// صيغ الـ IDs الحتمية.
abstract final class FirestoreIds {
  /// جلسة: `gid_yyyyMMdd_HHmm` بتوقيت القاهرة.
  /// مثال: `g1_20261119_1700`
  ///
  /// [cairoStart] لازم يكون وقت الحائط (wall-clock) بتوقيت القاهرة، يعني
  /// `TZDateTime` من حزمة timezone بموقع Africa/Cairo. الدالة بتقرا مكوّناته
  /// (سنة/شهر/يوم/ساعة/دقيقة) كما هي من غير أي تحويل. لو اتبعت `DateTime.utc`
  /// بترمي ArgumentError عشان الـ ID ميتحسبش غلط بفرق 2 أو 3 ساعات.
  static String session(String groupId, DateTime cairoStart) {
    if (cairoStart.isUtc) {
      throw ArgumentError.value(
        cairoStart,
        'cairoStart',
        'لازم وقت بتوقيت القاهرة، مش UTC',
      );
    }
    final d = '${_pad(cairoStart.year, 4)}${_pad(cairoStart.month, 2)}'
        '${_pad(cairoStart.day, 2)}';
    final t = '${_pad(cairoStart.hour, 2)}${_pad(cairoStart.minute, 2)}';
    return '${_part(groupId, 'groupId')}_${d}_$t';
  }

  /// حضور: `sessionId_sid`
  /// مثال: `g1_20261119_1700_s7`
  static String attendance(String sessionId, String studentId) =>
      '${_composite(sessionId, 'sessionId')}_${_part(studentId, 'studentId')}';

  /// درجة: `examId_sid`
  /// مثال: `e1_s7`
  static String score(String examId, String studentId) =>
      '${_part(examId, 'examId')}_${_part(studentId, 'studentId')}';

  /// ربط حساب بطالب: `uid_sid`
  /// مثال: `u9_s7`
  static String studentLink(String uid, String studentId) =>
      '${_part(uid, 'uid')}_${_part(studentId, 'studentId')}';

  /// طلب ربط: `uid_studentNo`
  /// مثال: `u9_7`
  static String linkRequest(String uid, int studentNo) =>
      '${_part(uid, 'uid')}_$studentNo';

  /// دفع (P1): `sid_gid_yyyyMM`
  /// مثال: `s7_g1_202611`
  static String payment(String studentId, String groupId, int year, int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'الشهر من 1 لـ 12');
    }
    return '${_part(studentId, 'studentId')}_${_part(groupId, 'groupId')}'
        '_${_pad(year, 4)}${_pad(month, 2)}';
  }

  /// نص الـ QR: `centerId:studentId` (ASCII ثابت، هدفه تعريف الطالب بس).
  /// مثال: `c1:s7`
  static String qr(String centerId, String studentId) =>
      '${_part(centerId, 'centerId')}:${_part(studentId, 'studentId')}';

  /// عكس [qr]. بيرجّع null لو النص مش بالصيغة بالظبط (حالة "رمز غير صالح"
  /// في ScanValidator). صارم: من غير trim، وجزءين بس، وكل جزء حروف وأرقام.
  static ({String centerId, String studentId})? tryParseQr(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final c = parts[0];
    final s = parts[1];
    if (!_alnum.hasMatch(c) || !_alnum.hasMatch(s)) return null;
    return (centerId: c, studentId: s);
  }
}
