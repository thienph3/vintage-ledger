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
  final _displayCtrl = TextEditingController();
  OverlayEntry? _overlay;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _syncDisplay();
    widget.controller.addListener(_onRawChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.dispose();
    _displayCtrl.dispose();
    widget.controller.removeListener(_onRawChanged);
    super.dispose();
  }

  void _syncDisplay() {
    final amount = int.tryParse(widget.controller.text) ?? 0;
    if (!_editing) {
      final locale = 'vi';
      _displayCtrl.text = amount > 0
          ? AmountFormatter.formatCurrency(amount, locale, currencyCode: widget.currency)
          : (widget.showZero ? AmountFormatter.formatCurrency(0, locale, currencyCode: widget.currency) : '');
    }
  }

  void _onRawChanged() {
    if (!_editing) _syncDisplay();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _editing = true;
      // Show raw number for editing, clear if 0
      final raw = int.tryParse(widget.controller.text) ?? 0;
      _displayCtrl.text = raw > 0 ? raw.toString() : '';
      _displayCtrl.selection = TextSelection.collapsed(offset: _displayCtrl.text.length);
      _showOverlay();
    } else {
      // Parse back, restore formatted
      final parsed = int.tryParse(_displayCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      widget.controller.text = parsed.toString();
      _editing = false;
      _syncDisplay();
      _removeOverlay();
    }
  }

  void _onDisplayChanged(String value) {
    // Strip non-digits, enforce max
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final clamped = digits.length > _maxDigits ? digits.substring(0, _maxDigits) : digits;

    if (clamped != value) {
      _displayCtrl.text = clamped;
      _displayCtrl.selection = TextSelection.collapsed(offset: clamped.length);
    }

    widget.controller.text = clamped.isEmpty ? '0' : clamped;
    _overlay?.markNeedsBuild();
  }

  void _selectAmount(int amount) {
    final str = amount.toString();
    final clamped = str.length > _maxDigits ? str.substring(0, _maxDigits) : str;
    _displayCtrl.text = clamped;
    _displayCtrl.selection = TextSelection.collapsed(offset: clamped.length);
    widget.controller.text = clamped;
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
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: TextField(
        controller: _displayCtrl,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        style: AppTextStyles.amount,
        onChanged: _onDisplayChanged,
        onTapOutside: (_) => _focusNode.unfocus(),
        decoration: InputDecoration(
          labelText: widget.label ?? S.of(context, 'amount'),
        ),
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

    // 8+ digits: show history defaults
    if (digits >= _maxDigits) return AmountHistory.topAmounts();

    // 7 digits: 1 chip (×10)
    if (digits == 7) return [base * 10];

    // 6 digits: 2 chips (×10, ×100)
    if (digits == 6) return [base * 10, base * 100];

    // 1-5 digits: 3 chips
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
