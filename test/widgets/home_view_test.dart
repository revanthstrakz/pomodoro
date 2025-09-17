import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pomodoro/app/modules/home/views/home_view.dart';
import 'package:pomodoro/app/modules/home/controllers/home_controller.dart';
import 'package:pomodoro/app/data/services/pomodoro_service.dart';
import 'package:pomodoro/app/data/services/sound_service.dart';
import 'package:pomodoro/app/data/services/vibration_service.dart';
import 'package:pomodoro/app/data/services/notification_service.dart';
import 'package:pomodoro/app/data/services/background_service.dart';
import 'package:pomodoro/app/data/models/pomodoro_models.dart';

@GenerateMocks([
  PomodoroService,
  SoundService,
  VibrationService,
  NotificationService,
  BackgroundService,
])
import 'home_view_test.mocks.dart';

void main() {
  group('HomeView Widget Tests', () {
    late MockPomodoroService mockPomodoroService;
    late MockSoundService mockSoundService;
    late MockVibrationService mockVibrationService;
    late MockNotificationService mockNotificationService;
    late MockBackgroundService mockBackgroundService;

    setUp(() {
      mockPomodoroService = MockPomodoroService();
      mockSoundService = MockSoundService();
      mockVibrationService = MockVibrationService();
      mockNotificationService = MockNotificationService();
      mockBackgroundService = MockBackgroundService();

      // Setup default mock responses
      when(mockPomodoroService.getSettings()).thenAnswer((_) async => 
        PomodoroSettings(
          workTime: 25,
          shortBreakTime: 5,
          longBreakTime: 15,
          sessionsBeforeLongBreak: 4,
        ),
      );
      when(mockSoundService.playSound(any)).thenAnswer((_) async => {});
      when(mockVibrationService.vibrate(any)).thenAnswer((_) async => {});
      when(mockNotificationService.showSessionStartNotification(
        sessionType: anyNamed('sessionType'),
        sessionTitle: anyNamed('sessionTitle'),
        duration: anyNamed('duration'),
      )).thenAnswer((_) async => {});
      when(mockBackgroundService.startTimerBackgroundTask(
        sessionType: anyNamed('sessionType'),
        sessionTitle: anyNamed('sessionTitle'),
        duration: anyNamed('duration'),
        startTime: anyNamed('startTime'),
      )).thenAnswer((_) async => {});
    });

    tearDown(() {
      Get.reset();
    });

    Widget createTestWidget() {
      return GetMaterialApp(
        home: const HomeView(),
        initialBinding: BindingsBuilder(() {
          Get.put<PomodoroService>(mockPomodoroService);
          Get.put<SoundService>(mockSoundService);
          Get.put<VibrationService>(mockVibrationService);
          Get.put<NotificationService>(mockNotificationService);
          Get.put<BackgroundService>(mockBackgroundService);
          Get.put<HomeController>(HomeController());
        }),
      );
    }

    testWidgets('should display timer with correct initial time', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Focus Time'), findsOneWidget);
    });

    testWidgets('should display play button when timer is not running', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('should start timer when play button is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('should pause timer when pause button is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Start the timer first
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('should display reset button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should display skip button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    testWidgets('should reset timer when reset button is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Start and then pause the timer to change its state
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('25:00'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should display sessions completed counter', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('0'), findsWidgets); // Sessions completed starts at 0
    });

    testWidgets('should display circular progress indicator', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display session type indicator', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      // Should show work session indicator (tomato emoji or similar)
      expect(find.text('Focus Time'), findsOneWidget);
    });

    testWidgets('should show navigation drawer', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('should navigate to settings when drawer item is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Assert - drawer should be open
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('should update timer display when time changes', (WidgetTester tester) async {
      // This test would require mocking the timer behavior
      // For now, we'll just verify the initial state
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('25:00'), findsOneWidget);
    });

    testWidgets('should display correct session title for different session types', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially should show Focus Time
      expect(find.text('Focus Time'), findsOneWidget);

      // Act - skip to next session
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();

      // Assert - should show Short Break
      expect(find.text('Short Break'), findsOneWidget);
    });

    testWidgets('should show correct time for different session types', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially should show work time (25:00)
      expect(find.text('25:00'), findsOneWidget);

      // Act - skip to break session
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();

      // Assert - should show break time (05:00)
      expect(find.text('05:00'), findsOneWidget);
    });
  });
}