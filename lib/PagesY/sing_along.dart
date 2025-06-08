import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';

class SingAlongScreen extends StatefulWidget {
  const SingAlongScreen({Key? key}) : super(key: key);

  @override
  _SingAlongScreenState createState() => _SingAlongScreenState();
}

class _SingAlongScreenState extends State<SingAlongScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isTtsEnabled = true;
  bool _isPaused = false;
  int _lives = 3;
  int _level = 1;
  int _score = 0;
  double _progress = 0.0;
  int _currentSongIndex = 0;
  int _currentWordIndex = 0;
  String? _suggestedWord;
  bool _waitingForInput = false;
  Timer? _timer;
  Timer? _repeatTimer;
  bool _isSpeaking = false;
  final List<Map<String, dynamic>> _songs = [
    {
      'lyrics': ['Twinkle', 'twinkle', 'little', 'star'],
      'distractors': ['sparkle', 'bright', 'sky', 'moon'],
      'baseSpeed': 2.0,
    },
    {
      'lyrics': ['Happy', 'and', 'you', 'know', 'it'],
      'distractors': ['clap', 'sing', 'smile', 'jump'],
      'baseSpeed': 1.8,
    },
    {
      'lyrics': ['Row', 'row', 'row', 'your', 'boat'],
      'distractors': ['paddle', 'sail', 'stream', 'river'],
      'baseSpeed': 1.5,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _initializeTts();
    _startLevel();
  }

  Future<void> _initializeTts() async {
    try {
      bool available = await _tts.isLanguageAvailable("en-US");
      if (!available) {
        print("TTS language en-US not available");
        return;
      }
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.7);
      await _tts.setVolume(1.0);
      _tts.setCompletionHandler(() {
        setState(() {
          _isSpeaking = false;
        });
      });
    } catch (e) {
      print("TTS initialization error: $e");
    }
  }

  Future<void> _loadHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _score = prefs.getInt('sing_along_high_score') ?? 0;
      });
    } catch (e) {
      print("Error loading high score: $e");
    }
  }

  Future<void> _saveHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sing_along_high_score', _score);
    } catch (e) {
      print("Error saving high score: $e");
    }
  }

  void _startLevel() {
    _timer?.cancel();
    _repeatTimer?.cancel();
    setState(() {
      _currentWordIndex = 0;
      _progress = 0.0;
      _isPaused = false;
      _suggestedWord = null;
      _waitingForInput = false;
      _isSpeaking = false;
    });
    _suggestNextWord();
  }

  void _suggestNextWord() {
    _repeatTimer?.cancel();
    if (_currentWordIndex >= _songs[_currentSongIndex]['lyrics'].length) {
      _showLevelCompleteDialog();
      return;
    }
    final random = Random();
    final currentLyrics = _songs[_currentSongIndex]['lyrics'] as List<String>;
    final distractors = _songs[_currentSongIndex]['distractors'] as List<String>;
    final options = <String>[];
    options.add(currentLyrics[_currentWordIndex]);
    options.addAll(distractors.sublist(0, min(2 + (_level - 1), distractors.length)));
    options.shuffle(random);
    setState(() {
      _suggestedWord = options.first;
      _waitingForInput = true;
    });
    if (_isTtsEnabled && !_isPaused) {
      _startWordRepetition(currentLyrics[_currentWordIndex]);
    }
  }

  void _startWordRepetition(String word) {
    _repeatTimer?.cancel();
    int repeatCount = 0;
    const maxRepeats = 2; // Limit to 2 repetitions after initial speak
    _speakWord(word); // Speak immediately
    _repeatTimer = Timer.periodic(const Duration(seconds: 1), (timer) { // Changed from 2 to 1 second
      if (_isTtsEnabled && !_isPaused && _waitingForInput && !_isSpeaking && repeatCount < maxRepeats) {
        _speakWord(word);
        repeatCount++;
      } else {
        timer.cancel();
      }
    });
  }

  void _speakWord(String word) {
    if (!_isSpeaking) {
      _isSpeaking = true;
      _tts.stop();
      _tts.speak(word).catchError((e) {
        print("TTS error: $e");
        _isSpeaking = false;
      });
    }
  }

  void _pauseResumeSong() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _tts.stop();
        _isSpeaking = false;
        _repeatTimer?.cancel();
      } else {
        if (_isTtsEnabled && _currentWordIndex < _songs[_currentSongIndex]['lyrics'].length && _waitingForInput) {
          _startWordRepetition(_songs[_currentSongIndex]['lyrics'][_currentWordIndex]);
        }
      }
    });
  }

  void _toggleTts() {
    setState(() {
      _isTtsEnabled = !_isTtsEnabled;
      if (!_isTtsEnabled) {
        _tts.stop();
        _isSpeaking = false;
        _repeatTimer?.cancel();
      } else if (_waitingForInput && !_isPaused && _currentWordIndex < _songs[_currentSongIndex]['lyrics'].length) {
        _startWordRepetition(_songs[_currentSongIndex]['lyrics'][_currentWordIndex]);
      }
    });
  }

  void _onConfirm(bool isCorrectChoice) {
    if (_isPaused || _suggestedWord == null || !_waitingForInput || _isSpeaking) return;
    _repeatTimer?.cancel();
    final currentLyrics = _songs[_currentSongIndex]['lyrics'] as List<String>;
    final isCorrect = _suggestedWord == currentLyrics[_currentWordIndex] && isCorrectChoice ||
        _suggestedWord != currentLyrics[_currentWordIndex] && !isCorrectChoice;
    setState(() {
      _score += isCorrect ? 10 : -5;
      if (_score < 0) _score = 0;
      if (!isCorrect) {
        _lives--;
        if (_lives <= 0) {
          _showGameOverDialog();
          return;
        }
      }
      _saveHighScore();
      _waitingForInput = false;
      _currentWordIndex++;
      _progress = _currentWordIndex / _songs[_currentSongIndex]['lyrics'].length;
    });
    if (_isTtsEnabled && !_isPaused && !_isSpeaking) {
      _isSpeaking = true;
      _tts.stop();
      _tts.speak(isCorrect ? "Correct!" : "Oops, wrong choice!").catchError((e) {
        print("TTS error: $e");
        _isSpeaking = false;
      });
    }
    if (_lives > 0) {
      _suggestNextWord();
    }
  }

  void _showLevelCompleteDialog() {
    _repeatTimer?.cancel();
    final stars = _lives == 3 ? 3 : _lives == 2 ? 2 : 1;
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Level Complete!').animate().fadeIn(),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $_score\nStars: $stars/3',
              style: const TextStyle(fontSize: 18),
            ).animate().scale(duration: const Duration(milliseconds: 300)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => Icon(
                index < stars ? Icons.star : Icons.star_border,
                color: Colors.yellow,
                size: 30,
              ).animate().fadeIn(delay: Duration(milliseconds: 100 * index))),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentSongIndex = (_currentSongIndex + 1) % _songs.length;
                _level++;
                _lives = min(_lives + 1, 3);
              });
              _startLevel();
            },
            child: const Text('Next Level'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    _repeatTimer?.cancel();
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over!').animate().fadeIn(),
        content: Text(
          'Score: $_score\nOut of lives! Restarting...',
          style: const TextStyle(fontSize: 18),
        ).animate().scale(duration: const Duration(milliseconds: 300)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _lives = 3;
                _score = 0;
                _level = 1;
                _currentSongIndex = Random().nextInt(_songs.length);
              });
              _startLevel();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLyrics = _songs[_currentSongIndex]['lyrics'] as List<String>;
    return Theme(
      data: ThemeData(
        primaryColor: Colors.pink.shade700,
        textTheme: GoogleFonts.poppinsTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink.shade300,
            textStyle: const TextStyle(fontSize: 18, color: Colors.white),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Sing Along Karaoke - Level $_level'),
          backgroundColor: Colors.pink.shade300,
          actions: [
            IconButton(
              icon: Icon(_isTtsEnabled ? Icons.volume_up : Icons.volume_off),
              onPressed: _toggleTts,
            ),
            IconButton(
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
              onPressed: _pauseResumeSong,
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade200, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Score: $_score',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        Row(
                          children: List.generate(3, (index) => Icon(
                            index < _lives ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                            size: 24,
                          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index))),
                        ),
                      ],
                    ).animate().slideY(begin: -0.2, end: 0.0, duration: const Duration(milliseconds: 500)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade700),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currentLyrics.join(' '),
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.pink.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: const Duration(milliseconds: 500)),
                    const SizedBox(height: 20),
                    if (_suggestedWord != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        decoration: BoxDecoration(
                          color: _waitingForInput ? Colors.pink.shade300 : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.yellow.shade300, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Suggested: $_suggestedWord',
                          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ).animate().scale(duration: const Duration(milliseconds: 200)).then().shake(
                            duration: const Duration(milliseconds: 300),
                            hz: _waitingForInput ? 4 : 0,
                          ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade400,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          onPressed: _waitingForInput && !_isSpeaking ? () => _onConfirm(true) : null,
                          child: const Text('Correct', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          onPressed: _waitingForInput && !_isSpeaking ? () => _onConfirm(false) : null,
                          child: const Text('Incorrect', style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _repeatTimer?.cancel();
    _tts.stop();
    super.dispose();
  }
}