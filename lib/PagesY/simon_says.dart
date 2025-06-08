import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import 'dart:async';

class SimonSaysScreen extends StatefulWidget {
  const SimonSaysScreen({Key? key}) : super(key: key);

  @override
  _SimonSaysScreenState createState() => _SimonSaysScreenState();
}

class _SimonSaysScreenState extends State<SimonSaysScreen> {
  final FlutterTts _tts = FlutterTts();
  final List<String> simpleActions = [
    'touch your nose',
    'clap your hands',
    'jump once',
    'wave your hand',
    'stomp your feet',
  ];
  final List<String> complexActions = [
    'jump three times',
    'spin around twice',
    'touch your left ear with your right hand',
    'count to five out loud',
    'do a little dance',
  ];
  
  List<String> get actions => level < 3 ? simpleActions : [...simpleActions, ...complexActions];
  
  String currentInstruction = '';
  int score = 0;
  int lives = 3;
  int level = 1;
  bool isSimonSays = false;
  bool showInstruction = false;
  bool isPlaying = false;
  bool isWaitingForResponse = false;
  Timer? instructionTimer;
  Timer? responseTimer;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(level < 4 ? 0.5 : 0.7);
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      score = prefs.getInt('simon_says_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('simon_says_high_score', score);
  }

  void _startGame() {
    setState(() {
      isPlaying = true;
      lives = 3;
      score = 0;
      level = 1;
    });
    _nextInstruction();
  }

  void _nextInstruction() {
    if (!isPlaying || lives <= 0) return;

    instructionTimer?.cancel();
    responseTimer?.cancel();

    setState(() {
      isSimonSays = level >= 2 ? Random().nextDouble() > 0.3 : true;
      currentInstruction = actions[Random().nextInt(actions.length)];
      showInstruction = true;
      isWaitingForResponse = false;
    });

    _tts.speak(isSimonSays ? 'Simon says $currentInstruction' : currentInstruction).then((_) {
      final instructionDelay = Duration(seconds: level < 4 ? 2 : 1);
      instructionTimer = Timer(instructionDelay, () {
        if (mounted) {
          setState(() {
            showInstruction = false;
            isWaitingForResponse = true;
          });
          
          // Give player time to respond
          responseTimer = Timer(const Duration(seconds: 3), () {
            if (isWaitingForResponse && isPlaying) {
              _checkResponse(null); // Timeout
            }
          });
        }
      });
    });
  }

  void _checkResponse(String? action) {
    if (!isWaitingForResponse || !isPlaying) return;

    responseTimer?.cancel();
    bool isCorrect = false;

    if (action == null) {
      // Timeout
      isCorrect = false;
    } else if (isSimonSays) {
      isCorrect = action == currentInstruction;
    } else {
      isCorrect = action != currentInstruction;
    }

    setState(() {
      isWaitingForResponse = false;
      if (isCorrect) {
        score += 10;
        if (score >= level * 50 && level < 4) {
          level++;
          _tts.speak('Level up! Now level $level');
          _initTTS(); // Adjust speech rate
        }
        _saveHighScore();
      } else {
        lives--;
        if (lives <= 0) {
          _tts.speak('Game over! Your score is $score');
          isPlaying = false;
          return;
        } else {
          _tts.speak('Wrong! Try again.');
        }
      }
    });

    if (isPlaying) {
      _nextInstruction();
    }
  }

  void _resetGame() {
    instructionTimer?.cancel();
    responseTimer?.cancel();
    setState(() {
      isPlaying = false;
      showInstruction = false;
      isWaitingForResponse = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Simon Says'),
        backgroundColor: Colors.pink.shade300,
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade200, Colors.blue.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Score: $score | Lives: $lives | Level: $level',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                if (showInstruction)
                  Text(
                    isSimonSays ? 'Simon says: $currentInstruction' : currentInstruction,
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.pink.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 300.ms),
                if (!isPlaying)
                  Column(
                    children: [
                      if (lives <= 0)
                        Text(
                          'Game Over! Score: $score',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        onPressed: _startGame,
                        child: const Text(
                          'Start Game',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(),
                if (isPlaying && !showInstruction && isWaitingForResponse)
                  Column(
                    children: [
                      const Text(
                        'What should you do?',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: actions.map((action) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink.shade300,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            ),
                            onPressed: () => _checkResponse(action),
                            child: Text(
                              action,
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ).animate().scale(duration: 200.ms);
                        }).toList(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    instructionTimer?.cancel();
    responseTimer?.cancel();
    _tts.stop();
    super.dispose();
  }
}