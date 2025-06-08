import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

class ColorTheWordScreen extends StatefulWidget {
  const ColorTheWordScreen({Key? key}) : super(key: key);

  @override
  _ColorTheWordScreenState createState() => _ColorTheWordScreenState();
}

class _ColorTheWordScreenState extends State<ColorTheWordScreen> {
  final FlutterTts _tts = FlutterTts();
  
  // Données pour les différents niveaux
  final List<Map<String, dynamic>> simpleItems = [
    {'image': '🍎', 'word': 'apple', 'color': Colors.red, 'size': 'medium'},
    {'image': '🍌', 'word': 'banana', 'color': Colors.yellow, 'size': 'medium'},
    {'image': '🍇', 'word': 'grapes', 'color': Colors.purple, 'size': 'small'},
    {'image': '🍊', 'word': 'orange', 'color': Colors.orange, 'size': 'medium'},
  ];
  
  final List<Map<String, dynamic>> complexItems = [
    {'image': '🐦', 'word': 'bird', 'color': Colors.blue, 'size': 'small'},
    {'image': '🐘', 'word': 'elephant', 'color': Colors.grey, 'size': 'big'},
    {'image': '🚗', 'word': 'car', 'color': Colors.red, 'size': 'medium'},
    {'image': '🌲', 'word': 'tree', 'color': Colors.green, 'size': 'big'},
  ];
  
  final List<Color> availableColors = [
    Colors.red,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.blue,
    Colors.green,
    Colors.grey,
    Colors.brown,
  ];
  
  int currentLevel = 1;
  int score = 0;
  int lives = 3;
  bool showFeedback = false;
  bool isCorrect = false;
  Color? selectedColor;
  String currentInstruction = '';
  List<Map<String, dynamic>> currentItems = [];
  List<Map<String, dynamic>> selectedItems = [];
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      score = prefs.getInt('color_the_word_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('color_the_word_high_score', score);
  }

  void _startGame() {
    setState(() {
      isPlaying = true;
      lives = 3;
      score = 0;
      currentLevel = 1;
      currentItems = [...simpleItems];
      _generateInstruction();
    });
  }

  void _generateInstruction() {
    if (!isPlaying) return;
    
    final random = Random();
    String instruction;
    List<Map<String, dynamic>> itemsToSelectFrom;
    
    // Sélection des items en fonction du niveau
    if (currentLevel < 3) {
      itemsToSelectFrom = simpleItems;
    } else {
      itemsToSelectFrom = [...simpleItems, ...complexItems];
    }
    
    // Sélection aléatoire de 1 à 3 items selon le niveau
    final itemCount = currentLevel < 2 ? 1 : (currentLevel < 4 ? 1 + random.nextInt(2) : 1 + random.nextInt(3));
    selectedItems = [];
    
    for (int i = 0; i < itemCount; i++) {
      selectedItems.add(itemsToSelectFrom[random.nextInt(itemsToSelectFrom.length)]);
    }
    
    // Génération de l'instruction selon le niveau
    if (currentLevel == 1) {
      instruction = "Color the ${selectedItems[0]['word']} ${_colorToName(selectedItems[0]['color'])}";
    } 
    else if (currentLevel == 2) {
      if (selectedItems.length == 1) {
        instruction = "Color the ${selectedItems[0]['word']} ${_colorToName(selectedItems[0]['color'])}";
      } else {
        instruction = "Color the ${selectedItems[0]['word']} ${_colorToName(selectedItems[0]['color'])} "
                     "and the ${selectedItems[1]['word']} ${_colorToName(selectedItems[1]['color'])}";
      }
    }
    else if (currentLevel == 3) {
      instruction = "Color the ${selectedItems[0]['size']} ${selectedItems[0]['word']} "
                   "${_colorToName(selectedItems[0]['color'])}";
    }
    else {
      if (selectedItems.length == 1) {
        instruction = "Color the ${selectedItems[0]['size']} ${selectedItems[0]['word']} "
                     "${_colorToName(selectedItems[0]['color'])}";
      } else {
        instruction = "Color the ${selectedItems.length} ${selectedItems[0]['size']} "
                     "${selectedItems[0]['word']}s ${_colorToName(selectedItems[0]['color'])}";
      }
    }
    
    setState(() {
      currentInstruction = instruction;
    });
    
    _tts.speak(instruction);
  }

  String _colorToName(Color color) {
    if (color == Colors.red) return 'red';
    if (color == Colors.yellow) return 'yellow';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.blue) return 'blue';
    if (color == Colors.green) return 'green';
    if (color == Colors.grey) return 'grey';
    if (color == Colors.brown) return 'brown';
    return '';
  }

  void _checkAnswer(Map<String, dynamic> item, Color color) {
    bool correct = color == item['color'];
    
    setState(() {
      showFeedback = true;
      isCorrect = correct;
      selectedColor = color;
      
      if (correct) {
        score += 10;
        // Vérifier si on peut passer au niveau suivant
        if (score >= currentLevel * 30 && currentLevel < 4) {
          currentLevel++;
          _tts.speak('Level up! Now level $currentLevel');
        }
        _saveHighScore();
        _tts.speak('Correct!');
      } else {
        lives--;
        _tts.speak('Try again!');
        if (lives <= 0) {
          _tts.speak('Game over! Your score is $score');
          isPlaying = false;
          return;
        }
      }
    });
    
    if (isPlaying && correct) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            showFeedback = false;
            selectedColor = null;
          });
          _generateInstruction();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Color the Word'),
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
                  'Score: $score | Lives: $lives | Level: $currentLevel',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
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
                if (isPlaying)
                  Column(
                    children: [
                      Text(
                        currentInstruction,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: selectedItems.map((item) {
                          return Column(
                            children: [
                              Text(
                                item['image'],
                                style: const TextStyle(fontSize: 50),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 5,
                                children: availableColors.map((color) {
                                  return GestureDetector(
                                    onTap: () => _checkAnswer(item, color),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: showFeedback && color == item['color']
                                              ? Colors.green
                                              : showFeedback && color != item['color']
                                                  ? Colors.red
                                                  : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade300,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        onPressed: _generateInstruction,
                        child: const Text(
                          'Repeat Instruction',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
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
    _tts.stop();
    super.dispose();
  }
}