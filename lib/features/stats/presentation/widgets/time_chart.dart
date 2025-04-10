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
  yearly,
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
          child: ToggleButtons(
            borderRadius: BorderRadius.circular(8),
            constraints: const BoxConstraints(
              minWidth: 80,
              minHeight: 32,
            ),
            isSelected: [
              _selectedRange == TimeRange.weekly,
              _selectedRange == TimeRange.monthly,
              _selectedRange == TimeRange.yearly,
            ],
            onPressed: (index) {
              setState(() {
                _selectedRange = TimeRange.values[index];
              });
            },
            children: const [
              Text('Weekly'),
              Text('Monthly'),
              Text('Yearly'),
            ],
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            selectedColor: Theme.of(context).colorScheme.primary,
            selectedBorderColor: Theme.of(context).colorScheme.primary,
            fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              case TimeRange.yearly:
                startDate = DateTime(now.year, 1, 1);
                daysToShow = 365;
                break;
            }
            
            // Initialize a map with all days in range, setting default values to 0
            final Map<DateTime, int> dailyTotals = {};
            
            if (_selectedRange == TimeRange.yearly) {
              // For yearly view, group by month
              for (int month = 1; month <= 12; month++) {
                final date = DateTime(now.year, month, 1);
                dailyTotals[date] = 0;
              }
            } else {
              // For weekly and monthly views, group by day
              for (int i = 0; i < daysToShow; i++) {
                final date = DateTime(
                  startDate.year,
                  startDate.month,
                  startDate.day + i,
                );
                dailyTotals[date] = 0;
              }
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
                if (_selectedRange == TimeRange.yearly) {
                  // For yearly view, group by month
                  final monthStart = DateTime(date.year, date.month, 1);
                  dailyTotals[monthStart] = (dailyTotals[monthStart] ?? 0) + entry.duration;
                } else {
                  dailyTotals[date] = (dailyTotals[date] ?? 0) + entry.duration;
                }
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
              case TimeRange.yearly:
                barWidth = 20;
                xAxisInterval = 1;
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
                          
                          if (_selectedRange == TimeRange.yearly) {
                            // For yearly view, show month names
                            return Text(
                              _getMonthAbbreviation(date.month),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                              ),
                            );
                          } else if (_selectedRange == TimeRange.monthly && date.weekday != DateTime.monday) {
                            // For monthly view, only show labels for Mondays
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

  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
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