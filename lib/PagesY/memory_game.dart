import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  _MemoryGameScreenState createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  final FlutterTts _tts = FlutterTts();
  final List<Map<String, dynamic>> allCards = [
    {'image': '🐱', 'word': 'cat', 'level': 1},
    {'image': '🐶', 'word': 'dog', 'level': 1},
    {'image': '☀️', 'word': 'sun', 'level': 1},
    {'image': '🍎', 'word': 'apple', 'level': 1},
    {'image': '🐦', 'word': 'bird', 'level': 2},
    {'image': '🐻', 'word': 'bear', 'level': 2},
    {'image': '🦁', 'word': 'lion', 'level': 2},
    {'image': '🐯', 'word': 'tiger', 'level': 2},
    {'image': '🐘', 'word': 'elephant', 'level': 3},
    {'image': '🍓', 'word': 'strawberry', 'level': 3},
    {'image': '🌈', 'word': 'rainbow', 'level': 3},
    {'image': '🦒', 'word': 'giraffe', 'level': 3},
  ];

  List<Map<String, dynamic>> cards = [];
  List<bool> flipped = [];
  List<bool> matched = [];
  int? firstIndex;
  int? secondIndex;
  int score = 1; // Start score at 1
  int highScore = 0;
  bool isGameOver = false;
  int level = 1;
  int cardCount = 4;
  int timeLeft = 45;
  Timer? _timer;
  bool _isInitializing = false;
  bool _isCheckingMatch = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadProgress();
    _initializeGame();
  }

  Future<void> _initializeTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      level = prefs.getInt('memory_game_level')?.clamp(1, 4) ?? 1;
      highScore = prefs.getInt('memory_game_high_score_level_$level') ?? 0;
      print('Loaded: level=$level, highScore=$highScore');
    });
  }

  Future<void> _saveProgress() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('memory_game_level', level);
    await prefs.setInt('memory_game_high_score_level_$level', highScore);
    print('Saved: level=$level, highScore=$highScore');
  }

  void _initializeGame() {
    if (_isInitializing) return;
    _isInitializing = true;

    setState(() {
      switch (level) {
        case 1:
          cardCount = 4;
          timeLeft = 45;
          break;
        case 2:
          cardCount = 6;
          timeLeft = 60;
          break;
        case 3:
          cardCount = 8;
          timeLeft = 75;
          break;
        case 4:
          cardCount = 10;
          timeLeft = 90;
          break;
      }

      final levelCards =
          allCards.where((card) => card['level'] <= level).toList();
      final selectedCards = levelCards.take(cardCount ~/ 2).toList()..shuffle();

      final List<Map<String, dynamic>> newCards = [];
      for (var card in selectedCards) {
        newCards.add(
            {'type': 'image', 'value': card['image'], 'word': card['word']});
        newCards.add(
          level == 4
              ? {'type': 'word', 'value': card['word'], 'word': card['word']}
              : {'type': 'image', 'value': card['image'], 'word': card['word']},
        );
      }

      newCards.shuffle(Random());

      cards = newCards;
      flipped = List.filled(cardCount, false);
      matched = List.filled(cardCount, false);
      firstIndex = null;
      secondIndex = null;
      score = 1; // Start score at 1 for each level
      isGameOver = false;
      print(
          'Game initialized: level=$level, cardCount=$cardCount, timeLeft=$timeLeft, score=$score');
    });

    _startTimer();
    _isInitializing = false;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || isGameOver) {
        timer.cancel();
        return;
      }
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
          print('Timer tick: timeLeft=$timeLeft');
        } else {
          isGameOver = true;
          _tts.speak('Time\'s up!');
          timer.cancel();
          _showGameOverDialog();
        }
      });
    });
  }

  Future<void> _onCardTap(int index) async {
    if (flipped[index] ||
        matched[index] ||
        secondIndex != null ||
        isGameOver ||
        _isCheckingMatch) {
      return;
    }

    setState(() {
      flipped[index] = true;
      _tts.speak(cards[index]['word']);
      if (firstIndex == null) {
        firstIndex = index;
      } else {
        secondIndex = index;
        _checkForMatch();
      }
    });
  }

  Future<void> _checkForMatch() async {
    _isCheckingMatch = true;
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) {
      _isCheckingMatch = false;
      return;
    }

    setState(() {
      final isMatch = cards[firstIndex!]['word'] == cards[secondIndex!]['word'];

      if (isMatch) {
        matched[firstIndex!] = true;
        matched[secondIndex!] = true;
        score += 10; // Increment score by 10 for each match
        _tts.speak('Great job! Match found!');
        print('Match found: score=$score');

        if (matched.every((element) => element)) {
          isGameOver = true;
          _timer?.cancel();
          highScore = max(highScore, score);
          _saveHighScore();
          if (level < 4) {
            level++;
            _saveProgress();
            print('Level incremented to: $level');
          } else {
            // Optionally reset to Level 1 after completing Level 4
            level = 1;
            _saveProgress();
            print('Game completed, reset to level=$level');
          }
          _showGameOverDialog();
        }
      } else {
        _tts.speak('Try again!');
        flipped[firstIndex!] = false;
        flipped[secondIndex!] = false;
      }

      firstIndex = null;
      secondIndex = null;
      _isCheckingMatch = false;
    });
  }

  Future<void> _saveHighScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('high_scores').add({
          'user_id': user.uid,
          'score': score,
          'game': 'Memory Game',
          'level': level,
          'timestamp': Timestamp.now(),
        });
        print('High score saved to Firestore: score=$score, level=$level');
      } catch (e) {
        print('Failed to save high score: $e');
      }
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isGameOver && timeLeft == 0
              ? 'Time\'s Up!'
              : level <= 4
                  ? 'Level ${level - 1} Completed!'
                  : 'Game Completed!',
        ),
        content: Text(
          'Score: $score\nHigh Score: $highScore\n${level <= 4 ? 'Next Level: $level' : 'Back to Level 1'}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeGame();
            },
            child: const Text('Play Again'),
          ),
          if (level <= 4 && matched.every((element) => element))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _initializeGame();
              },
              child: const Text('Next Level'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Game - Level $level'),
        backgroundColor: Colors.pink.shade300,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeGame,
            tooltip: 'Restart Game',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = (screenWidth / 120).floor().clamp(2, 4);
            final cardSize = screenWidth / crossAxisCount - 8;
            final cardFontSize = cardSize / 3;

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade100, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Score: $score | High: $highScore | Time: $timeLeft',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Level: $level',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(4.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _onCardTap(index),
                          child: Animate(
                            effects: const [
                              FlipEffect(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
                            ],
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: cardSize,
                                maxHeight: cardSize,
                              ),
                              child: Card(
                                elevation: 4.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: flipped[index] || matched[index]
                                        ? Text(
                                            cards[index]['value'],
                                            style: TextStyle(
                                              fontSize:
                                                  cards[index]['type'] == 'word'
                                                      ? cardFontSize * 0.7
                                                      : cardFontSize,
                                              fontWeight:
                                                  cards[index]['type'] == 'word'
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          )
                                        : Text(
                                            '❓',
                                            style: TextStyle(
                                                fontSize: cardFontSize),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
