import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pomodoro/app/core/storage_service.dart';
import 'package:pomodoro/app/data/models/pomodoro_models.dart';

class NotificationService extends GetxService {
  final StorageService _storageService = Get.find<StorageService>();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification settings
  final RxBool notificationsEnabled = true.obs;
  final RxBool backgroundNotificationsEnabled = true.obs;
  final RxBool showProgressInNotification = true.obs;

  // Notification IDs
  static const int timerNotificationId = 1;
  static const int sessionCompleteNotificationId = 2;
  static const int reminderNotificationId = 3;

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
    _loadNotificationSettings();
  }

  Future<void> _initializeNotifications() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      notificationsEnabled.value = 
          _storageService.read('notifications_enabled') ?? true;
      backgroundNotificationsEnabled.value = 
          _storageService.read('background_notifications_enabled') ?? true;
      showProgressInNotification.value = 
          _storageService.read('show_progress_in_notification') ?? true;
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  Future<void> _saveNotificationSettings() async {
    try {
      await _storageService.write('notifications_enabled', notificationsEnabled.value);
      await _storageService.write('background_notifications_enabled', backgroundNotificationsEnabled.value);
      await _storageService.write('show_progress_in_notification', showProgressInNotification.value);
    } catch (e) {
      print('Error saving notification settings: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    if (payload != null) {
      // Handle notification tap - could navigate to specific screen
      print('Notification tapped with payload: $payload');
      // Navigate to home screen
      Get.offAllNamed('/home');
    }
  }

  Future<void> showSessionCompleteNotification({
    required SessionType sessionType,
    required String sessionTitle,
    required int duration,
  }) async {
    if (!notificationsEnabled.value) return;

    final String title = 'Session Complete!';
    final String body = '$sessionTitle completed in ${_formatDuration(duration)}';
    final String emoji = _getSessionEmoji(sessionType);

    await _showNotification(
      id: sessionCompleteNotificationId,
      title: '$emoji $title',
      body: body,
      payload: 'session_complete',
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  Future<void> showSessionStartNotification({
    required SessionType sessionType,
    required String sessionTitle,
    required int duration,
  }) async {
    if (!notificationsEnabled.value || !backgroundNotificationsEnabled.value) return;

    final String title = 'Session Started';
    final String body = '$sessionTitle - ${_formatDuration(duration)} remaining';
    final String emoji = _getSessionEmoji(sessionType);

    await _showNotification(
      id: timerNotificationId,
      title: '$emoji $title',
      body: body,
      payload: 'session_active',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
    );
  }

  Future<void> updateTimerNotification({
    required SessionType sessionType,
    required String sessionTitle,
    required int timeRemaining,
    required double progress,
  }) async {
    if (!notificationsEnabled.value || 
        !backgroundNotificationsEnabled.value || 
        !showProgressInNotification.value) return;

    final String title = sessionTitle;
    final String body = '${_formatDuration(timeRemaining)} remaining';
    final String emoji = _getSessionEmoji(sessionType);

    await _showNotification(
      id: timerNotificationId,
      title: '$emoji $title',
      body: body,
      payload: 'session_active',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      progress: (progress * 100).round(),
      showProgress: true,
    );
  }

  Future<void> cancelTimerNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(timerNotificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
    bool ongoing = false,
    int? progress,
    bool showProgress = false,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'pomodoro_timer',
      'Pomodoro Timer',
      channelDescription: 'Notifications for Pomodoro timer sessions',
      importance: importance,
      priority: priority,
      ongoing: ongoing,
      autoCancel: !ongoing,
      showProgress: showProgress,
      maxProgress: showProgress ? 100 : 0,
      progress: progress ?? 0,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6366F1), // Primary color
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  String _getSessionEmoji(SessionType sessionType) {
    switch (sessionType) {
      case SessionType.work:
        return '🍅';
      case SessionType.shortBreak:
        return '☕';
      case SessionType.longBreak:
        return '🛌';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  // Settings update methods
  Future<void> updateNotificationsEnabled(bool enabled) async {
    notificationsEnabled.value = enabled;
    await _saveNotificationSettings();
    
    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  Future<void> updateBackgroundNotificationsEnabled(bool enabled) async {
    backgroundNotificationsEnabled.value = enabled;
    await _saveNotificationSettings();
    
    if (!enabled) {
      await cancelTimerNotification();
    }
  }

  Future<void> updateShowProgressInNotification(bool enabled) async {
    showProgressInNotification.value = enabled;
    await _saveNotificationSettings();
  }

  // Check notification permissions
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final permission = await Permission.notification.status;
      return permission.isGranted;
    } else if (Platform.isIOS) {
      final permission = await Permission.notification.status;
      return permission.isGranted;
    }
    return false;
  }

  // Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    final permission = await Permission.notification.request();
    return permission.isGranted;
  }
}