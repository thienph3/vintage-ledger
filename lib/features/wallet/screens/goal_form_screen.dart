import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
import 'package:vintage_ledger/common/widgets/amount_input_field.dart';
import 'package:vintage_ledger/common/widgets/form_save_button.dart';
import 'package:vintage_ledger/features/wallet/models/wallet_goal.dart';

class GoalFormScreen extends StatefulWidget {
  final String walletId;
  final WalletGoal? existing;

  const GoalFormScreen({super.key, required this.walletId, this.existing});

  bool get isEdit => existing != null;

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _savedCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String? _emoji;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final g = widget.existing!;
      _nameCtrl.text = g.name;
      _targetCtrl.text = g.targetAmount.toString();
      _savedCtrl.text = g.savedAmount.toString();
      _emoji = g.emoji;
      if (g.deadline != null) _deadline = DateTime.fromMillisecondsSinceEpoch(g.deadline!);
    } else {
      _targetCtrl.text = '0';
      _savedCtrl.text = '0';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDateText();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _savedCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  void _updateDateText() {
    if (_deadline != null) {
      _dateCtrl.text = DateFormat('dd/MM/yyyy').format(_deadline!);
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() { _deadline = picked; _updateDateText(); });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final target = int.tryParse(_targetCtrl.text) ?? 0;
    final saved = int.tryParse(_savedCtrl.text) ?? 0;
    if (target <= 0) {
      showAppSnackBar(context, S.of(context, 'amountMustBePositive'));
      return;
    }

    try {
      if (widget.isEdit) {
        await sl.goalService.updateGoal(widget.walletId, widget.existing!.id!, {
          'name': _nameCtrl.text.trim(),
          'target_amount': target,
          'saved_amount': saved,
          'deadline': _deadline?.millisecondsSinceEpoch,
          'emoji': _emoji,
        });
      } else {
        await sl.goalService.createGoal(widget.walletId, WalletGoal(
          name: _nameCtrl.text.trim(),
          targetAmount: target,
          savedAmount: saved,
          deadline: _deadline?.millisecondsSinceEpoch,
          emoji: _emoji,
        ));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showAppSnackBar(context, e.toString(), backgroundColor: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.isEdit ? S.of(context, 'editGoal') : S.of(context, 'addGoal'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: S.of(context, 'goalName'),
                prefixIcon: GestureDetector(
                  onTap: _pickEmoji,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_emoji ?? '🎯', style: AppTextStyles.emoji),
                  ),
                ),
              ),
              style: AppTextStyles.body,
              validator: (v) => v == null || v.trim().isEmpty ? S.of(context, 'goalNameRequired') : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AmountInputField(controller: _targetCtrl, label: S.of(context, 'targetAmount')),
            const SizedBox(height: AppSpacing.md),
            AmountInputField(controller: _savedCtrl, label: S.of(context, 'savedAmount')),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              readOnly: true,
              controller: _dateCtrl,
              decoration: InputDecoration(
                labelText: S.of(context, 'deadline'),
                suffixIcon: const Icon(Icons.calendar_today, size: 20),
                hintText: S.of(context, 'deadline'),
              ),
              onTap: _pickDeadline,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            FormSaveButton(isEdit: widget.isEdit, onPressed: _save),
          ],
        ),
      ),
    );
  }

  void _pickEmoji() async {
    const emojis = ['🎯', '💻', '✈️', '🏠', '🚗', '📱', '💍', '🎓', '🏦', '🎁', '🏖️', '💰'];
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: emojis.map((e) => GestureDetector(
            onTap: () => Navigator.pop(ctx, e),
            child: Text(e, style: AppTextStyles.emojiLarge),
          )).toList(),
        ),
      ),
    );
    if (picked != null) setState(() => _emoji = picked);
  }
}
