import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../history/domain/models/time_entry.dart';
import '../../../history/presentation/providers/history_provider.dart';

enum TimeRange {
  day,
  week,
  month,
  year,
}

class TimeChart extends ConsumerStatefulWidget {
  const TimeChart({super.key});

  @override
  ConsumerState<TimeChart> createState() => _TimeChartState();
}

class _TimeChartState extends ConsumerState<TimeChart> {
  TimeRange _timeRange = TimeRange.week;

  @override
  Widget build(BuildContext context) {
    final timeEntries = ref.watch(historyProvider);
    final chartData = _getChartData(timeEntries);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outdoor Time',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 191,
              child: chartData.isEmpty
                  ? Center(
                      child: Text(
                        'No data available for this time period',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        minY: 0,
                        maxY: chartData.map((e) => e.minutes.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= chartData.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    chartData[value.toInt()].label,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartData
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value.minutes.toDouble()))
                                .toList(),
                            isCurved: false,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                height: 32,
                child: SegmentedButton<TimeRange>(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 1),
                    ),
                    textStyle: MaterialStateProperty.all(
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                    ),
                    minimumSize: MaterialStateProperty.all(
                      const Size(20, 32),
                    ),
                    visualDensity: VisualDensity.compact,
                    side: MaterialStateProperty.all(
                      BorderSide.none,
                    ),
                    shape: MaterialStateProperty.all(
                      const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return const Color(0xFF847E73).withOpacity(0.1);
                        }
                        return Colors.transparent;
                      },
                    ),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return const Color(0xFF847E73);
                        }
                        return Theme.of(context).colorScheme.onSurfaceVariant;
                      },
                    ),
                    overlayColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                    alignment: Alignment.center,
                    fixedSize: MaterialStateProperty.all(
                      const Size.fromHeight(32),
                    ),
                  ),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: TimeRange.day,
                      label: Text('Day'),
                    ),
                    ButtonSegment(
                      value: TimeRange.week,
                      label: Text('Week'),
                    ),
                    ButtonSegment(
                      value: TimeRange.month,
                      label: Text('Month'),
                    ),
                    ButtonSegment(
                      value: TimeRange.year,
                      label: Text('Year'),
                    ),
                  ],
                  selected: {_timeRange},
                  onSelectionChanged: (Set<TimeRange> newSelection) {
                    setState(() {
                      _timeRange = newSelection.first;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ChartDataPoint> _getChartData(List<TimeEntry> entries) {
    final now = DateTime.now();
    final List<ChartDataPoint> data = [];

    switch (_timeRange) {
      case TimeRange.day:
        // Create 24 data points for each hour
        for (var i = 0; i < 24; i++) {
          final hour = now.hour - i;
          final date = DateTime(now.year, now.month, now.day, hour);
          final minutes = _getMinutesForDate(entries, date);
          data.insert(0, ChartDataPoint(
            label: '${hour.toString().padLeft(2, '0')}:00',
            minutes: minutes,
          ));
        }
        break;

      case TimeRange.week:
        // Create 7 data points for each day of the week
        for (var i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final minutes = _getMinutesForDate(entries, date);
          data.add(ChartDataPoint(
            label: _getDayName(date),
            minutes: minutes,
          ));
        }
        break;

      case TimeRange.month:
        // Create data points for each day of the current month
        final firstDay = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0);
        for (var date = firstDay;
            date.isBefore(lastDay.add(const Duration(days: 1)));
            date = date.add(const Duration(days: 1))) {
          final minutes = _getMinutesForDate(entries, date);
          data.add(ChartDataPoint(
            label: date.day.toString(),
            minutes: minutes,
          ));
        }
        break;

      case TimeRange.year:
        // Create 12 data points for each month
        for (var i = 0; i < 12; i++) {
          final date = DateTime(now.year, i);
          final minutes = _getMinutesForMonth(entries, date);
          data.add(ChartDataPoint(
            label: _getMonthName(date),
            minutes: minutes,
          ));
        }
        break;
    }

    return data;
  }

  int _getMinutesForDate(List<TimeEntry> entries, DateTime date) {
    return entries
        .where((entry) =>
            entry.date != null &&
            entry.date!.year == date.year &&
            entry.date!.month == date.month &&
            entry.date!.day == date.day)
        .fold<int>(
          0,
          (sum, entry) => sum + ((entry.duration ?? 0) ~/ 60),
        );
  }

  int _getMinutesForMonth(List<TimeEntry> entries, DateTime date) {
    return entries
        .where((entry) =>
            entry.date != null &&
            entry.date!.year == date.year &&
            entry.date!.month == date.month)
        .fold<int>(
          0,
          (sum, entry) => sum + ((entry.duration ?? 0) ~/ 60),
        );
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  String _getMonthName(DateTime date) {
    switch (date.month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
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