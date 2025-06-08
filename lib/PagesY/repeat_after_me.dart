import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:async';

enum Difficulty { easy, medium, hard }

class RepeatAfterMeScreen extends StatefulWidget {
  const RepeatAfterMeScreen({Key? key}) : super(key: key);

  @override
  _RepeatAfterMeScreenState createState() => _RepeatAfterMeScreenState();
}

class _RepeatAfterMeScreenState extends State<RepeatAfterMeScreen> {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<Difficulty, List<String>> phrases = {
    Difficulty.easy: [
      'I like apples',
      'The dog runs',
      'Hello friend',
      'Big blue sky',
      'Happy bird sings',
    ],
    Difficulty.medium: [
      'The sun shines brightly',
      'Cats chase mice',
      'Flowers bloom in spring',
      'The moon glows softly',
      'Children play happily',
    ],
    Difficulty.hard: [
      'The quick fox jumps over hills',
      'Stars twinkle in the night sky',
      'Waves crash on the rocky shore',
      'The old clock ticks loudly',
      'Birds soar above the mountain peaks',
    ],
  };
  int currentIndex = 0;
  int score = 0;
  int highScore = 0;
  int timeLeft = 15;
  Timer? _timer;
  Difficulty _difficulty = Difficulty.easy;
  bool showFeedback = false;
  bool isCorrect = false;
  bool _gameOver = false;
  String? _selectedPhrase; // Track the selected phrase for feedback

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _playPhrase();
    _startTimer();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('repeat_after_me_high_score_${_difficulty.name}') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      await prefs.setInt('repeat_after_me_high_score_${_difficulty.name}', score);
      setState(() {
        highScore = score;
      });
    }
  }

  void _playPhrase() async {
    await _tts.speak(phrases[_difficulty]![currentIndex]);
  }

  void _playSound(String asset) async {
    await _audioPlayer.play(AssetSource(asset));
  }

  void _startTimer() {
    _timer?.cancel();
    int timeLimit = _difficulty == Difficulty.easy
        ? 15
        : _difficulty == Difficulty.medium
            ? 10
            : 7;
    setState(() {
      timeLeft = timeLimit;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (timeLeft > 0) {
            timeLeft--;
          } else {
            _tts.speak('Time\'s up!');
            _playSound('sounds/game_over.mp3');
            timer.cancel();
            setState(() {
              _gameOver = true;
            });
            _saveHighScore();
          }
        });
      }
    });
  }

  void _onPhraseTap(String phrase) async {
    if (_gameOver) return;
    setState(() {
      _selectedPhrase = phrase; // Track the selected phrase
      isCorrect = phrase == phrases[_difficulty]![currentIndex];
      showFeedback = true;
      if (isCorrect) {
        score += _difficulty == Difficulty.easy
            ? 10
            : _difficulty == Difficulty.medium
                ? 15
                : 20;
        _playSound('sounds/correct.mp3');
        _tts.speak('Correct!');
        _saveHighScore();
        timeLeft = _difficulty == Difficulty.easy
            ? 15
            : _difficulty == Difficulty.medium
                ? 10
                : 7;
        currentIndex = Random().nextInt(phrases[_difficulty]!.length);
      } else {
        _playSound('sounds/incorrect.mp3');
        _tts.speak('Try again!');
      }
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        showFeedback = false;
        _selectedPhrase = null;
        if (isCorrect) {
          _playPhrase();
          _startTimer();
        }
      });
    }
  }

  List<String> _getOptions() {
    List<String> options = [phrases[_difficulty]![currentIndex]];
    int optionCount = _difficulty == Difficulty.easy ? 3 : _difficulty == Difficulty.medium ? 4 : 5;
    while (options.length < optionCount) {
      final randomPhrase = phrases[_difficulty]![Random().nextInt(phrases[_difficulty]!.length)];
      if (!options.contains(randomPhrase)) options.add(randomPhrase);
    }
    return options..shuffle();
  }

  void _restartGame() {
    setState(() {
      score = 0;
      currentIndex = Random().nextInt(phrases[_difficulty]!.length);
      _gameOver = false;
      _selectedPhrase = null;
    });
    _playPhrase();
    _startTimer();
  }

  void _changeDifficulty(Difficulty difficulty) {
    setState(() {
      _difficulty = difficulty;
      score = 0;
      currentIndex = Random().nextInt(phrases[_difficulty]!.length);
      _gameOver = false;
      _selectedPhrase = null;
    });
    _loadHighScore();
    _playPhrase();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final options = _getOptions();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Repeat After Me'),
        backgroundColor: Colors.pink.shade400,
        actions: [
          DropdownButton<Difficulty>(
            value: _difficulty,
            onChanged: (Difficulty? newValue) {
              if (newValue != null) {
                _changeDifficulty(newValue);
              }
            },
            items: Difficulty.values.map((Difficulty difficulty) {
              return DropdownMenuItem<Difficulty>(
                value: difficulty,
                child: Text(difficulty.name.toUpperCase()),
              );
            }).toList(),
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
                colors: [Colors.pink.shade100, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          if (_gameOver)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Game Over!',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.pink),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Score: $score',
                      style: const TextStyle(fontSize: 24),
                    ),
                    Text(
                      'High Score: $highScore',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade400,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      onPressed: _restartGame,
                      child: const Text(
                        'Play Again',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ).animate().fadeIn(),
              ),
            )
          else
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Score: $score | High Score: $highScore | Time: $timeLeft',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade400,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      onPressed: _playPhrase,
                      child: const Text(
                        'Hear Phrase',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: options.map((phrase) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: showFeedback && phrase == _selectedPhrase
                                ? (isCorrect ? Colors.green.shade400 : Colors.red.shade400)
                                : Colors.pink.shade300,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            minimumSize: const Size(150, 50),
                          ),
                          onPressed: () => _onPhraseTap(phrase),
                          child: Text(
                            phrase,
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ).animate().scale(duration: const Duration(milliseconds: 200));
                      }).toList(),
                    ),
                    if (showFeedback)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          isCorrect ? 'Correct!' : 'Try Again!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                        ).animate().fadeIn(),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }
}