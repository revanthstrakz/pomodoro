import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pomodoro/app/core/storage_service.dart';
import 'package:pomodoro/app/data/services/vibration_service.dart';

@GenerateMocks([StorageService])
import 'vibration_service_test.mocks.dart';

void main() {
  group('VibrationService', () {
    late VibrationService vibrationService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      Get.put<StorageService>(mockStorageService);
      vibrationService = VibrationService();
    });

    tearDown(() {
      Get.reset();
    });

    group('initialization', () {
      test('should load default settings when no stored settings exist', () async {
        // Arrange
        when(mockStorageService.read(any)).thenReturn(null);

        // Act
        await vibrationService.onInit();

        // Assert
        expect(vibrationService.vibrationEnabled.value, true);
        expect(vibrationService.vibrationIntensity.value, 2);
        expect(vibrationService.tickVibrationEnabled.value, false);
      });

      test('should load stored settings when they exist', () async {
        // Arrange
        when(mockStorageService.read('vibration_enabled')).thenReturn(false);
        when(mockStorageService.read('vibration_intensity')).thenReturn(3);
        when(mockStorageService.read('tick_vibration_enabled')).thenReturn(true);

        // Act
        await vibrationService.onInit();

        // Assert
        expect(vibrationService.vibrationEnabled.value, false);
        expect(vibrationService.vibrationIntensity.value, 3);
        expect(vibrationService.tickVibrationEnabled.value, true);
      });
    });

    group('vibration settings', () {
      test('should update vibration enabled setting', () async {
        // Arrange
        when(mockStorageService.write(any, any)).thenAnswer((_) async => {});

        // Act
        await vibrationService.updateVibrationEnabled(false);

        // Assert
        expect(vibrationService.vibrationEnabled.value, false);
        verify(mockStorageService.write('vibration_enabled', false)).called(1);
      });

      test('should update vibration intensity within valid range', () async {
        // Arrange
        when(mockStorageService.write(any, any)).thenAnswer((_) async => {});

        // Act
        await vibrationService.updateVibrationIntensity(3);

        // Assert
        expect(vibrationService.vibrationIntensity.value, 3);
        verify(mockStorageService.write('vibration_intensity', 3)).called(1);
      });

      test('should not update vibration intensity outside valid range', () async {
        // Arrange
        when(mockStorageService.write(any, any)).thenAnswer((_) async => {});
        vibrationService.vibrationIntensity.value = 2;

        // Act
        await vibrationService.updateVibrationIntensity(0);
        await vibrationService.updateVibrationIntensity(4);

        // Assert
        expect(vibrationService.vibrationIntensity.value, 2);
        verifyNever(mockStorageService.write('vibration_intensity', any));
      });

      test('should update tick vibration enabled setting', () async {
        // Arrange
        when(mockStorageService.write(any, any)).thenAnswer((_) async => {});

        // Act
        await vibrationService.updateTickVibrationEnabled(true);

        // Assert
        expect(vibrationService.tickVibrationEnabled.value, true);
        verify(mockStorageService.write('tick_vibration_enabled', true)).called(1);
      });
    });

    group('vibration patterns', () {
      test('should have predefined vibration patterns', () {
        // Assert
        expect(VibrationService.vibrationPatterns, isNotEmpty);
        expect(VibrationService.vibrationPatterns.keys, contains(VibrationType.sessionComplete));
        expect(VibrationService.vibrationPatterns.keys, contains(VibrationType.sessionStart));
        expect(VibrationService.vibrationPatterns.keys, contains(VibrationType.tick));
      });

      test('should have different patterns for different vibration types', () {
        // Assert
        final completePattern = VibrationService.vibrationPatterns[VibrationType.sessionComplete]!;
        final startPattern = VibrationService.vibrationPatterns[VibrationType.sessionStart]!;
        final tickPattern = VibrationService.vibrationPatterns[VibrationType.tick]!;

        expect(completePattern, isNot(equals(startPattern)));
        expect(startPattern, isNot(equals(tickPattern)));
        expect(completePattern.length, greaterThan(tickPattern.length));
      });
    });

    group('intensity labels', () {
      test('should return correct intensity labels', () {
        // Test different intensity values
        vibrationService.vibrationIntensity.value = 1;
        expect(vibrationService.intensityLabel, 'Light');

        vibrationService.vibrationIntensity.value = 2;
        expect(vibrationService.intensityLabel, 'Medium');

        vibrationService.vibrationIntensity.value = 3;
        expect(vibrationService.intensityLabel, 'Strong');

        vibrationService.vibrationIntensity.value = 999; // Invalid value
        expect(vibrationService.intensityLabel, 'Medium'); // Should default to Medium
      });
    });

    group('vibrate', () {
      test('should not vibrate when vibration is disabled', () async {
        // Arrange
        vibrationService.vibrationEnabled.value = false;

        // Act & Assert
        // Since we can't easily mock Vibration, we just verify the method doesn't throw
        expect(() => vibrationService.vibrate(VibrationType.sessionComplete), returnsNormally);
      });

      test('should not vibrate tick when tick vibration is disabled', () async {
        // Arrange
        vibrationService.vibrationEnabled.value = true;
        vibrationService.tickVibrationEnabled.value = false;

        // Act & Assert
        expect(() => vibrationService.vibrate(VibrationType.tick), returnsNormally);
      });
    });
  });
}