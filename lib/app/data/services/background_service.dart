import 'dart:convert';
import 'package:get/get.dart';
import 'package:workmanager/workmanager.dart';
import 'package:pomodoro/app/core/storage_service.dart';
import 'package:pomodoro/app/data/models/pomodoro_models.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case 'pomodoroTimerTask':
          await _handleTimerTask(inputData);
          break;
        case 'sessionReminderTask':
          await _handleReminderTask(inputData);
          break;
      }
      return Future.value(true);
    } catch (e) {
      // Background task error
      return Future.value(false);
    }
  });
}

Future<void> _handleTimerTask(Map<String, dynamic>? inputData) async {
  if (inputData == null) return;

  // This would handle timer updates in background
  // In a real implementation, you would:
  // 1. Update the remaining time
  // 2. Check if session is complete
  // 3. Send appropriate notifications
  // 4. Update persistent storage
}

Future<void> _handleReminderTask(Map<String, dynamic>? inputData) async {
  if (inputData == null) return;

  // This would send reminder notifications
  // when user hasn't used the app for a while
}

class BackgroundService extends GetxService {
  final StorageService _storageService = Get.find<StorageService>();
  
  // Background service settings
  final RxBool backgroundServiceEnabled = true.obs;
  final RxBool reminderNotificationsEnabled = true.obs;
  final RxInt reminderIntervalHours = 24.obs;

  static const String timerTaskName = 'pomodoroTimerTask';
  static const String reminderTaskName = 'sessionReminderTask';

  @override
  void onInit() {
    super.onInit();
    _initializeBackgroundService();
    _loadBackgroundSettings();
  }

  Future<void> _initializeBackgroundService() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Set to true for debugging
      );
    } catch (e) {
      // Error initializing background service
    }
  }

  Future<void> _loadBackgroundSettings() async {
    try {
      backgroundServiceEnabled.value = 
          (_storageService.read('background_service_enabled') as bool?) ?? true;
      reminderNotificationsEnabled.value = 
          (_storageService.read('reminder_notifications_enabled') as bool?) ?? true;
      reminderIntervalHours.value = 
          (_storageService.read('reminder_interval_hours') as int?) ?? 24;
    } catch (e) {
      // Error loading background settings
    }
  }

  Future<void> _saveBackgroundSettings() async {
    try {
      await _storageService.write('background_service_enabled', backgroundServiceEnabled.value);
      await _storageService.write('reminder_notifications_enabled', reminderNotificationsEnabled.value);
      await _storageService.write('reminder_interval_hours', reminderIntervalHours.value);
    } catch (e) {
      // Error saving background settings
    }
  }

  Future<void> startTimerBackgroundTask({
    required SessionType sessionType,
    required String sessionTitle,
    required int duration,
    required DateTime startTime,
  }) async {
    if (!backgroundServiceEnabled.value) return;

    try {
      // Cancel any existing timer task
      await Workmanager().cancelByUniqueName(timerTaskName);

      // Schedule periodic updates for the timer
      await Workmanager().registerPeriodicTask(
        timerTaskName,
        timerTaskName,
        frequency: const Duration(minutes: 1), // Update every minute
        inputData: {
          'sessionType': sessionType.name,
          'sessionTitle': sessionTitle,
          'duration': duration,
          'startTime': startTime.toIso8601String(),
        },
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
    } catch (e) {
      // Error starting background timer task
    }
  }

  Future<void> stopTimerBackgroundTask() async {
    try {
      await Workmanager().cancelByUniqueName(timerTaskName);
    } catch (e) {
      // Error stopping background timer task
    }
  }

  Future<void> scheduleReminderNotification() async {
    if (!reminderNotificationsEnabled.value) return;

    try {
      // Cancel any existing reminder task
      await Workmanager().cancelByUniqueName(reminderTaskName);

      // Schedule reminder notification
      await Workmanager().registerPeriodicTask(
        reminderTaskName,
        reminderTaskName,
        frequency: Duration(hours: reminderIntervalHours.value),
        inputData: {
          'reminderType': 'daily_reminder',
          'message': 'Time for a productive Pomodoro session!',
        },
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
    } catch (e) {
      // Error scheduling reminder notification
    }
  }

  Future<void> cancelReminderNotification() async {
    try {
      await Workmanager().cancelByUniqueName(reminderTaskName);
    } catch (e) {
      // Error canceling reminder notification
    }
  }

  Future<void> cancelAllBackgroundTasks() async {
    try {
      await Workmanager().cancelAll();
    } catch (e) {
      // Error canceling all background tasks
    }
  }

  // Settings update methods
  Future<void> updateBackgroundServiceEnabled(bool enabled) async {
    backgroundServiceEnabled.value = enabled;
    await _saveBackgroundSettings();
    
    if (!enabled) {
      await cancelAllBackgroundTasks();
    } else {
      // Re-initialize if needed
      await _initializeBackgroundService();
    }
  }

  Future<void> updateReminderNotificationsEnabled(bool enabled) async {
    reminderNotificationsEnabled.value = enabled;
    await _saveBackgroundSettings();
    
    if (enabled) {
      await scheduleReminderNotification();
    } else {
      await cancelReminderNotification();
    }
  }

  Future<void> updateReminderIntervalHours(int hours) async {
    if (hours > 0 && hours <= 168) { // Max 1 week
      reminderIntervalHours.value = hours;
      await _saveBackgroundSettings();
      
      if (reminderNotificationsEnabled.value) {
        await scheduleReminderNotification();
      }
    }
  }

  // Save timer state for background recovery
  Future<void> saveTimerState({
    required SessionType sessionType,
    required String sessionTitle,
    required int timeRemaining,
    required DateTime startTime,
    required bool isRunning,
    required bool isPaused,
  }) async {
    try {
      final timerState = {
        'sessionType': sessionType.name,
        'sessionTitle': sessionTitle,
        'timeRemaining': timeRemaining,
        'startTime': startTime.toIso8601String(),
        'isRunning': isRunning,
        'isPaused': isPaused,
        'lastUpdate': DateTime.now().toIso8601String(),
      };

      await _storageService.write('timer_state', json.encode(timerState));
    } catch (e) {
      // Error saving timer state
    }
  }

  // Restore timer state when app resumes
  Future<Map<String, dynamic>?> restoreTimerState() async {
    try {
      final stateJson = _storageService.read('timer_state') as String?;
      if (stateJson != null) {
        return json.decode(stateJson) as Map<String, dynamic>;
      }
    } catch (e) {
      // Error restoring timer state
    }
    return null;
  }

  // Clear timer state
  Future<void> clearTimerState() async {
    try {
      await _storageService.remove('timer_state');
    } catch (e) {
      // Error clearing timer state
    }
  }
}