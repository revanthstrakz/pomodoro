import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pomodoro/app/data/services/statistics_service.dart';

class GoalsWidget extends StatelessWidget {
  final StatisticsService statisticsService;

  const GoalsWidget({super.key, required this.statisticsService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goals & Streaks',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => _showAddGoalDialog(context),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Streak cards
          Row(
            children: [
              Expanded(
                child: _buildStreakCard(
                  context,
                  'Current Streak',
                  '${statisticsService.currentStreak.value}',
                  'days',
                  Icons.local_fire_department,
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStreakCard(
                  context,
                  'Longest Streak',
                  '${statisticsService.longestStreak.value}',
                  'days',
                  Icons.emoji_events,
                  theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Goals list
          Obx(() {
            final activeGoals = statisticsService.goals
                .where((goal) => goal.isActive)
                .toList();
                
            if (activeGoals.isEmpty) {
              return _buildEmptyGoalsState(context);
            }
            
            return Column(
              children: activeGoals.map((goal) => _buildGoalCard(context, goal)).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStreakCard(
    BuildContext context,
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    final theme = Theme.of(context);
    final progress = _calculateGoalProgress(goal);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        goal.description,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleGoalAction(context, goal, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getGoalProgressText(goal),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGoalsState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.flag_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Goals',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Set goals to track your progress and stay motivated!',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddGoalDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Goal'),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateGoalProgress(Goal goal) {
    // This would calculate actual progress based on goal type
    // For demo purposes, returning a random progress
    switch (goal.type) {
      case GoalType.dailySessions:
        return 0.7; // 70% progress
      case GoalType.weeklyHours:
        return 0.5; // 50% progress
      case GoalType.monthlyHours:
        return 0.3; // 30% progress
      case GoalType.streak:
        return 0.8; // 80% progress
    }
  }

  String _getGoalProgressText(Goal goal) {
    switch (goal.type) {
      case GoalType.dailySessions:
        return 'Target: ${goal.target} sessions per day';
      case GoalType.weeklyHours:
        return 'Target: ${goal.target} hours per week';
      case GoalType.monthlyHours:
        return 'Target: ${goal.target} hours per month';
      case GoalType.streak:
        return 'Target: ${goal.target} day streak';
    }
  }

  void _showAddGoalDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Add New Goal'),
        content: const Text('Goal creation dialog would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add goal logic would be here
              Get.back();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _handleGoalAction(BuildContext context, Goal goal, String action) {
    switch (action) {
      case 'edit':
        // Edit goal logic
        break;
      case 'delete':
        statisticsService.removeGoal(goal.id);
        break;
    }
  }
}