import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pomodoro/app/core/storage_service.dart';
import 'package:pomodoro/app/modules/theme/theme.dart';
// Import Platform
// Import kIsWeb

class ThemeController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  // Convert to Rx variables for better reactivity
  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  final Rx<Color?> _primarySeed = Rx<Color?>(AppTheme.defaultPrimarySeed);
  final Rx<Color?> _systemAccentColor = Rx<Color?>(null);
  final RxBool _useSystemAccentColor = false.obs;

  final Rx<ThemeData> lightTheme = AppTheme.lightTheme().obs;
  final Rx<ThemeData> darkTheme = AppTheme.darkTheme().obs;
  final Rx<ThemeData> currentTheme = AppTheme.lightTheme().obs;
  // Getters using .value to access the reactive values
  ThemeMode get themeMode => _themeMode.value;
  bool get isDarkMode => _themeMode.value == ThemeMode.dark;
  bool get isSystemTheme => _themeMode.value == ThemeMode.system;
  Color get primarySeed => _primarySeed.value ?? AppTheme.defaultPrimarySeed;
  set primarySeed(Color color) {
    _primarySeed.value = color;
    _useSystemAccentColor.value =
        false; // User selected a color, so don't use system's
    _saveSeedColor();
    _applyTheme();
  }

  ThemeData get lightThemeData => lightTheme.value;
  ThemeData get darkThemeData => darkTheme.value;
  ThemeData get currentThemeData => currentTheme.value;

  // Common preset colors that work well as seed colors
  static final List<Color> _presetColors = [
    const Color(0xFF1DCD9F), // Default teal
    const Color(0xFF6750A4), // Material 3 default
    const Color(0xFF007AFF), // iOS Blue
    const Color(0xFF34C759), // iOS Green
    const Color(0xFFFF9500), // iOS Orange
    const Color(0xFFFF3B30), // iOS Red
    const Color(0xFFAF52DE), // iOS Purple
    const Color(0xFF5856D6), // iOS Indigo
    const Color(0xFF03A9F4), // Light Blue
    const Color(0xFF2196F3), // Blue
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFE91E63), // Pink
    const Color(0xFFF44336), // Red
    const Color(0xFFFF9800), // Orange
    const Color(0xFF4CAF50), // Green
  ];

  Future<ThemeController> init() async {
    // Load saved theme or default to system
    final savedTheme = await _storageService.getThemeMode();
    _setInitialThemeMode(savedTheme);

    if (_useSystemAccentColor.value && _systemAccentColor.value != null) {
      _primarySeed.value = _systemAccentColor.value;
    } else {
      // Load saved seed color or generate a new one
      final savedSeedColor = await _storageService.getSeedColor();
      if (savedSeedColor != null) {
        _primarySeed.value = Color(savedSeedColor);
      } else {
        _generateSeedColor(); // This also saves the color
      }
    }

    _applyTheme();
    return this;
  }

  void _setInitialThemeMode(String? savedTheme) {
    if (savedTheme == 'dark') {
      _themeMode.value = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode.value = ThemeMode.light;
    } else {
      _themeMode.value = ThemeMode.system;
    }
  }

  void _generateSeedColor() {
    // Use a deterministic approach to select a color from preset colors
    // We can use device info or a unique ID to make it consistent per device
    final DateTime now = DateTime.now();
    final int seed = now.day + now.month + now.year;
    final Random random = Random(seed);

    final int colorIndex = random.nextInt(_presetColors.length);
    _primarySeed.value = _presetColors[colorIndex];

    // Save this generated color as the user's preference
    _saveSeedColor();
  }

  void toggleUseSystemAccentColor(bool useSystem) async {
    _useSystemAccentColor.value = useSystem;
    if (useSystem && _systemAccentColor.value != null) {
      _primarySeed.value = _systemAccentColor.value;
    } else if (!useSystem) {
      // Revert to last saved/generated color if not using system accent
      final savedSeedColor = await _storageService.getSeedColor();
      _primarySeed.value = savedSeedColor != null
          ? Color(savedSeedColor)
          : AppTheme.defaultPrimarySeed;
      if (savedSeedColor == null &&
          _primarySeed.value == AppTheme.defaultPrimarySeed) {
        // If no color was saved and we are reverting from system, generate one.
        _generateSeedColor();
      }
    }
    _applyTheme();
  }

  bool get useSystemAccentColor => _useSystemAccentColor.value;
  Color? get systemAccentColor => _systemAccentColor.value;

  void changeTheme() {
    _themeMode.value = _themeMode.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    _saveThemeMode();
    _applyTheme();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode.value = mode;
    _saveThemeMode();
    _applyTheme();
  }

  void changePrimarySeed(Color color) {
    _primarySeed.value = color;
    _useSystemAccentColor.value = false; // User selected a color
    _saveSeedColor();
    _applyTheme();
  }

  void _applyTheme() {
    final currentSeed =
        _useSystemAccentColor.value && _systemAccentColor.value != null
        ? _systemAccentColor.value
        : _primarySeed.value;

    // Update theme data
    lightTheme.value = AppTheme.lightTheme(
      currentSeed ?? AppTheme.defaultPrimarySeed,
    );
    darkTheme.value = AppTheme.darkTheme(
      currentSeed ?? AppTheme.defaultPrimarySeed,
    );

    // Update theme mode in GetX
    Get.changeThemeMode(_themeMode.value);

    bool effectivelyDarkMode;
    if (_themeMode.value == ThemeMode.system) {
      // Check if GetMaterialApp's context is available
      if (Get.key.currentContext != null) {
        // Access platformBrightness safely using MediaQuery
        final Brightness platformBrightness = MediaQuery.of(
          Get.key.currentContext!,
        ).platformBrightness;
        effectivelyDarkMode = (platformBrightness == Brightness.dark);
      } else {
        // Context not yet available (e.g., during initial app load).
        // Default to light theme. GetMaterialApp will handle ThemeMode.system correctly once it builds.
        effectivelyDarkMode = false;
      }
    } else {
      effectivelyDarkMode = (_themeMode.value == ThemeMode.dark);
    }

    // Update theme configurations in GetX
    Get.changeTheme(effectivelyDarkMode ? darkTheme.value : lightTheme.value);
    currentTheme.value = effectivelyDarkMode
        ? darkTheme.value
        : lightTheme.value;
  }

  void _saveThemeMode() {
    String theme = 'system';
    if (_themeMode.value == ThemeMode.dark) {
      theme = 'dark';
    } else if (_themeMode.value == ThemeMode.light) {
      theme = 'light';
    }
    _storageService.saveThemeMode(theme);
  }

  void _saveSeedColor() {
    if (_primarySeed.value != null) {
      // ignore: deprecated_member_use
      _storageService.saveSeedColor(_primarySeed.value!.value);
    }
  }

  // Called when system theme changes
  void onSystemBrightnessChange() {
    if (_themeMode.value == ThemeMode.system) {
      _applyTheme();
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Listen to system brightness changes
    ever(_themeMode, (_) => _applyTheme());
    // No need to listen to _primarySeed directly here if _applyTheme is called by its setters
    // ever(_primarySeed, (_) => _applyTheme());
    ever(_useSystemAccentColor, (_) => _applyTheme());

    // Add a listener for system accent color changes (if possible/needed, e.g. for Android 12+)
    // This might require more platform-specific listeners.
    // For now, fetching at init and when toggled is the main approach.
  }
}
