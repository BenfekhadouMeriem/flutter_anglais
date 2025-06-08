import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:math';

class AnimalSoundsScreen extends StatefulWidget {
  const AnimalSoundsScreen({Key? key}) : super(key: key);

  @override
  _AnimalSoundsScreenState createState() => _AnimalSoundsScreenState();
}

class _AnimalSoundsScreenState extends State<AnimalSoundsScreen> {
  final FlutterTts _tts = FlutterTts();
  final List<Map<String, String>> animals = [
    {'name': 'cat', 'emoji': '🐱', 'sound': 'Meow'},
    {'name': 'dog', 'emoji': '🐶', 'sound': 'Woof'},
    {'name': 'bird', 'emoji': '🐦', 'sound': 'Tweet'},
    {'name': 'cow', 'emoji': '🐄', 'sound': 'Moo'},
    {'name': 'sheep', 'emoji': '🐑', 'sound': 'Baa'},
    {'name': 'horse', 'emoji': '🐎', 'sound': 'Neigh'},
    {'name': 'pig', 'emoji': '🐷', 'sound': 'Oink'},
    {'name': 'elephant', 'emoji': '🐘', 'sound': 'Trumpet'},
  ];
  int currentIndex = 0;
  int score = 0;
  int highScore = 0;
  bool showFeedback = false;
  bool isCorrect = false;
  int timeLeft = 30;
  Timer? _timer;
  String difficulty = 'easy';
  int optionsCount = 3;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _startGame();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('animal_sounds_high_score_$difficulty') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      highScore = score;
      await prefs.setInt('animal_sounds_high_score_$difficulty', highScore);
    }
  }

  void _startGame() {
    setState(() {
      score = 0;
      timeLeft = difficulty == 'easy' ? 30 : difficulty == 'medium' ? 20 : 15;
      optionsCount = difficulty == 'easy' ? 3 : difficulty == 'medium' ? 4 : 5;
    });
    _startTimer();
    _playSound();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          _timer?.cancel();
          _showGameOverDialog();
        }
      });
    });
  }

  void _playSound() async {
    await _tts.setPitch(difficulty == 'hard' ? 1.2 : 1.0);
    await _tts.speak(animals[currentIndex]['sound']!);
  }

  void _onAnimalTap(String name) async {
    setState(() {
      isCorrect = name == animals[currentIndex]['name'];
      showFeedback = true;
      if (isCorrect) {
        score += difficulty == 'easy' ? 10 : difficulty == 'medium' ? 15 : 20;
        _tts.speak('Correct!');
        _saveHighScore();
      } else {
        score -= 5;
        _tts.speak('Try again!');
      }
    });
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        showFeedback = false;
        currentIndex = Random().nextInt(animals.length);
      });
      _playSound();
    }
  }

  List<Map<String, String>> _getOptions() {
    List<Map<String, String>> options = [animals[currentIndex]];
    while (options.length < optionsCount) {
      final randomAnimal = animals[Random().nextInt(animals.length)];
      if (!options.contains(randomAnimal)) options.add(randomAnimal);
    }
    return options..shuffle();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over!'),
        content: Text('Your score: $score\nHigh Score: $highScore'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _changeDifficulty(String newDifficulty) {
    setState(() {
      difficulty = newDifficulty;
    });
    _loadHighScore();
    _startGame();
  }

  @override
  Widget build(BuildContext context) {
    final options = _getOptions();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Animal Sounds Game'),
        backgroundColor: Colors.pink.shade300,
        actions: [
          DropdownButton<String>(
            value: difficulty,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            dropdownColor: Colors.pink.shade300,
            items: ['easy', 'medium', 'hard'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value[0].toUpperCase() + value.substring(1),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) _changeDifficulty(newValue);
            },
          ),
          const SizedBox(width: 16),
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
                        'Score: $score',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'High Score: $highScore',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Time: $timeLeft s',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: timeLeft < 5 ? Colors.red : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade300,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    label: const Text(
                      'Hear Sound',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    onPressed: _playSound,
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    children: options.map((animal) {
                      return GestureDetector(
                        onTap: () => _onAnimalTap(animal['name']!),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: showFeedback && animal['name'] == animals[currentIndex]['name']
                                ? Colors.green.shade400
                                : showFeedback && animal['name'] != animals[currentIndex]['name']
                                    ? Colors.red.shade400
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                            ],
                            border: Border.all(color: Colors.pink.shade200, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              animal['emoji']!,
                              style: const TextStyle(fontSize: 50),
                            ),
                          ),
                        ),
                      ).animate().scale(duration: const Duration(milliseconds: 300)).shake(
                            duration: showFeedback ? const Duration(milliseconds: 300) : Duration.zero,
                          );
                    }).toList(),
                  ),
                  if (showFeedback)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        isCorrect ? 'Great Job!' : 'Try Again!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isCorrect ? Colors.green.shade600 : Colors.red.shade600,
                        ),
                      ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
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
    super.dispose();
  }
}