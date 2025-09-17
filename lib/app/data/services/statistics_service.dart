import 'package:get/get.dart';
import 'package:pomodoro/app/core/storage_service.dart';
import 'package:pomodoro/app/data/models/pomodoro_models.dart';
import 'package:pomodoro/app/data/services/pomodoro_service.dart';
import 'dart:convert';

enum GoalType {
  dailySessions,
  weeklyHours,
  monthlyHours,
  streak,
}

class Goal {
  final String id;
  final GoalType type;
  final int target;
  final DateTime createdAt;
  final bool isActive;
  final String title;
  final String description;

  Goal({
    required this.id,
    required this.type,
    required this.target,
    required this.createdAt,
    required this.isActive,
    required this.title,
    required this.description,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      type: GoalType.values.byName(json['type'] as String),
      target: json['target'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'target': target,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'title': title,
      'description': description,
    };
  }
}

class WeeklyStats {
  final DateTime weekStart;
  final int totalSessions;
  final int totalWorkMinutes;
  final int totalBreakMinutes;
  final List<DailyStats> dailyStats;

  WeeklyStats({
    required this.weekStart,
    required this.totalSessions,
    required this.totalWorkMinutes,
    required this.totalBreakMinutes,
    required this.dailyStats,
  });
}

class DailyStats {
  final DateTime date;
  final int sessions;
  final int workMinutes;
  final int breakMinutes;

  DailyStats({
    required this.date,
    required this.sessions,
    required this.workMinutes,
    required this.breakMinutes,
  });
}

class MonthlyStats {
  final DateTime monthStart;
  final int totalSessions;
  final int totalWorkHours;
  final int totalBreakHours;
  final List<WeeklyStats> weeklyStats;

  MonthlyStats({
    required this.monthStart,
    required this.totalSessions,
    required this.totalWorkHours,
    required this.totalBreakHours,
    required this.weeklyStats,
  });
}

class StatisticsService extends GetxService {
  final StorageService _storageService = Get.find<StorageService>();
  final PomodoroService _pomodoroService = Get.find<PomodoroService>();

  final RxList<Goal> goals = <Goal>[].obs;
  final RxInt currentStreak = 0.obs;
  final RxInt longestStreak = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadGoals();
    _calculateStreaks();
  }

  Future<void> _loadGoals() async {
    try {
      final goalsJson = _storageService.read('pomodoro_goals');
      if (goalsJson != null) {
        final List<dynamic> goalsList = json.decode(goalsJson);
        goals.value = goalsList
            .map((goal) => Goal.fromJson(goal as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error loading goals: $e');
    }
  }

  Future<void> _saveGoals() async {
    try {
      final goalsJson = json.encode(goals.map((goal) => goal.toJson()).toList());
      await _storageService.write('pomodoro_goals', goalsJson);
    } catch (e) {
      print('Error saving goals: $e');
    }
  }

  Future<void> addGoal(Goal goal) async {
    goals.add(goal);
    await _saveGoals();
  }

  Future<void> updateGoal(Goal updatedGoal) async {
    final index = goals.indexWhere((goal) => goal.id == updatedGoal.id);
    if (index != -1) {
      goals[index] = updatedGoal;
      await _saveGoals();
    }
  }

  Future<void> removeGoal(String goalId) async {
    goals.removeWhere((goal) => goal.id == goalId);
    await _saveGoals();
  }

  Future<WeeklyStats> getWeeklyStats({DateTime? weekStart}) async {
    weekStart ??= _getWeekStart(DateTime.now());
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    final history = await _pomodoroService.getSessionHistory();
    final weekHistory = history.where((day) =>
        day.date.isAfter(weekStart!.subtract(const Duration(days: 1))) &&
        day.date.isBefore(weekEnd)).toList();

    int totalSessions = 0;
    int totalWorkMinutes = 0;
    int totalBreakMinutes = 0;
    List<DailyStats> dailyStats = [];

    // Create daily stats for each day of the week
    for (int i = 0; i < 7; i++) {
      final currentDate = weekStart.add(Duration(days: i));
      final dayData = weekHistory.firstWhereOrNull(
        (day) => _isSameDay(day.date, currentDate),
      );

      int daySessions = 0;
      int dayWorkMinutes = 0;
      int dayBreakMinutes = 0;

      if (dayData != null) {
        daySessions = dayData.completedSessions;
        dayWorkMinutes = (dayData.totalWorkDuration / 60).round();
        
        // Calculate break minutes
        for (final session in dayData.sessions) {
          if (session.type != SessionType.work && session.completed) {
            dayBreakMinutes += (session.duration / 60).round();
          }
        }
      }

      dailyStats.add(DailyStats(
        date: currentDate,
        sessions: daySessions,
        workMinutes: dayWorkMinutes,
        breakMinutes: dayBreakMinutes,
      ));

      totalSessions += daySessions;
      totalWorkMinutes += dayWorkMinutes;
      totalBreakMinutes += dayBreakMinutes;
    }

    return WeeklyStats(
      weekStart: weekStart,
      totalSessions: totalSessions,
      totalWorkMinutes: totalWorkMinutes,
      totalBreakMinutes: totalBreakMinutes,
      dailyStats: dailyStats,
    );
  }

  Future<MonthlyStats> getMonthlyStats({DateTime? monthStart}) async {
    monthStart ??= DateTime(DateTime.now().year, DateTime.now().month, 1);
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
    
    final history = await _pomodoroService.getSessionHistory();
    final monthHistory = history.where((day) =>
        day.date.isAfter(monthStart!.subtract(const Duration(days: 1))) &&
        day.date.isBefore(monthEnd)).toList();

    int totalSessions = 0;
    int totalWorkHours = 0;
    int totalBreakHours = 0;
    List<WeeklyStats> weeklyStats = [];

    // Generate weekly stats for each week in the month
    DateTime currentWeekStart = _getWeekStart(monthStart);
    while (currentWeekStart.isBefore(monthEnd)) {
      final weekStats = await getWeeklyStats(weekStart: currentWeekStart);
      weeklyStats.add(weekStats);
      
      totalSessions += weekStats.totalSessions;
      totalWorkHours += (weekStats.totalWorkMinutes / 60).round();
      totalBreakHours += (weekStats.totalBreakMinutes / 60).round();
      
      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
    }

    return MonthlyStats(
      monthStart: monthStart,
      totalSessions: totalSessions,
      totalWorkHours: totalWorkHours,
      totalBreakHours: totalBreakHours,
      weeklyStats: weeklyStats,
    );
  }

  Future<void> _calculateStreaks() async {
    final history = await _pomodoroService.getSessionHistory();
    if (history.isEmpty) {
      currentStreak.value = 0;
      longestStreak.value = 0;
      return;
    }

    // Sort history by date (newest first)
    history.sort((a, b) => b.date.compareTo(a.date));

    // Calculate current streak
    int current = 0;
    DateTime today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    for (final day in history) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      
      if (_isSameDay(dayDate, checkDate)) {
        if (day.completedSessions > 0) {
          current++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      } else if (dayDate.isBefore(checkDate)) {
        // Gap in streak
        break;
      }
    }

    currentStreak.value = current;

    // Calculate longest streak
    int longest = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    for (final day in history.reversed) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      
      if (day.completedSessions > 0) {
        if (lastDate == null || 
            dayDate.difference(lastDate).inDays == 1) {
          tempStreak++;
          longest = longest > tempStreak ? longest : tempStreak;
        } else {
          tempStreak = 1;
        }
        lastDate = dayDate;
      } else {
        tempStreak = 0;
      }
    }

    longestStreak.value = longest;
  }

  // Goal progress calculations
  int getDailyProgress(Goal goal, {DateTime? date}) {
    date ??= DateTime.now();
    // Implementation would check today's completed sessions
    // This is a simplified version
    return 0; // Would return actual progress
  }

  double getWeeklyProgress(Goal goal, {DateTime? weekStart}) {
    // Implementation would calculate weekly progress
    return 0.0; // Would return actual progress percentage
  }

  double getMonthlyProgress(Goal goal, {DateTime? monthStart}) {
    // Implementation would calculate monthly progress
    return 0.0; // Would return actual progress percentage
  }

  // Helper methods
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Get productivity insights
  Map<String, dynamic> getProductivityInsights() {
    return {
      'currentStreak': currentStreak.value,
      'longestStreak': longestStreak.value,
      'activeGoals': goals.where((goal) => goal.isActive).length,
      'completedGoals': goals.where((goal) => !goal.isActive).length,
    };
  }

  // Get best performing day of week
  Future<String> getBestDayOfWeek() async {
    final weekStats = await getWeeklyStats();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    int bestDayIndex = 0;
    int bestSessions = 0;
    
    for (int i = 0; i < weekStats.dailyStats.length; i++) {
      if (weekStats.dailyStats[i].sessions > bestSessions) {
        bestSessions = weekStats.dailyStats[i].sessions;
        bestDayIndex = i;
      }
    }
    
    return days[bestDayIndex];
  }
}