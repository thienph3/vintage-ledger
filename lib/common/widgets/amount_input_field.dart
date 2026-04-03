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
  OverlayEntry? _overlay;

  int get _rawAmount => int.tryParse(widget.controller.text) ?? 0;
  String get _locale => 'vi';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    // Show formatted on init
    _setFormatted(_rawAmount);
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.dispose();
    _fieldCtrl.dispose();
    super.dispose();
  }

  void _setFormatted(int amount) {
    _fieldCtrl.text = AmountFormatter.formatCurrency(amount, _locale, currencyCode: widget.currency);
  }

  int get _cursorBeforeSuffix {
    final pos = _fieldCtrl.text.lastIndexOf(RegExp(r'[0-9]'));
    return pos >= 0 ? pos + 1 : _fieldCtrl.text.length;
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _setFormatted(_rawAmount);
      _fieldCtrl.selection = TextSelection.collapsed(offset: _cursorBeforeSuffix);
      _showOverlay();
    } else {
      _setFormatted(_rawAmount);
      _removeOverlay();
    }
  }

  void _onChanged(String value) {
    // Extract digits only, enforce max
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

    _overlay?.markNeedsBuild();
  }

  void _selectAmount(int amount) {
    final clamped = amount.toString().length > _maxDigits
        ? int.parse(amount.toString().substring(0, _maxDigits))
        : amount;
    widget.controller.text = clamped.toString();
    _setFormatted(clamped);
    _fieldCtrl.selection = TextSelection.collapsed(offset: _cursorBeforeSuffix);
    _overlay?.markNeedsBuild();
  }

  void _showOverlay() {
    _removeOverlay();
    _overlay = OverlayEntry(builder: (_) => _ChipsBar(
      controller: widget.controller,
      onSelect: _selectAmount,
    ));
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _fieldCtrl,
      focusNode: _focusNode,
      keyboardType: TextInputType.number,
      style: AppTextStyles.amount,
      onChanged: _onChanged,
      onTapOutside: (_) => _focusNode.unfocus(),
      decoration: InputDecoration(
        labelText: widget.label ?? S.of(context, 'amount'),
      ),
    );
  }
}

class _ChipsBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<int> onSelect;

  const _ChipsBar({required this.controller, required this.onSelect});

  List<int> _chips(int base) {
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
    final locale = Localizations.localeOf(context).languageCode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomInset,
      child: Material(
        elevation: 0,
        color: AppColors.surface,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.3))),
          ),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final base = int.tryParse(value.text) ?? 0;
              final chips = _chips(base);

              if (chips.isEmpty) return const SizedBox.shrink();

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: chips.map((amount) {
                  final selected = base == amount;
                  return GestureDetector(
                    onTap: () => onSelect(amount),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
