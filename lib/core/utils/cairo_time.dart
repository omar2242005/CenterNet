import 'package:timezone/timezone.dart' as tz;

/// بيحوّل لحظة زمنية (Timestamp من Firestore) لوقت حائط بتوقيت القاهرة
/// للعرض، زي ما `core/utils/formatters.dart` متوقّع من الـ caller.
DateTime toCairoWallTime(DateTime instant) =>
    tz.TZDateTime.from(instant, tz.getLocation('Africa/Cairo'));
