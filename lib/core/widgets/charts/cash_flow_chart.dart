import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/features/reports/domain/entities/analytics_models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Line chart showing net cash flow over recent months.
class CashFlowChart extends StatelessWidget {
  const CashFlowChart({
    super.key,
    required this.data,
    this.height = 200,
  });

  final List<MonthlyCashFlow> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.every((d) => d.income == 0 && d.expense == 0)) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No cash flow data yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ),
      );
    }

    final values = data.map((d) => d.net).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY).abs() * 0.2 + 10;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY - padding,
          maxY: maxY + padding,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark
                  ? AppColors.dividerDark
                  : AppColors.dividerLight,
            ),
          ),
          borderData: FlBorderData(show: false),
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
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[index].label,
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  return LineTooltipItem(
                    Formatters.currency(spot.y),
                    const TextStyle(fontWeight: FontWeight.w600),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                data.length,
                (i) => FlSpot(i.toDouble(), data[i].net),
              ),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
