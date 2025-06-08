import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

enum Category { animals, colors, fruits, vehicles }

class TapAndLearnScreen extends StatefulWidget {
  const TapAndLearnScreen({Key? key}) : super(key: key);

  @override
  _TapAndLearnScreenState createState() => _TapAndLearnScreenState();
}

class _TapAndLearnScreenState extends State<TapAndLearnScreen> {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<Category, List<Map<String, String>>> objects = {
    Category.animals: [
      {'name': 'cat', 'emoji': '🐱'},
      {'name': 'dog', 'emoji': '🐶'},
      {'name': 'bird', 'emoji': '🐦'},
      {'name': 'fish', 'emoji': '🐟'},
      {'name': 'horse', 'emoji': '🐎'},
      {'name': 'rabbit', 'emoji': '🐰'},
      {'name': 'elephant', 'emoji': '🐘'},
      {'name': 'lion', 'emoji': '🦁'},
      {'name': 'tiger', 'emoji': '🐯'},
      {'name': 'bear', 'emoji': '🐻'},
    ],
    Category.colors: [
      {'name': 'red', 'emoji': '🔴'},
      {'name': 'blue', 'emoji': '🔵'},
      {'name': 'green', 'emoji': '🟢'},
      {'name': 'yellow', 'emoji': '🟡'},
      {'name': 'purple', 'emoji': '🟣'},
      {'name': 'orange', 'emoji': '🟠'},
      {'name': 'pink', 'emoji': '🌸'},
      {'name': 'brown', 'emoji': '🟤'},
      {'name': 'black', 'emoji': '⚫'},
      {'name': 'white', 'emoji': '⚪'},
    ],
    Category.fruits: [
      {'name': 'apple', 'emoji': '🍎'},
      {'name': 'banana', 'emoji': '🍌'},
      {'name': 'orange', 'emoji': '🍊'},
      {'name': 'grape', 'emoji': '🍇'},
      {'name': 'strawberry', 'emoji': '🍓'},
      {'name': 'lemon', 'emoji': '🍋'},
      {'name': 'pineapple', 'emoji': '🍍'},
      {'name': 'mango', 'emoji': '🥭'},
      {'name': 'watermelon', 'emoji': '🍉'},
      {'name': 'peach', 'emoji': '🍑'},
    ],
    Category.vehicles: [
      {'name': 'car', 'emoji': '🚗'},
      {'name': 'bus', 'emoji': '🚌'},
      {'name': 'bike', 'emoji': '🚲'},
      {'name': 'train', 'emoji': '🚂'},
      {'name': 'truck', 'emoji': '🚚'},
      {'name': 'boat', 'emoji': '⛵'},
      {'name': 'airplane', 'emoji': '✈️'},
      {'name': 'helicopter', 'emoji': '🚁'},
      {'name': 'motorcycle', 'emoji': '🏍️'},
      {'name': 'tractor', 'emoji': '🚜'},
    ],
  };
  int score = 0;
  int highScore = 0;
  int timeLeft = 30;
  Timer? _timer;
  Category _category = Category.animals;
  bool _gameOver = false;
  int? _tappedIndex;
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _startTimer();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('tap_and_learn_high_score_${_category.name}') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      await prefs.setInt('tap_and_learn_high_score_${_category.name}', score);
      setState(() {
        highScore = score;
      });
    }
  }

  void _playSound(String asset) async {
    await _audioPlayer.play(AssetSource(asset));
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      timeLeft = 30;
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

  void _onObjectTap(String name, int index) async {
    if (_gameOver) return;
    await _tts.speak(name);
    setState(() {
      score += 5;
      _tappedIndex = index;
      _showFeedback = true;
      _saveHighScore();
    });
    _playSound('sounds/tap.mp3');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showFeedback = false;
          _tappedIndex = null;
        });
      }
    });
  }

  void _restartGame() {
    setState(() {
      score = 0;
      _gameOver = false;
      _tappedIndex = null;
      _showFeedback = false;
    });
    _startTimer();
  }

  void _changeCategory(Category category) {
    setState(() {
      _category = category;
      score = 0;
      _gameOver = false;
      _tappedIndex = null;
      _showFeedback = false;
    });
    _loadHighScore();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Tap and Learn'),
        backgroundColor: Colors.pink.shade300,
        actions: [
          DropdownButton<Category>(
            value: _category,
            onChanged: (Category? newValue) {
              if (newValue != null) {
                _changeCategory(newValue);
              }
            },
            items: Category.values.map((Category category) {
              return DropdownMenuItem<Category>(
                value: category,
                child: Text(category.name.toUpperCase()),
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
                      'Category: ${_category.name.toUpperCase()}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Score: $score | High Score: $highScore | Time: $timeLeft',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: objects[_category]!.asMap().entries.map((entry) {
                        int index = entry.key;
                        var obj = entry.value;
                        return GestureDetector(
                          onTap: () => _onObjectTap(obj['name']!, index),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _showFeedback && index == _tappedIndex
                                      ? Colors.blue.shade200
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
                              ),
                              if (_showFeedback && index == _tappedIndex)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    obj['name']!.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                            ],
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
                      onPressed: _restartGame,
                      child: const Text(
                        'Reset Game',
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