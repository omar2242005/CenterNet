/// أنواع الفشل اللي الواجهة بتفرّق بينها.
enum FailureType {
  network,
  permission,
  notFound,
  alreadyExists,
  validation,
  unknown,
}

/// خطأ جاهز للعرض. الـ Repository هو اللي بيحوّل أي استثناء لـ [Failure]،
/// فالـ Cubit والشاشة عمرهم ما يشوفوا FirebaseException.
///
/// [message] دايمًا عربي ومناسب للمستخدم. [code] الكود الأصلي للتسجيل
/// والتشخيص فقط، ومتتعرضش للمستخدم.
class Failure implements Exception {
  final FailureType type;
  final String message;
  final String? code;

  const Failure(this.type, this.message, {this.code});

  const Failure.network({String? message, this.code})
      : type = FailureType.network,
        message = message ?? 'لا يوجد اتصال بالإنترنت. تأكد من الشبكة وحاول مرة أخرى.';

  const Failure.permission({String? message, this.code})
      : type = FailureType.permission,
        message = message ?? 'غير مسموح لك بتنفيذ هذه العملية.';

  const Failure.notFound({String? message, this.code})
      : type = FailureType.notFound,
        message = message ?? 'لم يتم العثور على البيانات المطلوبة.';

  const Failure.alreadyExists({String? message, this.code})
      : type = FailureType.alreadyExists,
        message = message ?? 'هذه البيانات موجودة بالفعل.';

  /// رسالة التحقق خاصة بكل حالة، فهي إلزامية.
  const Failure.validation(this.message, {this.code})
      : type = FailureType.validation;

  const Failure.unknown({String? message, this.code})
      : type = FailureType.unknown,
        message = message ?? 'حدث خطأ غير متوقع. حاول مرة أخرى.';

  @override
  bool operator ==(Object other) =>
      other is Failure &&
      other.type == type &&
      other.message == message &&
      other.code == code;

  @override
  int get hashCode => Object.hash(type, message, code);

  @override
  String toString() => 'Failure($type, $message, code: $code)';
}
