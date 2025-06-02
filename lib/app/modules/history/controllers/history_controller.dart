import 'package:get/get.dart';
import 'package:pomodoro/app/data/models/pomodoro_models.dart';
import 'package:pomodoro/app/data/services/pomodoro_service.dart';

class HistoryController extends GetxController {
  final PomodoroService _pomodoroService = Get.find<PomodoroService>();

  final RxList<PomodoroDay> history = <PomodoroDay>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSessionHistory();
  }

  Future<void> loadSessionHistory() async {
    isLoading.value = true;
    try {
      history.value = await _pomodoroService.getSessionHistory();
      print('Loaded history: ${history.length} days');
      for (var day in history) {
        print('Day: ${day.date} with ${day.sessions.length} sessions');
      }
    } catch (e) {
      print('Error loading history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Get total focus time across all days
  String get totalFocusTime {
    final totalSeconds = history.fold<int>(
      0,
      (sum, day) => sum + day.totalWorkDuration,
    );

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours h $minutes min';
    } else {
      return '$minutes min';
    }
  }

  // Get total completed sessions across all days
  int get totalCompletedSessions {
    return history.fold<int>(0, (sum, day) => sum + day.completedSessions);
  }

  // Format date for display
  String formatDate(DateTime date) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      // Format as Month Day, Year
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}
