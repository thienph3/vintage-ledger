import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/common/widgets/amount_history.dart';

const _maxDigits = 8;

class AmountInputField extends StatefulWidget {
  final TextEditingController controller;
  final String currency;
  final String? label;
  final bool showZero;

  const AmountInputField({
    super.key,
    required this.controller,
    this.currency = 'VND',
    this.label,
    this.showZero = false,
  });

  @override
  State<AmountInputField> createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends State<AmountInputField> {
  final _focusNode = FocusNode();
  final _fieldCtrl = TextEditingController();
  bool _focused = false;

  int get _rawAmount => int.tryParse(widget.controller.text) ?? 0;
  String get _locale => 'vi';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _setFormatted(_rawAmount);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _fieldCtrl.dispose();
    super.dispose();
  }

  void _setFormatted(int amount) {
    final formatted = AmountFormatter.formatCurrency(amount, _locale, currencyCode: widget.currency);
    final pos = formatted.lastIndexOf(RegExp(r'[0-9]'));
    _fieldCtrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: pos >= 0 ? pos + 1 : formatted.length),
    );
  }

  void _onFocusChanged() {
    setState(() => _focused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _setFormatted(_rawAmount);
    }
  }

  void _onChanged(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > _maxDigits) digits = digits.substring(0, _maxDigits);

    final amount = int.tryParse(digits) ?? 0;
    widget.controller.text = amount.toString();

    final formatted = AmountFormatter.formatCurrency(amount, _locale, currencyCode: widget.currency);
    final pos = formatted.lastIndexOf(RegExp(r'[0-9]'));
    _fieldCtrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: pos >= 0 ? pos + 1 : formatted.length),
    );
    setState(() {});
  }

  void _selectChip(int amount) {
    final clamped = amount.toString().length > _maxDigits
        ? int.parse(amount.toString().substring(0, _maxDigits))
        : amount;
    widget.controller.text = clamped.toString();
    _setFormatted(clamped);
    setState(() {});
    // Keep focus — schedule after frame to avoid losing it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
    });
  }

  List<int> _chips() {
    final base = _rawAmount;
    if (base <= 0) return AmountHistory.topAmounts();

    final digits = base.toString().length;
    if (digits >= _maxDigits) return AmountHistory.topAmounts();
    if (digits == 7) return [base * 10];
    if (digits == 6) return [base * 10, base * 100];
    if (digits <= 2) return [base * 1000, base * 10000, base * 100000];
    return [base * 10, base * 100, base * 1000];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _fieldCtrl,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          style: AppTextStyles.amount,
          onChanged: _onChanged,
          onTapOutside: (_) => _focusNode.unfocus(),
          decoration: InputDecoration(
            labelText: widget.label ?? S.of(context, 'amount'),
          ),
        ),
        if (_focused) _buildChips(),
      ],
    );
  }

  Widget _buildChips() {
    final chips = _chips();
    if (chips.isEmpty) return const SizedBox.shrink();

    final locale = Localizations.localeOf(context).languageCode;
    final base = _rawAmount;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: chips.map((amount) {
          final selected = base == amount;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _selectChip(amount),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AmountFormatter.formatCurrency(amount, locale),
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
