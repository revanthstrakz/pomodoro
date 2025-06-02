import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pomodoro/app/core/di.dart';
import 'package:pomodoro/app/core/storage_service.dart';

import 'package:pomodoro/app/modules/theme/theme_controller.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize storage service
  await Get.putAsync(() => StorageService().init());

  // Initialize dependencies
  DependencyInjection.init();

  // Initialize theme controller
  // The init method now handles fetching system accent color
  final themeController = Get.put(ThemeController());
  await themeController.init();

  final initialRoute = Routes.HOME;

  runApp(
    GetMaterialApp(
      title: "The Trade",
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      themeMode: themeController.themeMode,
      theme: themeController.lightThemeData,
      darkTheme: themeController.darkThemeData,
      debugShowCheckedModeBanner: false,
    ),
  );
}
