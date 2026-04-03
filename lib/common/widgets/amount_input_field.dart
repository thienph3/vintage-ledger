import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/common/widgets/amount_history.dart';

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
  OverlayEntry? _overlay;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlay = OverlayEntry(builder: (_) => _ChipsBar(
      controller: widget.controller,
      onSelect: (amount) {
        widget.controller.text = amount.toString();
        widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
      },
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
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.number,
      style: AppTextStyles.amount,
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

  List<int> _dynamicChips(String text) {
    final base = int.tryParse(text) ?? 0;
    if (base <= 0) return const [];
    final chips = <int>[];
    if (base < 1000) chips.add(base * 1000);
    if (base < 100) chips.add(base * 10000);
    if (base < 10) chips.add(base * 100000);
    return chips;
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
              final text = value.text.trim();
              final chips = text.isEmpty
                  ? AmountHistory.topAmounts()
                  : _dynamicChips(text);

              if (chips.isEmpty) return const SizedBox.shrink();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: chips.map((amount) {
                    final selected = (int.tryParse(text) ?? 0) == amount;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => onSelect(amount),
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
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
