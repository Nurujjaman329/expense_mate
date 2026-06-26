import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/features/reports/domain/entities/analytics_models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Side-by-side bar chart comparing income and expense.
class IncomeExpenseChart extends StatelessWidget {
  const IncomeExpenseChart({
    super.key,
    required this.data,
    this.height = 200,
  });

  final IncomeExpenseComparison data;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.income == 0 && data.expense == 0) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No income or expense data',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ),
      );
    }

    final maxY = [data.income, data.expense].reduce((a, b) => a > b ? a : b);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.25 + 1,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      Formatters.currency(rod.toY),
                      const TextStyle(fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) => Text(
                      Formatters.compactNumber(value),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final labels = ['Income', 'Expense'];
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(labels[index], style: const TextStyle(fontSize: 12)),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: data.income,
                      color: AppColors.income,
                      width: 36,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: data.expense,
                      color: AppColors.expense,
                      width: 36,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: AppColors.income, label: 'Income'),
            const SizedBox(width: 20),
            _LegendDot(color: AppColors.expense, label: 'Expense'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
