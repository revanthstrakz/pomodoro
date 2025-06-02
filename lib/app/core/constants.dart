class AppConstants {
  // App configuration
  static const String appName = 'Pomodoro';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String storageTokenKey = 'auth_token';
  static const String storageUserKey = 'user_data';
  static const String storageThemeKey = 'app_theme';
  static const String storageSessionsKey = 'pomodoro_sessions';
  static const String storageHistoryKey = 'pomodoro_history';
  static const String storageSettingsKey = 'pomodoro_settings';

  // Default Pomodoro times (in minutes)
  static const int defaultWorkTime = 25;
  static const int defaultShortBreak = 5;
  static const int defaultLongBreak = 15;
  static const int defaultSessionsBeforeLongBreak = 4;
}
