import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:pomodoro/app/data/models/pomodoro_models.dart';
import 'package:pomodoro/app/data/services/pomodoro_service.dart';
import 'package:pomodoro/app/data/services/sound_service.dart';
import 'package:pomodoro/app/data/services/vibration_service.dart';
import 'package:pomodoro/app/data/services/notification_service.dart';
import 'package:pomodoro/app/data/services/background_service.dart';

class HomeController extends GetxController {
  final PomodoroService _pomodoroService = Get.find<PomodoroService>();
  final SoundService _soundService = Get.find<SoundService>();
  final VibrationService _vibrationService = Get.find<VibrationService>();
  final NotificationService _notificationService = Get.find<NotificationService>();
  final BackgroundService _backgroundService = Get.find<BackgroundService>();

  // Timer
  Timer? _timer;
  final RxInt timeRemaining = 0.obs;
  final RxBool isRunning = false.obs;
  final RxBool isPaused = false.obs;
  final Rx<SessionType> currentSessionType = SessionType.work.obs;
  final RxInt sessionsCompleted = 0.obs;
  final RxString sessionTitle = "Focus Time".obs;

  // Settings
  final Rx<PomodoroSettings> settings = PomodoroSettings(
    workTime: 25,
    shortBreakTime: 5,
    longBreakTime: 15,
    sessionsBeforeLongBreak: 4,
  ).obs;

  // Session tracking
  DateTime? sessionStartTime;
  final uuid = const Uuid();

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  @override
  void onClose() {
    _timer?.cancel();
    _backgroundService.stopTimerBackgroundTask();
    _notificationService.cancelTimerNotification();
    super.onClose();
  }

  Future<void> _loadSettings() async {
    settings.value = await _pomodoroService.getSettings();
    _resetTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    isRunning.value = false;
    isPaused.value = false;

    switch (currentSessionType.value) {
      case SessionType.work:
        timeRemaining.value = settings.value.workTime * 60;
        break;
      case SessionType.shortBreak:
        timeRemaining.value = settings.value.shortBreakTime * 60;
        break;
      case SessionType.longBreak:
        timeRemaining.value = settings.value.longBreakTime * 60;
        break;
    }
  }

  void startTimer() {
    if (isRunning.value && !isPaused.value) return;

    // Record start time if starting fresh
    if (!isPaused.value) {
      sessionStartTime = DateTime.now();
      // Play start sound and vibration
      _soundService.playSound(SoundType.sessionStart);
      _vibrationService.vibrate(VibrationType.sessionStart);
      
      // Show notification for session start
      _notificationService.showSessionStartNotification(
        sessionType: currentSessionType.value,
        sessionTitle: sessionTitle.value,
        duration: timeRemaining.value,
      );
      
      // Start background task
      _backgroundService.startTimerBackgroundTask(
        sessionType: currentSessionType.value,
        sessionTitle: sessionTitle.value,
        duration: timeRemaining.value,
        startTime: sessionStartTime!,
      );
    } else {
      // Resume from pause
      _vibrationService.vibrate(VibrationType.sessionResume);
    }

    isRunning.value = true;
    isPaused.value = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining.value > 0) {
        timeRemaining.value--;
        
        // Play tick sound if enabled
        if (_soundService.tickSoundEnabled.value) {
          _soundService.playSound(SoundType.tick);
        }
        
        // Tick vibration if enabled
        if (_vibrationService.tickVibrationEnabled.value) {
          _vibrationService.vibrate(VibrationType.tick);
        }
        
        // Update notification progress
        _notificationService.updateTimerNotification(
          sessionType: currentSessionType.value,
          sessionTitle: sessionTitle.value,
          timeRemaining: timeRemaining.value,
          progress: progress,
        );
        
        // Save timer state for background recovery
        _backgroundService.saveTimerState(
          sessionType: currentSessionType.value,
          sessionTitle: sessionTitle.value,
          timeRemaining: timeRemaining.value,
          startTime: sessionStartTime!,
          isRunning: isRunning.value,
          isPaused: isPaused.value,
        );
      } else {
        completeSession();
      }
    });
  }

  void pauseTimer() {
    if (!isRunning.value) return;

    _timer?.cancel();
    isPaused.value = true;
    
    // Play pause vibration
    _vibrationService.vibrate(VibrationType.sessionPause);
    
    // Cancel timer notification
    _notificationService.cancelTimerNotification();
    
    // Stop background task
    _backgroundService.stopTimerBackgroundTask();
  }

  void resetSession() {
    _timer?.cancel();
    _resetTimer();
    sessionStartTime = null;
    
    // Cancel all notifications and background tasks
    _notificationService.cancelTimerNotification();
    _backgroundService.stopTimerBackgroundTask();
    _backgroundService.clearTimerState();
  }

  void skipToNextSession() {
    _timer?.cancel();

    // Skip to next session type based on current session
    if (currentSessionType.value == SessionType.work) {
      // Increment completed sessions
      sessionsCompleted.value++;

      // Check if we should take a long break
      if (sessionsCompleted.value % settings.value.sessionsBeforeLongBreak ==
          0) {
        currentSessionType.value = SessionType.longBreak;
        sessionTitle.value = "Long Break";
      } else {
        currentSessionType.value = SessionType.shortBreak;
        sessionTitle.value = "Short Break";
      }
    } else {
      // After any break, go back to work
      currentSessionType.value = SessionType.work;
      sessionTitle.value = "Focus Time";
    }

    _resetTimer();
  }

  void completeSession() {
    _timer?.cancel();

    // Save the completed session
    if (sessionStartTime != null) {
      final session = PomodoroSession(
        id: uuid.v4(),
        title: sessionTitle.value,
        startTime: sessionStartTime!,
        endTime: DateTime.now(),
        type: currentSessionType.value,
        duration: currentSessionType.value == SessionType.work
            ? settings.value.workTime * 60 - timeRemaining.value
            : currentSessionType.value == SessionType.shortBreak
            ? settings.value.shortBreakTime * 60 - timeRemaining.value
            : settings.value.longBreakTime * 60 - timeRemaining.value,
        targetDuration: currentSessionType.value == SessionType.work
            ? settings.value.workTime * 60
            : currentSessionType.value == SessionType.shortBreak
            ? settings.value.shortBreakTime * 60
            : settings.value.longBreakTime * 60,
        completed: true,
      );

      _pomodoroService.saveSession(session);
    }

    // Play completion sound and vibration
    _soundService.playSound(SoundType.sessionComplete);
    _vibrationService.vibrate(VibrationType.sessionComplete);

    // Show completion notification
    _notificationService.showSessionCompleteNotification(
      sessionType: currentSessionType.value,
      sessionTitle: sessionTitle.value,
      duration: currentSessionType.value == SessionType.work
          ? settings.value.workTime * 60 - timeRemaining.value
          : currentSessionType.value == SessionType.shortBreak
          ? settings.value.shortBreakTime * 60 - timeRemaining.value
          : settings.value.longBreakTime * 60 - timeRemaining.value,
    );

    // Show in-app notification
    Get.snackbar(
      'Session Complete!',
      'Great job! Take a moment to stretch.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );

    // Cancel background tasks
    _backgroundService.stopTimerBackgroundTask();
    _backgroundService.clearTimerState();

    // Move to next session
    skipToNextSession();
  }

  // For UI formatting
  String get formattedTimeRemaining {
    final minutes = (timeRemaining.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (timeRemaining.value % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Progress as a percentage (for circular progress indicator)
  double get progress {
    final total = currentSessionType.value == SessionType.work
        ? settings.value.workTime * 60
        : currentSessionType.value == SessionType.shortBreak
        ? settings.value.shortBreakTime * 60
        : settings.value.longBreakTime * 60;
    return 1 - (timeRemaining.value / total);
  }

  Color getSessionTypeColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (currentSessionType.value) {
      case SessionType.work:
        return colorScheme.primary;
      case SessionType.shortBreak:
        return colorScheme.tertiary;
      case SessionType.longBreak:
        return colorScheme.secondary;
    }
  }

  Future<void> updateSettings(PomodoroSettings newSettings) async {
    settings.value = newSettings;
    await _pomodoroService.saveSettings(newSettings);

    // Reset timer with new settings
    _resetTimer();
  }
}
