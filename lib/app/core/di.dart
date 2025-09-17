import 'package:get/get.dart';
import 'storage_service.dart';
import 'package:pomodoro/app/modules/theme/theme_controller.dart';
import 'package:pomodoro/app/data/services/pomodoro_service.dart';
import 'package:pomodoro/app/data/services/sound_service.dart';
import 'package:pomodoro/app/data/services/vibration_service.dart';
import 'package:pomodoro/app/data/services/notification_service.dart';
import 'package:pomodoro/app/data/services/background_service.dart';
import 'package:pomodoro/app/data/services/statistics_service.dart';

class DependencyInjection {
  static void init() {
    // Register services
    Get.put<StorageService>(StorageService(), permanent: true);
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<PomodoroService>(PomodoroService(), permanent: true);
    Get.put<SoundService>(SoundService(), permanent: true);
    Get.put<VibrationService>(VibrationService(), permanent: true);
    Get.put<NotificationService>(NotificationService(), permanent: true);
    Get.put<BackgroundService>(BackgroundService(), permanent: true);
    Get.put<StatisticsService>(StatisticsService(), permanent: true);
  }
}
