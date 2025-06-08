import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class ChatService {
  static const List<Map<String, String>> _vocabulary = [
    {'word': 'happy', 'definition': 'feeling or showing pleasure', 'example': 'She is happy to learn English.'},
    {'word': 'run', 'definition': 'to move quickly on foot', 'example': 'They run every morning.'},
    {'word': 'beautiful', 'definition': 'pleasing to the senses', 'example': 'The sunset is beautiful.'},
    {'word': 'eat', 'definition': 'to consume food', 'example': 'I eat breakfast at 7 AM.'},
    {'word': 'big', 'definition': 'large in size', 'example': 'The elephant is big.'},
    {'word': 'small', 'definition': 'little in size', 'example': 'The mouse is small.'},
    {'word': 'friend', 'definition': 'a person you like and trust', 'example': 'My friend helps me study.'},
    {'word': 'go', 'definition': 'to move or travel', 'example': 'We go to school by bus.'},
    {'word': 'look', 'definition': 'to direct your eyes', 'example': 'Look at the stars tonight.'},
    {'word': 'learn', 'definition': 'to gain knowledge or skill', 'example': 'I learn English every day.'},
  ];

  static const List<Map<String, dynamic>> _dialogues = [
    {
      'context': 'Practicing Present Tense',
      'steps': [
        {'speaker': 'bot', 'text': 'Let’s practice present tense! Complete: I ___ (to be) a student.'},
        {'speaker': 'user', 'text': 'I am a student.'},
        {'speaker': 'bot', 'text': 'Perfect! Now try: She ___ (to like) to read books.'},
        {'speaker': 'user', 'text': 'She likes to read books.'},
        {'speaker': 'bot', 'text': 'Great! One more: We ___ (to study) English every day.'},
        {'speaker': 'user', 'text': 'We study English every day.'},
      ],
      'tips': 'Use "am/is/are" for "to be" in present. Add "s" to verbs after "he/she/it".'
    },
    {
      'context': 'Learning Vocabulary: School',
      'steps': [
        {'speaker': 'bot', 'text': 'Let’s learn school words! What do you call a person who teaches?'},
        {'speaker': 'user', 'text': 'A teacher.'},
        {'speaker': 'bot', 'text': 'Correct! What’s the place where you write notes?'},
        {'speaker': 'user', 'text': 'A notebook.'},
        {'speaker': 'bot', 'text': 'Well done! What do you use to write on a board?'},
        {'speaker': 'user', 'text': 'A marker.'},
      ],
      'tips': 'Key school words: teacher, notebook, marker, book, desk, pencil.'
    },
    {
      'context': 'Fixing Sentences',
      'steps': [
        {'speaker': 'bot', 'text': 'Let’s fix sentences! Correct this: "i go to school yesterday."'},
        {'speaker': 'user', 'text': 'I went to school yesterday.'},
        {'speaker': 'bot', 'text': 'Great! Fix this: "She don’t like coffee."'},
        {'speaker': 'user', 'text': 'She doesn’t like coffee.'},
        {'speaker': 'bot', 'text': 'Excellent! Try: "He run fast every day."'},
        {'speaker': 'user', 'text': 'He runs fast every day.'},
      ],
      'tips': 'Capitalize "I". Use "went" for past of "go". Use "doesn’t" for "she/he/it" in negatives.'
    },
  ];

  static const List<Map<String, dynamic>> _quizQuestions = [
    {
      'type': 'definition',
      'question': 'What does "happy" mean?',
      'answer': 'feeling or showing pleasure',
      'options': ['feeling or showing pleasure', 'to move quickly', 'large in size'],
    },
    {
      'type': 'definition',
      'question': 'What does "run" mean?',
      'answer': 'to move quickly on foot',
      'options': ['to consume food', 'to move quickly on foot', 'pleasing to the senses'],
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
      'options': ['a type of food', 'a person you like and trust', 'a place to live'],
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

  static const List<String> _suggestedQuestions = [
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
  ];

  final Map<String, String> _responseCache = {};
  int _quizCorrectAnswers = 0;
  int _quizTotalQuestions = 0;
  List<double> _quizScores = [];
  Timer? _debounceTimer;

  List<String> get suggestedQuestions => _suggestedQuestions;
  List<Map<String, String>> get vocabulary => _vocabulary;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _quizCorrectAnswers = prefs.getInt('quizCorrect') ?? 0;
    _quizTotalQuestions = prefs.getInt('quizTotal') ?? 0;
    _quizScores = (prefs.getStringList('quizScores') ?? []).map((s) => double.tryParse(s) ?? 0.0).toList();
  }

  Future<void> savePreferences(List<Message> messages, bool useFrenchFeedback, bool isDarkMode) async {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quizCorrect', _quizCorrectAnswers);
      await prefs.setInt('quizTotal', _quizTotalQuestions);
      await prefs.setStringList('quizScores', _quizScores.map((s) => s.toString()).toList());
      await prefs.setBool('frenchFeedback', useFrenchFeedback);
      await prefs.setBool('darkMode', isDarkMode);
      await prefs.setStringList(
        'messages',
        messages.map((m) => m.toJson().values.join('|')).toList(),
      );
    });
  }

  Future<Map<String, dynamic>> processInput(
    String input,
    bool useFrenchFeedback,
    bool isQuizMode,
    Message? lastBotMessage,
  ) async {
    input = input.trim().toLowerCase();
    if (input.isEmpty) {
      return {
        'response': 'Please enter a valid message.',
        'feedback': useFrenchFeedback ? 'Veuillez entrer un message valide.' : 'Please enter a valid message.'
      };
    }

    final commands = {
      'quiz': _handleQuizCommand,
      'dialogue': _handleDialogueCommand,
      'toggle language': () => _toggleLanguage(useFrenchFeedback),
      'toggle theme': () => _toggleTheme(useFrenchFeedback),
      'clear chat': _handleClearChat,
    };

    for (var cmd in commands.keys) {
      if (input.contains(cmd)) {
        final result = await commands[cmd]!(input, useFrenchFeedback, isQuizMode, lastBotMessage);
        return result;
      }
    }

    if (isQuizMode && lastBotMessage?.feedback?.startsWith('dialogue:') == true) {
      return _checkDialogueResponse(input, lastBotMessage, useFrenchFeedback);
    } else if (isQuizMode) {
      return _checkQuizAnswer(input, lastBotMessage, useFrenchFeedback);
    } else if (RegExp(r'^\d+\s*[\+\-\*/]\s*\d+').hasMatch(input)) {
      return _handleMathCalculation(input, useFrenchFeedback);
    } else if (input.endsWith('?')) {
      return await _handleQuestion(input, useFrenchFeedback);
    } else if (input.contains('hello') || input.contains('hi')) {
      return {
        'response': 'Hello! Try writing an English sentence or ask a question.',
        'feedback': useFrenchFeedback ? 'Bonjour ! Essayez une phrase en anglais.' : 'Great start!'
      };
    } else if (input.contains('how are you')) {
      return {
        'response': 'I’m a bot, but I’m doing great! How about you?',
        'feedback': useFrenchFeedback ? 'Je suis un bot, je vais bien !' : 'Thanks for asking!'
      };
    } else if (input.contains('thank')) {
      return {
        'response': 'You’re welcome!',
        'feedback': useFrenchFeedback ? 'De rien !' : 'Happy to help!'
      };
    } else if (input.contains('what time') || input.contains('current time')) {
      final now = DateTime.now();
      return {
        'response': 'It’s currently ${now.hour}:${now.minute.toString().padLeft(2, '0')}.',
        'feedback': useFrenchFeedback ? 'Il est ${now.hour}h${now.minute.toString().padLeft(2, '0')}.' : 'Time checked!'
      };
    } else if (input.contains('bye') || input.contains('goodbye')) {
      return {
        'response': 'Goodbye! Have a great day!',
        'feedback': useFrenchFeedback ? 'Au revoir ! Bonne journée !' : 'See you soon!'
      };
    } else if (input.contains('name')) {
      return {
        'response': 'I’m your English learning assistant chatbot.',
        'feedback': useFrenchFeedback ? 'Je suis votre assistant d’apprentissage.' : 'Nice to meet you!'
      };
    } else {
      return _analyzeSentence(input, useFrenchFeedback);
    }
  }

  Future<Map<String, dynamic>> _handleQuestion(String input, bool useFrenchFeedback) async {
    if (_responseCache.containsKey(input)) {
      return {
        'response': _responseCache[input]!,
        'feedback': useFrenchFeedback ? 'Bonne question !' : 'Good question!'
      };
    }
    final response = await _callGrokAPI(input);
    _responseCache[input] = response;
    return {
      'response': response,
      'feedback': useFrenchFeedback ? 'Bonne question !' : 'Good question!'
    };
  }

  Map<String, dynamic> _handleMathCalculation(String input, bool useFrenchFeedback) {
    try {
      final parts = input.split(RegExp(r'[\+\-\*/]'));
      final num1 = double.parse(parts[0].trim());
      final num2 = double.parse(parts[1].trim());
      final operator = input.contains('+') ? '+' : input.contains('-') ? '-' : input.contains('*') ? '*' : '/';
      double result;
      switch (operator) {
        case '+':
          result = num1 + num2;
          break;
        case '-':
          result = num1 - num2;
          break;
        case '*':
          result = num1 * num2;
          break;
        case '/':
          result = num2 != 0 ? num1 / num2 : double.infinity;
          break;
        default:
          return {
            'response': 'Invalid calculation',
            'feedback': useFrenchFeedback ? 'Calcul invalide' : 'Invalid calculation'
          };
      }
      return {
        'response': 'Result: ${result.toStringAsFixed(2)}',
        'feedback': useFrenchFeedback ? 'Calcul réussi !' : 'Calculation done!'
      };
    } catch (e) {
      return {
        'response': 'Error: Invalid calculation format',
        'feedback': useFrenchFeedback ? 'Erreur : Format invalide.' : 'Use format like "2 + 3".'
      };
    }
  }

  Map<String, dynamic> _analyzeSentence(String input, bool useFrenchFeedback) {
    String feedback = '';
    String corrected = input;

    if (input.split(' ').first.toLowerCase() == 'i' && input.split(' ').first != 'I') {
      feedback += useFrenchFeedback
          ? 'Mettez "I" en majuscule. '
          : 'Always capitalize "I". ';
      corrected = corrected.replaceFirst('i', 'I');
    }

    final words = input.split(' ');
    if (words.length > 2 && ['he', 'she', 'it'].contains(words[0].toLowerCase())) {
      if (!words[1].endsWith('s') && _vocabulary.any((v) => v['word'] == words[1])) {
        feedback += useFrenchFeedback
            ? 'Ajoutez "s" au verbe après "he/she/it".'
            : 'Add "s" to the verb after "he/she/it".';
        corrected = '${words[0]} ${words[1]}s ${words.sublist(2).join(' ')}';
      }
    }

    if (feedback.isEmpty) {
      final relatedWord = _vocabulary[Random().nextInt(_vocabulary.length)];
      feedback = useFrenchFeedback
          ? 'Essayez : "${relatedWord['word']}" (${relatedWord['definition']}). Ex. : ${relatedWord['example']}'
          : 'Try: "${relatedWord['word']}" (${relatedWord['definition']}). Ex.: ${relatedWord['example']}';
    }

    return {
      'response': corrected == input ? 'Nice sentence!' : 'Corrected: $corrected',
      'feedback': feedback.isEmpty
          ? (useFrenchFeedback ? 'Bien joué !' : 'Well done!')
          : feedback,
    };
  }

  Map<String, dynamic> _handleQuizCommand(
    String input,
    bool useFrenchFeedback,
    bool isQuizMode,
    Message? lastBotMessage,
  ) {
    _quizTotalQuestions++;
    final randomQuestion = _quizQuestions[Random().nextInt(_quizQuestions.length)];
    String questionText = randomQuestion['question'];
    if (randomQuestion['options'] != null) {
      questionText += '\nOptions: ${randomQuestion['options'].join(', ')}';
    }
    return {
      'response': 'Quiz: $questionText',
      'feedback': 'quiz:${randomQuestion['type']}:${randomQuestion['question']}:${randomQuestion['answer']}',
      'isQuizMode': true,
    };
  }

  Map<String, dynamic> _checkQuizAnswer(
    String input,
    Message? lastBotMessage,
    bool useFrenchFeedback,
  ) {
    if (lastBotMessage?.feedback?.startsWith('quiz:') != true) {
      return {
        'response': 'Please answer the quiz question.',
        'feedback': useFrenchFeedback ? 'Veuillez répondre au quiz.' : 'Answer the quiz question.'
      };
    }

    final parts = lastBotMessage!.feedback!.split(':');
    final type = parts[1];
    final question = parts[2];
    final correctAnswer = parts[3];
    bool isCorrect = false;

    if (['definition', 'translation', 'past', 'opposite'].contains(type)) {
      isCorrect = input.toLowerCase().contains(correctAnswer.toLowerCase());
    } else if (type == 'sentence') {
      isCorrect = input.toLowerCase().trim() == correctAnswer.toLowerCase();
    }

    if (isCorrect) {
      _quizCorrectAnswers++;
      _quizScores.add(_quizCorrectAnswers / _quizTotalQuestions * 100);
      return {
        'response': 'Correct! Answer: "$correctAnswer". Score: $_quizCorrectAnswers/$_quizTotalQuestions. Type "quiz" for another!',
        'feedback': useFrenchFeedback ? 'Bien joué !' : 'Great job!',
        'isQuizMode': false,
      };
    } else {
      _quizScores.add(_quizCorrectAnswers / _quizTotalQuestions * 100);
      final nextQuestion = _handleQuizCommand('', useFrenchFeedback, true, null);
      return {
        'response': 'Not quite! Answer to "$question" is "$correctAnswer". Try: ${nextQuestion['response']}',
        'feedback': nextQuestion['feedback'],
        'isQuizMode': true,
      };
    }
  }

  Map<String, dynamic> _handleDialogueCommand(
    String input,
    bool useFrenchFeedback,
    bool isQuizMode,
    Message? lastBotMessage,
  ) {
    final randomDialogue = _dialogues[Random().nextInt(_dialogues.length)];
    return {
      'response': 'Dialogue: ${randomDialogue['context']}\n${randomDialogue['steps'][0]['text']}',
      'feedback': 'dialogue:0:${randomDialogue['context']}',
      'dialogueStep': 0,
      'dialogueContext': randomDialogue['context'],
      'isQuizMode': true,
    };
  }

  Map<String, dynamic> _checkDialogueResponse(
    String input,
    Message? lastBotMessage,
    bool useFrenchFeedback,
  ) {
    if (lastBotMessage == null || lastBotMessage.feedback == null || !lastBotMessage.feedback!.startsWith('dialogue:')) {
      return {
        'response': 'Error: No active dialogue.',
        'feedback': useFrenchFeedback ? 'Erreur : Aucun dialogue actif.' : 'No active dialogue.'
      };
    }

    final parts = lastBotMessage.feedback!.split(':');
    final step = int.parse(parts[1]);
    final context = parts[2];
    final dialogue = _dialogues.firstWhere((d) => d['context'] == context);
    final currentStep = dialogue['steps'][step];
    final nextStepIndex = step + 1;

    if (nextStepIndex >= dialogue['steps'].length) {
      return {
        'response': 'Great job! Dialogue complete: ${dialogue['context']}\nTips: ${dialogue['tips']}\nType "dialogue" to start another!',
        'feedback': useFrenchFeedback ? 'Dialogue terminé !' : 'Dialogue completed!',
        'isQuizMode': false,
      };
    }

    final nextStep = dialogue['steps'][nextStepIndex];
    if (currentStep['speaker'] == 'user') {
      final expected = currentStep['text'].toLowerCase();
      final userInput = input.toLowerCase().trim();
      bool isClose = userInput.contains(expected.split(' ')[0]) || userInput.contains(expected.split(' ').last);
      if (isClose) {
        return {
          'response': nextStep['text'],
          'feedback': 'dialogue:$nextStepIndex:$context',
          'dialogueStep': nextStepIndex,
          'dialogueContext': context,
          'isQuizMode': true,
        };
      } else {
        return {
          'response': 'Try again! Expected: "${currentStep['text']}"\nYour turn: ${currentStep['text']}',
          'feedback': 'dialogue:$step:$context',
          'dialogueStep': step,
          'dialogueContext': context,
          'isQuizMode': true,
        };
      }
    } else {
      return {
        'response': nextStep['text'],
        'feedback': 'dialogue:$nextStepIndex:$context',
        'dialogueStep': nextStepIndex,
        'dialogueContext': context,
        'isQuizMode': true,
      };
    }
  }

  Map<String, dynamic> _toggleLanguage(bool useFrenchFeedback) {
    return {
      'response': 'Feedback language switched to ${!useFrenchFeedback ? 'French' : 'English'}.',
      'feedback': !useFrenchFeedback ? 'Langue changée en français.' : 'Language switched to English.',
      'useFrenchFeedback': !useFrenchFeedback,
    };
  }

  Map<String, dynamic> _toggleTheme(bool useFrenchFeedback) {
    return {
      'response': 'Theme switched.',
      'feedback': useFrenchFeedback ? 'Thème changé.' : 'Theme updated!',
      'isDarkMode': true,
    };
  }

  Map<String, dynamic> _handleClearChat(
    String input,
    bool useFrenchFeedback,
    bool isQuizMode,
    Message? lastBotMessage,
  ) {
    _quizCorrectAnswers = 0;
    _quizTotalQuestions = 0;
    _quizScores.clear();
    return {
      'response': 'Chat history cleared.',
      'feedback': useFrenchFeedback ? 'Historique effacé.' : 'Chat cleared.',
      'clearChat': true,
    };
  }

  Future<String> _callGrokAPI(String query) async {
    try {
      const apiUrl = 'https://api.x.ai/grok';
      // TODO: Use flutter_secure_storage for API key
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer YOUR_API_KEY'},
        body: jsonEncode({'query': 'Provide a simple English explanation for: $query'}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['response'] ?? 'No answer found.';
      }
      return 'Error: Failed to fetch response.';
    } catch (e) {
      return 'Error: Network issue.';
    }
  }

  List<String> getSuggestions(String input) {
    input = input.toLowerCase();
    if (input.isEmpty) return _suggestedQuestions;
    return _vocabulary
        .where((word) => word['word']!.toLowerCase().startsWith(input))
        .map((word) => word['word']!)
        .toList();
  }

  Map<String, String> getWordDefinition(String word) {
    final vocab = _vocabulary.firstWhere(
      (v) => v['word']!.toLowerCase() == word.toLowerCase(),
      orElse: () => {'word': word, 'definition': 'Not found', 'example': 'No example available'},
    );
    return vocab;
  }

  int getQuizCorrectAnswers() => _quizCorrectAnswers;
  int getQuizTotalQuestions() => _quizTotalQuestions;
  List<double> getQuizScores() => _quizScores;
}