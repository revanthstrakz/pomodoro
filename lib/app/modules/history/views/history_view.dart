import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pomodoro/app/data/models/pomodoro_models.dart';
import 'package:pomodoro/app/data/services/statistics_service.dart';
import '../controllers/history_controller.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/monthly_chart.dart';
import '../widgets/goals_widget.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics & History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadSessionHistory(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // View selector
            _buildViewSelector(context),
            
            // Content based on selected view
            Expanded(
              child: SingleChildScrollView(
                child: _buildSelectedView(context),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildViewSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'daily',
                  label: Text('Daily'),
                  icon: Icon(Icons.today),
                ),
                ButtonSegment<String>(
                  value: 'weekly',
                  label: Text('Weekly'),
                  icon: Icon(Icons.view_week),
                ),
                ButtonSegment<String>(
                  value: 'monthly',
                  label: Text('Monthly'),
                  icon: Icon(Icons.calendar_month),
                ),
                ButtonSegment<String>(
                  value: 'goals',
                  label: Text('Goals'),
                  icon: Icon(Icons.flag),
                ),
              ],
              selected: {controller.selectedView.value},
              onSelectionChanged: (Set<String> selection) {
                controller.changeView(selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedView(BuildContext context) {
    switch (controller.selectedView.value) {
      case 'weekly':
        return _buildWeeklyView(context);
      case 'monthly':
        return _buildMonthlyView(context);
      case 'goals':
        return _buildGoalsView(context);
      case 'daily':
      default:
        return _buildDailyView(context);
    }
  }

  Widget _buildDailyView(BuildContext context) {
    if (controller.history.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Statistics card
        _buildStatisticsCard(context),

        // Session history list
        _buildHistoryList(context),
      ],
    );
  }

  Widget _buildWeeklyView(BuildContext context) {
    return Obx(() {
      if (controller.weeklyStats.value == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return WeeklyChart(weeklyStats: controller.weeklyStats.value!);
    });
  }

  Widget _buildMonthlyView(BuildContext context) {
    return Obx(() {
      if (controller.monthlyStats.value == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return MonthlyChart(monthlyStats: controller.monthlyStats.value!);
    });
  }

  Widget _buildGoalsView(BuildContext context) {
    final statisticsService = Get.find<StatisticsService>();
    return GoalsWidget(statisticsService: statisticsService);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Session History',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a session to see your history.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.timer),
            label: const Text('Start a Session'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistics', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context: context,
                    icon: Icons.timer,
                    value: controller.totalFocusTime,
                    label: 'Total Focus Time',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context: context,
                    icon: Icons.check_circle_outline,
                    value: '${controller.totalCompletedSessions}',
                    label: 'Sessions Completed',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return ListView.builder(
      itemCount: controller.history.length,
      itemBuilder: (context, index) {
        final day = controller.history[index];
        return _buildDayCard(context, day);
      },
    );
  }

  Widget _buildDayCard(BuildContext context, PomodoroDay day) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(controller.formatDate(day.date)),
        subtitle: Text(
          '${day.completedSessions} sessions - ${day.formattedTotalWorkDuration}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '${day.completedSessions}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: day.sessions.length,
            itemBuilder: (context, index) {
              return _buildSessionListItem(context, day.sessions[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSessionListItem(BuildContext context, PomodoroSession session) {
    // Format session time
    final timeStart =
        '${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}';

    return ListTile(
      dense: true,
      leading: Icon(
        session.type == SessionType.work
            ? Icons.work
            : session.type == SessionType.shortBreak
            ? Icons.coffee
            : Icons.hotel,
        color: session.getTypeColor(context),
      ),
      title: Text(session.title),
      subtitle: Text('${session.typeLabel} - Started at $timeStart'),
      trailing: Text(
        session.formattedDuration,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: session.getTypeColor(context),
        ),
      ),
    );
  }
}
