import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String description;
  final String audioUrl; // URL Google Drive (visualisation ou directe)
  final String transcription;
  final String imageUrl; // URL Google Drive (visualisation ou directe) ou vide

  const PlayerScreen({
    Key? key,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.transcription,
    required this.imageUrl,
  }) : super(key: key);

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  bool isPlaying = false;
  bool isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool isSeeking = false;
  List<Map<String, dynamic>> _parsedTranscription = [];
  String? errorMessage;

  // Convertit une URL Google Drive de visualisation en URL directe
  String _convertGoogleDriveUrl(String url, {bool isAudio = false}) {
  if (url.isEmpty) {
    print('⚠️ URL vide reçue');
    return '';
  }

  // Vérifier si l'URL est déjà directe
  if (url.contains('drive.google.com/uc') || !url.contains('drive.google.com')) {
    print('🔗 URL directe ou non-Google Drive : $url');
    return url;
  }

  // Convertir les URLs de visualisation Google Drive
  final RegExp regex = RegExp(r'file/d/([a-zA-Z0-9_-]+)/view');
  final match = regex.firstMatch(url);
  if (match != null) {
    final fileId = match.group(1);
    final convertedUrl = isAudio
        ? 'https://drive.google.com/uc?export=download&id=$fileId'
        : 'https://drive.google.com/uc?id=$fileId';
    print('🔄 URL convertie : $url -> $convertedUrl');
    return convertedUrl;
  }

  print('⚠️ URL Google Drive non reconnue : $url');
  return ''; // Retourner une chaîne vide si l'URL est invalide
}

  @override
  void initState() {
    super.initState();
    _setupAudio();
    _parseTranscription();

    _audioPlayer.durationStream.listen((d) {
      setState(() => _duration = d ?? Duration.zero);
    });

    _audioPlayer.positionStream.listen((p) {
      if (!isSeeking && (p - _position).inSeconds.abs() > 1) {
        setState(() => _position = p);
        _scrollToImportantText();
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          isPlaying = false;
          _position = _duration;
        });
      }
    });
  }

  Future<void> _setupAudio() async {
    setState(() => isLoading = true);
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception("Aucune connexion Internet.");
      }
      print("🌐 Connectivité vérifiée : $connectivityResult");

      // Vérifier si l'URL audio est valide
      if (widget.audioUrl.isEmpty) {
        throw Exception("URL audio vide.");
      }

      // Convertir l'URL Google Drive
      final convertedAudioUrl = _convertGoogleDriveUrl(widget.audioUrl, isAudio: true);
      if (convertedAudioUrl.isEmpty) {
        throw Exception("Impossible de convertir l'URL audio.");
      }

      print("📡 Tentative de chargement de l'audio : $convertedAudioUrl");

      // Configurer l'audio
      await _audioPlayer.setUrl(convertedAudioUrl);
      print("✅ Audio chargé avec succès. Durée : ${_audioPlayer.duration}");
    } on PlayerException catch (e, stackTrace) {
      print("❌ PlayerException : ${e.message}, code : ${e.code}");
      print("📜 StackTrace : $stackTrace");
      setState(() {
        errorMessage = "Erreur audio : ${e.message}";
      });
      _showErrorSnackBar(errorMessage!);
    } catch (e, stackTrace) {
      print("❌ Erreur lors du chargement de l'audio : $e");
      print("📜 StackTrace : $stackTrace");
      setState(() {
        errorMessage = "Erreur lors du chargement : $e";
      });
      _showErrorSnackBar(errorMessage!);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Réessayer',
          onPressed: _setupAudio,
        ),
      ),
    );
  }

  void _togglePlayPause() async {
    setState(() {
      isPlaying = !isPlaying;
    });

    try {
      if (isPlaying) {
        await _audioPlayer.play();
        print("▶️ Lecture du podcast démarrée.");
      } else {
        await _audioPlayer.pause();
        print("⏸️ Lecture du podcast en pause.");
      }
    } catch (e, stackTrace) {
      print("❌ Erreur lors de la lecture/pause : $e");
      print("📜 StackTrace : $stackTrace");
      setState(() {
        isPlaying = false;
        errorMessage = "Erreur lors de la lecture du podcast : $e";
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  Future<void> _seekAudio(Duration position) async {
    try {
      isSeeking = true;
      await _audioPlayer.seek(position);
      setState(() => _position = position);
      print("⏩ Position du podcast modifiée : ${position.inSeconds} secondes");
    } catch (e, stackTrace) {
      print("❌ Erreur lors du déplacement : $e");
      print("📜 StackTrace : $stackTrace");
      setState(() {
        errorMessage = "Erreur lors du déplacement dans le podcast : $e";
      });
      _showErrorSnackBar(errorMessage!);
    } finally {
      isSeeking = false;
    }
  }

  void _parseTranscription() {
    RegExp regex = RegExp(r'\[(\d+):(\d+).(\d+) --> (\d+):(\d+).(\d+)\] (.+)');
    _parsedTranscription = regex
        .allMatches(widget.transcription)
        .map((match) => {
              "start": Duration(
                  minutes: int.parse(match.group(1)!),
                  seconds: int.parse(match.group(2)!),
                  milliseconds: int.parse(match.group(3)!)),
              "end": Duration(
                  minutes: int.parse(match.group(4)!),
                  seconds: int.parse(match.group(5)!),
                  milliseconds: int.parse(match.group(6)!)),
              "text": match.group(7)!,
            })
        .toList();
    print("📝 Transcription parsée : ${_parsedTranscription.length} segments");
  }

  void _scrollToImportantText() {
    if (_scrollController.hasClients) {
      int importantIndex = _parsedTranscription.indexWhere((segment) =>
          _position >= segment["start"] && _position <= segment["end"]);

      if (importantIndex != -1) {
        double scrollPosition = importantIndex * 60.0;
        _scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        print("📜 Défilement vers le segment : $importantIndex");
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final convertedImageUrl = _convertGoogleDriveUrl(widget.imageUrl);
    print("🖼️ Tentative de chargement de l'image : $convertedImageUrl");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.pinkAccent,
              ),
            )
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: convertedImageUrl.isNotEmpty
                          ? Image.network(
                              convertedImageUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print(
                                    "❌ Erreur de chargement de l'image : $convertedImageUrl, erreur : $error");
                                return const Icon(
                                  Icons.broken_image,
                                  size: 80,
                                  color: Colors.grey,
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: const Center(
                                      child: CircularProgressIndicator()),
                                );
                              },
                            )
                          : const Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: isPlaying ? 24 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    child: Text(widget.title),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.description,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    activeColor: Colors.pinkAccent,
                    inactiveColor: Colors.grey,
                    min: 0,
                    max: _duration.inSeconds > 0
                        ? _duration.inSeconds.toDouble()
                        : 1,
                    value: _position.inSeconds
                        .toDouble()
                        .clamp(0, _duration.inSeconds.toDouble()),
                    onChanged: (value) {
                      setState(
                          () => _position = Duration(seconds: value.toInt()));
                    },
                    onChangeEnd: (value) async {
                      await _seekAudio(Duration(seconds: value.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, size: 40),
                        color: Colors.pinkAccent,
                        onPressed: () =>
                            _seekAudio(_position - const Duration(seconds: 10)),
                      ),
                      const SizedBox(width: 20),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isPlaying ? Colors.pinkAccent : Colors.grey[300],
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 60,
                            color: isPlaying ? Colors.white : Colors.pinkAccent,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.forward_10, size: 40),
                        color: Colors.pinkAccent,
                        onPressed: () =>
                            _seekAudio(_position + const Duration(seconds: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.pinkAccent.withOpacity(0.3)),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: _parsedTranscription
                                    .map<TextSpan>((segment) {
                                  final bool isImportant =
                                      _position >= segment["start"] &&
                                          _position <= segment["end"];
                                  Color textColor = isImportant
                                      ? Colors.black
                                      : Colors.black.withOpacity(0.5);
                                  return TextSpan(
                                    text: isImportant
                                        ? "\n${segment["text"]}\n\n"
                                        : "${segment["text"]}\n",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: isImportant
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: textColor,
                                      height: 1.5,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
/*import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String description;
  final String audioUrl;
  final String transcription;
  final String imageUrl;

  const PlayerScreen({
    Key? key,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.transcription,
    required this.imageUrl,
  }) : super(key: key);

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  bool isPlaying = false;
  bool isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool isSeeking = false;
  List<Map<String, dynamic>> _parsedTranscription = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAudio();
    _parseTranscription();

    _audioPlayer.durationStream.listen((d) {
      setState(() => _duration = d ?? Duration.zero);
    });

    _audioPlayer.positionStream.listen((p) {
      if (!isSeeking && (p - _position).inSeconds.abs() > 1) {
        setState(() => _position = p);
        _scrollToImportantText();
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          isPlaying = false;
          _position = _duration;
        });
      }
    });
  }

  Future<void> _setupAudio() async {
    setState(() => isLoading = true);
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception("Aucune connexion Internet.");
      }
      print("🌐 Connectivité vérifiée : $connectivityResult");

      if (widget.audioUrl.isEmpty || !Uri.parse(widget.audioUrl).isAbsolute) {
        throw Exception("URL audio vide ou invalide : ${widget.audioUrl}");
      }
      print("📡 Chargement de l'URL audio : ${widget.audioUrl}");

      await _audioPlayer.setUrl(widget.audioUrl);
      print("✅ Audio chargé avec succès. Durée : ${_audioPlayer.duration}");
    } on PlayerException catch (e, stackTrace) {
      print("❌ PlayerException : ${e.message}, code : ${e.code}");
      print("📜 StackTrace : $stackTrace");
      setState(() {
        errorMessage = "Erreur audio : ${e.message}";
      });
      _showErrorSnackBar(errorMessage!);
    } catch (e, stackTrace) {
      print("❌ Erreur lors du chargement de l'audio : $e");
      print("📜 StackTrace : $stackTrace");
      setState(() {
        errorMessage = "Erreur lors du chargement de l'audio : $e";
      });
      _showErrorSnackBar(errorMessage!);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Réessayer',
          onPressed: _setupAudio,
        ),
      ),
    );
  }

  void _togglePlayPause() async {
    setState(() {
      isPlaying = !isPlaying;
    });

    try {
      if (isPlaying) {
        await _audioPlayer.play();
        print("▶️ Lecture du podcast démarrée.");
      } else {
        await _audioPlayer.pause();
        print("⏸️ Lecture du podcast en pause.");
      }
    } catch (e, stackTrace) {
      print("❌ Erreur lors de la lecture/pause : $e");
      print("📜 StackTrace : $stackTrace");
      setState(() {
        isPlaying = false;
        errorMessage = "Erreur lors de la lecture du podcast : $e";
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  Future<void> _seekAudio(Duration position) async {
    try {
      isSeeking = true;
      await _audioPlayer.seek(position);
      setState(() => _position = position);
      print("⏩ Position du podcast modifiée : ${position.inSeconds} secondes");
    } catch (e, stackTrace) {
      print("❌ Erreur lors du déplacement : $e");
      print("📜 StackTrace : $stackTrace");
      setState(() {
        errorMessage = "Erreur lors du déplacement dans le podcast : $e";
      });
      _showErrorSnackBar(errorMessage!);
    } finally {
      isSeeking = false;
    }
  }

  void _parseTranscription() {
    RegExp regex = RegExp(r'\[(\d+):(\d+).(\d+) --> (\d+):(\d+).(\d+)\] (.+)');
    _parsedTranscription = regex
        .allMatches(widget.transcription)
        .map((match) => {
              "start": Duration(
                  minutes: int.parse(match.group(1)!),
                  seconds: int.parse(match.group(2)!),
                  milliseconds: int.parse(match.group(3)!)),
              "end": Duration(
                  minutes: int.parse(match.group(4)!),
                  seconds: int.parse(match.group(5)!),
                  milliseconds: int.parse(match.group(6)!)),
              "text": match.group(7)!,
            })
        .toList();
    print("📝 Transcription parsée : ${_parsedTranscription.length} segments");
  }

  void _scrollToImportantText() {
    if (_scrollController.hasClients) {
      int importantIndex = _parsedTranscription.indexWhere((segment) =>
          _position >= segment["start"] && _position <= segment["end"]);

      if (importantIndex != -1) {
        double scrollPosition = importantIndex * 60.0;
        _scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        print("📜 Défilement vers le segment : $importantIndex");
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.pinkAccent,
              ),
            )
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: widget.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.imageUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print(
                                    "❌ Erreur de chargement de l'image : ${widget.imageUrl}, erreur : $error");
                                return const Icon(
                                  Icons.broken_image,
                                  size: 80,
                                  color: Colors.grey,
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: const Center(
                                      child: CircularProgressIndicator()),
                                );
                              },
                            )
                          : const Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: isPlaying ? 24 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    child: Text(widget.title),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.description,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    activeColor: Colors.pinkAccent,
                    inactiveColor: Colors.grey,
                    min: 0,
                    max: _duration.inSeconds > 0
                        ? _duration.inSeconds.toDouble()
                        : 1,
                    value: _position.inSeconds
                        .toDouble()
                        .clamp(0, _duration.inSeconds.toDouble()),
                    onChanged: (value) {
                      setState(
                          () => _position = Duration(seconds: value.toInt()));
                    },
                    onChangeEnd: (value) async {
                      await _seekAudio(Duration(seconds: value.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, size: 40),
                        color: Colors.pinkAccent,
                        onPressed: () =>
                            _seekAudio(_position - const Duration(seconds: 10)),
                      ),
                      const SizedBox(width: 20),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isPlaying ? Colors.pinkAccent : Colors.grey[300],
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 60,
                            color: isPlaying ? Colors.white : Colors.pinkAccent,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.forward_10, size: 40),
                        color: Colors.pinkAccent,
                        onPressed: () =>
                            _seekAudio(_position + const Duration(seconds: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.pinkAccent.withOpacity(0.3)),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: _parsedTranscription
                                    .map<TextSpan>((segment) {
                                  final bool isImportant =
                                      _position >= segment["start"] &&
                                          _position <= segment["end"];
                                  Color textColor = isImportant
                                      ? Colors.black
                                      : Colors.black.withOpacity(0.5);
                                  return TextSpan(
                                    text: isImportant
                                        ? "\n${segment["text"]}\n\n"
                                        : "${segment["text"]}\n",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: isImportant
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: textColor,
                                      height: 1.5,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
*/
/*import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String description;
  final String audioUrl;
  final String transcription;
  final String imageUrl;

  const PlayerScreen({
    Key? key,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.transcription,
    required this.imageUrl,
  }) : super(key: key);

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  bool isPlaying = false;
  bool isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool isSeeking = false;
  List<Map<String, dynamic>> _parsedTranscription = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _setupAudio();
    _parseTranscription();

    _audioPlayer.durationStream.listen((d) {
      setState(() => _duration = d ?? Duration.zero);
    });

    _audioPlayer.positionStream.listen((p) {
      if (!isSeeking && (p - _position).inSeconds.abs() > 1) {
        setState(() => _position = p);
        _scrollToImportantText();
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          isPlaying = false;
          _position = _duration;
        });
      }
    });
  }

  Future<void> _checkPermissions() async {
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
  }

  Future<void> _setupAudio() async {
    setState(() => isLoading = true);
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception("No internet connection");
      }

      if (widget.audioUrl.isEmpty || !Uri.parse(widget.audioUrl).isAbsolute) {
        throw Exception("Invalid or empty audio URL: ${widget.audioUrl}");
      }

      print("Loading audio URL: ${widget.audioUrl}");
      final uri = Uri.parse(widget.audioUrl);
      final response = await http.head(uri);
      print("HTTP Response: ${response.statusCode} - ${response.reasonPhrase}");
      if (response.statusCode != 200) {
        throw Exception("HTTP error: ${response.statusCode}");
      }

      await _audioPlayer.setUrl(widget.audioUrl);
      print("Audio loaded successfully. Duration: ${_audioPlayer.duration}");
    } on PlayerException catch (e) {
      print("PlayerException: ${e.message}, code: ${e.code}");
      setState(() {
        errorMessage = "Audio error: ${e.message}";
        isLoading = false;
      });
      _showErrorSnackBar(errorMessage!);
    } catch (e, stackTrace) {
      print("Error loading audio: $e");
      print("StackTrace: $stackTrace");
      setState(() {
        errorMessage = "Error loading audio: $e";
        isLoading = false;
      });
      _showErrorSnackBar(errorMessage!);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _togglePlayPause() async {
    setState(() {
      isPlaying = !isPlaying;
    });

    try {
      if (isPlaying) {
        await _audioPlayer.play();
        print("Lecture du podcast démarrée.");
      } else {
        await _audioPlayer.pause();
        print("Lecture du podcast en pause.");
      }
    } catch (e) {
      setState(() {
        isPlaying = false;
        errorMessage = "Erreur lors de la lecture du podcast: $e";
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  Future<void> _seekAudio(Duration position) async {
    try {
      isSeeking = true;
      await _audioPlayer.seek(position);
      setState(() => _position = position);
      print("Position du podcast modifiée: ${position.inSeconds} secondes");
    } catch (e) {
      setState(() {
        errorMessage = "Erreur lors du déplacement dans le podcast: $e";
      });
      _showErrorSnackBar(errorMessage!);
    } finally {
      isSeeking = false;
    }
  }

  void _parseTranscription() {
    RegExp regex = RegExp(r'\[(\d+):(\d+).(\d+) --> (\d+):(\d+).(\d+)\] (.+)');
    _parsedTranscription = regex
        .allMatches(widget.transcription)
        .map((match) => {
              "start": Duration(
                  minutes: int.parse(match.group(1)!),
                  seconds: int.parse(match.group(2)!),
                  milliseconds: int.parse(match.group(3)!)),
              "end": Duration(
                  minutes: int.parse(match.group(4)!),
                  seconds: int.parse(match.group(5)!),
                  milliseconds: int.parse(match.group(6)!)),
              "text": match.group(7)!,
            })
        .toList();
  }

  void _scrollToImportantText() {
    if (_scrollController.hasClients) {
      int importantIndex = _parsedTranscription.indexWhere((segment) =>
          _position >= segment["start"] && _position <= segment["end"]);

      if (importantIndex != -1) {
        double scrollPosition = importantIndex * 60.0;
        _scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.pinkAccent,
              ),
            )
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        widget.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: isPlaying ? 24 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    child: Text(widget.title),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.description,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    activeColor: Colors.pinkAccent,
                    inactiveColor: Colors.grey,
                    min: 0,
                    max: _duration.inSeconds > 0
                        ? _duration.inSeconds.toDouble()
                        : 1,
                    value: _position.inSeconds
                        .toDouble()
                        .clamp(0, _duration.inSeconds.toDouble()),
                    onChanged: (value) {
                      setState(
                          () => _position = Duration(seconds: value.toInt()));
                    },
                    onChangeEnd: (value) async {
                      await _seekAudio(Duration(seconds: value.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, size: 40),
                        color: Colors.pinkAccent,
                        onPressed: () =>
                            _seekAudio(_position - const Duration(seconds: 10)),
                      ),
                      const SizedBox(width: 20),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isPlaying ? Colors.pinkAccent : Colors.grey[300],
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 60,
                            color: isPlaying ? Colors.white : Colors.pinkAccent,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.forward_10, size: 40),
                        color: Colors.pinkAccent,
                        onPressed: () =>
                            _seekAudio(_position + const Duration(seconds: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.pinkAccent.withOpacity(0.3)),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: _parsedTranscription
                                    .map<TextSpan>((segment) {
                                  final bool isImportant =
                                      _position >= segment["start"] &&
                                          _position <= segment["end"];
                                  Color textColor = isImportant
                                      ? Colors.black
                                      : Colors.black.withOpacity(0.5);
                                  return TextSpan(
                                    text: isImportant
                                        ? "\n${segment["text"]}\n\n"
                                        : "${segment["text"]}\n",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: isImportant
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: textColor,
                                      height: 1.5,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
*/