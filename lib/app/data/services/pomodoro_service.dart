import 'dart:convert';
import 'package:get/get.dart';
import 'package:pomodoro/app/core/constants.dart';
import 'package:pomodoro/app/core/storage_service.dart';
import 'package:pomodoro/app/data/models/pomodoro_models.dart';

class PomodoroService extends GetxService {
  final StorageService _storageService = Get.find<StorageService>();

  // Load settings from storage or return defaults
  Future<PomodoroSettings> getSettings() async {
    final settingsJson =
        await _storageService.read(AppConstants.storageSettingsKey);

    if (settingsJson != null) {
      try {
        final Map<String, dynamic> settingsMap = json.decode(settingsJson);
        return PomodoroSettings.fromJson(settingsMap);
      } catch (e) {
        return _getDefaultSettings();
      }
    } else {
      return _getDefaultSettings();
    }
  }

  PomodoroSettings _getDefaultSettings() {
    return PomodoroSettings(
      workTime: AppConstants.defaultWorkTime,
      shortBreakTime: AppConstants.defaultShortBreak,
      longBreakTime: AppConstants.defaultLongBreak,
      sessionsBeforeLongBreak: AppConstants.defaultSessionsBeforeLongBreak,
    );
  }

  // Save settings
  Future<void> saveSettings(PomodoroSettings settings) async {
    final settingsJson = json.encode(settings.toJson());
    await _storageService.write(AppConstants.storageSettingsKey, settingsJson);
  }

  // Get session history
  Future<List<PomodoroDay>> getSessionHistory() async {
    final historyJson =
        await _storageService.read(AppConstants.storageHistoryKey);
    if (historyJson != null) {
      try {
        final List<dynamic> historyList = json.decode(historyJson);
        return historyList
            .map((day) => PomodoroDay.fromJson(day as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Error parsing session history: $e');
        return [];
      }
    } else {
      return [];
    }
  }

  // Save a completed session
  Future<void> saveSession(PomodoroSession session) async {
    // Get existing history
    final history = await getSessionHistory();

    // Find if there's already a day entry for today
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final todayIndex = history.indexWhere(
      (day) =>
          day.date.year == today.year &&
          day.date.month == today.month &&
          day.date.day == today.day,
    );

    if (todayIndex >= 0) {
      // Add to existing day
      history[todayIndex].sessions.add(session);
    } else {
      // Create new day
      history.add(PomodoroDay(
        date: today,
        sessions: [session],
      ));
    }

    // Sort history by date (newest first)
    history.sort((a, b) => b.date.compareTo(a.date));

    // Save updated history
    final historyJson =
        json.encode(history.map((day) => day.toJson()).toList());
    await _storageService.write(AppConstants.storageHistoryKey, historyJson);
  }
}
