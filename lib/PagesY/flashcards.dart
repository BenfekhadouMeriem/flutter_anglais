import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:math';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  _FlashcardsScreenState createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final FlutterTts _tts = FlutterTts();
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 2));
  final List<Map<String, String>> cards = [
    {'image': '🐱', 'word': 'cat'},
    {'image': '🐶', 'word': 'dog'},
    {'image': '☀️', 'word': 'sun'},
    {'image': '🍎', 'word': 'apple'},
    {'image': '🐦', 'word': 'bird'},
    {'image': '🍌', 'word': 'banana'},
    {'image': '🐻', 'word': 'bear'},
    {'image': '🦁', 'word': 'lion'},
    {'image': '🐘', 'word': 'elephant'},
    {'image': '🍓', 'word': 'strawberry'},
  ];
  int currentIndex = 0;
  int score = 1;
  int highScore = 0;
  int level = 1;
  int timeLeft = 60; // For Level 3
  bool showFeedback = false;
  bool isCorrect = false;
  Set<int> learnedWords = {};
  Timer? _timer;
  bool isGameOver = false;
  List<String> options = [];
  String? spokenWord; // For Level 4

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
      level = prefs.getInt('flashcards_level')?.clamp(1, 4) ?? 1;
      highScore = prefs.getInt('flashcards_high_score_level_$level') ?? 0;
      print('Loaded: level=$level, highScore=$highScore');
    });
  }

  Future<void> _saveProgress() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('flashcards_level', level);
    await prefs.setInt('flashcards_high_score_level_$level', highScore);
    print('Saved: level=$level, highScore=$highScore');
  }

  void _initializeGame() {
    setState(() {
      currentIndex = 0;
      score = 1; // Start score at 1
      learnedWords.clear();
      isGameOver = false;
      showFeedback = false;
      options = _getOptions();
      spokenWord = level == 4 ? cards[currentIndex]['word'] : null;
      if (level == 3) {
        timeLeft = 60;
        _startTimer();
      } else {
        _timer?.cancel();
        timeLeft = 0;
      }
      print('Game initialized: level=$level, score=$score, timeLeft=$timeLeft');
    });
    _playAudio();
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

  void _playAudio() async {
    final wordToSpeak = level == 4 ? spokenWord : cards[currentIndex]['word'];
    if (wordToSpeak != null) {
      await _tts.speak(wordToSpeak);
      if (level == 2 || level == 3) {
        await _tts.speak('Which one is the $wordToSpeak?');
      }
    }
  }

  List<String> _getOptions() {
    if (level == 1) return [];
    final optionCount = level == 2 ? 3 : 4;
    List<String> options = [cards[currentIndex]['word']!];
    while (options.length < optionCount) {
      final randomWord = cards[Random().nextInt(cards.length)]['word']!;
      if (!options.contains(randomWord)) options.add(randomWord);
    }
    return options..shuffle();
  }

  void _onCardTap(int index) async {
    if (isGameOver || showFeedback) return;

    setState(() {
      showFeedback = true;
      isCorrect = level == 4
          ? cards[index]['word'] == spokenWord
          : index == currentIndex;
      if (isCorrect) {
        score += 10;
        learnedWords.add(currentIndex);
        _tts.speak('Great job!');
        if (learnedWords.length == cards.length) {
          _confettiController.play();
          isGameOver = true;
          highScore = max(highScore, score);
          _saveProgress();
          if (level < 4) {
            level++;
            _saveProgress();
            print('Level incremented to: $level');
          } else {
            level = 1;
            _saveProgress();
            print('Game completed, reset to level=$level');
          }
          _showGameOverDialog();
        }
      } else {
        _tts.speak('Try again!');
      }
    });

    if (!isGameOver) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        showFeedback = false;
        currentIndex = (currentIndex + 1) % cards.length;
        options = _getOptions();
        spokenWord =
            level == 4 ? cards[Random().nextInt(cards.length)]['word'] : null;
      });
      _playAudio();
    }
  }

  void _onNextTap() {
    setState(() {
      learnedWords.add(currentIndex);
      score += 10;
      if (learnedWords.length == cards.length) {
        isGameOver = true;
        highScore = max(highScore, score);
        _saveProgress();
        if (level < 4) {
          level++;
          _saveProgress();
          print('Level incremented to: $level');
        } else {
          level = 1;
          _saveProgress();
          print('Game completed, reset to level=$level');
        }
        _confettiController.play();
        _showGameOverDialog();
      } else {
        currentIndex = (currentIndex + 1) % cards.length;
        _playAudio();
      }
    });
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
          if (level <= 4 && learnedWords.length == cards.length)
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
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Flashcards - Level $level'),
      backgroundColor: Colors.pink.shade300,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _initializeGame,
          tooltip: 'Restart Game',
        ),
      ],
    ),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade100, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount =
                level == 1 ? 1 : (screenWidth / 120).floor().clamp(2, 4);
            final cardSize = screenWidth / crossAxisCount - 4;
            final cardFontSize = cardSize / 3;

            return Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Score: $score | High: $highScore${level == 3 ? ' | Time: $timeLeft' : ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Level: $level',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: LinearProgressIndicator(
                        value: learnedWords.length / cards.length,
                        backgroundColor: Colors.grey.shade300,
                        color: Colors.pink.shade300,
                        minHeight: 8,
                      ),
                    ),
                    SizedBox(
                      height: cardSize *
                          (level == 1
                              ? 1
                              : level == 2
                                  ? 1.5
                                  : 2),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(2.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 2.0,
                          mainAxisSpacing: 2.0,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: level == 1
                            ? 1
                            : level == 2
                                ? 3
                                : 4,
                        itemBuilder: (context, index) {
                          final displayIndex = level == 1
                              ? currentIndex
                              : (options.length > index ? index : 0);
                          final displayCard = level == 4
                              ? cards[Random().nextInt(cards.length)]
                              : cards[displayIndex];
                          return GestureDetector(
                            onTap: level == 1 ? null : () => _onCardTap(displayIndex),
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
                                  color: showFeedback && level != 1
                                      ? (isCorrect &&
                                              displayIndex ==
                                                  (level == 4
                                                      ? cards.indexWhere(
                                                          (c) => c['word'] == spokenWord)
                                                      : currentIndex)
                                          ? Colors.green
                                          : Colors.red)
                                      : Colors.white,
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: Text(
                                        level == 4
                                            ? displayCard['image']!
                                            : cards[displayIndex]['image']!,
                                        style: TextStyle(fontSize: cardFontSize),
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
                    if (level == 1)
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade300,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          onPressed: _onNextTap,
                          child: const Text(
                            'Next',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    if (level != 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          alignment: WrapAlignment.center,
                          children: options.map((word) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: showFeedback &&
                                        word == cards[currentIndex]['word']
                                    ? Colors.green
                                    : showFeedback &&
                                            word != cards[currentIndex]['word']
                                        ? Colors.red
                                        : Colors.pink.shade300,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                              ),
                              onPressed: showFeedback
                                  ? null
                                  : () => _onCardTap(cards.indexWhere(
                                      (c) => c['word'] == word)),
                              child: Text(
                                word,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ).animate().scale(
                                duration: const Duration(milliseconds: 200));
                          }).toList(),
                        ),
                      ),
                    if (showFeedback && level != 1)
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          isCorrect ? 'Correct!' : 'Try Again!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                        ).animate().fadeIn(),
                      ),
                  ],
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: [
                      Colors.pink,
                      Colors.blue,
                      Colors.green,
                      Colors.yellow
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
    _confettiController.dispose();
    super.dispose();
  }
}
