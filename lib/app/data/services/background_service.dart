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
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}

Future<void> _handleTimerTask(Map<String, dynamic>? inputData) async {
  if (inputData == null) return;

  // This would handle timer updates in background
  // For now, we'll just log the task
  print('Background timer task executed');
  
  // In a real implementation, you would:
  // 1. Update the remaining time
  // 2. Check if session is complete
  // 3. Send appropriate notifications
  // 4. Update persistent storage
}

Future<void> _handleReminderTask(Map<String, dynamic>? inputData) async {
  if (inputData == null) return;

  print('Background reminder task executed');
  
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
      print('Error initializing background service: $e');
    }
  }

  Future<void> _loadBackgroundSettings() async {
    try {
      backgroundServiceEnabled.value = 
          _storageService.read('background_service_enabled') ?? true;
      reminderNotificationsEnabled.value = 
          _storageService.read('reminder_notifications_enabled') ?? true;
      reminderIntervalHours.value = 
          _storageService.read('reminder_interval_hours') ?? 24;
    } catch (e) {
      print('Error loading background settings: $e');
    }
  }

  Future<void> _saveBackgroundSettings() async {
    try {
      await _storageService.write('background_service_enabled', backgroundServiceEnabled.value);
      await _storageService.write('reminder_notifications_enabled', reminderNotificationsEnabled.value);
      await _storageService.write('reminder_interval_hours', reminderIntervalHours.value);
    } catch (e) {
      print('Error saving background settings: $e');
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
      print('Error starting background timer task: $e');
    }
  }

  Future<void> stopTimerBackgroundTask() async {
    try {
      await Workmanager().cancelByUniqueName(timerTaskName);
    } catch (e) {
      print('Error stopping background timer task: $e');
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
      print('Error scheduling reminder notification: $e');
    }
  }

  Future<void> cancelReminderNotification() async {
    try {
      await Workmanager().cancelByUniqueName(reminderTaskName);
    } catch (e) {
      print('Error canceling reminder notification: $e');
    }
  }

  Future<void> cancelAllBackgroundTasks() async {
    try {
      await Workmanager().cancelAll();
    } catch (e) {
      print('Error canceling all background tasks: $e');
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
      print('Error saving timer state: $e');
    }
  }

  // Restore timer state when app resumes
  Future<Map<String, dynamic>?> restoreTimerState() async {
    try {
      final stateJson = _storageService.read('timer_state');
      if (stateJson != null) {
        return json.decode(stateJson) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error restoring timer state: $e');
    }
    return null;
  }

  // Clear timer state
  Future<void> clearTimerState() async {
    try {
      await _storageService.remove('timer_state');
    } catch (e) {
      print('Error clearing timer state: $e');
    }
  }
}