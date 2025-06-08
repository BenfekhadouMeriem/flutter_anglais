import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/text_styles.dart'; // Your style file

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({Key? key}) : super(key: key);

  @override
  _TranslationScreenState createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  String _translatedText = '';
  String _sourceLanguage = 'English'; // Default to English
  String _targetLanguage = 'French';
  bool _isTranslating = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _debounceTimer;
  bool _isConnected = true;

  // Comprehensive list of languages with ISO 639-1 codes (and some ISO 639-2 for less common languages)
  final Map<String, String> _languageCodes = {
    'Afrikaans': 'af',
    'Albanian': 'sq',
    'Amharic': 'am',
    'Arabic': 'ar',
    'Armenian': 'hy',
    'Azerbaijani': 'az',
    'Basque': 'eu',
    'Belarusian': 'be',
    'Bengali': 'bn',
    'Bosnian': 'bs',
    'Bulgarian': 'bg',
    'Catalan': 'ca',
    'Cebuano': 'ceb',
    'Chichewa': 'ny',
    'Chinese': 'zh',
    'Corsican': 'co',
    'Croatian': 'hr',
    'Czech': 'cs',
    'Danish': 'da',
    'Dutch': 'nl',
    'English': 'en',
    'Esperanto': 'eo',
    'Estonian': 'et',
    'Filipino': 'tl',
    'Finnish': 'fi',
    'French': 'fr',
    'Frisian': 'fy',
    'Galician': 'gl',
    'Georgian': 'ka',
    'German': 'de',
    'Greek': 'el',
    'Gujarati': 'gu',
    'Haitian Creole': 'ht',
    'Hausa': 'ha',
    'Hawaiian': 'haw',
    'Hebrew': 'he',
    'Hindi': 'hi',
    'Hmong': 'hmn',
    'Hungarian': 'hu',
    'Icelandic': 'is',
    'Igbo': 'ig',
    'Indonesian': 'id',
    'Irish': 'ga',
    'Italian': 'it',
    'Japanese': 'ja',
    'Javanese': 'jv',
    'Kannada': 'kn',
    'Kazakh': 'kk',
    'Khmer': 'km',
    'Korean': 'ko',
    'Kurdish': 'ku',
    'Kyrgyz': 'ky',
    'Lao': 'lo',
    'Latin': 'la',
    'Latvian': 'lv',
    'Lithuanian': 'lt',
    'Luxembourgish': 'lb',
    'Macedonian': 'mk',
    'Malagasy': 'mg',
    'Malay': 'ms',
    'Malayalam': 'ml',
    'Maltese': 'mt',
    'Maori': 'mi',
    'Marathi': 'mr',
    'Mongolian': 'mn',
    'Myanmar': 'my',
    'Nepali': 'ne',
    'Norwegian': 'no',
    'Odia': 'or',
    'Pashto': 'ps',
    'Persian': 'fa',
    'Polish': 'pl',
    'Portuguese': 'pt',
    'Punjabi': 'pa',
    'Romanian': 'ro',
    'Russian': 'ru',
    'Samoan': 'sm',
    'Scots Gaelic': 'gd',
    'Serbian': 'sr',
    'Sesotho': 'st',
    'Shona': 'sn',
    'Sindhi': 'sd',
    'Sinhala': 'si',
    'Slovak': 'sk',
    'Slovenian': 'sl',
    'Somali': 'so',
    'Spanish': 'es',
    'Sundanese': 'su',
    'Swahili': 'sw',
    'Swedish': 'sv',
    'Tajik': 'tg',
    'Tamil': 'ta',
    'Telugu': 'te',
    'Thai': 'th',
    'Turkish': 'tr',
    'Ukrainian': 'uk',
    'Urdu': 'ur',
    'Uyghur': 'ug',
    'Uzbek': 'uz',
    'Vietnamese': 'vi',
    'Welsh': 'cy',
    'Xhosa': 'xh',
    'Yiddish': 'yi',
    'Yoruba': 'yo',
    'Zulu': 'zu',
  };

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
    _inputController.addListener(_onTextChanged);
    _checkNetwork(); // Check network on init
  }

  void _onTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_inputController.text.isNotEmpty) _translateText();
    });
  }

  Future<void> _translateText() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || text.length < 2) {
      _showErrorSnackBar('Please enter valid text to translate');
      setState(() {
        _isTranslating = false;
        _translatedText = '';
      });
      return;
    }

    if (text.length > 500) {
      _showErrorSnackBar('Text exceeds 500 bytes. Please shorten it.');
      setState(() {
        _isTranslating = false;
        _translatedText = '';
      });
      return;
    }

    await _checkNetwork();
    if (!_isConnected) {
      _showErrorSnackBar('No internet connection');
      setState(() {
        _isTranslating = false;
        _translatedText = '';
      });
      return;
    }

    setState(() {
      _isTranslating = true;
      _translatedText = '';
    });

    // Retry logic for transient errors
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final url = Uri.parse('https://api.mymemory.translated.net/get');
        final queryParams = {
          'q': text,
          'langpair':
              '${_getLangCode(_sourceLanguage)}|${_getLangCode(_targetLanguage)}',
        };
        print(
            'Translation request (attempt ${attempt + 1}): $url?$queryParams');
        final response = await http.get(
          url.replace(queryParameters: queryParams),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 15));
        print('Translation response: ${response.statusCode} ${response.body}');

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          setState(() {
            // Extract translation from response (prioritize human translation)
            _translatedText =
                json['responseData']['translatedText'] ?? 'Translation error';
            _isTranslating = false;
            _animationController.forward(from: 0);
          });
          return;
        } else if (response.statusCode == 429 || response.statusCode == 503) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        } else {
          _handleErrorResponse(response.statusCode, response.body);
          return;
        }
      } catch (e) {
        print('Translation error (attempt ${attempt + 1}): $e');
        if (attempt == 2) {
          setState(() {
            _isTranslating = false;
            _translatedText = '';
          });
          _showErrorSnackBar(
              'Translation failed: Check your connection or try again later');
        }
      }
    }
  }

  void _handleErrorResponse(int statusCode, String responseBody) {
    setState(() {
      _isTranslating = false;
      _translatedText = '';
    });
    String message;
    try {
      final json = jsonDecode(responseBody);
      message =
          json['responseDetails'] ?? 'Translation failed (Error $statusCode)';
    } catch (_) {
      message = 'Translation failed (Error $statusCode)';
    }
    switch (statusCode) {
      case 400:
        message = 'Bad request: $message';
        break;
      case 429:
        message = 'Too many requests. Please wait and try again.';
        break;
      case 503:
        message = 'Server unavailable. Try again later.';
        break;
      default:
        message = 'Translation failed (Error $statusCode)';
    }
    _showErrorSnackBar(message);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getLangCode(String language) {
    return _languageCodes[language] ?? 'en';
  }

  Future<void> _checkNetwork() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      setState(() {
        _isConnected = connectivityResult != ConnectivityResult.none;
      });
      if (!_isConnected) {
        _showErrorSnackBar('No internet connection');
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
      });
      _showErrorSnackBar('Network check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Translation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: _checkNetwork,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLanguageDropdown(
                    _sourceLanguage,
                    (value) => setState(() {
                      _sourceLanguage = value!;
                      if (_inputController.text.isNotEmpty) _translateText();
                    }),
                    'Source',
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, color: Colors.black),
                    onPressed: () {
                      setState(() {
                        final temp = _sourceLanguage;
                        _sourceLanguage = _targetLanguage;
                        _targetLanguage = temp;
                        if (_inputController.text.isNotEmpty) _translateText();
                      });
                    },
                  ),
                  _buildLanguageDropdown(
                    _targetLanguage,
                    (value) => setState(() {
                      _targetLanguage = value!;
                      if (_inputController.text.isNotEmpty) _translateText();
                    }),
                    'Target',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  hintText: 'Enter text to translate...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  prefixIcon: const Icon(Icons.translate, color: Colors.black),
                  suffixIcon: _inputController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black),
                          onPressed: () {
                            _inputController.clear();
                            setState(() {
                              _translatedText = '';
                            });
                          },
                        )
                      : null,
                ),
                style: const TextStyle(color: Colors.black),
                maxLines: 4,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _translateText(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    _isTranslating || !_isConnected ? null : _translateText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                  elevation: 5,
                ),
                child: _isTranslating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Translate',
                        style: AppTextStyles.buttonText.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              if (_translatedText.isNotEmpty)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade200, Colors.grey.shade300],
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _translatedText,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () async {
                            try {
                              await Clipboard.setData(
                                  ClipboardData(text: _translatedText));
                              _showErrorSnackBar(
                                  'Translation copied to clipboard');
                            } catch (e) {
                              _showErrorSnackBar('Failed to copy to clipboard');
                            }
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.pink.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(
      String value, ValueChanged<String?> onChanged, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey.shade100,
        ),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          items: _languageCodes.keys
              .map((lang) => DropdownMenuItem(
                    value: lang,
                    child: Text(
                      lang,
                      style: AppTextStyles.buttonText
                          .copyWith(color: Colors.black),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          hint: Text(label),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _inputController.removeListener(_onTextChanged);
    _inputController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
