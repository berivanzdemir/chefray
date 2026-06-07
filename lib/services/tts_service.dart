import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { idle, playing, paused }

class TtsService extends ChangeNotifier {
  late FlutterTts _flutterTts;
  TtsState _state = TtsState.idle;
  TtsState get state => _state;

  String _currentText = "";
  int _lastProgress = 0;
  
  TtsService() {
    _initTts();
  }

  void _initTts() async {
    _flutterTts = FlutterTts();
    try {
      await _flutterTts.setLanguage("tr-TR");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _state = TtsState.playing;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _state = TtsState.idle;
        _lastProgress = 0;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        _state = TtsState.idle;
        _lastProgress = 0;
        debugPrint("TTS error: $msg");
        notifyListeners();
      });

      _flutterTts.setProgressHandler((text, start, end, word) {
        if (_state == TtsState.playing) {
          _lastProgress = end;
        }
      });
    } catch (e) {
      debugPrint("TTS init error: $e");
    }
  }

  Future<void> speak(String text) async {
    if (_state == TtsState.playing) {
      await stop();
    }
    _currentText = text;
    _lastProgress = 0;
    _state = TtsState.playing;
    notifyListeners();
    await _flutterTts.speak(text);
  }

  Future<void> pause() async {
    if (_state == TtsState.playing) {
      await _flutterTts.stop(); // Safe stop for cross-platform
      _state = TtsState.paused;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (_state == TtsState.paused) {
      _state = TtsState.playing;
      notifyListeners();
      if (_lastProgress > 0 && _lastProgress < _currentText.length) {
        int startCut = _lastProgress;
        // Geriye doğru ilk boşluğu bul, kelime bölünmesin
        int spaceIdx = _currentText.lastIndexOf(' ', _lastProgress);
        if (spaceIdx != -1 && spaceIdx < startCut) {
          startCut = spaceIdx;
        } else if (spaceIdx == -1) {
          startCut = 0; // fallback
        }
        
        String remainingText = _currentText.substring(startCut).trim();
        await _flutterTts.speak(remainingText);
      } else {
        await _flutterTts.speak(_currentText);
      }
    }
  }

  Future<void> restart(String text) async {
    await stop();
    await speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _state = TtsState.idle;
    _lastProgress = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
