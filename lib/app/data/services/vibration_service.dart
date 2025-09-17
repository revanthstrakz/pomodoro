import 'package:get/get.dart';
import 'package:vibration/vibration.dart';
import 'package:pomodoro/app/core/storage_service.dart';

enum VibrationType {
  sessionComplete,
  sessionStart,
  sessionPause,
  sessionResume,
  tick,
}

class VibrationService extends GetxService {
  final StorageService _storageService = Get.find<StorageService>();
  
  // Vibration settings
  final RxBool vibrationEnabled = true.obs;
  final RxInt vibrationIntensity = 2.obs; // 1-3 scale
  final RxBool tickVibrationEnabled = false.obs;

  // Vibration patterns (in milliseconds)
  static const Map<VibrationType, List<int>> vibrationPatterns = {
    VibrationType.sessionComplete: [0, 500, 200, 500, 200, 500],
    VibrationType.sessionStart: [0, 300, 100, 300],
    VibrationType.sessionPause: [0, 200],
    VibrationType.sessionResume: [0, 100, 50, 100],
    VibrationType.tick: [0, 50],
  };

  @override
  void onInit() {
    super.onInit();
    _loadVibrationSettings();
  }

  Future<void> _loadVibrationSettings() async {
    try {
      vibrationEnabled.value = _storageService.read('vibration_enabled') ?? true;
      vibrationIntensity.value = _storageService.read('vibration_intensity') ?? 2;
      tickVibrationEnabled.value = _storageService.read('tick_vibration_enabled') ?? false;
    } catch (e) {
      print('Error loading vibration settings: $e');
    }
  }

  Future<void> _saveVibrationSettings() async {
    try {
      await _storageService.write('vibration_enabled', vibrationEnabled.value);
      await _storageService.write('vibration_intensity', vibrationIntensity.value);
      await _storageService.write('tick_vibration_enabled', tickVibrationEnabled.value);
    } catch (e) {
      print('Error saving vibration settings: $e');
    }
  }

  Future<void> vibrate(VibrationType vibrationType) async {
    if (!vibrationEnabled.value) return;

    // Skip tick vibration if disabled
    if (vibrationType == VibrationType.tick && !tickVibrationEnabled.value) {
      return;
    }

    try {
      // Check if device has vibration capability
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) return;

      final pattern = vibrationPatterns[vibrationType];
      if (pattern != null) {
        // Adjust pattern intensity based on settings
        final adjustedPattern = _adjustPatternIntensity(pattern);
        
        // Check if custom vibration patterns are supported
        final hasCustomVibrationsSupport = await Vibration.hasCustomVibrationsSupport();
        
        if (hasCustomVibrationsSupport == true) {
          await Vibration.vibrate(pattern: adjustedPattern);
        } else {
          // Fallback to simple vibration
          await _simpleVibrate(vibrationType);
        }
      }
    } catch (e) {
      print('Error vibrating: $e');
      // Fallback to simple vibration
      await _simpleVibrate(vibrationType);
    }
  }

  List<int> _adjustPatternIntensity(List<int> pattern) {
    // Adjust vibration duration based on intensity setting
    final multiplier = vibrationIntensity.value / 2.0;
    return pattern.map((duration) {
      if (duration == 0) return 0; // Don't modify delays
      return (duration * multiplier).round();
    }).toList();
  }

  Future<void> _simpleVibrate(VibrationType vibrationType) async {
    try {
      int duration;
      switch (vibrationType) {
        case VibrationType.sessionComplete:
          duration = 1000;
          break;
        case VibrationType.sessionStart:
          duration = 500;
          break;
        case VibrationType.sessionPause:
          duration = 200;
          break;
        case VibrationType.sessionResume:
          duration = 300;
          break;
        case VibrationType.tick:
          duration = 50;
          break;
      }

      // Adjust duration based on intensity
      final adjustedDuration = (duration * (vibrationIntensity.value / 2.0)).round();
      await Vibration.vibrate(duration: adjustedDuration);
    } catch (e) {
      print('Error with simple vibration: $e');
    }
  }

  Future<void> updateVibrationEnabled(bool enabled) async {
    vibrationEnabled.value = enabled;
    await _saveVibrationSettings();
  }

  Future<void> updateVibrationIntensity(int intensity) async {
    if (intensity >= 1 && intensity <= 3) {
      vibrationIntensity.value = intensity;
      await _saveVibrationSettings();
    }
  }

  Future<void> updateTickVibrationEnabled(bool enabled) async {
    tickVibrationEnabled.value = enabled;
    await _saveVibrationSettings();
  }

  // Test vibration with current settings
  Future<void> testVibration() async {
    await vibrate(VibrationType.sessionComplete);
  }

  // Check if device supports vibration
  Future<bool> hasVibrationSupport() async {
    try {
      return await Vibration.hasVibrator() ?? false;
    } catch (e) {
      print('Error checking vibration support: $e');
      return false;
    }
  }

  // Get vibration intensity label
  String get intensityLabel {
    switch (vibrationIntensity.value) {
      case 1:
        return 'Light';
      case 2:
        return 'Medium';
      case 3:
        return 'Strong';
      default:
        return 'Medium';
    }
  }
}