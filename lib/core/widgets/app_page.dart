import 'package:flutter/material.dart';

/// صفحة قياسية لكل الشاشات اللي بتتفتح فوق (push): Scaffold + AppBar.
///
/// الهدف إن كل الشاشات يبقى شكلها واحد: نفس شريط العنوان، ونفس الـ SafeArea،
/// ونفس زر الرجوع الافتراضي. اللي محتاج عنوان مركّب يستخدم [titleWidget].
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    this.title,
    this.titleWidget,
    required this.body,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
    this.safeArea = true,
    this.backgroundColor,
  }) : assert(
          title != null || titleWidget != null,
          'لازم title أو titleWidget',
        );

  /// عنوان الشريط (نص). لو محتاج Widget استخدم [titleWidget].
  final String? title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;

  /// true (الافتراضي): المحتوى بيتلف في SafeArea.
  final bool safeArea;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: AppBar(
        title: titleWidget ?? Text(title!),
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      body: safeArea ? SafeArea(child: body) : body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
