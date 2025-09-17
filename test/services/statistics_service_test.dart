import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pomodoro/app/core/storage_service.dart';
import 'package:pomodoro/app/data/services/pomodoro_service.dart';
import 'package:pomodoro/app/data/services/statistics_service.dart';
import 'package:pomodoro/app/data/models/pomodoro_models.dart';

@GenerateMocks([StorageService, PomodoroService])
import 'statistics_service_test.mocks.dart';

void main() {
  group('StatisticsService', () {
    late StatisticsService statisticsService;
    late MockStorageService mockStorageService;
    late MockPomodoroService mockPomodoroService;

    setUp(() {
      mockStorageService = MockStorageService();
      mockPomodoroService = MockPomodoroService();
      Get.put<StorageService>(mockStorageService);
      Get.put<PomodoroService>(mockPomodoroService);
      statisticsService = StatisticsService();
    });

    tearDown(() {
      Get.reset();
    });

    group('Goal management', () {
      test('should add a new goal', () async {
        // Arrange
        when(mockStorageService.write(any, any)).thenAnswer((_) async => {});
        final goal = Goal(
          id: '1',
          type: GoalType.dailySessions,
          target: 4,
          createdAt: DateTime.now(),
          isActive: true,
          title: 'Daily Sessions Goal',
          description: 'Complete 4 sessions daily',
        );

        // Act
        await statisticsService.addGoal(goal);

        // Assert
        expect(statisticsService.goals.length, 1);
        expect(statisticsService.goals.first.id, '1');
        verify(mockStorageService.write('pomodoro_goals', any)).called(1);
      });

      test('should update existing goal', () async {
        // Arrange
        when(mockStorageService.write(any, any)).thenAnswer((_) async => {});
        final goal = Goal(
          id: '1',
          type: GoalType.dailySessions,
          target: 4,
          createdAt: DateTime.now(),
          isActive: true,
          title: 'Daily Sessions Goal',
          description: 'Complete 4 sessions daily',
        );
        statisticsService.goals.add(goal);

        final updatedGoal = Goal(
          id: '1',
          type: GoalType.dailySessions,
          target: 6,
          createdAt: goal.createdAt,
          isActive: true,
          title: 'Updated Daily Sessions Goal',
          description: 'Complete 6 sessions daily',
        );

        // Act
        await statisticsService.updateGoal(updatedGoal);

        // Assert
        expect(statisticsService.goals.length, 1);
        expect(statisticsService.goals.first.target, 6);
        expect(statisticsService.goals.first.title, 'Updated Daily Sessions Goal');
        verify(mockStorageService.write('pomodoro_goals', any)).called(1);
      });

      test('should remove goal', () async {
        // Arrange
        when(mockStorageService.write(any, any)).thenAnswer((_) async => {});
        final goal = Goal(
          id: '1',
          type: GoalType.dailySessions,
          target: 4,
          createdAt: DateTime.now(),
          isActive: true,
          title: 'Daily Sessions Goal',
          description: 'Complete 4 sessions daily',
        );
        statisticsService.goals.add(goal);

        // Act
        await statisticsService.removeGoal('1');

        // Assert
        expect(statisticsService.goals.length, 0);
        verify(mockStorageService.write('pomodoro_goals', any)).called(1);
      });
    });

    group('Weekly statistics', () {
      test('should calculate weekly stats correctly', () async {
        // Arrange
        final now = DateTime.now();
        final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
        
        final mockHistory = [
          PomodoroDay(
            date: weekStart,
            sessions: [
              PomodoroSession(
                id: '1',
                title: 'Work Session',
                startTime: weekStart,
                endTime: weekStart.add(const Duration(minutes: 25)),
                type: SessionType.work,
                duration: 1500,
                targetDuration: 1500,
                completed: true,
              ),
            ],
          ),
          PomodoroDay(
            date: weekStart.add(const Duration(days: 1)),
            sessions: [
              PomodoroSession(
                id: '2',
                title: 'Work Session',
                startTime: weekStart.add(const Duration(days: 1)),
                endTime: weekStart.add(const Duration(days: 1, minutes: 25)),
                type: SessionType.work,
                duration: 1500,
                targetDuration: 1500,
                completed: true,
              ),
              PomodoroSession(
                id: '3',
                title: 'Short Break',
                startTime: weekStart.add(const Duration(days: 1, minutes: 30)),
                endTime: weekStart.add(const Duration(days: 1, minutes: 35)),
                type: SessionType.shortBreak,
                duration: 300,
                targetDuration: 300,
                completed: true,
              ),
            ],
          ),
        ];

        when(mockPomodoroService.getSessionHistory())
            .thenAnswer((_) async => mockHistory);

        // Act
        final weeklyStats = await statisticsService.getWeeklyStats(weekStart: weekStart);

        // Assert
        expect(weeklyStats.weekStart, weekStart);
        expect(weeklyStats.totalSessions, 2); // Only work sessions count
        expect(weeklyStats.totalWorkMinutes, 50); // 25 + 25 minutes
        expect(weeklyStats.totalBreakMinutes, 5); // 5 minutes break
        expect(weeklyStats.dailyStats.length, 7); // 7 days in a week
      });
    });

    group('Monthly statistics', () {
      test('should calculate monthly stats correctly', () async {
        // Arrange
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        
        when(mockPomodoroService.getSessionHistory())
            .thenAnswer((_) async => []);

        // Act
        final monthlyStats = await statisticsService.getMonthlyStats(monthStart: monthStart);

        // Assert
        expect(monthlyStats.monthStart, monthStart);
        expect(monthlyStats.totalSessions, 0);
        expect(monthlyStats.totalWorkHours, 0);
        expect(monthlyStats.totalBreakHours, 0);
        expect(monthlyStats.weeklyStats, isNotEmpty);
      });
    });

    group('Goal types', () {
      test('should have all expected goal types', () {
        // Assert
        expect(GoalType.values, contains(GoalType.dailySessions));
        expect(GoalType.values, contains(GoalType.weeklyHours));
        expect(GoalType.values, contains(GoalType.monthlyHours));
        expect(GoalType.values, contains(GoalType.streak));
      });
    });

    group('Goal serialization', () {
      test('should serialize and deserialize goal correctly', () {
        // Arrange
        final originalGoal = Goal(
          id: 'test-id',
          type: GoalType.weeklyHours,
          target: 10,
          createdAt: DateTime(2023, 12, 1),
          isActive: true,
          title: 'Test Goal',
          description: 'Test Description',
        );

        // Act
        final json = originalGoal.toJson();
        final deserializedGoal = Goal.fromJson(json);

        // Assert
        expect(deserializedGoal.id, originalGoal.id);
        expect(deserializedGoal.type, originalGoal.type);
        expect(deserializedGoal.target, originalGoal.target);
        expect(deserializedGoal.createdAt, originalGoal.createdAt);
        expect(deserializedGoal.isActive, originalGoal.isActive);
        expect(deserializedGoal.title, originalGoal.title);
        expect(deserializedGoal.description, originalGoal.description);
      });
    });

    group('Productivity insights', () {
      test('should return productivity insights', () {
        // Arrange
        statisticsService.currentStreak.value = 5;
        statisticsService.longestStreak.value = 12;
        statisticsService.goals.addAll([
          Goal(
            id: '1',
            type: GoalType.dailySessions,
            target: 4,
            createdAt: DateTime.now(),
            isActive: true,
            title: 'Active Goal 1',
            description: 'Description 1',
          ),
          Goal(
            id: '2',
            type: GoalType.weeklyHours,
            target: 10,
            createdAt: DateTime.now(),
            isActive: false,
            title: 'Inactive Goal',
            description: 'Description 2',
          ),
        ]);

        // Act
        final insights = statisticsService.getProductivityInsights();

        // Assert
        expect(insights['currentStreak'], 5);
        expect(insights['longestStreak'], 12);
        expect(insights['activeGoals'], 1);
        expect(insights['completedGoals'], 1);
      });
    });
  });
}