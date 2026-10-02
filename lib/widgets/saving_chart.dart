import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Month labels used by the savings chart for the x-axis.
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

// Displays monthly saving, income, and expense trends as a line chart.
class SavingChart extends StatelessWidget {
  final List<double> saving;
  final List<double> income;
  final List<double> expense;

  const SavingChart({
    super.key,
    required this.saving,
    required this.income,
    required this.expense,
  });

  /// Converts a list of monthly values into a line series for the chart.
  LineChartBarData _line(List<double> values, Color color) {
    return LineChartBarData(
      spots:
          List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i])),
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) =>
            FlDotCirclePainter(radius: 3, color: color, strokeWidth: 0),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  /// Draws the savings trend chart with saving, income, and expense lines.
  @override
  Widget build(BuildContext context) {
    final allValues = [...saving, ...income, ...expense];
    final maxY =
        (allValues.isEmpty ? 1000 : allValues.reduce((a, b) => a > b ? a : b)) *
            1.2;
    final minY =
        (allValues.isEmpty ? 0 : allValues.reduce((a, b) => a < b ? a : b)) *
            1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _legendDot(AppColors.textPrimary.withValues(alpha: 0.6), 'Saving',
                const Color(0xFF3E7BFA)),
            const SizedBox(width: 16),
            _legendDot(AppColors.income, 'Income', AppColors.income),
            const SizedBox(width: 16),
            _legendDot(AppColors.expense, 'Expense', AppColors.expense),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: minY.isFinite ? minY.toDouble() : 0,
              maxY: maxY.isFinite ? maxY.toDouble() : 1000,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) =>
                    const FlLine(color: AppColors.divider, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= _months.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_months[i],
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textSecondary)),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                _line(saving, const Color(0xFF3E7BFA)),
                _line(income, AppColors.income),
                _line(expense, AppColors.expense),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a small legend item for the savings chart.
  Widget _legendDot(Color unused, String label, Color color) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
