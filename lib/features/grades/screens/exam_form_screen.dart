import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/models/group.dart';
import '../cubit/exam_form_cubit.dart';
import '../grade_format.dart';
import '../repositories/exams_repository.dart';
import '../../../core/widgets/app_page.dart';

/// إنشاء امتحان جديد (بيتعمل مسودة).
class ExamFormScreen extends StatelessWidget {
  const ExamFormScreen({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExamFormCubit(sl<ExamsRepository>(), group),
      child: const _ExamFormView(),
    );
  }
}

class _ExamFormView extends StatefulWidget {
  const _ExamFormView();

  @override
  State<_ExamFormView> createState() => _ExamFormViewState();
}

class _ExamFormViewState extends State<_ExamFormView> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _max = TextEditingController(text: '100');
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ExamFormCubit>().submit(
      title: _title.text,
      date: _date,
      maxScore: double.parse(_max.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppPage(
      title: l10n.examAddTitle,
      body: BlocConsumer<ExamFormCubit, ExamFormState>(
        listener: (context, state) {
          if (state.status == ExamFormStatus.success) {
            context.pop(state.saved);
          } else if (state.status == ExamFormStatus.failure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(failureText(state.failure))));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _title,
                    label: l10n.examFieldTitle,
                    maxLength: 120,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? l10n.validationRequired
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _max,
                    label: l10n.examFieldMax,
                    isLtr: true,
                    latinDigits: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').trim());
                      return (n == null || !n.isFinite || n <= 0)
                          ? l10n.examMaxInvalid
                          : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: fmtDate(l10n, _date),
                    icon: Icons.event,
                    variant: AppButtonVariant.secondary,
                    onPressed: _pickDate,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l10n.examSave,
                    isLoading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
