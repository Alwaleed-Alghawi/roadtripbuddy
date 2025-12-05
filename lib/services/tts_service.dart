import 'package:flutter_tts/flutter_tts.dart';

/// Service for Text-to-Speech in Arabic and English
/// Simulates Google Cloud Text-to-Speech API
class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  /// Initialize TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    _isInitialized = true;
  }

  /// Speak text in English
  Future<void> speakEnglish(String text) async {
    await initialize();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.speak(text);
  }

  /// Speak text in Arabic
  Future<void> speakArabic(String text) async {
    await initialize();
    await _flutterTts.setLanguage('ar-SA');
    await _flutterTts.speak(text);
  }

  /// Read trip directions for a day
  Future<void> readTripDirections(
    int dayNumber,
    String directions, {
    bool inArabic = false,
  }) async {
    final intro = inArabic
        ? 'اليوم رقم $dayNumber'
        : 'Day $dayNumber directions';

    final fullText = '$intro. $directions';

    if (inArabic) {
      await speakArabic(fullText);
    } else {
      await speakEnglish(fullText);
    }
  }

  /// Read turn-by-turn directions
  Future<void> readTurnByTurn(
    List<String> directions, {
    bool inArabic = false,
  }) async {
    for (int i = 0; i < directions.length; i++) {
      final stepIntro = inArabic ? 'الخطوة ${i + 1}' : 'Step ${i + 1}';
      final fullDirection = '$stepIntro. ${directions[i]}';

      if (inArabic) {
        await speakArabic(fullDirection);
      } else {
        await speakEnglish(fullDirection);
      }

      // Small pause between steps
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Read trip summary
  Future<void> readTripSummary(
    String destination,
    int days,
    int activities, {
    bool inArabic = false,
  }) async {
    final summary = inArabic
        ? 'رحلة إلى $destination. المدة $days أيام. عدد الأنشطة $activities'
        : 'Trip to $destination. Duration: $days days. Activities: $activities';

    if (inArabic) {
      await speakArabic(summary);
    } else {
      await speakEnglish(summary);
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Pause speaking
  Future<void> pause() async {
    await _flutterTts.pause();
  }

  /// Check if TTS is speaking
  Future<bool> isSpeaking() async {
    return await _flutterTts.awaitSpeakCompletion(true);
  }

  /// Get available languages
  Future<List<dynamic>> getAvailableLanguages() async {
    return await _flutterTts.getLanguages;
  }

  /// Set speech rate (0.0 - 1.0)
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  /// Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  /// Dispose
  void dispose() {
    _flutterTts.stop();
  }
}