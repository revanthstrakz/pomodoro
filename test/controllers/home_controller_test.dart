import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
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
import 'home_controller_test.mocks.dart';

void main() {
  group('HomeController', () {
    late HomeController homeController;
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

      Get.put<PomodoroService>(mockPomodoroService);
      Get.put<SoundService>(mockSoundService);
      Get.put<VibrationService>(mockVibrationService);
      Get.put<NotificationService>(mockNotificationService);
      Get.put<BackgroundService>(mockBackgroundService);

      homeController = HomeController();
    });

    tearDown(() {
      Get.reset();
    });

    group('initialization', () {
      test('should load settings on init', () async {
        // Arrange
        final mockSettings = PomodoroSettings(
          workTime: 25,
          shortBreakTime: 5,
          longBreakTime: 15,
          sessionsBeforeLongBreak: 4,
        );
        when(mockPomodoroService.getSettings())
            .thenAnswer((_) async => mockSettings);

        // Act
        homeController.onInit();

        // Assert
        expect(homeController.settings.value, mockSettings);
        expect(homeController.timeRemaining.value, 25 * 60); // 25 minutes in seconds
        verify(mockPomodoroService.getSettings()).called(1);
      });
    });

    group('timer controls', () {
      setUp(() {
        final mockSettings = PomodoroSettings(
          workTime: 25,
          shortBreakTime: 5,
          longBreakTime: 15,
          sessionsBeforeLongBreak: 4,
        );
        when(mockPomodoroService.getSettings())
            .thenAnswer((_) async => mockSettings);
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
        when(mockBackgroundService.saveTimerState(
          sessionType: anyNamed('sessionType'),
          sessionTitle: anyNamed('sessionTitle'),
          timeRemaining: anyNamed('timeRemaining'),
          startTime: anyNamed('startTime'),
          isRunning: anyNamed('isRunning'),
          isPaused: anyNamed('isPaused'),
        )).thenAnswer((_) async => {});
      });

      test('should start timer correctly', () {
        // Arrange
        expect(homeController.isRunning.value, false);
        expect(homeController.isPaused.value, false);

        // Act
        homeController.startTimer();

        // Assert
        expect(homeController.isRunning.value, true);
        expect(homeController.isPaused.value, false);
        expect(homeController.sessionStartTime, isNotNull);
        verify(mockSoundService.playSound(SoundType.sessionStart)).called(1);
        verify(mockVibrationService.vibrate(VibrationType.sessionStart)).called(1);
      });

      test('should pause timer correctly', () {
        // Arrange
        homeController.startTimer();
        when(mockVibrationService.vibrate(VibrationType.sessionPause))
            .thenAnswer((_) async => {});
        when(mockNotificationService.cancelTimerNotification())
            .thenAnswer((_) async => {});
        when(mockBackgroundService.stopTimerBackgroundTask())
            .thenAnswer((_) async => {});

        // Act
        homeController.pauseTimer();

        // Assert
        expect(homeController.isRunning.value, false);
        expect(homeController.isPaused.value, true);
        verify(mockVibrationService.vibrate(VibrationType.sessionPause)).called(1);
        verify(mockNotificationService.cancelTimerNotification()).called(1);
        verify(mockBackgroundService.stopTimerBackgroundTask()).called(1);
      });

      test('should reset session correctly', () {
        // Arrange
        homeController.startTimer();
        when(mockNotificationService.cancelTimerNotification())
            .thenAnswer((_) async => {});
        when(mockBackgroundService.stopTimerBackgroundTask())
            .thenAnswer((_) async => {});
        when(mockBackgroundService.clearTimerState())
            .thenAnswer((_) async => {});

        // Act
        homeController.resetSession();

        // Assert
        expect(homeController.isRunning.value, false);
        expect(homeController.isPaused.value, false);
        expect(homeController.sessionStartTime, isNull);
        expect(homeController.timeRemaining.value, 25 * 60); // Reset to work time
        verify(mockNotificationService.cancelTimerNotification()).called(1);
        verify(mockBackgroundService.stopTimerBackgroundTask()).called(1);
        verify(mockBackgroundService.clearTimerState()).called(1);
      });
    });

    group('session management', () {
      test('should skip to next session correctly', () {
        // Arrange
        expect(homeController.currentSessionType.value, SessionType.work);
        expect(homeController.sessionsCompleted.value, 0);

        // Act
        homeController.skipToNextSession();

        // Assert
        expect(homeController.currentSessionType.value, SessionType.shortBreak);
        expect(homeController.sessionTitle.value, "Short Break");
        expect(homeController.sessionsCompleted.value, 1);
      });

      test('should move to long break after configured sessions', () {
        // Arrange
        homeController.sessionsCompleted.value = 3; // One before long break threshold

        // Act
        homeController.skipToNextSession();

        // Assert
        expect(homeController.currentSessionType.value, SessionType.longBreak);
        expect(homeController.sessionTitle.value, "Long Break");
        expect(homeController.sessionsCompleted.value, 4);
      });

      test('should return to work after break sessions', () {
        // Arrange
        homeController.currentSessionType.value = SessionType.shortBreak;

        // Act
        homeController.skipToNextSession();

        // Assert
        expect(homeController.currentSessionType.value, SessionType.work);
        expect(homeController.sessionTitle.value, "Focus Time");
      });
    });

    group('session completion', () {
      test('should complete session and save data', () async {
        // Arrange
        homeController.sessionStartTime = DateTime.now().subtract(const Duration(minutes: 25));
        homeController.timeRemaining.value = 0;
        
        when(mockPomodoroService.saveSession(any)).thenAnswer((_) async => {});
        when(mockSoundService.playSound(SoundType.sessionComplete))
            .thenAnswer((_) async => {});
        when(mockVibrationService.vibrate(VibrationType.sessionComplete))
            .thenAnswer((_) async => {});
        when(mockNotificationService.showSessionCompleteNotification(
          sessionType: anyNamed('sessionType'),
          sessionTitle: anyNamed('sessionTitle'),
          duration: anyNamed('duration'),
        )).thenAnswer((_) async => {});
        when(mockBackgroundService.stopTimerBackgroundTask())
            .thenAnswer((_) async => {});
        when(mockBackgroundService.clearTimerState())
            .thenAnswer((_) async => {});

        // Act
        homeController.completeSession();

        // Assert
        verify(mockPomodoroService.saveSession(any)).called(1);
        verify(mockSoundService.playSound(SoundType.sessionComplete)).called(1);
        verify(mockVibrationService.vibrate(VibrationType.sessionComplete)).called(1);
        verify(mockNotificationService.showSessionCompleteNotification(
          sessionType: anyNamed('sessionType'),
          sessionTitle: anyNamed('sessionTitle'),
          duration: anyNamed('duration'),
        )).called(1);
      });
    });

    group('formatting', () {
      test('should format time remaining correctly', () {
        // Test various time values
        homeController.timeRemaining.value = 1500; // 25:00
        expect(homeController.formattedTimeRemaining, '25:00');

        homeController.timeRemaining.value = 65; // 01:05
        expect(homeController.formattedTimeRemaining, '01:05');

        homeController.timeRemaining.value = 5; // 00:05
        expect(homeController.formattedTimeRemaining, '00:05');

        homeController.timeRemaining.value = 0; // 00:00
        expect(homeController.formattedTimeRemaining, '00:00');
      });

      test('should calculate progress correctly', () {
        // Arrange - 25 minute work session
        homeController.currentSessionType.value = SessionType.work;
        homeController.settings.value = PomodoroSettings(
          workTime: 25,
          shortBreakTime: 5,
          longBreakTime: 15,
          sessionsBeforeLongBreak: 4,
        );

        // Test different remaining times
        homeController.timeRemaining.value = 1500; // 25 minutes remaining (0% progress)
        expect(homeController.progress, 0.0);

        homeController.timeRemaining.value = 750; // 12.5 minutes remaining (50% progress)
        expect(homeController.progress, closeTo(0.5, 0.01));

        homeController.timeRemaining.value = 0; // 0 minutes remaining (100% progress)
        expect(homeController.progress, 1.0);
      });
    });

    group('settings update', () {
      test('should update settings and reset timer', () async {
        // Arrange
        final newSettings = PomodoroSettings(
          workTime: 30,
          shortBreakTime: 10,
          longBreakTime: 20,
          sessionsBeforeLongBreak: 3,
        );
        when(mockPomodoroService.saveSettings(newSettings))
            .thenAnswer((_) async => {});

        // Act
        await homeController.updateSettings(newSettings);

        // Assert
        expect(homeController.settings.value, newSettings);
        expect(homeController.timeRemaining.value, 30 * 60); // New work time
        verify(mockPomodoroService.saveSettings(newSettings)).called(1);
      });
    });
  });
}