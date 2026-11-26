import '../features/home/models/home_destination.dart';

/// آخر وجهة حدّدها الـ HomeGate للمستخدم الحالي (في الذاكرة بس).
/// الـ redirect بيقراها متزامنة. للتوجيه فقط، مفيش صلاحية بتيجي منها.
class SessionRole {
  HomeDestination? _value;

  HomeDestination? get value => _value;

  void set(HomeDestination destination) => _value = destination;

  void clear() => _value = null;
}
