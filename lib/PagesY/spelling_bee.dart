import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

class SpellingBeeScreen extends StatefulWidget {
  const SpellingBeeScreen({Key? key}) : super(key: key);

  @override
  _SpellingBeeScreenState createState() => _SpellingBeeScreenState();
}

class _SpellingBeeScreenState extends State<SpellingBeeScreen> {
  final FlutterTts _tts = FlutterTts();
  final Map<int, List<Map<String, String>>> _levelWords = {
    1: [
      {'image': '🐱', 'word': 'cat'},
      {'image': '🐶', 'word': 'dog'},
      {'image': '🍎', 'word': 'apple'},
      {'image': '🐦', 'word': 'bird'},
      {'image': '🍌', 'word': 'banana'},
    ],
    2: [
      {'image': '🦒', 'word': 'giraffe'},
      {'image': '🦋', 'word': 'butterfly'},
      {'image': '🐘', 'word': 'elephant'},
      {'image': '🦁', 'word': 'lion'},
      {'image': '🦄', 'word': 'unicorn'},
    ],
    3: [
      {'image': '🚀', 'word': 'astronaut'},
      {'image': '🏰', 'word': 'castle'},
      {'image': '🎻', 'word': 'violin'},
      {'image': '🌋', 'word': 'volcano'},
      {'image': '🧭', 'word': 'compass'},
    ],
  };
  
  int currentLevel = 1;
  int currentIndex = 0;
  String currentAnswer = '';
  int score = 0;
  bool showHint = false;
  List<String> letterOptions = [];
  int attempts = 0;
  int wordsPerLevel = 3;
  int wordsCompletedInLevel = 0;
  bool _showAlphabet = false;

  List<Map<String, String>> get currentLevelWords => _levelWords[currentLevel] ?? _levelWords[1]!;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _generateLetterOptions();
    _playWord();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentLevel = prefs.getInt('spelling_bee_level') ?? 1;
      score = prefs.getInt('spelling_bee_high_score') ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('spelling_bee_level', currentLevel);
    await prefs.setInt('spelling_bee_high_score', score);
  }

  void _generateLetterOptions() {
    final correctWord = currentLevelWords[currentIndex]['word']!;
    letterOptions = correctWord.split('')..shuffle();
    
    int extraLetters = currentLevel + 2;
    
    while (letterOptions.length < correctWord.length + extraLetters) {
      final randomLetter = String.fromCharCode(97 + Random().nextInt(26));
      if (!letterOptions.contains(randomLetter)) {
        letterOptions.add(randomLetter);
      }
    }
    letterOptions.shuffle();
  }

  void _playWord() async {
    await _tts.speak(currentLevelWords[currentIndex]['word']!);
  }

  void _onLetterTap(String letter) {
    setState(() {
      currentAnswer += letter;
      if (currentAnswer.length == currentLevelWords[currentIndex]['word']!.length) {
        _checkAnswer();
      }
    });
  }

  void _checkAnswer() async {
    if (currentAnswer.toLowerCase() == currentLevelWords[currentIndex]['word']!.toLowerCase()) {
      setState(() {
        score += 10 * currentLevel;
        attempts = 0;
        showHint = false;
        currentAnswer = '';
        wordsCompletedInLevel++;
        
        if (wordsCompletedInLevel >= wordsPerLevel) {
          wordsCompletedInLevel = 0;
          if (currentLevel < _levelWords.length) {
            currentLevel++;
            _tts.speak('Level up! Now level $currentLevel');
          } else {
            _tts.speak('Congratulations! You completed all levels!');
          }
          currentIndex = 0;
        } else {
          currentIndex = (currentIndex + 1) % currentLevelWords.length;
        }
        
        _generateLetterOptions();
        _tts.speak('Correct! Great job!');
        _saveProgress();
      });
    } else {
      setState(() {
        attempts++;
        currentAnswer = '';
        _tts.speak('Try again!');
      });
      if (attempts >= 3) {
        setState(() {
          showHint = true;
        });
      }
    }
  }

  void _clearAnswer() {
    setState(() {
      currentAnswer = '';
    });
  }

  void _resetGame() {
    setState(() {
      currentLevel = 1;
      currentIndex = 0;
      score = 0;
      wordsCompletedInLevel = 0;
      currentAnswer = '';
      showHint = false;
      attempts = 0;
      _showAlphabet = false;
      _generateLetterOptions();
      _saveProgress();
    });
  }

  void _toggleAlphabet() {
    setState(() {
      _showAlphabet = !_showAlphabet;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spelling Bee - Level $currentLevel'),
        backgroundColor: Colors.pink.shade300,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: 'Reset Game',
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Score: $score | Level: $currentLevel',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (showHint)
              Column(
                children: [
                  Text(
                    currentLevelWords[currentIndex]['image']!,
                    style: const TextStyle(fontSize: 100),
                  ).animate().fadeIn(),
                  Text(
                    'Word length: ${currentLevelWords[currentIndex]['word']!.length} letters',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Text(
              currentAnswer.isEmpty ? 'Tap letters to spell' : currentAnswer,
              style: TextStyle(
                fontSize: 24,
                color: Colors.pink.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: letterOptions.map((letter) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade300,
                    padding: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _onLetterTap(letter),
                  child: Text(
                    letter.toUpperCase(),
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ).animate().scale(duration: const Duration(milliseconds: 200));
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (_showAlphabet)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Card(
                  color: Colors.white.withOpacity(0.8),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: 'abcdefghijklmnopqrstuvwxyz'.split('').map((letter) {
                        return InkWell(
                          onTap: () {
                            _onLetterTap(letter);
                            _toggleAlphabet();
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: letterOptions.contains(letter) 
                                ? Colors.green.shade200 
                                : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              letter.toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                color: letterOptions.contains(letter)
                                  ? Colors.black 
                                  : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  onPressed: _playWord,
                  child: const Text(
                    'Hear Again',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  onPressed: _clearAnswer,
                  child: const Text(
                    'Clear',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  onPressed: _toggleAlphabet,
                  child: const Text(
                    'Help',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: wordsCompletedInLevel / wordsPerLevel,
              backgroundColor: Colors.grey.shade300,
              color: Colors.pink,
              minHeight: 10,
            ),
            Text(
              'Progress: $wordsCompletedInLevel/$wordsPerLevel',
              style: const TextStyle(fontSize: 16),
            ),
          ],
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