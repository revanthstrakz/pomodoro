import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pomodoro/app/data/services/statistics_service.dart';

class MonthlyChart extends StatelessWidget {
  final MonthlyStats monthlyStats;

  const MonthlyChart({super.key, required this.monthlyStats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final weekIndex = value.toInt();
                        if (weekIndex >= 0 && weekIndex < monthlyStats.weeklyStats.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              'W${weekIndex + 1}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${value.toInt()}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (monthlyStats.weeklyStats.length - 1).toDouble(),
                minY: 0,
                maxY: _getMaxY(),
                lineBarsData: [
                  // Sessions line
                  LineChartBarData(
                    spots: _getSessionSpots(),
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: theme.colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: theme.colorScheme.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  // Work hours line
                  LineChartBarData(
                    spots: _getWorkHoursSpots(),
                    isCurved: true,
                    color: theme.colorScheme.secondary,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: theme.colorScheme.secondary,
                          strokeWidth: 2,
                          strokeColor: theme.colorScheme.surface,
                        );
                      },
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => theme.colorScheme.surface,
                    tooltipBorder: BorderSide(
                      color: theme.colorScheme.outline,
                    ),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final weekIndex = touchedSpot.x.toInt();
                        final weekStats = monthlyStats.weeklyStats[weekIndex];
                        
                        if (touchedSpot.barIndex == 0) {
                          return LineTooltipItem(
                            'Week ${weekIndex + 1}\n${weekStats.totalSessions} sessions',
                            TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } else {
                          return LineTooltipItem(
                            'Week ${weekIndex + 1}\n${(weekStats.totalWorkMinutes / 60).toStringAsFixed(1)}h work',
                            TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                context,
                'Sessions',
                theme.colorScheme.primary,
              ),
              const SizedBox(width: 24),
              _buildLegendItem(
                context,
                'Work Hours',
                theme.colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Monthly summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Total Sessions',
                '${monthlyStats.totalSessions}',
                Icons.check_circle_outline,
                theme.colorScheme.primary,
              ),
              _buildStatItem(
                context,
                'Work Hours',
                '${monthlyStats.totalWorkHours}h',
                Icons.work_outline,
                theme.colorScheme.secondary,
              ),
              _buildStatItem(
                context,
                'Break Hours',
                '${monthlyStats.totalBreakHours}h',
                Icons.coffee_outlined,
                theme.colorScheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  double _getMaxY() {
    final maxSessions = monthlyStats.weeklyStats
        .map((week) => week.totalSessions)
        .reduce((a, b) => a > b ? a : b);
    final maxWorkHours = monthlyStats.weeklyStats
        .map((week) => (week.totalWorkMinutes / 60).round())
        .reduce((a, b) => a > b ? a : b);
    
    return (maxSessions > maxWorkHours ? maxSessions : maxWorkHours) + 5.0;
  }

  List<FlSpot> _getSessionSpots() {
    return monthlyStats.weeklyStats.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalSessions.toDouble());
    }).toList();
  }

  List<FlSpot> _getWorkHoursSpots() {
    return monthlyStats.weeklyStats.asMap().entries.map((entry) {
      final workHours = (entry.value.totalWorkMinutes / 60).round();
      return FlSpot(entry.key.toDouble(), workHours.toDouble());
    }).toList();
  }
}