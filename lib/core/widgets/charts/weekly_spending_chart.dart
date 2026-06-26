import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/features/reports/domain/entities/analytics_models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Bar chart showing daily expense totals for the last 7 days.
class WeeklySpendingChart extends StatelessWidget {
  const WeeklySpendingChart({
    super.key,
    required this.data,
    this.height = 200,
  });

  final List<ChartDataPoint> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.every((d) => d.value == 0)) {
      return _EmptyChart(height: height, message: 'No spending this week');
    }

    final maxY = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2 + 1,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  Formatters.currency(rod.toY),
                  TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
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
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  Formatters.compactNumber(value),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[index].label,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: gridColor,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data[index].value,
                  color: AppColors.expense.withValues(alpha: 0.85),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.height, required this.message});

  final double height;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
      ),
    );
  }
}
