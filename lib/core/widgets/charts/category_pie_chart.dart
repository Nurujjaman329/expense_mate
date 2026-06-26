import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/features/reports/domain/entities/analytics_models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Pie chart showing expense distribution by category.
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.data,
    this.size = 200,
  });

  final List<CategorySpending> data;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: size,
        child: Center(
          child: Text(
            'No category data',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: data.map((item) {
                return PieChartSectionData(
                  value: item.amount,
                  color: item.color,
                  title: '${(item.percentage * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.take(5).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.categoryName,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      Formatters.currency(item.amount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
