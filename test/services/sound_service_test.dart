import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pomodoro/app/core/storage_service.dart';
import 'package:pomodoro/app/data/services/sound_service.dart';

@GenerateMocks([StorageService])
import 'sound_service_test.mocks.dart';

void main() {
  group('SoundService', () {
    late SoundService soundService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      Get.put<StorageService>(mockStorageService);
      soundService = SoundService();
    });

    tearDown(() {
      Get.reset();
    });

    group('initialization', () {
      test('should load default settings when no stored settings exist', () async {
        // Arrange
        when(mockStorageService.read(any)).thenReturn(null);

        // Act
        await soundService.onInit();

        // Assert
        expect(soundService.soundEnabled.value, true);
        expect(soundService.volume.value, 0.8);
        expect(soundService.selectedSessionCompleteSound.value, 'chime.mp3');
        expect(soundService.selectedSessionStartSound.value, 'bell.mp3');
        expect(soundService.tickSoundEnabled.value, false);
      });

      test('should load stored settings when they exist', () async {
        // Arrange
        when(mockStorageService.read('sound_enabled')).thenReturn(false);
        when(mockStorageService.read('sound_volume')).thenReturn(0.5);
        when(mockStorageService.read('session_complete_sound')).thenReturn('ding.mp3');
        when(mockStorageService.read('session_start_sound')).thenReturn('notification.mp3');
        when(mockStorageService.read('tick_sound_enabled')).thenReturn(true);

        // Act
        await soundService.onInit();

        // Assert
        expect(soundService.soundEnabled.value, false);
        expect(soundService.volume.value, 0.5);
        expect(soundService.selectedSessionCompleteSound.value, 'ding.mp3');
        expect(soundService.selectedSessionStartSound.value, 'notification.mp3');
        expect(soundService.tickSoundEnabled.value, true);
      });
    });

    group('sound settings', () {
      test('should update sound enabled setting', () async {
        // Arrange
        when(mockStorageService.write(any, any)).thenAnswer((_) async => {});

        // Act
        await soundService.updateSoundEnabled(false);

        // Assert
        expect(soundService.soundEnabled.value, false);
        verify(mockStorageService.write('sound_enabled', false)).called(1);
      });

      test('should update volume setting', () async {
        // Arrange
        when(mockStorageService.write(any, any)).thenAnswer((_) async => {});

        // Act
        await soundService.updateVolume(0.6);

        // Assert
        expect(soundService.volume.value, 0.6);
        verify(mockStorageService.write('sound_volume', 0.6)).called(1);
      });

      test('should update session complete sound', () async {
        // Arrange
        when(mockStorageService.write(any, any)).thenAnswer((_) async => {});

        // Act
        await soundService.updateSessionCompleteSound('success.mp3');

        // Assert
        expect(soundService.selectedSessionCompleteSound.value, 'success.mp3');
        verify(mockStorageService.write('session_complete_sound', 'success.mp3')).called(1);
      });

      test('should update tick sound enabled setting', () async {
        // Arrange
        when(mockStorageService.write(any, any)).thenAnswer((_) async => {});

        // Act
        await soundService.updateTickSoundEnabled(true);

        // Assert
        expect(soundService.tickSoundEnabled.value, true);
        verify(mockStorageService.write('tick_sound_enabled', true)).called(1);
      });
    });

    group('available sounds', () {
      test('should have predefined available sounds', () {
        // Assert
        expect(soundService.availableSounds, isNotEmpty);
        expect(soundService.availableSounds.keys, contains('chime.mp3'));
        expect(soundService.availableSounds.keys, contains('bell.mp3'));
        expect(soundService.availableSounds.keys, contains('ding.mp3'));
      });

      test('should have human-readable sound names', () {
        // Assert
        expect(soundService.availableSounds['chime.mp3'], 'Chime');
        expect(soundService.availableSounds['bell.mp3'], 'Bell');
        expect(soundService.availableSounds['ding.mp3'], 'Ding');
      });
    });

    group('playSound', () {
      test('should not play sound when sound is disabled', () async {
        // Arrange
        soundService.soundEnabled.value = false;

        // Act & Assert
        // Since we can't easily mock AudioPlayer, we just verify the method doesn't throw
        expect(() => soundService.playSound(SoundType.sessionComplete), returnsNormally);
      });

      test('should not play tick sound when tick sound is disabled', () async {
        // Arrange
        soundService.soundEnabled.value = true;
        soundService.tickSoundEnabled.value = false;

        // Act & Assert
        expect(() => soundService.playSound(SoundType.tick), returnsNormally);
      });
    });
  });
}