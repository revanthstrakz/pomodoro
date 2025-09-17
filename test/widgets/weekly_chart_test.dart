import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pomodoro/app/modules/history/widgets/weekly_chart.dart';
import 'package:pomodoro/app/data/services/statistics_service.dart';

void main() {
  group('WeeklyChart Widget Tests', () {
    late WeeklyStats mockWeeklyStats;

    setUp(() {
      // Create mock weekly stats
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
      
      mockWeeklyStats = WeeklyStats(
        weekStart: weekStart,
        totalSessions: 15,
        totalWorkMinutes: 375, // 6.25 hours
        totalBreakMinutes: 75,  // 1.25 hours
        dailyStats: [
          DailyStats(date: weekStart, sessions: 3, workMinutes: 75, breakMinutes: 15),
          DailyStats(date: weekStart.add(const Duration(days: 1)), sessions: 2, workMinutes: 50, breakMinutes: 10),
          DailyStats(date: weekStart.add(const Duration(days: 2)), sessions: 4, workMinutes: 100, breakMinutes: 20),
          DailyStats(date: weekStart.add(const Duration(days: 3)), sessions: 1, workMinutes: 25, breakMinutes: 5),
          DailyStats(date: weekStart.add(const Duration(days: 4)), sessions: 3, workMinutes: 75, breakMinutes: 15),
          DailyStats(date: weekStart.add(const Duration(days: 5)), sessions: 2, workMinutes: 50, breakMinutes: 10),
          DailyStats(date: weekStart.add(const Duration(days: 6)), sessions: 0, workMinutes: 0, breakMinutes: 0),
        ],
      );
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: WeeklyChart(weeklyStats: mockWeeklyStats),
        ),
      );
    }

    testWidgets('should display weekly overview title', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Weekly Overview'), findsOneWidget);
    });

    testWidgets('should display bar chart', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('should display weekly statistics summary', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Work Time'), findsOneWidget);
      expect(find.text('Break Time'), findsOneWidget);
      expect(find.text('15'), findsOneWidget); // Total sessions
      expect(find.text('6.3h'), findsOneWidget); // Work hours
      expect(find.text('1.3h'), findsOneWidget); // Break hours
    });

    testWidgets('should display correct statistics icons', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.work_outline), findsOneWidget);
      expect(find.byIcon(Icons.coffee_outlined), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should display chart with proper height', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxHeight, 300);
    });
  });

  group('WeeklyStats Data Model Tests', () {
    test('should create WeeklyStats with correct properties', () {
      // Arrange
      final weekStart = DateTime(2023, 12, 4); // Monday
      final dailyStats = [
        DailyStats(date: weekStart, sessions: 2, workMinutes: 50, breakMinutes: 10),
        DailyStats(date: weekStart.add(const Duration(days: 1)), sessions: 3, workMinutes: 75, breakMinutes: 15),
      ];

      // Act
      final weeklyStats = WeeklyStats(
        weekStart: weekStart,
        totalSessions: 5,
        totalWorkMinutes: 125,
        totalBreakMinutes: 25,
        dailyStats: dailyStats,
      );

      // Assert
      expect(weeklyStats.weekStart, weekStart);
      expect(weeklyStats.totalSessions, 5);
      expect(weeklyStats.totalWorkMinutes, 125);
      expect(weeklyStats.totalBreakMinutes, 25);
      expect(weeklyStats.dailyStats.length, 2);
    });
  });

  group('DailyStats Data Model Tests', () {
    test('should create DailyStats with correct properties', () {
      // Arrange
      final date = DateTime(2023, 12, 4);

      // Act
      final dailyStats = DailyStats(
        date: date,
        sessions: 3,
        workMinutes: 75,
        breakMinutes: 15,
      );

      // Assert
      expect(dailyStats.date, date);
      expect(dailyStats.sessions, 3);
      expect(dailyStats.workMinutes, 75);
      expect(dailyStats.breakMinutes, 15);
    });
  });
}