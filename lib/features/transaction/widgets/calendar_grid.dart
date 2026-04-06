import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime month;
  final Map<int, int> dailyExpense;
  final int? selectedDay;
  final int? todayDay;
  final ValueChanged<int> onDayTap;

  const CalendarGrid({
    super.key,
    required this.month,
    required this.dailyExpense,
    required this.onDayTap,
    this.selectedDay,
    this.todayDay,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Mon

    return Column(
      children: [
        _buildWeekdayHeader(),
        const SizedBox(height: AppSpacing.xs),
        _buildGrid(daysInMonth, firstWeekday, locale),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    return Row(
      children: List.generate(7, (i) => Expanded(
        child: Center(
          child: Text(
            DateFormatter.weekdayShort(i + 1),
            style: AppTextStyles.caption,
          ),
        ),
      )),
    );
  }

  Widget _buildGrid(int daysInMonth, int firstWeekday, String locale) {
    final rows = <Widget>[];
    var day = 1 - (firstWeekday - 1); // offset to fill leading blanks

    while (day <= daysInMonth) {
      final cells = <Widget>[];
      for (var col = 0; col < 7; col++) {
        if (day < 1 || day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox.shrink()));
        } else {
          cells.add(_buildCell(day, locale));
        }
        day++;
      }
      rows.add(Row(children: cells));
    }

    return Column(children: rows);
  }

  Widget _buildCell(int day, String locale) {
    final isSelected = day == selectedDay;
    final isToday = day == todayDay;
    final expense = dailyExpense[day];

    return Expanded(
      child: GestureDetector(
        onTap: () => onDayTap(day),
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withAlpha(30) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day number
              Container(
                width: 22, height: 22,
                decoration: isToday && !isSelected
                    ? const BoxDecoration(shape: BoxShape.circle, color: AppColors.divider)
                    : null,
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: isSelected || isToday ? FontWeight.w600 : null,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
              ),
              // Expense amount
              if (expense != null && expense > 0)
                Text(
                  '-${AmountFormatter.formatCompact(expense, locale)}',
                  style: AppTextStyles.calendarExpense,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
