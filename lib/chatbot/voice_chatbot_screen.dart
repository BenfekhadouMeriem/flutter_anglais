import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import '../widgets/text_styles.dart';
import 'dart:developer' as developer;

enum Level { basic, dailyLife, conversation, verbs, vocabulary, phrases }

extension LevelExtension on Level {
  String get title => switch (this) {
        Level.basic => 'Basic Questions',
        Level.dailyLife => 'Daily Life',
        Level.conversation => 'Conversation & Opinion',
        Level.verbs => 'Basic Verbs',
        Level.vocabulary => 'Vocabulary Quiz',
        Level.phrases => 'Useful Phrases',
      };
}

class VoiceChatbotScreen extends StatefulWidget {
  const VoiceChatbotScreen({Key? key}) : super(key: key);

  @override
  _VoiceChatbotScreenState createState() => _VoiceChatbotScreenState();
}

class _VoiceChatbotScreenState extends State<VoiceChatbotScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool _ttsInitialized = false;
  String _recognizedText = '';
  String _botMessage = 'Select a level to start practicing!';
  List<Map<String, String>> _conversation = [];
  int _currentQuestionIndex = 0;
  Color _feedbackColor = Colors.black54;
  Level _selectedLevel = Level.basic;

  // Response statistics
  final Map<Level, Map<String, int>> _stats = {
    Level.basic: {'correct': 0, 'incorrect': 0},
    Level.dailyLife: {'correct': 0, 'incorrect': 0},
    Level.conversation: {'correct': 0, 'incorrect': 0},
    Level.verbs: {'correct': 0, 'incorrect': 0},
    Level.vocabulary: {'correct': 0, 'incorrect': 0},
    Level.phrases: {'correct': 0, 'incorrect': 0},
  };

  // Questions organized by level/theme
  final Map<Level, List<Map<String, String>>> _questions = {
    Level.basic: [
      {'question': 'What is your name?', 'expected': 'my name is'},
      {'question': 'How old are you?', 'expected': 'i am'},
      {'question': 'Where are you from?', 'expected': 'i am from'},
      {'question': 'Do you speak English?', 'expected': 'yes'},
      {'question': 'How are you today?', 'expected': 'i am'},
      {'question': 'What do you do?', 'expected': 'i am'},
      {'question': 'What is your favorite color?', 'expected': 'my favorite color is'},
      {'question': 'What is this? It’s a pen.', 'expected': 'pen'},
      {'question': 'Can you count from 1 to 10?', 'expected': 'one two three'},
      {'question': 'Do you like music?', 'expected': 'yes'},
    ],
    Level.dailyLife: [
      {'question': 'What time do you wake up?', 'expected': 'i wake up'},
      {'question': 'What do you eat for breakfast?', 'expected': 'i eat'},
      {'question': 'What is your favorite food?', 'expected': 'my favorite food is'},
      {'question': 'Do you like coffee or tea?', 'expected': 'coffee'},
      {'question': 'What do you do on weekends?', 'expected': 'on weekends'},
      {'question': 'Can you describe your daily routine?', 'expected': 'my daily routine'},
      {'question': 'What day is it today?', 'expected': 'today is'},
      {'question': 'What is the weather like today?', 'expected': 'the weather is'},
      {'question': 'Do you go to school or work?', 'expected': 'i go to'},
      {'question': 'What do you wear in winter?', 'expected': 'in winter'},
    ],
    Level.conversation: [
      {'question': 'What do you like to do in your free time?', 'expected': 'in my free time'},
      {'question': 'Have you ever traveled abroad?', 'expected': 'yes'},
      {'question': 'What is your dream job?', 'expected': 'my dream job'},
      {'question': 'What do you think about learning English?', 'expected': 'learning english'},
      {'question': 'What are your strengths and weaknesses?', 'expected': 'my strengths'},
      {'question': 'What is your biggest goal in life?', 'expected': 'my biggest goal'},
      {'question': 'Do you prefer reading books or watching movies?', 'expected': 'i prefer'},
      {'question': 'Tell me about your family.', 'expected': 'my family'},
      {'question': 'What makes you happy?', 'expected': 'makes me happy'},
      {'question': 'Do you think technology is helpful or harmful?', 'expected': 'technology is'},
    ],
    Level.verbs: [
      {'question': 'Can you make a sentence with “to go”?', 'expected': 'i go'},
      {'question': 'What is the past tense of “eat”?', 'expected': 'ate'},
      {'question': 'Complete the sentence: “I ___ to school every day.”', 'expected': 'go'},
    ],
    Level.vocabulary: [
      {'question': 'What is this? It’s an apple.', 'expected': 'apple'},
      {'question': 'Which word means “grand” in English?', 'expected': 'big'},
      {'question': 'Match the word: It’s a dog.', 'expected': 'dog'},
    ],
    Level.phrases: [
      {'question': 'How do you say “merci” in English?', 'expected': 'thank you'},
      {'question': 'What do you say when you meet someone?', 'expected': 'hello'},
      {'question': 'What do you say when someone says “Thank you”?', 'expected': 'you’re welcome'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  void _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          developer.log('Speech status: $status');
          if (status == 'notListening') {
            setState(() => _isListening = false);
            if (_recognizedText.isNotEmpty) {
              _processResponse(_recognizedText);
            }
          }
        },
        onError: (error) {
          developer.log('Speech error: $error');
          setState(() {
            _botMessage = 'Speech recognition error: Check microphone permissions.';
            _conversation.add({'bot': _botMessage});
            _feedbackColor = Colors.red;
          });
          _speak(_botMessage);
        },
      );
      if (!available) {
        setState(() {
          _botMessage = 'Speech recognition not available on this device.';
          _conversation.add({'bot': _botMessage});
        });
        _speak(_botMessage);
      } else {
        // Log available locales for debugging
        List<dynamic> locales = await _speech.locales();
        developer.log('Available locales: ${locales.map((l) => l.localeId).toList()}');
      }
    } catch (e) {
      developer.log('Speech initialization error: $e');
      setState(() {
        _botMessage = 'Failed to initialize speech recognition: $e';
        _conversation.add({'bot': _botMessage});
      });
      _speak(_botMessage);
    }
  }

  void _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.4);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      setState(() => _ttsInitialized = true);
      _speak(_botMessage);
    } catch (e) {
      developer.log('TTS initialization error: $e');
      setState(() {
        _ttsInitialized = false;
        _botMessage = 'Text-to-speech unavailable: Please check device settings.';
        _conversation.add({'bot': _botMessage});
      });
    }
  }

  void _speak(String text) async {
    if (_ttsInitialized) {
      try {
        await _tts.speak(text);
      } catch (e) {
        developer.log('TTS speak error: $e');
        setState(() {
          _botMessage = 'Error speaking: $e';
          _conversation.add({'bot': _botMessage});
        });
      }
    }
  }

  void _askNextQuestion() async {
    if (_currentQuestionIndex < _questions[_selectedLevel]!.length) {
      String question = _questions[_selectedLevel]![_currentQuestionIndex]['question']!;
      setState(() {
        _botMessage = question;
        _conversation.add({'bot': question});
        _feedbackColor = Colors.black54;
      });
      _speak(question);
    } else {
      double probability = _calculateProbability();
      String completionMessage = 'Great job! Your correct response rate for ${_selectedLevel.title} is ${probability.toStringAsFixed(1)}%. Select a new level to continue.';
      setState(() {
        _botMessage = completionMessage;
        _conversation.add({'bot': completionMessage});
        _feedbackColor = Colors.green;
      });
      _speak(completionMessage);
      _currentQuestionIndex = 0;
    }
  }

  void _listen() async {
    if (!_isListening) {
      setState(() {
        _isListening = true;
        _recognizedText = '';
        _feedbackColor = Colors.black54;
      });
      try {
        await _speech.listen(
          onResult: (result) {
            setState(() {
              _recognizedText = result.recognizedWords;
              _feedbackColor = result.finalResult ? Colors.blue : Colors.black54;
            });
            developer.log('Recognized: ${result.recognizedWords}, Final: ${result.finalResult}');
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
          localeId: 'en-US', // Explicitly set to English
        );
      } catch (e) {
        developer.log('Speech listen error: $e');
        setState(() {
          _isListening = false;
          _botMessage = 'Error during speech recognition: $e';
          _conversation.add({'bot': _botMessage});
          _feedbackColor = Colors.red;
        });
        _speak(_botMessage);
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_recognizedText.isNotEmpty) {
        _processResponse(_recognizedText);
      }
    }
  }

  void _processResponse(String response) {
    if (_currentQuestionIndex >= _questions[_selectedLevel]!.length) return;

    String expected = _questions[_selectedLevel]![_currentQuestionIndex]['expected']!.toLowerCase();
    response = response.toLowerCase().trim();

    setState(() {
      _conversation.add({'user': response});
    });

    String feedback;
    if (response.contains(expected)) {
      feedback = 'Excellent! You pronounced it correctly!';
      _feedbackColor = Colors.green;
      _stats[_selectedLevel]!['correct'] = _stats[_selectedLevel]!['correct']! + 1;
      _currentQuestionIndex++;
    } else {
      feedback = 'You mean to say "$expected".';
      _feedbackColor = Colors.red;
      _stats[_selectedLevel]!['incorrect'] = _stats[_selectedLevel]!['incorrect']! + 1;
    }

    setState(() {
      _botMessage = feedback;
      _conversation.add({'bot': feedback});
    });

    _speak(feedback);
    Future.delayed(const Duration(seconds: 2), _askNextQuestion);
  }

  double _calculateProbability() {
    int correct = _stats[_selectedLevel]!['correct']!;
    int incorrect = _stats[_selectedLevel]!['incorrect']!;
    int total = correct + incorrect;
    return total > 0 ? (correct / total) * 100 : 0.0;
  }

  void _showStats() {
    double probability = _calculateProbability();
    String message = 'Your correct response rate for ${_selectedLevel.title} is ${probability.toStringAsFixed(1)}%.\nCorrect: ${_stats[_selectedLevel]!['correct']}\nIncorrect: ${_stats[_selectedLevel]!['incorrect']}';
    setState(() {
      _botMessage = message;
      _conversation.add({'bot': message});
    });
    _speak(message);
  }

  void _selectLevel(Level level) {
    setState(() {
      _selectedLevel = level;
      _currentQuestionIndex = 0;
      _conversation.clear();
      _stats[_selectedLevel]!['correct'] = 0;
      _stats[_selectedLevel]!['incorrect'] = 0;
      _botMessage = 'Starting ${_selectedLevel.title}!';
      _feedbackColor = Colors.black54;
    });
    _speak(_botMessage);
    _askNextQuestion();
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'English Pronunciation Practice',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD81B60)),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Level selection menu
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButton<Level>(
                value: _selectedLevel,
                isExpanded: true,
                items: Level.values.map((level) {
                  return DropdownMenuItem<Level>(
                    value: level,
                    child: Text(
                      level.title,
                      style: AppTextStyles.buttonText.copyWith(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (Level? newLevel) {
                  if (newLevel != null) {
                    _selectLevel(newLevel);
                  }
                },
              ),
            ),
            // Stats button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: _showStats,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Show Stats',
                  style: AppTextStyles.buttonText.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _conversation.length,
                itemBuilder: (context, index) {
                  bool isBot = _conversation[index].containsKey('bot');
                  return Align(
                    alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5.0),
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: isBot ? Colors.pink.shade100 : Colors.pink.shade300,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isBot
                            ? _conversation[index]['bot']!
                            : _conversation[index]['user']!,
                        style: AppTextStyles.buttonText.copyWith(
                          color: isBot ? Colors.black87 : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _recognizedText.isEmpty ? 'Say the answer...' : _recognizedText,
                style: AppTextStyles.buttonText.copyWith(
                  color: _feedbackColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: GestureDetector(
                onTap: _listen,
                child: Lottie.asset(
                  'assets/lottie/ai_play.json',
                  height: 100,
                  width: 100,
                  animate: _isListening,
                  onLoaded: (composition) {
                    if (composition == null) {
                      setState(() {
                        _botMessage = 'Error loading animation. Check assets in pubspec.yaml.';
                        _conversation.add({'bot': _botMessage});
                      });
                      _speak(_botMessage);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}