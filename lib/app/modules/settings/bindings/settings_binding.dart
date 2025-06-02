import 'package:get/get.dart';
import 'package:pomodoro/app/modules/theme/theme_controller.dart';

import '../controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    // Create a new controller each time but don't make it permanent
    Get.lazyPut<SettingsController>(() => SettingsController());

    // Make sure theme controller is available
    if (!Get.isRegistered<ThemeController>()) {
      Get.lazyPut<ThemeController>(() => ThemeController());
    }
  }
}
