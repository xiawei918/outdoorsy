import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../../core/theme/app_colors.dart';

class TimeChart extends ConsumerWidget {
  const TimeChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(historyProvider);
    
    return entries.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (timeEntries) {
        // Get the current date and the date 7 days ago
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 6));
        
        // Initialize a map with all 7 days, setting default values to 0
        final Map<DateTime, int> dailyTotals = {};
        for (int i = 0; i < 7; i++) {
          final date = DateTime(
            sevenDaysAgo.year,
            sevenDaysAgo.month,
            sevenDaysAgo.day + i,
          );
          dailyTotals[date] = 0;
        }
        
        // Add up durations for days with entries
        for (final entry in timeEntries) {
          final date = DateTime(
            entry.date.year,
            entry.date.month,
            entry.date.day,
          );
          
          // Only include entries from the last 7 days
          if (date.isAfter(sevenDaysAgo.subtract(const Duration(days: 1))) && 
              !date.isAfter(now)) {
            dailyTotals[date] = (dailyTotals[date] ?? 0) + entry.duration;
          }
        }

        // Convert to list of spots for the chart
        final spots = dailyTotals.entries.map((entry) {
          return FlSpot(
            entry.key.millisecondsSinceEpoch.toDouble(),
            entry.value / 60.0, // Convert seconds to minutes
          );
        }).toList()
          ..sort((a, b) => a.x.compareTo(b.x));

        // Find the maximum value for y-axis scaling
        final maxMinutes = spots.isEmpty ? 30.0 : 
            spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
        final yAxisMax = (maxMinutes / 10).ceil() * 10.0; // Round up to nearest 10

        return SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 10,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.gray200,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 10,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}m',
                        style: const TextStyle(
                          color: AppColors.gray400,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return Text(
                        '${date.month}/${date.day}',
                        style: const TextStyle(
                          color: AppColors.gray400,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              maxY: yAxisMax,
              barGroups: spots.map((spot) {
                return BarChartGroupData(
                  x: spot.x.toInt(),
                  barRods: [
                    BarChartRodData(
                      toY: spot.y,
                      color: AppColors.primary,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class ChartDataPoint {
  final String label;
  final int minutes;

  ChartDataPoint({
    required this.label,
    required this.minutes,
  });
} 