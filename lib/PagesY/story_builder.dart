import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class StoryBuilderScreen extends StatefulWidget {
  const StoryBuilderScreen({Key? key}) : super(key: key);

  @override
  _StoryBuilderScreenState createState() => _StoryBuilderScreenState();
}

class _StoryBuilderScreenState extends State<StoryBuilderScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isTtsEnabled = true;
  final List<Map<String, dynamic>> templates = [
    {
      'template': 'The [animal] goes to the [place].',
      'animal': {
        'correct': ['cat', 'dog', 'bird', 'elephant', 'tiger'],
        'incorrect': ['table', 'cloud', 'book']
      },
      'place': {
        'correct': ['park', 'beach', 'school', 'forest', 'zoo'],
        'incorrect': ['spoon', 'shirt', 'pencil']
      },
      'validation_rules': (Map<String, String> words) => words['animal'] != null && words['place'] != null,
    },
    {
      'template': '[person] eats a [food].',
      'person': {
        'correct': ['boy', 'girl', 'teacher', 'chef', 'astronaut'],
        'incorrect': ['car', 'tree', 'lamp']
      },
      'food': {
        'correct': ['apple', 'banana', 'cake', 'pizza', 'sushi'],
        'incorrect': ['rock', 'pen', 'chair']
      },
      'validation_rules': (Map<String, String> words) => words['person'] != null && words['food'] != null,
    },
    {
      'template': 'A [adjective] [animal] explores the [place].',
      'adjective': {
        'correct': ['brave', 'curious', 'sneaky', 'happy', 'giant'],
        'incorrect': ['blue', 'round', 'soft']
      },
      'animal': {
        'correct': ['lion', 'penguin', 'fox', 'bear', 'rabbit'],
        'incorrect': ['desk', 'window', 'clock']
      },
      'place': {
        'correct': ['mountain', 'cave', 'desert', 'jungle', 'city'],
        'incorrect': ['fork', 'hat', 'bag']
      },
      'validation_rules': (Map<String, String> words) =>
          words['adjective'] != null && words['animal'] != null && words['place'] != null,
    },
  ];
  int currentTemplateIndex = 0;
  Map<String, String> selectedWords = {};
  int score = 0;
  double _progress = 0.0;
  bool? _isSentenceCorrect;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
    } catch (e) {
      print("TTS initialization error: $e");
    }
  }

  Future<void> _loadHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        score = prefs.getInt('story_builder_high_score') ?? 0;
      });
    } catch (e) {
      print("Error loading high score: $e");
    }
  }

  Future<void> _saveHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('story_builder_high_score', score);
    } catch (e) {
      print("Error saving high score: $e");
    }
  }

  bool _validateSentence() {
    final template = templates[currentTemplateIndex];
    final validationRules = template['validation_rules'] as bool Function(Map<String, String>);
    bool isValid = validationRules(selectedWords);
    for (var key in selectedWords.keys) {
      final correctWords = template[key]['correct'] as List<String>;
      if (!correctWords.contains(selectedWords[key])) {
        isValid = false;
        break;
      }
    }
    return isValid;
  }

  void _selectWord(String key, String word) async {
    setState(() {
      selectedWords[key] = word;
      _progress = selectedWords.length / templates[currentTemplateIndex].keys.where((k) => k != 'template' && k != 'validation_rules').length;
      if (_isTtsEnabled) {
        _tts.speak(word).catchError((e) => print("TTS error: $e"));
      }
      if (selectedWords.length == templates[currentTemplateIndex].keys.where((k) => k != 'template' && k != 'validation_rules').length) {
        _isSentenceCorrect = _validateSentence();
        score += _isSentenceCorrect! ? 20 : 5;
        if (_isSentenceCorrect!) {
          _readStory();
        } else {
          if (_isTtsEnabled) {
            _tts.speak("Oops, that sentence doesn't make sense!");
          }
        }
        _saveHighScore();
        _showGameOverDialog();
      }
    });
  }

  void _readStory() async {
    if (!_isTtsEnabled) return;
    String story = templates[currentTemplateIndex]['template'] as String;
    selectedWords.forEach((key, value) {
      story = story.replaceAll('[$key]', value);
    });
    try {
      await _tts.speak(story);
    } catch (e) {
      print("TTS story reading error: $e");
    }
  }

  void _resetStory() {
    setState(() {
      selectedWords.clear();
      _progress = 0.0;
      _isSentenceCorrect = null;
      currentTemplateIndex = Random().nextInt(templates.length);
    });
  }

  void _toggleTts() {
    setState(() {
      _isTtsEnabled = !_isTtsEnabled;
      if (!_isTtsEnabled) _tts.stop();
    });
  }

void _showGameOverDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(_isSentenceCorrect! ? 'Great Story!' : 'Try Again!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSentenceCorrect!
                ? 'Your story makes sense! Score: $score'
                : 'That story was a bit odd. Score: $score',
            style: const TextStyle(fontSize: 18),
          ),
          if (!_isSentenceCorrect!)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Try choosing words that fit the story better!',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _resetStory();
          },
          child: const Text(
            'New Story',
            style: TextStyle(color: Colors.pink),
          ),
        ),
      ],
    ),
  );
}


  List<String> _getWordOptions(String key) {
    final template = templates[currentTemplateIndex];
    final correctWords = List<String>.from(template[key]['correct']);
    final incorrectWords = List<String>.from(template[key]['incorrect']);
    final random = Random();
    final options = <String>[];
    options.addAll(correctWords..shuffle(random));
    options.addAll(incorrectWords.sublist(0, min(2, incorrectWords.length))..shuffle(random));
    return options..shuffle(random);
  }

  @override
@override
Widget build(BuildContext context) {
  final currentTemplate = templates[currentTemplateIndex];

  return Theme(
    data: ThemeData(
      primaryColor: Colors.pink.shade400,
      textTheme: GoogleFonts.poppinsTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink.shade300,
          textStyle: const TextStyle(fontSize: 18, color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Story Builder'),
        backgroundColor: Colors.pink.shade300,
        actions: [
          IconButton(
            icon: Icon(_isTtsEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: _toggleTts,
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
                colors: [Colors.pink.shade200, Colors.blue.shade300],
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
                  Text(
                    'Score: $score',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ).animate().slideY(begin: -0.2, end: 0.0, duration: const Duration(milliseconds: 500)),

                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade700),
                    minHeight: 10,
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          (currentTemplate['template'] as String).replaceAllMapped(
                            RegExp(r'\[(\w+)\]'),
                            (match) => selectedWords[match.group(1)] ?? '[${match.group(1)}]',
                          ),
                          style: TextStyle(
                            fontSize: 22,
                            color: _isSentenceCorrect == null
                                ? Colors.pink.shade900
                                : _isSentenceCorrect!
                                    ? Colors.green.shade900
                                    : Colors.red.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (_isSentenceCorrect != null)
                        Icon(
                          _isSentenceCorrect! ? Icons.check_circle : Icons.error,
                          color: _isSentenceCorrect! ? Colors.green : Colors.red,
                          size: 24,
                        ),
                    ],
                  ).animate().fadeIn(duration: const Duration(milliseconds: 500)),

                  const SizedBox(height: 30),

                  // Boucle sur les champs du template
                  ...currentTemplate.keys
                      .where((k) => k != 'template' && k != 'validation_rules')
                      .map((key) {
                    return Column(
                      children: [
                        Text(
                          'Choose $key:',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 20,
                          runSpacing: 12,
                          children: _getWordOptions(key).map((word) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedWords[key] == word
                                    ? Colors.green.shade400
                                    : Colors.pink.shade300,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _selectWord(key, word),
                              child: Text(
                                word,
                                style: const TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ).animate().scale(duration: const Duration(milliseconds: 200));
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }).toList(),

                  // Bouton si toutes les options sont remplies
                  if (selectedWords.length ==
                      currentTemplate.keys.where((k) => k != 'template' && k != 'validation_rules').length)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _resetStory,
                      child: const Text(
                        'New Story',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ).animate().shake(duration: const Duration(milliseconds: 300)),

                  const SizedBox(height: 20),
                ],
              ),
            ),
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