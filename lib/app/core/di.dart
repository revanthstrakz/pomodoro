import 'package:get/get.dart';
import 'storage_service.dart';
import 'package:pomodoro/app/modules/theme/theme_controller.dart';
import 'package:pomodoro/app/data/services/pomodoro_service.dart';

class DependencyInjection {
  static void init() {
    // Register services
    Get.put<StorageService>(StorageService(), permanent: true);
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<PomodoroService>(PomodoroService(), permanent: true);
  }
}
