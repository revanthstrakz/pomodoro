import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:pomodoro/app/modules/theme/theme_controller.dart';

import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Appearance section
            _buildAppearanceSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appearance', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        // Use Obx for reactive UI updates
        Obx(() {
          final themeController = Get.find<ThemeController>();
          return Column(
            children: [
              // Dark mode toggle
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle between light and dark theme'),
                value: themeController.isDarkMode,
                onChanged: (_) => themeController.changeTheme(),
                secondary: Icon(
                  themeController.isDarkMode
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              // Theme color picker
              ListTile(
                title: const Text('Theme Color'),
                subtitle: const Text('Choose primary color for your app theme'),
                leading: Icon(
                  Icons.color_lens_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: themeController.primarySeed,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                onTap: () => _showColorPicker(context, themeController),
              ),

              // Use System Accent Color Toggle
              if (themeController.systemAccentColor !=
                  null) // Only show if system accent color is available
                SwitchListTile(
                  title: const Text('Use System Accent Color'),
                  subtitle: Text(
                    'Match app theme with your system\'s color (Android 12+)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: themeController.useSystemAccentColor,
                  onChanged: (bool value) {
                    themeController.toggleUseSystemAccentColor(value);
                  },
                  secondary: Icon(
                    Icons.android_outlined, // Or appropriate icon
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  void _showColorPicker(BuildContext context, ThemeController themeController) {
    Color pickerColor = themeController.primarySeed;

    Get.dialog(
      AlertDialog(
        title: const Text('Choose a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              pickerColor = color;
            },
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hueWheel,
            pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              themeController.changePrimarySeed(pickerColor);
              Get.back();

              // Show restart notification after theme color change
              _showRestartNotification(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showRestartNotification(BuildContext context) {
    // Material design snackbar for notification
    Get.snackbar(
      'Theme Color Changed',
      'Restart the application for all changes to take effect',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Theme.of(context).colorScheme.surface,
      colorText: Theme.of(context).colorScheme.onSurface,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 5),
      borderRadius: 8,
      icon: const Icon(Icons.refresh, color: Colors.orange),
      mainButton: TextButton(
        onPressed: () {
          // Hide the snackbar
          if (Get.isSnackbarOpen) {
            Get.back();
          }

          // Show dialog with more information
          _showRestartDialog(context);
        },
        child: const Text('MORE INFO'),
      ),
    );
  }

  void _showRestartDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 10),
            const Text('Restart Required'),
          ],
        ),
        content: const Text(
          'Some theme changes are applied immediately, but for the best experience, '
          'please restart the application to ensure all UI elements reflect your new color scheme.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK, I UNDERSTAND'),
          ),
        ],
      ),
    );
  }
}
