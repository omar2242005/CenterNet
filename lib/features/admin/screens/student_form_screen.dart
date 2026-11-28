import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validation_text.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../students/cubit/student_form_cubit.dart';
import '../../students/models/student.dart';
import '../../students/repository/students_repository.dart';
import '../../../core/widgets/app_page.dart';

/// إضافة طالب جديد، أو تعديل بيانات [editing]. بيرجّع الطالب المحفوظ بـ pop.
class StudentFormScreen extends StatelessWidget {
  const StudentFormScreen({super.key, this.editing});

  final Student? editing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          StudentFormCubit(sl<StudentsRepository>(), editing: editing),
      child: _StudentFormView(editing: editing),
    );
  }
}

class _StudentFormView extends StatefulWidget {
  const _StudentFormView({this.editing});

  final Student? editing;

  @override
  State<_StudentFormView> createState() => _StudentFormViewState();
}

class _StudentFormViewState extends State<_StudentFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.editing?.fullName ?? '',
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.editing?.phone ?? '',
  );
  late final TextEditingController _grade = TextEditingController(
    text: widget.editing?.grade ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _grade.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<StudentFormCubit>().submit(
      fullName: _name.text,
      phone: _phone.text,
      grade: _grade.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.editing != null;

    return AppPage(
      title: isEdit ? l10n.studentsEditTitle : l10n.studentsAddTitle,
      body: BlocConsumer<StudentFormCubit, StudentFormState>(
        listener: (context, state) {
          if (state.status == StudentFormStatus.success) {
            context.pop<Student>(state.saved);
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                AppTextField(
                  controller: _name,
                  label: l10n.studentFieldName,
                  textInputAction: TextInputAction.next,
                  enabled: !state.isSubmitting,
                  validator: (v) => Validators.name(v ?? '')?.message(l10n),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _phone,
                  label: l10n.studentFieldPhone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  isLtr: true,
                  latinDigits: true,
                  enabled: !state.isSubmitting,
                  validator: (v) => Validators.mobile(v ?? '')?.message(l10n),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _grade,
                  label: l10n.studentFieldGrade,
                  textInputAction: TextInputAction.done,
                  enabled: !state.isSubmitting,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (state.status == StudentFormStatus.failure &&
                    state.failure != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      state.failure!.message,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.error),
                    ),
                  ),
                AppButton(
                  label: l10n.studentSave,
                  isLoading: state.isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
