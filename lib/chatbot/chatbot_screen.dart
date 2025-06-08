import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isQuizMode = false;
  bool _useFrenchFeedback = false;
  bool _isDarkMode = false;
  int _quizCorrectAnswers = 0;
  int _quizTotalQuestions = 0;
  List<double> _quizScores = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  List<String> _suggestions = [];

  // Expanded vocabulary data
  static const List<Map<String, String>> _vocabulary = [
    {
      'word': 'happy',
      'definition': 'feeling or showing pleasure',
      'example': 'She is happy to learn English.'
    },
    {
      'word': 'run',
      'definition': 'to move quickly on foot',
      'example': 'They run every morning.'
    },
    {
      'word': 'beautiful',
      'definition': 'pleasing to the senses',
      'example': 'The sunset is beautiful.'
    },
    {
      'word': 'eat',
      'definition': 'to consume food',
      'example': 'I eat breakfast at 7 AM.'
    },
    {
      'word': 'big',
      'definition': 'large in size',
      'example': 'The elephant is big.'
    },
    {
      'word': 'small',
      'definition': 'little in size',
      'example': 'The mouse is small.'
    },
    {
      'word': 'friend',
      'definition': 'a person you like and trust',
      'example': 'My friend helps me study.'
    },
    {
      'word': 'go',
      'definition': 'to move or travel',
      'example': 'We go to school by bus.'
    },
    {
      'word': 'look',
      'definition': 'to direct your eyes',
      'example': 'Look at the stars tonight.'
    },
    {
      'word': 'learn',
      'definition': 'to gain knowledge or skill',
      'example': 'I learn English every day.'
    },
  ];

  // Sample dialogue data for practice
  static const List<Map<String, dynamic>> _dialogues = [
    {
      'context': 'At the restaurant',
      'steps': [
        {'speaker': 'user', 'text': 'Hello, can I see the menu?'},
        {
          'speaker': 'bot',
          'text': 'Of course! Here is the menu. What would you like to order?'
        },
        {'speaker': 'user', 'text': 'I’d like a pizza and a soda, please.'},
        {'speaker': 'bot', 'text': 'Great choice! Anything else?'},
        {'speaker': 'user', 'text': 'No, that’s all. Thank you!'},
        {
          'speaker': 'bot',
          'text': 'Your order is placed. It’ll be ready in 15 minutes.'
        },
      ],
      'tips': 'Use "I’d like" for polite requests. "That’s all" ends the order.'
    },
    {
      'context': 'At the airport',
      'steps': [
        {
          'speaker': 'user',
          'text': 'Good morning, where is the check-in counter?'
        },
        {
          'speaker': 'bot',
          'text': 'Good morning! It’s to the left, near gate 3.'
        },
        {
          'speaker': 'user',
          'text': 'Thank you! What time does my flight board?'
        },
        {
          'speaker': 'bot',
          'text': 'What’s your flight number? I can check for you.'
        },
        {'speaker': 'user', 'text': 'It’s flight AB123 to London.'},
        {
          'speaker': 'bot',
          'text': 'Flight AB123 boards at 10:30 AM. Safe travels!'
        },
      ],
      'tips':
          'Use "Good morning" to greet. Ask clear questions like "What time...?"'
    },
    {
      'context': 'Shopping',
      'steps': [
        {'speaker': 'user', 'text': 'Hi, how much is this shirt?'},
        {'speaker': 'bot', 'text': 'Hello! The shirt costs 20 dollars.'},
        {'speaker': 'user', 'text': 'Can you make it cheaper?'},
        {
          'speaker': 'bot',
          'text': 'I can offer a 10% discount. So, 18 dollars. Okay?'
        },
        {'speaker': 'user', 'text': 'Yes, I’ll take it. Thanks!'},
        {'speaker': 'bot', 'text': 'You’re welcome! Here’s your shirt.'},
      ],
      'tips':
          'Use "how much" for prices. "I’ll take it" means you agree to buy.'
    },
  ];

  // Expanded question bank for quizzes
  static const List<Map<String, dynamic>> _quizQuestions = [
    {
      'type': 'definition',
      'question': 'What does "happy" mean?',
      'answer': 'feeling or showing pleasure',
      'options': [
        'feeling or showing pleasure',
        'to move quickly',
        'large in size'
      ],
    },
    {
      'type': 'definition',
      'question': 'What does "run" mean?',
      'answer': 'to move quickly on foot',
      'options': [
        'to consume food',
        'to move quickly on foot',
        'pleasing to the senses'
      ],
    },
    {
      'type': 'sentence',
      'question': 'Fill in: I ___ to school every day.',
      'answer': 'go',
      'options': ['go', 'goes', 'going'],
    },
    {
      'type': 'sentence',
      'question': 'Fill in: She ___ a beautiful dress.',
      'answer': 'wears',
      'options': ['wear', 'wears', 'wearing'],
    },
    {
      'type': 'translation',
      'question': 'Translate: Je mange une pomme.',
      'answer': 'I eat an apple.',
      'options': ['I eat an apple.', 'I run fast.', 'I see a bird.'],
    },
    {
      'type': 'past',
      'question': 'What is the past tense of "go"?',
      'answer': 'went',
      'options': ['go', 'went', 'gone'],
    },
    {
      'type': 'opposite',
      'question': 'What is the opposite of "big"?',
      'answer': 'small',
      'options': ['tall', 'small', 'fast'],
    },
    {
      'type': 'definition',
      'question': 'What does "friend" mean?',
      'answer': 'a person you like and trust',
      'options': [
        'a type of food',
        'a person you like and trust',
        'a place to live'
      ],
    },
    {
      'type': 'sentence',
      'question': 'Fill in: We ___ English every day.',
      'answer': 'learn',
      'options': ['learn', 'learns', 'learning'],
    },
    {
      'type': 'translation',
      'question': 'Translate: Comment vas-tu?',
      'answer': 'How are you?',
      'options': ['What time is it?', 'How are you?', 'Where are you?'],
    },
  ];

  // Suggested questions for quick access
  /*static const List<String> _suggestedQuestions = [
    'Hello',
    'What time is it?',
    'Thank you',
    'Help',
    'What\'s your name?',
    'Start quiz',
    'Start dialogue',
    'How do I say "bonjour"?',
    'What is the past of "eat"?',
    'Correct this: i go to park.',
  ];*/

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _speech = stt.SpeechToText();
    // Load preferences and then add initial message
    _loadPreferences().then((_) {
      _addInitialMessage();
      setState(() {});
    });
    _animationController.forward();
    _messageController.addListener(_updateSuggestions);
  }

  // Add initial bot message only if messages list is empty
  void _addInitialMessage() {
    const welcomeMessage =
        'Welcome to your English learning assistant! Ask a question, try a sentence, type "quiz" or "dialogue", do math (e.g., 2 + 3), or use voice input!';
    // Check if the welcome message already exists
    bool hasWelcomeMessage =
        _messages.any((msg) => msg['text'] == welcomeMessage);
    if (_messages.isEmpty || !hasWelcomeMessage) {
      _messages.add({
        'text': welcomeMessage,
        'sender': 'bot',
        'timestamp': DateTime.now(),
      });
      setState(() {});
    }
  }

  // Load saved preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = prefs.getBool('darkMode') ?? false;
        _useFrenchFeedback = prefs.getBool('frenchFeedback') ?? false;
        _quizCorrectAnswers = prefs.getInt('quizCorrect') ?? 0;
        _quizTotalQuestions = prefs.getInt('quizTotal') ?? 0;
        _quizScores = (prefs.getStringList('quizScores') ?? [])
            .map((s) => double.tryParse(s) ?? 0.0)
            .toList();
        _messages.addAll((prefs.getStringList('messages') ?? []).map((m) {
          final parts = m.split('|');
          return {
            'text': parts[0],
            'sender': parts[1],
            'timestamp': DateTime.parse(parts[2]),
            'feedback': parts.length > 3 ? parts[3] : null,
            'dialogueStep': parts.length > 4 ? int.tryParse(parts[4]) : null,
            'dialogueContext': parts.length > 5 ? parts[5] : null,
          };
        }).toList());
      });
    } catch (e) {
      _showSnackBar('Failed to load preferences');
    }
  }

  // Save preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', _isDarkMode);
      await prefs.setBool('frenchFeedback', _useFrenchFeedback);
      await prefs.setInt('quizCorrect', _quizCorrectAnswers);
      await prefs.setInt('quizTotal', _quizTotalQuestions);
      await prefs.setStringList(
          'quizScores', _quizScores.map((s) => s.toString()).toList());
      await prefs.setStringList(
        'messages',
        _messages
            .map((m) =>
                '${m['text']}|${m['sender']}|${m['timestamp'].toIso8601String()}|${m['feedback'] ?? ''}|${m['dialogueStep'] ?? ''}|${m['dialogueContext'] ?? ''}')
            .toList(),
      );
    } catch (e) {
      _showSnackBar('Failed to save preferences');
    }
  }

  // Clear chat history
  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear the chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _messages.clear();
        _quizCorrectAnswers = 0;
        _quizTotalQuestions = 0;
        _quizScores.clear();
        _isQuizMode = false;
        _addInitialMessage();
      });
      await _savePreferences();
      _showSnackBar('Chat history cleared');
    }
  }

  // Process user input
  Future<Map<String, String>> _processUserInput(String input) async {
    input = input.trim();
    final lowerInput = input.toLowerCase();

    if (lowerInput.isEmpty) {
      return {
        'response': 'Please enter a valid message.',
        'feedback': _useFrenchFeedback
            ? 'Veuillez entrer un message valide.'
            : 'Please enter a valid message.'
      };
    }

    if (lowerInput == 'quiz' || lowerInput == 'start quiz') {
      setState(() => _isQuizMode = true);
      return _generateQuizQuestion();
    } else if (lowerInput == 'dialogue' || lowerInput == 'start dialogue') {
      return _startDialogue();
    } else if (lowerInput == 'clear chat') {
      await _clearChat();
      return {
        'response': 'Chat history cleared.',
        'feedback': _useFrenchFeedback ? 'Historique effacé.' : 'Chat cleared.'
      };
    } else if (_isQuizMode) {
      return _checkQuizAnswer(input);
    } else if (lowerInput == 'toggle language') {
      setState(() => _useFrenchFeedback = !_useFrenchFeedback);
      await _savePreferences();
      return {
        'response':
            'Feedback language switched to ${_useFrenchFeedback ? 'French' : 'English'}.',
        'feedback': _useFrenchFeedback
            ? 'Langue changée en français.'
            : 'Language switched to English.'
      };
    } else if (lowerInput == 'toggle theme') {
      setState(() => _isDarkMode = !_isDarkMode);
      await _savePreferences();
      return {
        'response': 'Theme switched to ${_isDarkMode ? 'dark' : 'light'} mode.',
        'feedback': _useFrenchFeedback
            ? 'Thème changé en mode ${_isDarkMode ? 'sombre' : 'clair'}.'
            : 'Theme updated!'
      };
    } else if (RegExp(r'^\d+\s*[\+\-\*/]\s*\d+').hasMatch(lowerInput)) {
      return _handleMathCalculation(lowerInput);
    } else if (lowerInput.startsWith('hi') || lowerInput.startsWith('hello')) {
      return {
        'response': 'Hello! Try writing an English sentence or ask a question.',
        'feedback': _useFrenchFeedback
            ? 'Bonjour ! Essayez d’écrire une phrase en anglais.'
            : 'Great start! "Hi" and "hello" are common greetings.'
      };
    } else if (lowerInput.contains('how are you')) {
      return {
        'response': 'I’m a bot, but I’m doing great! How about you?',
        'feedback': _useFrenchFeedback
            ? 'Je suis un bot, mais je vais bien !'
            : 'Thanks for asking!'
      };
    } else if (lowerInput.contains('thank')) {
      return {
        'response': 'You’re welcome!',
        'feedback': _useFrenchFeedback ? 'De rien !' : 'Happy to help!'
      };
    } else if (lowerInput.contains('what time') ||
        lowerInput.contains('current time')) {
      final now = DateTime.now();
      return {
        'response':
            'It’s currently ${now.hour}:${now.minute.toString().padLeft(2, '0')}.',
        'feedback': _useFrenchFeedback
            ? 'Il est actuellement ${now.hour}h${now.minute.toString().padLeft(2, '0')}.'
            : 'Time checked!'
      };
    } else if (lowerInput.contains('bye') || lowerInput.contains('goodbye')) {
      return {
        'response': 'Goodbye! Have a great day!',
        'feedback':
            _useFrenchFeedback ? 'Au revoir ! Bonne journée !' : 'See you soon!'
      };
    } else if (lowerInput.contains('name')) {
      return {
        'response': 'I’m your English learning assistant chatbot.',
        'feedback': _useFrenchFeedback
            ? 'Je suis votre assistant d’apprentissage de l’anglais.'
            : 'Nice to meet you!'
      };
    } else if (input.endsWith('?')) {
      final apiResponse = await _callGrokAPI(input);
      return {
        'response': apiResponse,
        'feedback': _useFrenchFeedback
            ? 'Bonne question ! Continuez à explorer.'
            : 'Good question! Keep exploring.'
      };
    } else {
      return _analyzeSentence(input);
    }
  }

  // Handle math calculations
  Map<String, String> _handleMathCalculation(String input) {
    try {
      final parts = input.split(RegExp(r'[\+\-\*/]'));
      final num1 = double.parse(parts[0].trim());
      final num2 = double.parse(parts[1].trim());
      final operator = input.contains('+')
          ? '+'
          : input.contains('-')
              ? '-'
              : input.contains('*')
                  ? '*'
                  : '/';
      String result;
      switch (operator) {
        case '+':
          result = (num1 + num2).toStringAsFixed(2);
          break;
        case '-':
          result = (num1 - num2).toStringAsFixed(2);
          break;
        case '*':
          result = (num1 * num2).toStringAsFixed(2);
          break;
        case '/':
          result = num2 != 0
              ? (num1 / num2).toStringAsFixed(2)
              : 'Error: Division by zero';
          break;
        default:
          result = 'Invalid calculation';
      }
      return {
        'response': 'Result: $result',
        'feedback': _useFrenchFeedback ? 'Calcul réussi !' : 'Calculation done!'
      };
    } catch (e) {
      return {
        'response': 'Error: Invalid calculation format',
        'feedback': _useFrenchFeedback
            ? 'Erreur : Format de calcul invalide.'
            : 'Please use format like "2 + 3".'
      };
    }
  }

  // Analyze user sentence
  Map<String, String> _analyzeSentence(String sentence) {
    String feedback = '';
    String corrected = sentence;

    // Check for capitalization of "I"
    if (sentence.split(' ').first.toLowerCase() == 'i' &&
        sentence.split(' ').first != 'I') {
      feedback += _useFrenchFeedback
          ? 'Mettez toujours "I" en majuscule pour vous référer à vous-même. '
          : 'Always capitalize "I" when referring to yourself. ';
      corrected = corrected.replaceFirst('i', 'I');
    }

    // Check for basic verb conjugation (e.g., third person singular)
    final words = sentence.split(' ');
    if (words.length > 2 && words[0].toLowerCase() == 'he' ||
        words[0].toLowerCase() == 'she' ||
        words[0].toLowerCase() == 'it') {
      if (!words[1].endsWith('s') &&
          _vocabulary.any((v) => v['word'] == words[1])) {
        feedback += _useFrenchFeedback
            ? 'Ajoutez "s" au verbe après "he", "she", ou "it" (ex. : "he runs").'
            : 'Add "s" to the verb after "he", "she", or "it" (e.g., "he runs").';
        corrected = '${words[0]} ${words[1]}s ${words.sublist(2).join(' ')}';
      }
    }

    // Add vocabulary suggestion if no correction needed
    if (feedback.isEmpty) {
      final relatedWord = _vocabulary[Random().nextInt(_vocabulary.length)];
      feedback = _useFrenchFeedback
          ? 'Essayez ce mot : "${relatedWord['word']}" (${relatedWord['definition']}). Exemple : ${relatedWord['example']}'
          : 'Try using this word: "${relatedWord['word']}" (${relatedWord['definition']}). Example: ${relatedWord['example']}';
    }

    return {
      'response':
          corrected == sentence ? 'Nice sentence!' : 'Corrected: $corrected',
      'feedback': feedback.isEmpty
          ? (_useFrenchFeedback
              ? 'Bien joué ! Votre phrase est claire.'
              : 'Well done! Your sentence is clear.')
          : feedback,
    };
  }

  // Generate quiz question
  Map<String, String> _generateQuizQuestion() {
    final randomQuestion =
        _quizQuestions[Random().nextInt(_quizQuestions.length)];
    setState(() => _quizTotalQuestions++);
    String questionText = randomQuestion['question'];
    if (randomQuestion['options'] != null) {
      questionText += '\nOptions: ${randomQuestion['options'].join(', ')}';
    }
    return {
      'response': 'Quiz: $questionText',
      'feedback':
          'quiz:${randomQuestion['type']}:${randomQuestion['question']}:${randomQuestion['answer']}',
    };
  }

  // Check quiz answer
  Map<String, String> _checkQuizAnswer(String input) {
    final lastMessage = _messages.lastWhere((msg) => msg['sender'] == 'bot');
    if (lastMessage['feedback'].startsWith('quiz:')) {
      final parts = lastMessage['feedback'].split(':');
      final type = parts[1];
      final question = parts[2];
      final correctAnswer = parts[3];
      bool isCorrect = false;

      if (type == 'definition' ||
          type == 'translation' ||
          type == 'past' ||
          type == 'opposite') {
        isCorrect = input.toLowerCase().contains(correctAnswer.toLowerCase());
      } else if (type == 'sentence') {
        isCorrect = input.toLowerCase().trim() == correctAnswer.toLowerCase();
      }

      if (isCorrect) {
        setState(() {
          _isQuizMode = false;
          _quizCorrectAnswers++;
          _quizScores.add(_quizCorrectAnswers / _quizTotalQuestions * 100);
          _savePreferences();
        });
        return {
          'response':
              'Correct! Answer: "$correctAnswer". Your score: $_quizCorrectAnswers/$_quizTotalQuestions. Type "quiz" for another!',
          'feedback': _useFrenchFeedback ? 'Bien joué !' : 'Great job!'
        };
      } else {
        setState(() {
          _quizScores.add(_quizCorrectAnswers / _quizTotalQuestions * 100);
          _savePreferences();
        });
        return {
          'response':
              'Not quite! The answer to "$question" is "$correctAnswer". Try another: ${_generateQuizQuestion()['response']}',
          'feedback': 'quiz:$type:$question:$correctAnswer'
        };
      }
    }
    return {
      'response': 'Please answer the quiz question.',
      'feedback': _useFrenchFeedback
          ? 'Veuillez répondre à la question du quiz.'
          : 'Please answer the quiz question.'
    };
  }

  // Start dialogue practice
  Map<String, String> _startDialogue() {
    final randomDialogue = _dialogues[Random().nextInt(_dialogues.length)];
    setState(() {
      _isQuizMode = true; // Reuse quiz mode to track dialogue state
    });
    return {
      'response':
          'Dialogue: ${randomDialogue['context']}\n${randomDialogue['steps'][0]['text']}',
      'feedback': 'dialogue:0:${randomDialogue['context']}',
      'dialogueStep': '0',
      'dialogueContext': randomDialogue['context'],
    };
  }

  // Check dialogue response
  Map<String, String> _checkDialogueResponse(String input) {
    final lastMessage = _messages.lastWhere((msg) => msg['sender'] == 'bot');
    if (lastMessage['feedback'].startsWith('dialogue:')) {
      final parts = lastMessage['feedback'].split(':');
      final step = int.parse(parts[1]);
      final context = parts[2];
      final dialogue = _dialogues.firstWhere((d) => d['context'] == context);
      final currentStep = dialogue['steps'][step];
      final nextStepIndex = step + 1;

      if (nextStepIndex >= dialogue['steps'].length) {
        setState(() {
          _isQuizMode = false;
        });
        return {
          'response':
              'Great job! Dialogue complete: ${dialogue['context']}\nTips: ${dialogue['tips']}\nType "dialogue" to start another!',
          'feedback':
              _useFrenchFeedback ? 'Dialogue terminé !' : 'Dialogue completed!'
        };
      }

      final nextStep = dialogue['steps'][nextStepIndex];
      if (currentStep['speaker'] == 'user') {
        // Check user response (basic similarity check)
        final expected = currentStep['text'].toLowerCase();
        final userInput = input.toLowerCase().trim();
        bool isClose = userInput.contains(expected.split(' ')[0]) ||
            userInput.contains(expected.split(' ').last);
        if (isClose) {
          return {
            'response': nextStep['text'],
            'feedback': 'dialogue:$nextStepIndex:$context',
            'dialogueStep': nextStepIndex.toString(),
            'dialogueContext': context,
          };
        } else {
          return {
            'response':
                'Try again! Expected: "${currentStep['text']}"\nYour turn: ${currentStep['text']}',
            'feedback': 'dialogue:$step:$context',
            'dialogueStep': step.toString(),
            'dialogueContext': context,
          };
        }
      } else {
        return {
          'response': nextStep['text'],
          'feedback': 'dialogue:$nextStepIndex:$context',
          'dialogueStep': nextStepIndex.toString(),
          'dialogueContext': context,
        };
      }
    }
    return {
      'response': 'Please respond to the dialogue.',
      'feedback': _useFrenchFeedback
          ? 'Veuillez répondre au dialogue.'
          : 'Please respond to the dialogue.'
    };
  }

  // Call xAI Grok API
  Future<String> _callGrokAPI(String query) async {
    try {
      const apiUrl = 'https://api.x.ai/grok';
      const apiKey = 'YOUR_API_KEY'; // Replace with secure API key management
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'query': 'Provide a simple English explanation for: $query',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ??
            'I couldn’t find an answer. Try a different question!';
      } else {
        return 'Error: Failed to fetch response. Try again!';
      }
    } catch (e) {
      return 'Error: Network issue. Please check your connection.';
    }
  }

  // Start voice input
  Future<void> _startListening() async {
    if (_isListening) return;
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _messageController.text = result.recognizedWords;
            if (result.finalResult) {
              _isListening = false;
              _sendMessage();
            }
          });
        },
        onSoundLevelChange: (level) {
          // Optionally handle sound level feedback
        },
      );
      _showSnackBar('Listening...');
    } else {
      setState(() => _isListening = false);
      _showSnackBar('Speech recognition not available');
    }
  }

  // Update autocomplete suggestions
  void _updateSuggestions() {
    final input = _messageController.text.toLowerCase();
    setState(() {
      _suggestions = _vocabulary
          .where((word) => word['word']!.toLowerCase().startsWith(input))
          .map((word) => word['word']!)
          .toList();
      //if (input.isEmpty) _suggestions = _suggestedQuestions;
    });
  }

  // Send message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      _showSnackBar('Please enter a message');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _messages.add({
        'text': _messageController.text,
        'sender': 'user',
        'timestamp': DateTime.now(),
      });
      _isTyping = true;
    });

    final userMessage = _messageController.text;
    _messageController.clear();
    _suggestions.clear();

    final result = await _processUserInput(userMessage);
    setState(() {
      _messages.add({
        'text': result['response']!,
        'sender': 'bot',
        'timestamp': DateTime.now(),
        'feedback': result['feedback'],
        'dialogueStep': result['dialogueStep'],
        'dialogueContext': result['dialogueContext'],
      });
      _isTyping = false;
      _animationController.forward(from: 0);
    });
    await _savePreferences();
    _scrollToBottom();
  }

  // Scroll to bottom of chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Show word definition dialog
  void _showWordDefinition(String word) {
    final vocab = _vocabulary.firstWhere(
      (v) => v['word']!.toLowerCase() == word.toLowerCase(),
      orElse: () => {
        'word': word,
        'definition': 'Not found',
        'example': 'No example available'
      },
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vocab['word']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Definition: ${vocab['definition']}'),
            const SizedBox(height: 8),
            Text('Example: ${vocab['example']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Show snackbar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'English Learning Chatbot',
            style: TextStyle(fontWeight: FontWeight.bold),
            semanticsLabel: 'English Learning Chatbot',
          ),
          centerTitle: true,
          elevation: 0,
          leading: Semantics(
            label: 'Go back',
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            ),
          ),
          actions: [
            Semantics(
              label: 'Start Quiz',
              child: IconButton(
                icon: const Icon(Icons.quiz, color: Colors.pink),
                onPressed: () {
                  _messageController.text = 'quiz';
                  _sendMessage();
                },
                tooltip: 'Start Quiz',
              ),
            ),
            Semantics(
              label: 'Start Dialogue',
              child: IconButton(
                icon: const Icon(Icons.chat, color: Colors.green),
                onPressed: () {
                  _messageController.text = 'dialogue';
                  _sendMessage();
                },
                tooltip: 'Start Dialogue',
              ),
            ),
            Semantics(
              label: 'Toggle Feedback Language',
              child: IconButton(
                icon: Icon(Icons.language,
                    color: _useFrenchFeedback ? Colors.blue : null),
                onPressed: () {
                  _messageController.text = 'toggle language';
                  _sendMessage();
                },
                tooltip: 'Toggle Feedback Language',
              ),
            ),
            Semantics(
              label: 'Toggle Theme',
              child: IconButton(
                icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  _messageController.text = 'toggle theme';
                  _sendMessage();
                },
                tooltip: 'Toggle Theme',
              ),
            ),
            Semantics(
              label: 'Clear Chat History',
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _clearChat,
                tooltip: 'Clear Chat',
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Quiz progress
            if (_quizTotalQuestions > 0)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      'Quiz Score: $_quizCorrectAnswers/$_quizTotalQuestions (${(_quizCorrectAnswers / _quizTotalQuestions * 100).toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      semanticsLabel:
                          'Quiz Score: $_quizCorrectAnswers out of $_quizTotalQuestions',
                    ),
                    if (_quizScores.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                  _quizScores.length,
                                  (i) => FlSpot(i.toDouble(), _quizScores[i]),
                                ),
                                isCurved: true,
                                barWidth: 2,
                                color: Colors.blue,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                            titlesData: const FlTitlesData(show: false),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            minY: 0,
                            maxY: 100,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // Chat area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Typing...',
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final message = _messages[index];
                  final isUser = message['sender'] == 'user';
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isUser
                                ? [Colors.pink.shade300, Colors.pink.shade500]
                                : _isDarkMode
                                    ? [
                                        Colors.grey.shade700,
                                        Colors.grey.shade900
                                      ]
                                    : [
                                        Colors.grey.shade200,
                                        Colors.grey.shade300
                                      ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final words = message['text']!.split(' ');
                                for (var word in words) {
                                  if (_vocabulary.any((v) =>
                                      v['word']!.toLowerCase() ==
                                      word.toLowerCase())) {
                                    _showWordDefinition(word);
                                    break;
                                  }
                                }
                              },
                              child: Text(
                                message['text']!,
                                style: TextStyle(
                                  color: isUser
                                      ? Colors.black
                                      : _isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                  fontSize: 16,
                                ),
                                semanticsLabel: message['text'],
                              ),
                            ),
                            if (message['feedback'] != null &&
                                message['feedback'].isNotEmpty &&
                                !message['feedback'].startsWith('quiz:') &&
                                !message['feedback'].startsWith('dialogue:'))
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Tip: ${message['feedback']}',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  semanticsLabel: 'Tip: ${message['feedback']}',
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(message['timestamp']),
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.black54,
                                fontSize: 12,
                              ),
                              semanticsLabel:
                                  'Sent at ${_formatTimestamp(message['timestamp'])}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Autocomplete suggestions
            if (_suggestions.isNotEmpty)
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _suggestions.map((suggestion) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(suggestion),
                        onPressed: () {
                          _messageController.text = suggestion;
                          _suggestions.clear();
                          setState(() {});
                        },
                        backgroundColor: _isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade200,
                        labelStyle: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            // Suggested questions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              /*child: Wrap(
                spacing: 8,
                children: _suggestedQuestions.map((question) {
                  return ActionChip(
                    label: Text(question),
                    onPressed: () {
                      _messageController.text = question;
                      _sendMessage();
                    },
                    backgroundColor: _isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    tooltip: question,
                  );
                }).toList(),
              ),*/
            ),
            // Input box
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText:
                            'Type a sentence, "quiz", "dialogue", or math...',
                        hintStyle: TextStyle(
                          color: _isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: _isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        prefixIcon:
                            const Icon(Icons.message, color: Colors.pink),
                        errorText: _messageController.text.trim().isEmpty &&
                                _messages.isNotEmpty
                            ? 'Please enter a message'
                            : null,
                      ),
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: _isListening ? null : _startListening,
                    backgroundColor:
                        _isListening ? Colors.grey : Colors.pink.shade300,
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.black,
                    ),
                    tooltip: 'Voice Input',
                    heroTag: 'mic',
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: Colors.pink.shade300,
                    child: const Icon(Icons.send, color: Colors.black),
                    tooltip: 'Send Message',
                    heroTag: 'send',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.removeListener(_updateSuggestions);
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _speech.stop();
    super.dispose();
  }
}
