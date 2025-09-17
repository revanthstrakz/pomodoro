import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pomodoro/app/modules/history/widgets/goals_widget.dart';
import 'package:pomodoro/app/data/services/statistics_service.dart';

@GenerateMocks([StatisticsService])
import 'goals_widget_test.mocks.dart';

void main() {
  group('GoalsWidget Widget Tests', () {
    late MockStatisticsService mockStatisticsService;

    setUp(() {
      mockStatisticsService = MockStatisticsService();
      
      // Setup default mock responses
      when(mockStatisticsService.currentStreak).thenReturn(RxInt(5));
      when(mockStatisticsService.longestStreak).thenReturn(RxInt(12));
      when(mockStatisticsService.goals).thenReturn(RxList<Goal>([]));
    });

    tearDown(() {
      Get.reset();
    });

    Widget createTestWidget() {
      return GetMaterialApp(
        home: Scaffold(
          body: GoalsWidget(statisticsService: mockStatisticsService),
        ),
      );
    }

    testWidgets('should display goals and streaks title', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Goals & Streaks'), findsOneWidget);
    });

    testWidgets('should display add goal button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should display current streak card', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('days'), findsWidgets);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('should display longest streak card', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Longest Streak'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('should display empty goals state when no goals exist', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No Active Goals'), findsOneWidget);
      expect(find.text('Set goals to track your progress and stay motivated!'), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      expect(find.text('Add Goal'), findsOneWidget);
    });

    testWidgets('should display goal cards when goals exist', (WidgetTester tester) async {
      // Arrange
      final mockGoals = [
        Goal(
          id: '1',
          type: GoalType.dailySessions,
          target: 4,
          createdAt: DateTime.now(),
          isActive: true,
          title: 'Daily Sessions Goal',
          description: 'Complete 4 sessions daily',
        ),
        Goal(
          id: '2',
          type: GoalType.weeklyHours,
          target: 10,
          createdAt: DateTime.now(),
          isActive: true,
          title: 'Weekly Hours Goal',
          description: 'Work 10 hours per week',
        ),
      ];
      when(mockStatisticsService.goals).thenReturn(RxList<Goal>(mockGoals));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Daily Sessions Goal'), findsOneWidget);
      expect(find.text('Complete 4 sessions daily'), findsOneWidget);
      expect(find.text('Weekly Hours Goal'), findsOneWidget);
      expect(find.text('Work 10 hours per week'), findsOneWidget);
    });

    testWidgets('should show progress indicators for goals', (WidgetTester tester) async {
      // Arrange
      final mockGoals = [
        Goal(
          id: '1',
          type: GoalType.dailySessions,
          target: 4,
          createdAt: DateTime.now(),
          isActive: true,
          title: 'Daily Sessions Goal',
          description: 'Complete 4 sessions daily',
        ),
      ];
      when(mockStatisticsService.goals).thenReturn(RxList<Goal>(mockGoals));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('%'), findsOneWidget);
    });

    testWidgets('should show goal menu when tapped', (WidgetTester tester) async {
      // Arrange
      final mockGoals = [
        Goal(
          id: '1',
          type: GoalType.dailySessions,
          target: 4,
          createdAt: DateTime.now(),
          isActive: true,
          title: 'Daily Sessions Goal',
          description: 'Complete 4 sessions daily',
        ),
      ];
      when(mockStatisticsService.goals).thenReturn(RxList<Goal>(mockGoals));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('should show add goal dialog when add button is tapped', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Add New Goal'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('should display proper goal progress text', (WidgetTester tester) async {
      // Arrange
      final mockGoals = [
        Goal(
          id: '1',
          type: GoalType.dailySessions,
          target: 4,
          createdAt: DateTime.now(),
          isActive: true,
          title: 'Daily Sessions Goal',
          description: 'Complete 4 sessions daily',
        ),
        Goal(
          id: '2',
          type: GoalType.weeklyHours,
          target: 10,
          createdAt: DateTime.now(),
          isActive: true,
          title: 'Weekly Hours Goal',
          description: 'Work 10 hours per week',
        ),
      ];
      when(mockStatisticsService.goals).thenReturn(RxList<Goal>(mockGoals));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Target: 4 sessions per day'), findsOneWidget);
      expect(find.text('Target: 10 hours per week'), findsOneWidget);
    });

    testWidgets('should have proper card layout', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('Goal Data Model Tests', () {
    test('should create Goal with correct properties', () {
      // Arrange
      final createdAt = DateTime.now();

      // Act
      final goal = Goal(
        id: 'test-id',
        type: GoalType.dailySessions,
        target: 5,
        createdAt: createdAt,
        isActive: true,
        title: 'Test Goal',
        description: 'Test Description',
      );

      // Assert
      expect(goal.id, 'test-id');
      expect(goal.type, GoalType.dailySessions);
      expect(goal.target, 5);
      expect(goal.createdAt, createdAt);
      expect(goal.isActive, true);
      expect(goal.title, 'Test Goal');
      expect(goal.description, 'Test Description');
    });

    test('should serialize and deserialize Goal correctly', () {
      // Arrange
      final originalGoal = Goal(
        id: 'test-id',
        type: GoalType.weeklyHours,
        target: 10,
        createdAt: DateTime(2023, 12, 1),
        isActive: false,
        title: 'Weekly Goal',
        description: 'Work 10 hours weekly',
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
}