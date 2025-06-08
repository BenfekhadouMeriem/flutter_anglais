import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:async';

enum Difficulty { easy, medium, hard }

class FindObjectScreen extends StatefulWidget {
  const FindObjectScreen({Key? key}) : super(key: key);

  @override
  _FindObjectScreenState createState() => _FindObjectScreenState();
}

class _FindObjectScreenState extends State<FindObjectScreen> {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Map<String, String>> objects = [
    {'name': 'apple', 'emoji': '🍎', 'color': 'red'},
    {'name': 'banana', 'emoji': '🍌', 'color': 'yellow'},
    {'name': 'grapes', 'emoji': '🍇', 'color': 'purple'},
    {'name': 'orange', 'emoji': '🍊', 'color': 'orange'},
    {'name': 'lemon', 'emoji': '🍋', 'color': 'yellow'},
    {'name': 'strawberry', 'emoji': '🍓', 'color': 'red'},
  ];
  int currentIndex = 0;
  int? _feedbackIndex; // Index de l'objet à colorer pour le feedback
  int score = 0;
  int highScore = 0;
  int timeLeft = 30;
  Timer? _timer;
  Difficulty _difficulty = Difficulty.easy;
  bool _gameOver = false;
  bool _isCorrect = false;
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _playHint();
    _startTimer();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('find_object_high_score_${_difficulty.name}') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      await prefs.setInt('find_object_high_score_${_difficulty.name}', score);
      setState(() {
        highScore = score;
      });
    }
  }

  void _playHint() async {
    await _tts.speak('Find something ${objects[currentIndex]['color']}');
  }

  void _playSound(String asset) async {
    await _audioPlayer.play(AssetSource(asset));
  }

  void _startTimer() {
    _timer?.cancel();
    int timeLimit = _difficulty == Difficulty.easy
        ? 30
        : _difficulty == Difficulty.medium
            ? 20
            : 10;
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

  void _onObjectTap(String name) async {
    if (_gameOver) return;

    // Trouver l'index de l'objet tapé
    int tappedIndex = objects.indexWhere((obj) => obj['name'] == name);

    // Vérifier si la couleur de l'objet tapé correspond à la couleur demandée
    if (objects[tappedIndex]['color'] == objects[currentIndex]['color']) {
      setState(() {
        score += _difficulty == Difficulty.easy
            ? 10
            : _difficulty == Difficulty.medium
                ? 15
                : 20;
        _isCorrect = true;
        _showFeedback = true;
        _feedbackIndex = tappedIndex; // Stocker l'index de l'objet tapé
        currentIndex = Random().nextInt(objects.length); // Passer à la question suivante
        timeLeft = _difficulty == Difficulty.easy
            ? 30
            : _difficulty == Difficulty.medium
                ? 20
                : 10;
      });
      _playSound('sounds/correct.mp3');
      await _tts.speak('Correct!');
      _playHint();
      _startTimer();
    } else {
      setState(() {
        _isCorrect = false;
        _showFeedback = true;
        _feedbackIndex = tappedIndex; // Stocker l'index de l'objet incorrect
      });
      _playSound('sounds/incorrect.mp3');
      await _tts.speak('Try again!');
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showFeedback = false;
          _feedbackIndex = null; // Réinitialiser après le feedback
        });
      }
    });
  }

  void _restartGame() {
    setState(() {
      score = 0;
      currentIndex = Random().nextInt(objects.length);
      _gameOver = false;
      _feedbackIndex = null;
    });
    _playHint();
    _startTimer();
  }

  void _changeDifficulty(Difficulty difficulty) {
    setState(() {
      _difficulty = difficulty;
      _gameOver = false;
      score = 0;
      currentIndex = Random().nextInt(objects.length);
      _feedbackIndex = null;
    });
    _loadHighScore();
    _playHint();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Find the Object'),
        backgroundColor: Colors.pink.shade300,
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
                        backgroundColor: Colors.pink.shade300,
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
                    Text(
                      'Find something ${objects[currentIndex]['color']}',
                      style: TextStyle(fontSize: 20, color: Colors.pink.shade700, fontWeight: FontWeight.bold),
                    ).animate().fadeIn(),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: objects.asMap().entries.map((entry) {
                        int index = entry.key;
                        var obj = entry.value;
                        return GestureDetector(
                          onTap: () => _onObjectTap(obj['name']!),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _showFeedback && index == _feedbackIndex
                                  ? (_isCorrect ? Colors.green.shade200 : Colors.red.shade200)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                            ),
                            child: Center(
                              child: Text(
                                obj['emoji']!,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ).animate().scale(duration: const Duration(milliseconds: 200)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade300,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      onPressed: _playHint,
                      child: const Text(
                        'Hear Hint',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
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