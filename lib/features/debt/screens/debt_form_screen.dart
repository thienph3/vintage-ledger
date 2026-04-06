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
import 'package:vintage_ledger/features/debt/models/debt.dart';

class DebtFormScreen extends StatefulWidget {
  final Debt? existing;

  const DebtFormScreen({super.key, this.existing});

  @override
  State<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends State<DebtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  DebtType _type = DebtType.lend;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final d = widget.existing!;
      _nameCtrl.text = d.partyName;
      _amountCtrl.text = d.totalAmount.toString();
      _noteCtrl.text = d.note ?? '';
      _type = d.type;
      if (d.dueDate != null) _dueDate = DateTime.fromMillisecondsSinceEpoch(d.dueDate!);
    } else {
      _amountCtrl.text = '0';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dueDate != null) _dateCtrl.text = DateFormat('dd/MM/yyyy').format(_dueDate!);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = int.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      showAppSnackBar(context, S.of(context, 'amountMustBePositive'));
      return;
    }

    try {
      await sl.debtService.createDebt(Debt(
        type: _type,
        partyName: _nameCtrl.text.trim(),
        totalAmount: amount,
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        dueDate: _dueDate?.millisecondsSinceEpoch,
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showAppSnackBar(context, e.toString(), backgroundColor: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'addDebt'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildTypeToggle(),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: S.of(context, 'partyName'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              style: AppTextStyles.body,
              validator: (v) => v == null || v.trim().isEmpty ? S.of(context, 'partyNameRequired') : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AmountInputField(controller: _amountCtrl),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              readOnly: true,
              controller: _dateCtrl,
              decoration: InputDecoration(
                labelText: S.of(context, 'dueDate'),
                suffixIcon: const Icon(Icons.calendar_today, size: 20),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked == null) return;
                setState(() { _dueDate = picked; _dateCtrl.text = DateFormat('dd/MM/yyyy').format(picked); });
              },
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: S.of(context, 'note'),
                hintText: S.of(context, 'noteHint'),
              ),
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            FormSaveButton(isEdit: false, onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.divider.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _pill(DebtType.lend, S.of(context, 'lend')),
          const SizedBox(width: 4),
          _pill(DebtType.borrow, S.of(context, 'borrow')),
        ],
      ),
    );
  }

  Widget _pill(DebtType type, String label) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label, style: AppTextStyles.buttonLabel.copyWith(
            color: selected ? AppColors.primary : AppColors.textPrimary, fontSize: 16,
          )),
        ),
      ),
    );
  }
}
