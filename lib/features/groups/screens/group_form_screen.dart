import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/digits.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../staff/models/staff_member.dart';
import '../../staff/models/staff_roster.dart';
import '../../staff/repository/staff_repository.dart';
import '../cubit/group_form_cubit.dart';
import '../models/group.dart';
import '../models/group_input.dart';
import '../repository/groups_repository.dart';

/// إنشاء مجموعة جديدة، أو تعديل [editing]. بيرجّع المجموعة المحفوظة بـ pop.
/// المعلم والمساعدين بيتجابوا من قائمة فريق السنتر (النشطين بس).
/// الحد الأقصى للمساعدين في المجموعة (نفس حد الـ Rules v6).
const int maxAssistantsPerGroup = 6;

class GroupFormScreen extends StatelessWidget {
  const GroupFormScreen({super.key, this.editing});

  final Group? editing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupFormCubit(sl<GroupsRepository>(), editing: editing),
      child: _GroupFormView(editing: editing),
    );
  }
}

/// مسودة ميعاد في الفورم (المدة بتتكتب نص وتتقري عند الحفظ).
class _SlotDraft {
  _SlotDraft({
    required this.weekday,
    required this.startMinutes,
    required int durationMinutes,
  }) : durationController =
            TextEditingController(text: durationMinutes.toString());

  _SlotDraft.fromSlot(GroupSlot slot)
      : this(
          weekday: slot.weekday,
          startMinutes: slot.startMinutes,
          durationMinutes: slot.durationMinutes,
        );

  int weekday;
  int startMinutes;
  final TextEditingController durationController;

  void dispose() => durationController.dispose();

  GroupSlot toSlot() => GroupSlot(
        weekday: weekday,
        startMinutes: startMinutes,
        durationMinutes:
            int.tryParse(toLatinDigits(durationController.text)) ?? 0,
      );
}

class _GroupFormView extends StatefulWidget {
  const _GroupFormView({this.editing});

  final Group? editing;

  @override
  State<_GroupFormView> createState() => _GroupFormViewState();
}

class _GroupFormViewState extends State<_GroupFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.editing?.name ?? '');
  late final TextEditingController _subject =
      TextEditingController(text: widget.editing?.subject ?? '');
  late final TextEditingController _grade =
      TextEditingController(text: widget.editing?.grade ?? '');
  late final TextEditingController _room =
      TextEditingController(text: widget.editing?.room ?? '');
  late final TextEditingController _capacity = TextEditingController(
    text: widget.editing?.capacity?.toString() ?? '',
  );
  late final TextEditingController _fee = TextEditingController(
    text: (widget.editing?.monthlyFee ?? 0) > 0
        ? piastersToDecimalString(widget.editing!.monthlyFee)
        : '',
  );

  late String? _teacherId = widget.editing?.teacherId;
  late final Set<String> _assistantIds = <String>{
    ...widget.editing?.assistantIds ?? const <String>[],
  };
  late final List<_SlotDraft> _slots = <_SlotDraft>[
    for (final s in widget.editing?.slots ?? const <GroupSlot>[])
      _SlotDraft.fromSlot(s),
  ];

  String? _formError;
  late final Future<StaffRoster> _staffFuture =
      sl<StaffRepository>().loadStaff();

  @override
  void dispose() {
    _name.dispose();
    _subject.dispose();
    _grade.dispose();
    _room.dispose();
    _capacity.dispose();
    _fee.dispose();
    for (final s in _slots) {
      s.dispose();
    }
    super.dispose();
  }

  int? _parseCapacity() {
    final text = toLatinDigits(_capacity.text).trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  int? _parseFee() {
    final text = toLatinDigits(_fee.text).trim();
    if (text.isEmpty) return 0;
    final pounds = double.tryParse(text);
    if (pounds == null || pounds < 0) return null;
    return (pounds * 100).round();
  }

  String? _capacityValidator(String? _) {
    final text = toLatinDigits(_capacity.text).trim();
    if (text.isEmpty) return null;
    final value = int.tryParse(text);
    if (value == null || value < 1) {
      return AppLocalizations.of(context).groupInvalidCapacity;
    }
    return null;
  }

  String? _feeValidator(String? _) {
    if (_parseFee() == null) {
      return AppLocalizations.of(context).groupInvalidFee;
    }
    return null;
  }


  void _addSlot() {
    setState(() {
      _slots.add(
        _SlotDraft(weekday: DateTime.saturday, startMinutes: 1020, durationMinutes: 90),
      );
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<GroupFormCubit>();
    setState(() => _formError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    for (final s in _slots) {
      final d = int.tryParse(toLatinDigits(s.durationController.text));
      if (d == null ||
          d < GroupSlot.minDurationMinutes ||
          d > GroupSlot.maxDurationMinutes) {
        setState(() => _formError = l10n.groupInvalidDuration);
        return;
      }
    }
    final input = GroupInput(
      name: _name.text,
      subject: _subject.text,
      grade: _grade.text,
      teacherId: _teacherId ?? '',
      assistantIds: _assistantIds.toList(),
      room: _room.text,
      capacity: _parseCapacity(),
      monthlyFee: _parseFee() ?? 0,
      slots: [for (final s in _slots) s.toSlot()],
    );
    final error = input.validate();
    if (error != null) {
      setState(() => _formError = error);
      return;
    }
    // تعارض القاعة والميعاد مع باقي المجموعات قبل الحفظ.
    try {
      final conflict = await cubit.findRoomConflict(input);
      if (!mounted) return;
      if (conflict != null) {
        final slot = conflict.slot;
        setState(
          () => _formError = l10n.groupRoomConflict(
            conflict.group.name,
            l10n.weekdayName('d${slot.weekday}'),
            formatMinutesOfDay(l10n, slot.startMinutes),
            formatMinutesOfDay(l10n, slot.startMinutes + slot.durationMinutes),
          ),
        );
        return;
      }
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _formError = f.message);
      return;
    }
    cubit.submit(input);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.editing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.groupEditTitle : l10n.groupsAddTitle),
      ),
      body: SafeArea(
        child: BlocConsumer<GroupFormCubit, GroupFormState>(
          listener: (context, state) {
            if (state.status == GroupFormStatus.success) {
              context.pop<Group>(state.saved);
            }
          },
          builder: (context, state) {
            final enabled = !state.isSubmitting;
            return Form(
              key: _formKey,
              child: ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  AppTextField(
                    controller: _name,
                    label: l10n.groupFieldName,
                    textInputAction: TextInputAction.next,
                    enabled: enabled,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _subject,
                    label: l10n.groupFieldSubject,
                    textInputAction: TextInputAction.next,
                    enabled: enabled,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _grade,
                    label: l10n.groupFieldGrade,
                    textInputAction: TextInputAction.next,
                    enabled: enabled,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _room,
                    label: l10n.groupFieldRoom,
                    textInputAction: TextInputAction.next,
                    enabled: enabled,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FutureBuilder<StaffRoster>(
                    future: _staffFuture,
                    builder: (context, snap) =>
                        _staffSection(context, snap, enabled),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _capacity,
                    label: l10n.groupFieldCapacity,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    isLtr: true,
                    latinDigits: true,
                    enabled: enabled,
                    validator: _capacityValidator,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _fee,
                    label: l10n.groupFieldFee,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    isLtr: true,
                    latinDigits: true,
                    enabled: enabled,
                    validator: _feeValidator,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.groupSlotsTitle,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < _slots.length; i++) ...[
                    _SlotCard(
                      slot: _slots[i],
                      enabled: enabled,
                      onChanged: () => setState(() {}),
                      onRemove: () => setState(() {
                        _slots[i].dispose();
                        _slots.removeAt(i);
                      }),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: enabled ? _addSlot : null,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.groupAddSlot),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_formError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        _formError!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.error),
                      ),
                    )
                  else if (state.status == GroupFormStatus.failure &&
                      state.failure != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        state.failure!.message,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.error),
                      ),
                    ),
                  AppButton(
                    label: l10n.studentSave,
                    isLoading: state.isSubmitting,
                    onPressed: enabled ? _submit : null,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _staffSection(
    BuildContext context,
    AsyncSnapshot<StaffRoster> snap,
    bool enabled,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (snap.hasError) {
      return Text(
        snap.error.toString(),
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
      );
    }
    if (!snap.hasData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final members = snap.data!.members;
    final teachers = <StaffMember>[
      for (final m in members)
        if (m.role == StaffMemberRole.teacher && m.active) m,
    ];
    final assistants = <StaffMember>[
      for (final m in members)
        if (m.role == StaffMemberRole.assistant && m.active) m,
    ];
    final teacherValue =
        teachers.any((t) => t.uid == _teacherId) ? _teacherId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (teachers.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.groupNoTeachers,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.error),
            ),
          ),
        DropdownButtonFormField<String>(
          initialValue: teacherValue,
          decoration: InputDecoration(labelText: l10n.groupFieldTeacher),
          items: [
            for (final t in teachers)
              DropdownMenuItem(value: t.uid, child: Text(t.name)),
          ],
          onChanged:
              enabled ? (value) => setState(() => _teacherId = value) : null,
          validator: (value) =>
              value == null ? l10n.validationRequired : null,
        ),
        if (assistants.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.groupFieldAssistants,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final a in assistants)
                FilterChip(
                  label: Text(a.name),
                  selected: _assistantIds.contains(a.uid),
                  onSelected: enabled &&
                          (_assistantIds.contains(a.uid) ||
                              _assistantIds.length < maxAssistantsPerGroup)
                      ? (selected) => setState(() {
                            if (selected) {
                              _assistantIds.add(a.uid);
                            } else {
                              _assistantIds.remove(a.uid);
                            }
                          })
                      : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });

  final _SlotDraft slot;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: slot.startMinutes ~/ 60,
        minute: slot.startMinutes % 60,
      ),
    );
    if (picked == null) return;
    slot.startMinutes = picked.hour * 60 + picked.minute;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: slot.weekday,
                  decoration:
                      InputDecoration(labelText: l10n.groupSlotDay),
                  items: [
                    for (var w = DateTime.monday; w <= DateTime.sunday; w++)
                      DropdownMenuItem(
                        value: w,
                        child: Text(l10n.weekdayName('d$w')),
                      ),
                  ],
                  onChanged: enabled
                      ? (value) {
                          slot.weekday = value ?? slot.weekday;
                          onChanged();
                        }
                      : null,
                ),
              ),
              IconButton(
                tooltip: l10n.groupSlotRemove,
                icon: const Icon(Icons.delete_outline),
                onPressed: enabled ? onRemove : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: enabled ? () => _pickTime(context) : null,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    formatMinutesOfDay(l10n, slot.startMinutes),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  controller: slot.durationController,
                  label: l10n.groupSlotDuration,
                  keyboardType: TextInputType.number,
                  isLtr: true,
                  latinDigits: true,
                  enabled: enabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
