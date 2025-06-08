import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class CatchTheWordScreen extends StatefulWidget {
  const CatchTheWordScreen({super.key});

  @override
  _CatchTheWordScreenState createState() => _CatchTheWordScreenState();
}

class _CatchTheWordScreenState extends State<CatchTheWordScreen> {
  int level = 1;
  int score = 0;
  int lives = 3;
  int highScore = 0;
  List<String> words = [];
  List<Map<String, dynamic>> fallingWords = [];
  String instruction = '';
  Timer? gameTimer;
  Random random = Random();
  bool isGameOver = false;
  bool isPaused = false;
  final FlutterTts _tts = FlutterTts();
  String? tappedWord;
  bool showInstruction = true;

  // Level data with extreme speeds
  final Map<int, Map<String, dynamic>> levelData = {
    1: {
      'instruction': 'Catch all animals!',
      'correctWords': ['cat', 'dog', 'bird', 'fish', 'tiger'],
      'trapWords': ['car', 'book', 'table', 'pen'],
      'speed': 100.0,
      'spawnRate': 0.3,
      'ttsPitch': 1.0,
      'maxWords': 8,
    },
    2: {
      'instruction': 'Level 2 - Faster!',
      'correctWords': ['ant', 'bear', 'wolf', 'deer', 'fox'],
      'trapWords': ['aunt', 'beer', 'wool', 'door', 'box'],
      'speed': 150.0,
      'spawnRate': 0.2,
      'ttsPitch': 1.1,
      'maxWords': 10,
    },
    3: {
      'instruction': 'Level 3 - Extreme!',
      'correctWords': ['lion', 'elephant', 'zebra', 'giraffe', 'monkey'],
      'trapWords': ['table', 'chair', 'lamp', 'clock', 'phone'],
      'speed': 200.0,
      'spawnRate': 0.15,
      'ttsPitch': 1.2,
      'maxWords': 12,
    },
    4: {
      'instruction': 'Final Level - Good luck!',
      'correctWords': ['rat', 'mat', 'pat', 'lat', 'flat'],
      'trapWords': ['dog', 'pen', 'sun', 'tree', 'car'],
      'speed': 250.0,
      'spawnRate': 0.1,
      'ttsPitch': 1.3,
      'maxWords': 15,
    },
  };

  @override
  void initState() {
    super.initState();
    _configureTts();
    startLevel(level);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => showInstruction = false);
    });
  }

  void _configureTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
    } catch (e) {
      print('TTS config error: $e');
    }
  }

  void startLevel(int level) {
    if (!mounted) return;
    setState(() {
      words = [
        ...levelData[level]!['correctWords'],
        ...levelData[level]!['trapWords'],
      ];
      instruction = levelData[level]!['instruction'];
      fallingWords.clear();
      isGameOver = false;
      isPaused = false;
      showInstruction = true;
    });
    _speakInstruction();
    startSpawningWords(level);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => showInstruction = false);
    });
  }

  void _speakInstruction() async {
    try {
      await _tts.stop();
      await _tts.awaitSpeakCompletion(true);
      await _tts.setPitch(levelData[level]!['ttsPitch']);
      await _tts.speak(instruction);
    } catch (e) {
      print('TTS error: $e');
    }
  }

  void startSpawningWords(int level) {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(
      Duration(milliseconds: (levelData[level]!['spawnRate'] * 1000).toInt()),
      (timer) {
        if (mounted && fallingWords.length < 5 && !isGameOver && !isPaused) { // Augmenté le nombre max de mots à 5
          spawnWord();
        }
      },
    );
  }

  void spawnWord() {
    final word = words[random.nextInt(words.length)];
    final isCorrect = levelData[level]!['correctWords'].contains(word);
    final maxWidth = MediaQuery.of(context).size.width - 50;
    const slotWidth = 80.0;
    final slots = (maxWidth / slotWidth).floor();
    final occupiedSlots = <int>{};

    for (var existingWord in fallingWords) {
      final slot = (existingWord['position'].dx / slotWidth).floor();
      occupiedSlots.add(slot);
    }

    final availableSlots = List.generate(slots, (index) => index)
        .where((slot) => !occupiedSlots.contains(slot))
        .toList();

    if (availableSlots.isEmpty) return;

    final slot = availableSlots[random.nextInt(availableSlots.length)];
    final xPosition = slot * slotWidth;

    setState(() {
      fallingWords.add({
        'word': word,
        'isCorrect': isCorrect,
        'position': Offset(xPosition, -50),
        'key': UniqueKey(),
      });
    });
  }

  void onWordTapped(String word, bool isCorrect, Key key) {
    if (isGameOver || isPaused) return;
    setState(() {
      tappedWord = word;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => tappedWord = null);
    });

    if (isCorrect) {
      setState(() {
        score += level == 1 ? 6 : level == 4 ? 12 : 10;
        fallingWords.removeWhere((w) => w['key'] == key);
      });
      try {
        _tts.stop();
        _tts.setPitch(1.0);
        _tts.speak('Good catch!');
      } catch (e) {
        print('TTS error: $e');
      }
      if (score >= 60 && level == 1 ||
          score >= 100 && level == 2 ||
          score >= 140 && level == 3) {
        level++;
        if (level <= 4) {
          startLevel(level);
        }
      }
    } else {
      setState(() {
        if (level == 4) {
          isGameOver = true;
          gameTimer?.cancel();
          instruction = 'Game Over! Wrong word!';
          if (score > highScore) highScore = score;
          _speakInstruction();
        } else {
          lives--;
          if (lives <= 0) {
            isGameOver = true;
            gameTimer?.cancel();
            instruction = 'Game Over! No lives left!';
            if (score > highScore) highScore = score;
            _speakInstruction();
          }
        }
        fallingWords.removeWhere((w) => w['key'] == key);
      });
    }
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
      if (!isPaused) {
        startSpawningWords(level);
      }
    });
    if (isPaused) {
      try {
        _tts.stop();
        _tts.speak('Game paused');
      } catch (e) {
        print('TTS error: $e');
      }
    }
  }

  void restartGame() {
    setState(() {
      score = 0;
      level = 1;
      lives = 3;
      isGameOver = false;
      isPaused = false;
      fallingWords.clear();
      instruction = '';
      highScore = 0;
    });
    startLevel(level);
  }

  void goToMainMenu() {
    restartGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    try {
      _tts.stop();
    } catch (e) {
      print('TTS stop error: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade100, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('Catch the Word - Level $level'),
            backgroundColor: Colors.pink.shade300.withOpacity(0.8),
            actions: [
              IconButton(
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: togglePause,
                tooltip: isPaused ? 'Resume' : 'Pause',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: restartGame,
                tooltip: 'Restart Game',
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Score: $score',
                          style: const TextStyle(
                              fontSize: 20, 
                              color: Colors.white, 
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Lives: ${'❤️' * lives}',
                          style: const TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AnimatedOpacity(
                opacity: showInstruction ? 1.0 : 0.0,
                duration: const Duration(seconds: 1),
                child: Center(
                  child: Text(
                    instruction,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 4, color: Colors.black87),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (isGameOver)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Game Over! Score: $score',
                          style: const TextStyle(
                              fontSize: 32, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.red),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'High Score: $highScore',
                          style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        if (score >= 100)
                          const Text(
                            '🎉 Great Job!',
                            style: TextStyle(fontSize: 24),
                          ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 15),
                              ),
                              onPressed: restartGame,
                              child: const Text(
                                'Play Again',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 15),
                              ),
                              onPressed: goToMainMenu,
                              child: const Text(
                                'Main Menu',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (isPaused && !isGameOver)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Paused',
                      style: TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.blue),
                    ),
                  ),
                ),
              ...fallingWords.map((word) {
                return FallingWordWidget(
                  key: word['key'],
                  word: word['word'],
                  isCorrect: word['isCorrect'],
                  xPosition: word['position'].dx,
                  speed: levelData[level]!['speed'],
                  screenHeight: MediaQuery.of(context).size.height,
                  onMiss: () {
                    if (isGameOver || isPaused) return;
                    setState(() {
                      if (word['isCorrect']) {
                        lives--;
                        try {
                          _tts.stop();
                          _tts.setPitch(1.0);
                          _tts.speak('Missed!');
                        } catch (e) {
                          print('TTS error: $e');
                        }
                        if (lives <= 0) {
                          isGameOver = true;
                          gameTimer?.cancel();
                          instruction = 'Game Over! No lives left!';
                          if (score > highScore) highScore = score;
                          _speakInstruction();
                        }
                      } else {
                        score = (score - 5).clamp(0, double.infinity).toInt();
                        try {
                          _tts.stop();
                          _tts.setPitch(0.9);
                          _tts.speak('Wrong word missed!');
                        } catch (e) {
                          print('TTS error: $e');
                        }
                      }
                      fallingWords.removeWhere((w) => w['key'] == word['key']);
                    });
                  },
                  onTap: (w, isCorrect) => onWordTapped(w, isCorrect, word['key']),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class FallingWordWidget extends StatefulWidget {
  final String word;
  final bool isCorrect;
  final double xPosition;
  final double speed;
  final double screenHeight;
  final VoidCallback onMiss;
  final Function(String, bool) onTap;

  const FallingWordWidget({
    required this.word,
    required this.isCorrect,
    required this.xPosition,
    required this.speed,
    required this.screenHeight,
    required this.onMiss,
    required this.onTap,
    super.key,
  });

  @override
  _FallingWordWidgetState createState() => _FallingWordWidgetState();
}

class _FallingWordWidgetState extends State<FallingWordWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isTapped = false;
  bool _hasMissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: (widget.screenHeight / widget.speed * 1000).toInt()),
      vsync: this,
    );
    _animation = Tween<double>(begin: -50, end: widget.screenHeight).animate(_controller)
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted && !_hasMissed) {
          _hasMissed = true;
          widget.onMiss();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.xPosition,
      top: _animation.value,
      child: GestureDetector(
        onTap: () {
          if (_hasMissed) return;
          setState(() => isTapped = true);
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) setState(() => isTapped = false);
          });
          _controller.stop();
          widget.onTap(widget.word, widget.isCorrect);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(isTapped ? 1.5 : 1.0),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: isTapped
                ? Colors.yellow.withOpacity(0.9)
                : widget.isCorrect
                    ? Colors.green.withOpacity(0.7)
                    : Colors.red.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isCorrect ? Colors.green.shade900 : Colors.red.shade900,
              width: 2,
            ),
          ),
          child: Text(
            widget.word,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
            ),
          ),
        ),
      ),
    );
  }
}