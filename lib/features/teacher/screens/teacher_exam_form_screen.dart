import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../app/di.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/cairo_time.dart';
import '../../grades/grade_format.dart';
import '../../grades/repositories/exams_repository.dart';
import '../../groups/models/group.dart';
import '../../groups/repository/groups_repository.dart';
import '../cubit/teacher_exam_form_cubit.dart';
import '../../../core/widgets/app_page.dart';

/// إنشاء اختبار: الاسم، المجموعة، التاريخ، وقت البداية، الدرجة النهائية.
/// (بيتعمل مسودة؛ التاريخ ووقت البداية بيتخزنوا في حقل `date` بتوقيت القاهرة.)
class TeacherExamFormScreen extends StatelessWidget {
  const TeacherExamFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TeacherExamFormCubit(sl<GroupsRepository>(), sl<ExamsRepository>())
            ..load(),
      child: const _FormView(),
    );
  }
}

class _FormView extends StatefulWidget {
  const _FormView();

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _max = TextEditingController(text: '100');
  Group? _group;
  late DateTime _date = toCairoWallTime(DateTime.now());
  TimeOfDay _time = const TimeOfDay(hour: 16, minute: 0);

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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final group = _group;
    if (group == null) return;
    final cairo = tz.getLocation('Africa/Cairo');
    final start = tz.TZDateTime(
      cairo,
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    context.read<TeacherExamFormCubit>().submit(
      group: group,
      title: _title.text,
      start: start,
      maxScore: double.parse(_max.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppPage(
      title: l10n.teacherExamFormTitle,
      body: BlocConsumer<TeacherExamFormCubit, TeacherExamFormState>(
        listener: (context, state) {
          if (state.status == TeacherExamFormStatus.success) {
            context.pop(state.saved);
          } else if (state.status == TeacherExamFormStatus.failure &&
              state.groups.isNotEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(failureText(state.failure))));
          }
        },
        builder: (context, state) {
          if (state.status == TeacherExamFormStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == TeacherExamFormStatus.failure &&
              state.groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(failureText(state.failure)),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: l10n.retry,
                      expand: false,
                      onPressed: () =>
                          context.read<TeacherExamFormCubit>().load(),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(l10n.teacherExamNoGroups),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _title,
                    label: l10n.teacherExamFieldName,
                    maxLength: 120,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? l10n.validationRequired
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<Group>(
                    initialValue: _group,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.teacherExamFieldGroup,
                    ),
                    items: [
                      for (final g in state.groups)
                        DropdownMenuItem(
                          value: g,
                          child: Text(
                            g.subject.isEmpty
                                ? g.name
                                : '${g.subject} · ${g.name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (g) => setState(() => _group = g),
                    validator: (g) =>
                        g == null ? l10n.teacherExamGroupRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label:
                        '${l10n.teacherExamFieldDate}: ${fmtDate(l10n, _date)}',
                    icon: Icons.event,
                    variant: AppButtonVariant.secondary,
                    onPressed: _pickDate,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label:
                        '${l10n.teacherExamFieldStart}: ${formatMinutesOfDay(l10n, _time.hour * 60 + _time.minute)}',
                    icon: Icons.schedule,
                    variant: AppButtonVariant.secondary,
                    onPressed: _pickTime,
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
