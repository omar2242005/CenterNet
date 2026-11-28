import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'repository/attendance_repository.dart';
import 'repository/firestore_attendance_repository.dart';

/// سطر الـ DI بتاع الـ attendance module.
///
/// الحضور مشترك بين الأدوار، فمفيش مسارات (routes) هنا: كل دور بيركّب
/// شاشاته تحت مساره (المساعد مثلًا تحت `/assistant`).
void registerAttendance(GetIt g) {
  g.registerLazySingleton<AttendanceRepository>(
    () => FirestoreAttendanceRepository(
      g<FirebaseAuth>(),
      g<FirebaseFirestore>(),
    ),
  );
}
