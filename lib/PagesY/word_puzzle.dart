import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

class WordPuzzleScreen extends StatefulWidget {
  const WordPuzzleScreen({Key? key}) : super(key: key);

  @override
  _WordPuzzleScreenState createState() => _WordPuzzleScreenState();
}

class _WordPuzzleScreenState extends State<WordPuzzleScreen> {
  final FlutterTts _tts = FlutterTts();
  final Map<int, List<Map<String, String>>> levels = {
    1: [
      {'word': 'CAT', 'scrambled': 'ACT', 'hint': '🐱 A pet that meows'},
      {'word': 'SUN', 'scrambled': 'NUS', 'hint': '☀️ Shines in the sky'},
      {'word': 'DOG', 'scrambled': 'GOD', 'hint': '🐶 A loyal friend'},
    ],
    2: [
      {'word': 'APPLE', 'scrambled': 'PPAEL', 'hint': '🍎 A red fruit'},
      {'word': 'CHAIR', 'scrambled': 'AHICR', 'hint': '🪑 Sit on it'},
      {'word': 'HOUSE', 'scrambled': 'OHSEU', 'hint': '🏠 Where you live'},
    ],
    3: [
      {'word': 'NIGHT', 'scrambled': 'GHINT', 'hint': '🌙 Opposite of day'},
      {'word': 'CHEESE', 'scrambled': 'EHCSEE', 'hint': '🧀 Made from milk'},
      {'word': 'THOUGHT', 'scrambled': 'OHTHUGT', 'hint': '💭 What you think'},
    ],
    4: [
      {
        'word': 'BANANA',
        'scrambled': 'ANANAB',
        'hint': '🍌 A yellow fruit',
        'category': 'Fruits'
      },
      {
        'word': 'TIGER',
        'scrambled': 'IGTRE',
        'hint': '🐅 A striped animal',
        'category': 'Animals'
      },
      {
        'word': 'PENCIL',
        'scrambled': 'ICNLEP',
        'hint': '✏️ Used for writing',
        'category': 'School'
      },
    ],
  };

  int currentLevel = 1;
  int currentIndex = 0;
  String currentAnswer = '';
  bool isCorrect = false;
  int score = 0;
  int hintsUsed = 0;
  int totalWordsCompleted = 0;
  bool isTtsInitialized = false;
  List<String> scrambledLetters = [];

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _setScrambledLetters();
  }

  Future<void> _initializeTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    setState(() {
      isTtsInitialized = true;
    });
  }

  void _setScrambledLetters() {
    final letters = levels[currentLevel]![currentIndex]['scrambled']!.split('');
    letters.shuffle(Random());
    setState(() {
      scrambledLetters = letters;
    });
  }

  void _onLetterTap(String letter) async {
    if (isCorrect) return;
    HapticFeedback.lightImpact();
    setState(() {
      final correctWord = levels[currentLevel]![currentIndex]['word']!;
      if (currentAnswer.length < correctWord.length) {
        currentAnswer += letter;
        if (currentAnswer == correctWord) {
          isCorrect = true;
          score += 10 - hintsUsed * 2;
          if (isTtsInitialized) {
            _tts.speak('Great job! Match found!');
          }
          totalWordsCompleted++;
          _checkLevelCompletion();
        }
      }
    });
  }

  void _useHint() {
    if (hintsUsed >= levels[currentLevel]![currentIndex]['word']!.length - 1 ||
        isCorrect) return;
    HapticFeedback.lightImpact();
    setState(() {
      final correctWord = levels[currentLevel]![currentIndex]['word']!;
      if (currentAnswer.length < correctWord.length) {
        currentAnswer += correctWord[currentAnswer.length];
        hintsUsed++;
        if (currentAnswer == correctWord) {
          isCorrect = true;
          score += 10 - hintsUsed * 2;
          if (isTtsInitialized) {
            _tts.speak('Great job! Match found!');
          }
          totalWordsCompleted++;
          _checkLevelCompletion();
        }
      }
    });
  }

  void _clearAnswer() {
    HapticFeedback.lightImpact();
    setState(() {
      currentAnswer = '';
      hintsUsed = 0;
    });
  }

  void _nextWord() {
    HapticFeedback.lightImpact();
    setState(() {
      currentAnswer = '';
      isCorrect = false;
      hintsUsed = 0;
      currentIndex = (currentIndex + 1) % levels[currentLevel]!.length;
      _setScrambledLetters();
    });
  }

  void _checkLevelCompletion() {
    if (totalWordsCompleted >= levels[currentLevel]!.length &&
        currentLevel < levels.length) {
      setState(() {
        currentLevel++;
        currentIndex = 0;
        totalWordsCompleted = 0;
        _setScrambledLetters();
        if (isTtsInitialized) {
          _tts.speak('Level $currentLevel unlocked!');
        }
      });
    } else if (totalWordsCompleted >= levels[currentLevel]!.length &&
        currentLevel == levels.length) {
      if (isTtsInitialized) {
        _tts.speak('Congratulations! All levels completed!');
      }
      _showGameOverDialog();
    }
  }

  void _restartGame() {
    HapticFeedback.lightImpact();
    setState(() {
      currentLevel = 1;
      currentIndex = 0;
      currentAnswer = '';
      isCorrect = false;
      score = 0;
      hintsUsed = 0;
      totalWordsCompleted = 0;
      _setScrambledLetters();
    });
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        title: const Text(
          'Game Completed!',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        content: Text(
          'Score: $score\nAll levels completed!',
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restartGame();
            },
            child: const Text(
              'Play Again',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Word Puzzle - Level $currentLevel',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.pink.shade400,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _restartGame,
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
              final crossAxisCount = (screenWidth / 80).floor().clamp(4, 6);
              final buttonSize = screenWidth / crossAxisCount - 8;
              final buttonFontSize = buttonSize / 2.5;

              return Column(
                children: [
                  // Add space before the body content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Score: $score',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Level: $currentLevel',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 75),
                          Card(
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Hint: ${levels[currentLevel]![currentIndex]['hint']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    isCorrect
                                        ? 'Great Job!'
                                        : 'Unscramble the Word:',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    currentAnswer.isEmpty
                                        ? '_' *
                                            levels[currentLevel]![currentIndex]
                                                    ['word']!
                                                .length
                                        : currentAnswer,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: isCorrect
                                          ? Colors.green.shade600
                                          : Colors.pink.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 4.0),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: scrambledLetters.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () =>
                                    _onLetterTap(scrambledLetters[index]),
                                child: Animate(
                                  effects: const [
                                    FlipEffect(
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    ),
                                  ],
                                  child: Card(
                                    elevation: 4.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Center(
                                      child: Text(
                                        scrambledLetters[index],
                                        style: TextStyle(
                                          fontSize: buttonFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade600,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      elevation: 4.0,
                                    ),
                                    onPressed: isCorrect ? null : _clearAnswer,
                                    child: const Text(
                                      'Clear',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      elevation: 4.0,
                                    ),
                                    onPressed: isCorrect ? null : _useHint,
                                    child: const Text(
                                      'Hint',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (isCorrect) ...[
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 12),
                                        elevation: 4.0,
                                      ),
                                      onPressed: _nextWord,
                                      child: const Text(
                                        'Next Word',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
    _tts.stop();
    super.dispose();
  }
}
