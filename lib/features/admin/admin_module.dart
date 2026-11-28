import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../centers/center_route_names.dart';
import '../grades/grade_route_names.dart';
import '../groups/group_route_names.dart';
import '../groups/models/group.dart';
import '../linking/link_route_names.dart';
import '../linking/models/invite_code.dart';
import '../payments/payment_route_names.dart';
import '../staff/staff_route_names.dart';
import '../students/models/student.dart';
import '../students/student_route_names.dart';
import 'screens/center_settings_screen.dart';
import 'screens/exams_list_screen.dart';
import 'screens/group_enrollment_screen.dart';
import 'screens/group_sessions_screen.dart';
import 'screens/groups_list_screen.dart';
import 'screens/link_requests_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/scores_entry_screen.dart';
import 'screens/staff_invite_screen.dart';
import 'screens/staff_list_screen.dart';
import 'screens/student_detail_screen.dart';
import 'screens/student_form_screen.dart';
import 'screens/students_list_screen.dart';

/// الـ DI: مفيش حاجة خاصة بالأدمن. كل الـ repositories والـ cubits اللي
/// الشاشات دي بتستخدمها مشتركة، وبتتسجل في الـ features بتاعتها
/// (students / groups / staff / centers / linking / payments / grades).
/// الملف ده مسؤول عن مسارات شاشات الأدمن بس، عشان الـ features المشتركة
/// ما تحتاجش تعرف حاجة عن فولدر الدور.
///
/// المسارات نفسها ما اتغيرتش: الأسماء في ملفات *_route_names زي ما هي.

/// سطر الـ router بتاع الأدمن.
final List<RouteBase> adminRoutes = <RouteBase>[
  // الطلاب.
  GoRoute(
    path: StudentRoutes.list,
    builder: (context, state) => const StudentsListScreen(),
  ),
  GoRoute(
    path: StudentRoutes.create,
    builder: (context, state) => const StudentFormScreen(),
  ),
  GoRoute(
    path: StudentRoutes.detail,
    redirect: (context, state) =>
        state.extra is Student ? null : StudentRoutes.list,
    builder: (context, state) =>
        StudentDetailScreen(student: state.extra! as Student),
  ),
  GoRoute(
    path: StudentRoutes.edit,
    redirect: (context, state) =>
        state.extra is Student ? null : StudentRoutes.list,
    builder: (context, state) =>
        StudentFormScreen(editing: state.extra! as Student),
  ),
  // المجموعات (الفورم مشترك مع المعلم، ومساره في groups_module).
  GoRoute(
    path: GroupRoutes.list,
    builder: (context, state) => const GroupsListScreen(),
  ),
  GoRoute(
    path: GroupRoutes.students,
    redirect: (context, state) =>
        state.extra is Group ? null : GroupRoutes.list,
    builder: (context, state) =>
        GroupEnrollmentScreen(group: state.extra! as Group),
  ),
  GoRoute(
    path: GroupRoutes.sessions,
    redirect: (context, state) =>
        state.extra is Group ? null : GroupRoutes.list,
    builder: (context, state) =>
        GroupSessionsScreen(group: state.extra! as Group),
  ),
  // الفريق (شاشة الانضمام مشتركة، ومسارها في staff_module).
  GoRoute(
    path: StaffRoutes.list,
    builder: (context, state) => const StaffListScreen(),
  ),
  GoRoute(
    path: StaffRoutes.inviteTeacher,
    builder: (context, state) =>
        const StaffInviteScreen(role: StaffInviteRole.teacher),
  ),
  GoRoute(
    path: StaffRoutes.inviteAssistant,
    builder: (context, state) =>
        const StaffInviteScreen(role: StaffInviteRole.assistant),
  ),
  // إعدادات السنتر (إنشاء السنتر مشترك، ومساره في centers_module).
  GoRoute(
    path: CenterRoutes.settings,
    builder: (context, state) => const CenterSettingsScreen(),
  ),
  // طلبات الربط (إدخال الكود والطلب نفسهم مشتركين مع الطالب/ولي الأمر).
  GoRoute(
    path: LinkRoutes.requests,
    builder: (context, state) => const LinkRequestsScreen(),
  ),
  // المدفوعات.
  GoRoute(
    path: PaymentRoutes.list,
    builder: (context, state) => const PaymentsScreen(),
  ),
  // الامتحانات (فورم الامتحان مشترك مع المعلم، ومساره في grades_module).
  GoRoute(
    path: GradeRoutes.exams,
    builder: (context, state) {
      final group = state.extra;
      if (group is! Group) return const _MissingArgs();
      return ExamsListScreen(group: group);
    },
  ),
  GoRoute(
    path: GradeRoutes.scores,
    builder: (context, state) {
      final args = state.extra;
      if (args is! ExamScoresArgs) return const _MissingArgs();
      return ScoresEntryScreen(group: args.group, exam: args.exam);
    },
  ),
];

/// لو الشاشة اتفتحت من غير البيانات (مثلًا refresh على الويب).
class _MissingArgs extends StatelessWidget {
  const _MissingArgs();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: SizedBox.shrink());
}
