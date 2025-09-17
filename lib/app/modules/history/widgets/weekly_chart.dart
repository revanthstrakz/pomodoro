import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pomodoro/app/data/services/statistics_service.dart';

class WeeklyChart extends StatelessWidget {
  final WeeklyStats weeklyStats;

  const WeeklyChart({super.key, required this.weeklyStats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: theme.colorScheme.surface,
                    tooltipBorder: BorderSide(
                      color: theme.colorScheme.outline,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][group.x];
                      final sessions = weeklyStats.dailyStats[group.x].sessions;
                      final minutes = weeklyStats.dailyStats[group.x].workMinutes;
                      return BarTooltipItem(
                        '$day\n$sessions sessions\n${minutes}min',
                        TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
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
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            days[value.toInt()],
                            style: style.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        );
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
                barGroups: _createBarGroups(theme),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Sessions',
                '${weeklyStats.totalSessions}',
                Icons.check_circle_outline,
                theme.colorScheme.primary,
              ),
              _buildStatItem(
                context,
                'Work Time',
                '${(weeklyStats.totalWorkMinutes / 60).toStringAsFixed(1)}h',
                Icons.work_outline,
                theme.colorScheme.secondary,
              ),
              _buildStatItem(
                context,
                'Break Time',
                '${(weeklyStats.totalBreakMinutes / 60).toStringAsFixed(1)}h',
                Icons.coffee_outlined,
                theme.colorScheme.tertiary,
              ),
            ],
          ),
        ],
      ),
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
    final maxSessions = weeklyStats.dailyStats
        .map((day) => day.sessions)
        .reduce((a, b) => a > b ? a : b);
    return (maxSessions + 2).toDouble();
  }

  List<BarChartGroupData> _createBarGroups(ThemeData theme) {
    return weeklyStats.dailyStats.asMap().entries.map((entry) {
      final index = entry.key;
      final dayStats = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dayStats.sessions.toDouble(),
            color: theme.colorScheme.primary,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }
}