import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/project_model.dart';
import '../../theme/app_colors.dart';

class TrendChartCard extends StatelessWidget {
  final Project project;

  const TrendChartCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    if (project.weeklyProgress.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Avance Semanal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Esta semana', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1.0,
                  barTouchData: BarTouchData(
                    enabled: false,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.black87,
                      tooltipPadding: const EdgeInsets.all(4),
                      tooltipMargin: 8,
                      getTooltipItem: (
                        BarChartGroupData group,
                        int groupIndex,
                        BarChartRodData rod,
                        int rodIndex,
                      ) {
                        return BarTooltipItem(
                          '${(rod.toY * 100).round()}%',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.bold, fontSize: 12);
                          String text;
                          switch (value.toInt()) {
                            case 0: text = 'L'; break;
                            case 1: text = 'M'; break;
                            case 2: text = 'M'; break;
                            case 3: text = 'J'; break;
                            case 4: text = 'V'; break;
                            case 5: text = 'S'; break;
                            case 6: text = 'D'; break;
                            default: text = ''; break;
                          }
                          return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text(text, style: style));
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: project.weeklyProgress.asMap().entries.map((entry) {
                    final index = entry.key;
                    final value = entry.value;
                    final isToday = index == project.weeklyProgress.length - 1;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: isToday ? AppColors.accent : AppColors.primary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                      showingTooltipIndicators: isToday ? [0] : [],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
