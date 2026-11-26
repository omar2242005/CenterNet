import 'group.dart';

/// بيانات الفورم لإنشاء/تعديل مجموعة، مع تحققها (نقي، من غير Firebase).
/// الحدود هنا نفس حدود `firestore.rules`، فالـ Rules مبترفضش حاجة عدّت من هنا.
class GroupInput {
  const GroupInput({
    required this.name,
    required this.teacherId,
    this.subject = '',
    this.grade = '',
    this.assistantIds = const <String>[],
    this.room = '',
    this.capacity,
    this.monthlyFee = 0,
    this.slots = const <GroupSlot>[],
  });

  static const int maxName = 80;
  static const int maxText = 60;
  static const int maxAssistants = 10;
  static const int maxSlots = 14;

  final String name;
  final String subject;
  final String grade;
  final String teacherId;
  final List<String> assistantIds;
  final String room;
  final int? capacity;

  /// بالقروش (450 ج.م = 45000).
  final int monthlyFee;
  final List<GroupSlot> slots;

  /// رسالة عربية للخطأ الأول، أو null لو كله سليم.
  String? validate() {
    final n = name.trim();
    if (n.isEmpty) return 'اكتب اسم المجموعة.';
    if (n.length > maxName) return 'اسم المجموعة طويل (الحد $maxName حرف).';
    if (subject.trim().length > maxText) return 'اسم المادة طويل.';
    if (grade.trim().length > maxText) return 'اسم الصف طويل.';
    if (room.trim().length > maxText) return 'اسم القاعة طويل.';
    if (teacherId.isEmpty) return 'اختر المعلم.';
    if (assistantIds.contains(teacherId)) {
      return 'المعلم لا يمكن أن يكون مساعدًا في نفس المجموعة.';
    }
    if (assistantIds.toSet().length > maxAssistants) {
      return 'الحد الأقصى $maxAssistants مساعدين.';
    }
    final cap = capacity;
    if (cap != null && cap < 1) return 'السعة لازم تكون 1 أو أكثر.';
    if (monthlyFee < 0) return 'السعر لا يمكن أن يكون سالبًا.';
    if (slots.length > maxSlots) return 'الحد الأقصى $maxSlots مواعيد.';
    if (_hasOverlap(slots)) return 'يوجد ميعادان متداخلان في نفس اليوم.';
    return null;
  }

  static bool _hasOverlap(List<GroupSlot> slots) {
    for (var i = 0; i < slots.length; i++) {
      for (var j = i + 1; j < slots.length; j++) {
        if (slotsOverlap(slots[i], slots[j])) return true;
      }
    }
    return false;
  }
}
