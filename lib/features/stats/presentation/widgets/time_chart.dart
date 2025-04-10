import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_switch/flutter_switch.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../../core/theme/app_colors.dart';

// Define the available timeframes
enum TimeRange {
  weekly,
  monthly,
}

class TimeChart extends ConsumerStatefulWidget {
  const TimeChart({super.key});

  @override
  ConsumerState<TimeChart> createState() => _TimeChartState();
}

class _TimeChartState extends ConsumerState<TimeChart> {
  TimeRange _selectedRange = TimeRange.weekly;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(historyProvider);
    
    return Column(
      children: [
        // Timeframe selector
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Weekly',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _selectedRange == TimeRange.weekly 
                      ? FontWeight.w600 
                      : FontWeight.w400,
                  color: _selectedRange == TimeRange.weekly
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              FlutterSwitch(
                width: 40.0,
                height: 24.0,
                valueFontSize: 0.0,
                toggleSize: 20.0,
                value: _selectedRange == TimeRange.monthly,
                borderRadius: 12.0,
                padding: 2.0,
                activeColor: Theme.of(context).colorScheme.primary,
                onToggle: (value) {
                  setState(() {
                    _selectedRange = value ? TimeRange.monthly : TimeRange.weekly;
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Monthly',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _selectedRange == TimeRange.monthly 
                      ? FontWeight.w600 
                      : FontWeight.w400,
                  color: _selectedRange == TimeRange.monthly
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        // Chart
        entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (timeEntries) {
            // Get the current date and the date range based on selected view
            final now = DateTime.now();
            DateTime startDate;
            int daysToShow;
            
            switch (_selectedRange) {
              case TimeRange.weekly:
                startDate = now.subtract(const Duration(days: 6));
                daysToShow = 7;
                break;
              case TimeRange.monthly:
                startDate = DateTime(now.year, now.month - 1, now.day);
                daysToShow = 30;
                break;
            }
            
            // Initialize a map with all days in range, setting default values to 0
            final Map<DateTime, int> dailyTotals = {};
            for (int i = 0; i < daysToShow; i++) {
              final date = DateTime(
                startDate.year,
                startDate.month,
                startDate.day + i,
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
              
              // Only include entries from the selected range
              if (date.isAfter(startDate.subtract(const Duration(days: 1))) && 
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

            // Determine bar width and x-axis interval based on timeframe
            double barWidth;
            double xAxisInterval;
            switch (_selectedRange) {
              case TimeRange.weekly:
                barWidth = 16;
                xAxisInterval = 1;
                break;
              case TimeRange.monthly:
                barWidth = 8;
                xAxisInterval = 5;
                break;
            }

            return SizedBox(
              height: 240,
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
                        reservedSize: 35,
                        interval: 10,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}m',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
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
                        reservedSize: 25,
                        interval: xAxisInterval,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          
                          // For monthly view, only show labels for Mondays
                          if (_selectedRange == TimeRange.monthly && date.weekday != DateTime.monday) {
                            return const SizedBox.shrink();
                          }
                          
                          return Text(
                            '${date.month}/${date.day}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: _selectedRange == TimeRange.weekly ? 11 : 10,
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
                          width: barWidth,
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
        ),
      ],
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