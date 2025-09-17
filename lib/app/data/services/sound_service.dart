import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:pomodoro/app/core/storage_service.dart';

enum SoundType {
  sessionComplete,
  sessionStart,
  tick,
}

class SoundService extends GetxService {
  final StorageService _storageService = Get.find<StorageService>();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Sound settings
  final RxBool soundEnabled = true.obs;
  final RxDouble volume = 0.8.obs;
  final RxString selectedSessionCompleteSound = 'chime.mp3'.obs;
  final RxString selectedSessionStartSound = 'bell.mp3'.obs;
  final RxBool tickSoundEnabled = false.obs;

  // Available sound files
  final Map<String, String> availableSounds = {
    'chime.mp3': 'Chime',
    'bell.mp3': 'Bell',
    'ding.mp3': 'Ding',
    'notification.mp3': 'Notification',
    'success.mp3': 'Success',
  };

  @override
  void onInit() {
    super.onInit();
    _loadSoundSettings();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }

  Future<void> _loadSoundSettings() async {
    try {
      soundEnabled.value = _storageService.read('sound_enabled') ?? true;
      volume.value = _storageService.read('sound_volume') ?? 0.8;
      selectedSessionCompleteSound.value = 
          _storageService.read('session_complete_sound') ?? 'chime.mp3';
      selectedSessionStartSound.value = 
          _storageService.read('session_start_sound') ?? 'bell.mp3';
      tickSoundEnabled.value = _storageService.read('tick_sound_enabled') ?? false;
    } catch (e) {
      print('Error loading sound settings: $e');
    }
  }

  Future<void> _saveSoundSettings() async {
    try {
      await _storageService.write('sound_enabled', soundEnabled.value);
      await _storageService.write('sound_volume', volume.value);
      await _storageService.write('session_complete_sound', selectedSessionCompleteSound.value);
      await _storageService.write('session_start_sound', selectedSessionStartSound.value);
      await _storageService.write('tick_sound_enabled', tickSoundEnabled.value);
    } catch (e) {
      print('Error saving sound settings: $e');
    }
  }

  Future<void> playSound(SoundType soundType) async {
    if (!soundEnabled.value) return;

    try {
      String soundFile;
      switch (soundType) {
        case SoundType.sessionComplete:
          soundFile = selectedSessionCompleteSound.value;
          break;
        case SoundType.sessionStart:
          soundFile = selectedSessionStartSound.value;
          break;
        case SoundType.tick:
          if (!tickSoundEnabled.value) return;
          soundFile = 'tick.mp3';
          break;
      }

      await _audioPlayer.setVolume(volume.value);
      await _audioPlayer.play(AssetSource('sounds/$soundFile'));
    } catch (e) {
      print('Error playing sound: $e');
      // Fallback to system sound if asset fails
      _playSystemSound(soundType);
    }
  }

  void _playSystemSound(SoundType soundType) {
    // Fallback system sounds - this would use platform-specific implementations
    // For now, we'll just print a message
    print('Playing system sound for: ${soundType.name}');
  }

  Future<void> updateSoundEnabled(bool enabled) async {
    soundEnabled.value = enabled;
    await _saveSoundSettings();
  }

  Future<void> updateVolume(double newVolume) async {
    volume.value = newVolume;
    await _saveSoundSettings();
  }

  Future<void> updateSessionCompleteSound(String soundFile) async {
    selectedSessionCompleteSound.value = soundFile;
    await _saveSoundSettings();
  }

  Future<void> updateSessionStartSound(String soundFile) async {
    selectedSessionStartSound.value = soundFile;
    await _saveSoundSettings();
  }

  Future<void> updateTickSoundEnabled(bool enabled) async {
    tickSoundEnabled.value = enabled;
    await _saveSoundSettings();
  }

  Future<void> previewSound(String soundFile) async {
    if (!soundEnabled.value) return;

    try {
      await _audioPlayer.setVolume(volume.value);
      await _audioPlayer.play(AssetSource('sounds/$soundFile'));
    } catch (e) {
      print('Error previewing sound: $e');
    }
  }

  // Test if a sound file exists and can be played
  Future<bool> testSound(String soundFile) async {
    try {
      await _audioPlayer.setVolume(0.1); // Very low volume for testing
      await _audioPlayer.play(AssetSource('sounds/$soundFile'));
      return true;
    } catch (e) {
      print('Sound test failed for $soundFile: $e');
      return false;
    }
  }
}