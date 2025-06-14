import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:edit_distance/edit_distance.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:camera/camera.dart';

class LirePlayerScreen extends StatefulWidget {
  final String title;
  final String audioUrl;
  final String transcription;
  final String imageUrl;

  const LirePlayerScreen({
    super.key,
    required this.title,
    required this.audioUrl,
    required this.transcription,
    required this.imageUrl,
  });

  @override
  State<LirePlayerScreen> createState() => _LirePlayerScreenState();
}

class _LirePlayerScreenState extends State<LirePlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _audioPlayer;
  late final SpeechToText _speechToText;
  final _levenshtein = Levenshtein();
  CameraController? _cameraController;
  Future<void>? _initializeCameraFuture;
  bool _isCameraEnabled = false; // Toggle state for camera preview

  bool isPlaying = false;
  bool isListening = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  String recognizedText = '';
  String pronunciationFeedback = '';
  bool speechInitialized = false;
  bool isLoading = true;
  double soundLevel = 0.0;
  double fontSize = 20.0;
  List<TextSpan> _transcriptionSpans = [];
  late AnimationController _animationController;
  int _correctWordsCount = 0;
  Timer? _keepAliveTimer;
  bool _showPronunciationTips = false;
  bool _isDarkMode = false;
  double _playbackSpeed = 1.0;
  final List<double> _availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  Timer? _inactivityTimer;
  final Duration _inactivityDuration = const Duration(minutes: 30);
  List<bool> _wordCorrectness = [];
  int _currentWordIndex = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _speechToText = SpeechToText();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initAudioPlayer();
    _initSpeech();
    _updateTranscriptionDisplay();
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      if (mounted && isPlaying) {
        _playPause();
        _showInactivityDialog();
      }
    });
  }

  void _showInactivityDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Inactive'),
        content: const Text('Would you like to continue listening?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                _playPause();
                _resetInactivityTimer();
              }
            },
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  Future<void> _initAudioPlayer() async {
    setState(() => isLoading = true);
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No internet connection.');
      }

      if (widget.audioUrl.isEmpty || !Uri.parse(widget.audioUrl).isAbsolute) {
        throw Exception("Invalid or empty audio URL: ${widget.audioUrl}");
      }

      await _audioPlayer.setUrl(widget.audioUrl);

      _audioPlayer.durationStream.listen((d) {
        if (mounted) {
          setState(() => duration = d ?? Duration.zero);
        }
      });

      _audioPlayer.positionStream.listen((p) {
        if (mounted) {
          setState(() => position = p);
          _resetInactivityTimer();
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() => isPlaying = state.playing);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          pronunciationFeedback = 'Audio loading error: ${e.toString()}';
          isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _initSpeech() async {
    try {
      speechInitialized = await _speechToText.initialize(
        onStatus: (status) {
          if (mounted) {
            setState(() {
              pronunciationFeedback =
                  'Status: $status${isListening ? " (restarting)" : ""}';
              if (status == 'notListening' && isListening) {
                isListening = false;
                _restartListening();
              }
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              isListening = false;
              pronunciationFeedback = _getSpeechErrorMessage(error);
            });
            if (!error.permanent) {
              _restartListening();
            }
          }
        },
      );
      if (!speechInitialized && mounted) {
        setState(() {
          pronunciationFeedback = 'Failed to initialize speech recognition.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          pronunciationFeedback = 'Initialization error: $e';
        });
      }
    }
  }

  Future<void> _initCamera() async {
    if (!_isCameraEnabled) return; // Only initialize if camera is enabled

    try {
      bool hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        if (mounted) {
          setState(() {
            pronunciationFeedback = 'Camera permission denied.';
            _isCameraEnabled = false; // Disable camera if permission denied
          });
        }
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            pronunciationFeedback = 'No cameras available.';
            _isCameraEnabled = false;
          });
        }
        return;
      }

      // Select the front-facing camera
      CameraDescription? frontCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }
      frontCamera ??= cameras[0]; // Fallback to first camera if no front camera

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initializeCameraFuture = _cameraController!.initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            pronunciationFeedback = 'Camera initialization error: $e';
            _isCameraEnabled = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          pronunciationFeedback = 'Camera setup error: $e';
          _isCameraEnabled = false;
        });
      }
    }
  }

  Future<void> _toggleCamera(bool enable) async {
    if (enable == _isCameraEnabled) return;

    if (mounted) {
      setState(() {
        _isCameraEnabled = enable;
      });
    }

    if (enable) {
      await _initCamera();
    } else {
      // Dispose camera resources when disabled
      await _cameraController?.dispose();
      if (mounted) {
        setState(() {
          _cameraController = null;
          _initializeCameraFuture = null;
        });
      }
    }
  }

  Future<bool> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  String _getSpeechErrorMessage(dynamic error) {
    String errorMessage = error.toString();
    String message = 'Error: $errorMessage';
    if (errorMessage.toLowerCase().contains('permission')) {
      message += '\nPlease grant microphone access.';
    } else if (errorMessage.toLowerCase().contains('timeout') ||
        errorMessage.toLowerCase().contains('no speech')) {
      message += '\nSpeech stopped due to silence, restarting...';
    } else if (errorMessage.toLowerCase().contains('network')) {
      message += '\nNetwork issue.';
    }
    print('Speech error: $errorMessage');
    return message;
  }

  String _cleanTranscription(String transcription,
      {bool forComparison = false}) {
    if (transcription.isEmpty) {
      return '';
    }
    String cleaned = transcription
        .replaceAll(
            RegExp(r'\[\d{2}:\d{3}\.\d{3} --> \d{2}:\d{2}\.\d{3}\]'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (forComparison) cleaned = cleaned.toLowerCase();
    return cleaned;
  }

  @override
  void dispose() {
    _keepAliveTimer?.cancel();
    _inactivityTimer?.cancel();
    _audioPlayer.stop().then((_) => _audioPlayer.dispose());
    _speechToText.stop();
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    try {
      if (isPlaying) {
        await _audioPlayer.pause();
        _animationController.reverse();
      } else {
        await _audioPlayer.play();
        _animationController.forward();
        _resetInactivityTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          pronunciationFeedback = 'Audio playback error: $e';
        });
      }
    }
  }

  Future<void> _seekForward() async {
    final newPosition = position + Duration(seconds: 10);
    await _audioPlayer.seek(newPosition);
    _resetInactivityTimer();
  }

  Future<void> _seekBackward() async {
    final newPosition = position - Duration(seconds: 10);
    await _audioPlayer.seek(newPosition);
    _resetInactivityTimer();
  }

  Future<bool> _checkMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _startListening() async {
    if (!speechInitialized) {
      if (mounted) {
        setState(() =>
            pronunciationFeedback = 'Speech recognition not initialized.');
      }
      return;
    }

    bool hasPermission = await _checkMicrophonePermission();
    if (!hasPermission) {
      if (mounted) {
        setState(() => pronunciationFeedback = 'Microphone permission denied.');
      }
      return;
    }

    bool hasConnectivity = await _checkConnectivity();
    if (!hasConnectivity) {
      if (mounted) {
        setState(() => pronunciationFeedback = 'No internet connection.');
      }
      return;
    }

    if (!isListening) {
      if (mounted) {
        setState(() {
          if (recognizedText.isEmpty) recognizedText = '';
          pronunciationFeedback = 'Speak now...';
          isListening = true;
          soundLevel = 0.0;
          _currentWordIndex = 0;
          _wordCorrectness = List.filled(
              _cleanTranscription(widget.transcription).split(' ').length,
              false);
        });
      }

      try {
        await _speechToText.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                recognizedText = result.recognizedWords;
                pronunciationFeedback = result.recognizedWords.isNotEmpty
                    ? 'Keep speaking...'
                    : 'Speak now...';
                _evaluateRealTimePronunciation();
                _updateTranscriptionDisplay();
              });
              _resetInactivityTimer();
            }
          },
          onSoundLevelChange: (level) {
            if (mounted) {
              setState(() => soundLevel = level);
            }
          },
          localeId: 'en-US',
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 10),
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: false,
        );

        _keepAliveTimer?.cancel();
        _keepAliveTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
          if (mounted && isListening && _speechToText.isNotListening) {
            _restartListening();
          }
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            isListening = false;
            pronunciationFeedback = 'Listening error: $e';
          });
          _restartListening();
        }
      }
    }
  }

  Future<void> _restartListening() async {
    int retryCount = 0;
    const maxRetries = 3;
    while (retryCount < maxRetries &&
        mounted &&
        !isListening &&
        speechInitialized) {
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        await _startListening();
        return;
      } catch (e) {
        retryCount++;
        if (mounted) {
          setState(() {
            pronunciationFeedback = 'Retry $retryCount/$maxRetries failed: $e';
          });
        }
      }
    }
    if (retryCount >= maxRetries && mounted) {
      setState(() {
        pronunciationFeedback =
            'Failed to restart listening after $maxRetries attempts.';
      });
    }
  }

  Future<void> _stopListening() async {
    if (isListening) {
      _keepAliveTimer?.cancel();
      await _speechToText.stop();
      if (mounted) {
        setState(() {
          isListening = false;
          pronunciationFeedback = recognizedText.isNotEmpty
              ? 'Listening stopped. Analyzing...'
              : 'No text detected.';
        });
        if (recognizedText.isNotEmpty) {
          _evaluatePronunciation();
          _updateTranscriptionDisplay();
        } else if (soundLevel < -5) {
          setState(() {
            pronunciationFeedback += '\nSpeak louder.';
          });
        }
        _resetInactivityTimer();
      }
    }
  }

  void _evaluateRealTimePronunciation() {
    final referenceText =
        _cleanTranscription(widget.transcription, forComparison: true);
    if (referenceText.isEmpty) return;

    final referenceWords = referenceText.split(' ');
    final userWords = recognizedText
        .toLowerCase()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    _correctWordsCount = 0;
    _wordCorrectness = List.filled(referenceWords.length, false);

    for (int i = 0; i < referenceWords.length && i < userWords.length; i++) {
      final refWord = referenceWords[i];
      final userWord = userWords[i];
      final distance = _levenshtein.distance(refWord, userWord);
      final maxLength =
          refWord.length > userWord.length ? refWord.length : userWord.length;
      final similarity = maxLength > 0 ? 1.0 - (distance / maxLength) : 0.0;
      _wordCorrectness[i] = similarity >= 0.9;
      if (_wordCorrectness[i]) _correctWordsCount++;
    }

    _currentWordIndex = userWords.length;
  }

  void _evaluatePronunciation() {
    final referenceText =
        _cleanTranscription(widget.transcription, forComparison: true);
    if (referenceText.isEmpty) {
      if (mounted) {
        setState(() {
          pronunciationFeedback = 'No reference transcription available.';
        });
      }
      return;
    }

    final referenceWords = referenceText.split(' ');
    final userWords = recognizedText
        .toLowerCase()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
    final totalWords = referenceWords.length;
    _correctWordsCount = 0;
    _wordCorrectness = List.filled(totalWords, false);

    for (int i = 0; i < totalWords && i < userWords.length; i++) {
      final refWord = referenceWords[i];
      final userWord = userWords[i];
      final distance = _levenshtein.distance(refWord, userWord);
      final maxLength =
          refWord.length > userWord.length ? refWord.length : userWord.length;
      final similarity = maxLength > 0 ? 1.0 - (distance / maxLength) : 0.0;
      _wordCorrectness[i] = similarity >= 0.9;
      if (_wordCorrectness[i]) _correctWordsCount++;
    }

    final similarity = totalWords > 0 ? _correctWordsCount / totalWords : 0.0;

    if (mounted) {
      setState(() {
        pronunciationFeedback = similarity >= 0.85
            ? 'Excellent pronunciation!'
            : similarity >= 0.65
                ? 'Good pronunciation.'
                : 'Pronunciation needs improvement.';
        pronunciationFeedback += '\nYou said: "$recognizedText"';
        pronunciationFeedback +=
            '\nCorrect words: $_correctWordsCount/$totalWords';
      });
      _updateTranscriptionDisplay();
    }
  }

  void _updateTranscriptionDisplay() {
    print('Updating transcription display with fontSize: $fontSize');
    final referenceText = _cleanTranscription(widget.transcription);
    final newSpans = <TextSpan>[];

    if (referenceText.isEmpty) {
      newSpans.add(
        const TextSpan(
          text: 'No transcription available.',
          style: TextStyle(
            fontSize: 18.0,
            height: 1.5,
            color: Colors.grey,
            fontFamily: 'Roboto',
          ),
        ),
      );
    } else {
      final referenceWords = referenceText.split(' ');
      for (int i = 0; i < referenceWords.length; i++) {
        final refWord = referenceWords[i];
        final isCorrect = i < _wordCorrectness.length && _wordCorrectness[i];

        newSpans.add(
          TextSpan(
            text: '$refWord ',
            style: TextStyle(
              fontSize: fontSize,
              height: 1.6,
              color: i < _currentWordIndex
                  ? (isCorrect ? Colors.green : Colors.red)
                  : _isDarkMode
                      ? Colors.white
                      : Colors.black,
              backgroundColor: i == _currentWordIndex && isListening
                  ? Colors.yellow[200]
                  : null,
              fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
              decoration: i == _currentWordIndex && isListening
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor: Colors.blue,
              fontFamily: 'Roboto',
            ),
          ),
        );
      }
    }

    _transcriptionSpans = newSpans;
    if (mounted) {
      setState(() {
        print('Transcription spans updated with ${newSpans.length} spans');
      });
    }
  }

  void _increaseFontSize() {
    if (mounted) {
      setState(() {
        fontSize = (fontSize + 2).clamp(14.0, 30.0);
        print('Font size increased to: $fontSize');
        _updateTranscriptionDisplay();
      });
    }
  }

  void _decreaseFontSize() {
    if (mounted) {
      setState(() {
        fontSize = (fontSize - 2).clamp(14.0, 30.0);
        print('Font size decreased to: $fontSize');
        _updateTranscriptionDisplay();
      });
    }
  }

  void _toggleDarkMode() {
    if (mounted) {
      setState(() {
        _isDarkMode = !_isDarkMode;
        print('Dark mode toggled: $_isDarkMode');
        _updateTranscriptionDisplay();
      });
    }
  }

  void _togglePronunciationTips() {
    if (mounted) {
      setState(() {
        _showPronunciationTips = !_showPronunciationTips;
      });
    }
  }

  Future<void> _changePlaybackSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
      if (mounted) {
        setState(() => _playbackSpeed = speed);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          pronunciationFeedback = 'Playback speed change error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isDarkMode
        ? ThemeData.dark().copyWith(
            primaryColor: Colors.pinkAccent,
            colorScheme: ColorScheme.dark(primary: Colors.pinkAccent),
            scaffoldBackgroundColor: Colors.grey[900],
            cardTheme: CardTheme(
              color: Colors.grey[850],
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Roboto'),
              bodyMedium: TextStyle(fontFamily: 'Roboto'),
            ),
          )
        : ThemeData.light().copyWith(
            primaryColor: Colors.pinkAccent,
            colorScheme: ColorScheme.light(primary: Colors.pinkAccent),
            scaffoldBackgroundColor: Colors.grey[100],
            cardTheme: CardTheme(
              color: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Roboto'),
              bodyMedium: TextStyle(fontFamily: 'Roboto'),
            ),
          );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title, style: const TextStyle(fontFamily: 'Roboto')),
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.textTheme.bodyLarge?.color,
          elevation: 0,
          actions: [
            AnimatedScale(
              scale: _isDarkMode ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: _toggleDarkMode,
                tooltip: 'Toggle Dark Mode',
              ),
            ),
            AnimatedScale(
              scale: fontSize < 30.0 ? 1.0 : 0.9,
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                icon: const Icon(Icons.text_increase),
                tooltip: 'Increase Text Size',
                onPressed: fontSize < 30.0
                    ? () {
                        _increaseFontSize();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Font size increased to $fontSize'),
                            duration: const Duration(milliseconds: 500),
                          ),
                        );
                      }
                    : null,
              ),
            ),
            AnimatedScale(
              scale: fontSize > 14.0 ? 1.0 : 0.9,
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                icon: const Icon(Icons.text_decrease),
                tooltip: 'Decrease Text Size',
                onPressed: fontSize > 14.0
                    ? () {
                        _decreaseFontSize();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Font size decreased to $fontSize'),
                            duration: const Duration(milliseconds: 500),
                          ),
                        );
                      }
                    : null,
              ),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: _resetInactivityTimer,
          child: Stack(
            children: [
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMainView(),
              AnimatedOpacity(
                opacity: _showPronunciationTips ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _showPronunciationTips
                    ? _buildPronunciationTipsOverlay()
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildPronunciationTipsButton(),
      ),
    );
  }

  Widget _buildPronunciationTipsButton() {
    return FloatingActionButton(
      onPressed: _togglePronunciationTips,
      backgroundColor: Colors.pinkAccent,
      child: AnimatedRotation(
        turns: _showPronunciationTips ? 0.125 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: const Icon(Icons.help_outline),
      ),
      tooltip: 'Pronunciation Tips',
      elevation: 6,
      mini: MediaQuery.of(context).size.width < 600,
    );
  }

  Widget _buildPlaybackSpeedControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Speed: ',
            style: TextStyle(
              fontSize: 16,
              color: _isDarkMode ? Colors.white70 : Colors.black87,
              fontFamily: 'Roboto',
            ),
          ),
          DropdownButton<double>(
            value: _playbackSpeed,
            items: _availableSpeeds.map((speed) {
              return DropdownMenuItem<double>(
                value: speed,
                child: Text(
                  '${speed}x',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontFamily: 'Roboto',
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) => _changePlaybackSpeed(value!),
            dropdownColor: _isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            underline: const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildPronunciationTipsOverlay() {
    return GestureDetector(
      onTap: _togglePronunciationTips,
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pronunciation Tips',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Speak clearly at a natural pace\n'
                    '• Hold phone 15-20 cm from mouth\n'
                    '• Avoid background noise\n'
                    '• Practice difficult words separately\n'
                    '• Focus on word stress and intonation',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: _isDarkMode ? Colors.white70 : Colors.black87,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _togglePronunciationTips,
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.pinkAccent,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluationResult() {
    final referenceText = _cleanTranscription(widget.transcription);
    final referenceWords = referenceText.split(' ');
    final totalWords = referenceWords.length;
    final similarity = totalWords > 0 ? _correctWordsCount / totalWords : 0.0;

    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _getFeedbackIcon(similarity),
                  color: _getFeedbackColor(similarity),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _getFeedbackTitle(similarity),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: _getFeedbackColor(similarity),
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: similarity,
              backgroundColor: Colors.grey[300],
              color: _getFeedbackColor(similarity),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 12),
            Text(
              'Accuracy: ${(similarity * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                color: _isDarkMode ? Colors.white70 : Colors.black87,
                fontFamily: 'Roboto',
              ),
            ),
            if (_correctWordsCount < totalWords) ...[
              const SizedBox(height: 8),
              Text(
                'Incorrect words: ${totalWords - _correctWordsCount}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getFeedbackColor(double similarity) {
    if (similarity >= 0.85) {
      return Colors.green;
    } else if (similarity >= 0.65) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getFeedbackIcon(double similarity) {
    if (similarity >= 0.85) return Icons.check_circle;
    if (similarity >= 0.65) return Icons.warning;
    return Icons.error;
  }

  String _getFeedbackTitle(double similarity) {
    if (similarity >= 0.85) return 'Excellent!';
    if (similarity >= 0.65) return 'Good Job';
    return 'Needs Work';
  }

  Widget _buildMainView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildImageSection()),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildAudioControls()),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildSpeechSection()),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          if (!isListening &&
              recognizedText.isNotEmpty &&
              pronunciationFeedback.isNotEmpty)
            SliverToBoxAdapter(child: _buildEvaluationResult()),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          SliverFillRemaining(child: _buildTranscriptionSection()),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: widget.imageUrl.isNotEmpty && Uri.parse(widget.imageUrl).isAbsolute
            ? Image.network(
                widget.imageUrl,
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.25,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.25,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.25,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              )
            : Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.25,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.image,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }

  Widget _buildTranscriptionSection() {
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 12.0),
              child: Text(
                'Transcription',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.white : Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: RichText(
                  key: ValueKey(fontSize),
                  text: TextSpan(
                    children: _transcriptionSpans,
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1.6,
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: Icons.replay_10,
                  label: 'Rewind 10s',
                  onPressed: _seekBackward,
                ),
                const SizedBox(width: 24),
                AnimatedScale(
                  scale: isPlaying ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _buildControlButton(
                    icon: isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    label: isPlaying ? 'Pause' : 'Play',
                    onPressed: _playPause,
                    size: 56,
                  ),
                ),
                const SizedBox(width: 24),
                _buildControlButton(
                  icon: Icons.forward_10,
                  label: 'Forward 10s',
                  onPressed: _seekForward,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPlaybackSpeedControl(),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.pinkAccent,
                inactiveTrackColor: Colors.grey[300],
                thumbColor: Colors.pinkAccent,
                overlayColor: Colors.pinkAccent.withOpacity(0.3),
                trackHeight: 6.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              ),
              child: Slider(
                value: position.inSeconds.toDouble(),
                max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0,
                onChanged: duration.inSeconds > 0
                    ? (value) async {
                        final newPosition = Duration(seconds: value.toInt());
                        await _audioPlayer.seek(newPosition);
                        _resetInactivityTimer();
                      }
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(
                      fontSize: 14,
                      color: _isDarkMode ? Colors.white70 : Colors.black87,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      fontSize: 14,
                      color: _isDarkMode ? Colors.white70 : Colors.black87,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    double size = 32,
  }) {
    return AnimatedOpacity(
      opacity: duration.inSeconds > 0 ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: IconButton(
        icon: Icon(icon),
        iconSize: size,
        onPressed: duration.inSeconds > 0
            ? () {
                onPressed();
                _resetInactivityTimer();
              }
            : null,
        tooltip: label,
        color: Colors.pinkAccent,
        splashRadius: 28,
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        splashColor: Colors.pinkAccent.withOpacity(0.2),
        highlightColor: Colors.pinkAccent.withOpacity(0.1),
      ),
    );
  }

  Widget _buildSpeechSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 600;
        final double fontSize = isSmallScreen ? 14.0 : 16.0;
        final double iconSize = isSmallScreen ? 20.0 : 24.0;

        return Card(
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedScale(
                      scale: isListening ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          isListening ? _stopListening() : _startListening();
                          _resetInactivityTimer();
                        },
                        icon: Icon(
                          isListening ? Icons.mic_off : Icons.mic,
                          color: Colors.pinkAccent,
                          size: iconSize,
                        ),
                        label: Text(
                          isListening ? 'Stop' : 'Speak',
                          style: TextStyle(
                            color: Colors.pinkAccent,
                            fontSize: fontSize,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Camera',
                          style: TextStyle(
                            fontSize: fontSize,
                            color: _isDarkMode ? Colors.white70 : Colors.black87,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        Switch(
                          value: _isCameraEnabled,
                          onChanged: (value) {
                            _toggleCamera(value);
                            _resetInactivityTimer();
                          },
                          activeColor: Colors.pinkAccent,
                        ),
                      ],
                    ),
                  ],
                ),
                if (isListening &&
                    _isCameraEnabled &&
                    _cameraController != null &&
                    _cameraController!.value.isInitialized) ...[
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: FutureBuilder<void>(
                        future: _initializeCameraFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done) {
                            return CameraPreview(_cameraController!);
                          } else if (snapshot.hasError) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Text(
                                  'Camera Error',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
                if (pronunciationFeedback.isNotEmpty) ...[
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  AnimatedOpacity(
                    opacity: pronunciationFeedback.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      pronunciationFeedback,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: isListening
                            ? Colors.blue
                            : _isDarkMode
                                ? Colors.white70
                                : Colors.black87,
                        fontFamily: 'Roboto',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (isListening) ...[
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  LinearProgressIndicator(
                    value: soundLevel.clamp(-20.0, 0.0) / -20.0,
                    backgroundColor: Colors.grey[300],
                    color: Colors.blue,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }
}