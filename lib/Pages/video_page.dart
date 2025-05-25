import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Screens/player_screen.dart';
import 'dart:ui';
import '../widgets/custom_drawer.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({Key? key}) : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  List podcasts = [];
  List filteredPodcasts = [];
  bool isLoading = true;
  String errorMessage = '';
  String searchQuery = '';

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _clearCache(); // Supprimer le cache au démarrage
    _loadCachedPodcasts();
    fetchPodcasts();
    _searchController.addListener(() {
      _filterPodcasts(_searchController.text);
    });
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('podcasts_cache');
    print('🗑️ Cache supprimé');
  }

  Future<void> _loadCachedPodcasts() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('podcasts_cache');
    if (cachedData != null) {
      try {
        setState(() {
          podcasts = json.decode(cachedData);
          filteredPodcasts = podcasts
              .where((p) => p['audioUrl']?.isNotEmpty ?? false)
              .toList();
          isLoading = false;
        });
        print('📂 Podcasts chargés depuis le cache : ${podcasts.length}');
      } catch (e) {
        print('❌ Erreur de décodage du cache: $e');
        await prefs.remove('podcasts_cache');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _convertPodcasts(
      List<QueryDocumentSnapshot> docs) async {
    final List<Map<String, dynamic>> result = [];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      print('📄 Traitement du document ${doc.id} : $data');
      final converted = <String, dynamic>{};

      for (final key in data.keys) {
        final value = data[key];
        if (value == null) {
          converted[key] = null;
        } else if (value is Timestamp) {
          converted[key] = value.toDate().toString();
        } else if (value is DocumentReference) {
          converted[key] = value.path;
        } else if (value is GeoPoint) {
          converted[key] = {'lat': value.latitude, 'lng': value.longitude};
        } else if (value is List) {
          converted[key] = _convertList(value);
        } else {
          converted[key] = value;
        }
      }

      String audioUrl = converted['audioUrl'] ?? '';
      String imageUrl = converted['imageUrl'] ?? '';

      if (audioUrl.isEmpty) {
        print('⚠️ Document ${doc.id} : audioUrl manquant ou vide');
      }

      result.add({
        'id': doc.id,
        ...converted,
        'audioUrl': audioUrl,
        'imageUrl': imageUrl,
      });
    }

    print('📋 ${result.length} podcasts récupérés');
    return result;
  }

  dynamic _convertList(List list) {
    return list.map((item) {
      if (item is Timestamp) {
        return item.toDate().toString();
      } else if (item is DocumentReference) {
        return item.path;
      } else if (item is Map) {
        return _convertMap(item);
      }
      return item;
    }).toList();
  }

  dynamic _convertMap(Map map) {
    return map.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toString());
      } else if (value is DocumentReference) {
        return MapEntry(key, value.path);
      }
      return MapEntry(key, value);
    });
  }

  Future<void> _cachePodcasts(List<Map<String, dynamic>> podcasts) async {
    final validPodcasts =
        podcasts.where((p) => p['audioUrl']?.isNotEmpty ?? false).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('podcasts_cache', json.encode(validPodcasts));
    print('💾 ${validPodcasts.length} podcasts mis en cache');
  }

  Future<void> fetchPodcasts() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        errorMessage =
            'Aucune connexion réseau. Veuillez vérifier votre connexion.';
        isLoading = false;
      });
      return;
    }

    try {
      final querySnapshot = await _firestore.collection('contents').get();
      if (querySnapshot.docs.isEmpty) {
        throw Exception('Aucun podcast trouvé.');
      }
      final podcastsData = await _convertPodcasts(querySnapshot.docs);

      setState(() {
        podcasts = podcastsData;
        filteredPodcasts = podcasts;
        isLoading = false;
        if (podcasts.isEmpty) {
          errorMessage =
              'Aucun podcast valide trouvé. Vérifiez les données Firestore.';
        }
      });

      await _cachePodcasts(podcastsData);
    } catch (e) {
      print("❌ Erreur: $e");
      setState(() {
        errorMessage = 'Impossible de charger les podcasts : $e';
        isLoading = false;
      });
    }
  }

  void _filterPodcasts(String query) {
    setState(() {
      searchQuery = query;
      filteredPodcasts = podcasts
          .where((podcast) =>
              podcast['title']
                  ?.toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ??
              false)
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                style: const TextStyle(color: Colors.black),
              )
            : const Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.black),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filterPodcasts('');
                }
              });
            },
          ),
          const SizedBox(width: 16),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: fetchPodcasts,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.03),
              Container(
                height: screenHeight * 0.25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: AssetImage('assets/microphone.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      left: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Practice your English',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: screenWidth * 0.12,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: screenWidth * 0.06,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Text(
                'Trending Podcast',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                errorMessage,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              ElevatedButton(
                                onPressed: fetchPodcasts,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : filteredPodcasts.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun podcast trouvé.',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredPodcasts.length,
                              itemBuilder: (context, index) {
                                final podcast = filteredPodcasts[index];
                                final filePath =
                                    podcast['audioUrl']?.toString() ?? '';
                                final imagePath =
                                    podcast['imageUrl']?.toString() ?? '';
                                final title =
                                    podcast['title']?.toString() ?? 'Podcast';
                                final description =
                                    podcast['description']?.toString() ??
                                        'Aucune description';
                                final transcription =
                                    podcast['transcription']?.toString() ?? '';

                                return Card(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: size.height * 0.005),
                                    child: ListTile(
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: imagePath.isNotEmpty
                                            ? Image.network(
                                                imagePath,
                                                width: size.width * 0.15,
                                                height: size.width * 0.15,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  print(
                                                      '❌ Erreur chargement image: $error pour $imagePath');
                                                  return SizedBox(
                                                    width: size.width * 0.15,
                                                    height: size.width * 0.15,
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                      size: 40,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                },
                                              )
                                            : SizedBox(
                                                width: size.width * 0.15,
                                                height: size.width * 0.15,
                                                child: const Icon(
                                                  Icons.image,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                      ),
                                      title: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: size.width * 0.035,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: size.width * 0.03),
                                          ),
                                          SizedBox(height: size.height * 0.003),
                                          const Icon(
                                            Icons.favorite_border,
                                            color: Colors.grey,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                      trailing: StatefulBuilder(
                                        builder: (context, setState) {
                                          return IconButton(
                                            icon: Icon(
                                              Icons.play_circle_fill,
                                              size: size.width * 0.07,
                                              color: Colors.black,
                                            ),
                                            onPressed: () {
                                              if (filePath.isEmpty) {
                                                print(
                                                    '❌ audioUrl vide pour $title: $filePath');
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        '❌ Fichier audio introuvable pour $title. Vérifiez audioUrl dans Firestore.'),
                                                  ),
                                                );
                                                return;
                                              }
                                              print(
                                                  '▶️ Navigation vers PlayerScreen avec audioUrl: $filePath');
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PlayerScreen(
                                                    title: title,
                                                    description: description,
                                                    audioUrl: filePath,
                                                    transcription:
                                                        transcription,
                                                    imageUrl: imagePath,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ],
          ),
        ),
      ),
    );
  }
}
/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Screens/player_screen.dart';
import 'dart:ui';
import '../widgets/custom_drawer.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({Key? key}) : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  List podcasts = [];
  List filteredPodcasts = [];
  bool isLoading = true;
  String errorMessage = '';
  String searchQuery = '';

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadCachedPodcasts();
    fetchPodcasts();
    _searchController.addListener(() {
      _filterPodcasts(_searchController.text);
    });
  }

  Future<void> _loadCachedPodcasts() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('podcasts_cache');
    if (cachedData != null) {
      setState(() {
        podcasts = json.decode(cachedData);
        filteredPodcasts = podcasts;
        isLoading = false;
      });
    }
  }

  Future<void> _cachePodcasts(List podcasts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('podcasts_cache', json.encode(podcasts));
  }

  Future<void> fetchPodcasts() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        errorMessage =
            'Aucune connexion réseau. Veuillez vérifier votre connexion.';
        isLoading = false;
      });
      return;
    }

    try {
      final data = await supabase.from('contents').select();
      if (data.isEmpty) {
        throw Exception('Aucun podcast trouvé.');
      }
      setState(() {
        podcasts = data;
        print('Podcasts in VideoPage: $podcasts'); // Débogage
        filteredPodcasts = podcasts;
        isLoading = false;
      });
      await _cachePodcasts(podcasts);
    } catch (e) {
      print("❌ Erreur: $e");
      setState(() {
        errorMessage = 'Impossible de charger les podcasts : $e';
        isLoading = false;
      });
    }
  }

  void _filterPodcasts(String query) {
    setState(() {
      searchQuery = query;
      filteredPodcasts = podcasts
          .where((podcast) =>
              podcast['title']
                  ?.toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ??
              false)
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                style: const TextStyle(color: Colors.black),
              )
            : const Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.black),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filterPodcasts('');
                }
              });
            },
          ),
          const SizedBox(width: 16),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: fetchPodcasts,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.03),
              Container(
                height: screenHeight * 0.25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: AssetImage('assets/microphone.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      left: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Practice your English',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: screenWidth * 0.12,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: screenWidth * 0.06,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Text(
                'Trending Podcast',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                errorMessage,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              ElevatedButton(
                                onPressed: fetchPodcasts,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : filteredPodcasts.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun podcast trouvé.',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredPodcasts.length,
                              itemBuilder: (context, index) {
                                final podcast = filteredPodcasts[index];
                                final filePath =
                                    podcast['file_path']?.toString() ?? '';
                                final imagePath =
                                    podcast['image_path']?.toString() ?? '';
                                final title =
                                    podcast['title']?.toString() ?? 'Podcast';
                                final description =
                                    podcast['description']?.toString() ??
                                        'Aucune description';
                                final transcription =
                                    podcast['transcription']?.toString() ?? '';

                                return Card(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: size.height * 0.005),
                                    child: ListTile(
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: imagePath.isNotEmpty
                                            ? Image.network(
                                                imagePath,
                                                width: size.width * 0.15,
                                                height: size.width * 0.15,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return SizedBox(
                                                    width: size.width * 0.15,
                                                    height: size.width * 0.15,
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                      size: 40,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                },
                                              )
                                            : SizedBox(
                                                width: size.width * 0.15,
                                                height: size.width * 0.15,
                                                child: const Icon(
                                                  Icons.image,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                      ),
                                      title: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: size.width * 0.035,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: size.width * 0.03),
                                          ),
                                          SizedBox(height: size.height * 0.003),
                                          const Icon(
                                            Icons.favorite_border,
                                            color: Colors.grey,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                      trailing: StatefulBuilder(
                                        builder: (context, setState) {
                                          return IconButton(
                                            icon: Icon(
                                              Icons.play_circle_fill,
                                              size: size.width * 0.07,
                                              color: Colors.black,
                                            ),
                                            onPressed: () {
                                              if (filePath.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        '❌ Fichier audio introuvable !'),
                                                  ),
                                                );
                                                return;
                                              }
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PlayerScreen(
                                                    title: title,
                                                    description: description,
                                                    audioUrl: filePath,
                                                    transcription:
                                                        transcription,
                                                    imageUrl: imagePath,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ],
          ),
        ),
      ),
    );
  }
}
*/

/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Screens/player_screen.dart';
import 'dart:ui';
import '../widgets/custom_drawer.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({Key? key}) : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  List podcasts = [];
  List filteredPodcasts = [];
  bool isLoading = true;
  String errorMessage = '';
  String searchQuery = '';

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCachedPodcasts();
    fetchPodcasts();
    _searchController.addListener(() {
      _filterPodcasts(_searchController.text);
    });
  }

  Future<void> _loadCachedPodcasts() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('podcasts_cache');
    if (cachedData != null) {
      setState(() {
        podcasts = json.decode(cachedData);
        filteredPodcasts = podcasts;
        isLoading = false;
      });
    }
  }

  Future<void> _cachePodcasts(List podcasts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('podcasts_cache', json.encode(podcasts));
  }

  Future<void> fetchPodcasts() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        errorMessage =
            'Aucune connexion réseau. Veuillez vérifier votre connexion.';
        isLoading = false;
      });
      return;
    }

    const String apiUrl = 'http://192.168.100.186:8000/api/contents';

    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Délai de connexion dépassé. Serveur lent ou inaccessible.');
        },
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          podcasts = jsonData['contents'] ?? [];
          print('Podcasts in VideoPage: $podcasts'); // Débogage
          filteredPodcasts = podcasts;
          isLoading = false;
        });
        await _cachePodcasts(podcasts);
      } else {
        setState(() {
          errorMessage = 'Erreur serveur: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Erreur: $e");
      setState(() {
        errorMessage = 'Impossible de charger les podcasts : $e';
        isLoading = false;
      });
    }
  }

  void _filterPodcasts(String query) {
    setState(() {
      searchQuery = query;
      filteredPodcasts = podcasts
          .where((podcast) =>
              podcast['title'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                style: const TextStyle(color: Colors.black),
              )
            : const Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.black),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filterPodcasts('');
                }
              });
            },
          ),
          const SizedBox(width: 16),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: fetchPodcasts,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.03),
              Container(
                height: screenHeight * 0.25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: AssetImage('assets/microphone.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      left: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Practice your English',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: screenWidth * 0.12,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: screenWidth * 0.06,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Text(
                'Trending Podcast',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                errorMessage,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              ElevatedButton(
                                onPressed: fetchPodcasts,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : filteredPodcasts.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun podcast trouvé.',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredPodcasts.length,
                              itemBuilder: (context, index) {
                                final podcast = filteredPodcasts[index];
                                final filePath =
                                    podcast['file_path']?.toString() ?? '';
                                final imagePath =
                                    podcast['image_path']?.toString() ?? '';
                                final title =
                                    podcast['title']?.toString() ?? 'Podcast';
                                final description =
                                    podcast['description']?.toString() ??
                                        'Aucune description';
                                final transcription =
                                    podcast['transcription']?.toString() ?? '';

                                final fullUrl = filePath.startsWith("http")
                                    ? filePath
                                    : "http://192.168.100.186:8000$filePath";

                                final imgUrl = imagePath.isNotEmpty &&
                                        !imagePath.startsWith("http")
                                    ? "http://192.168.100.186:8000${imagePath.startsWith('/') ? '' : '/'}$imagePath"
                                    : imagePath;

                                return Card(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical:
                                            size.height * 0.005), // réduit
                                    child: ListTile(
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            6), // légèrement réduit
                                        child: imagePath.isNotEmpty
                                            ? Image.network(
                                                imgUrl,
                                                width:
                                                    size.width * 0.15, // réduit
                                                height: size.width * 0.15,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return SizedBox(
                                                    width: size.width * 0.15,
                                                    height: size.width * 0.15,
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                      size: 40,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                },
                                              )
                                            : SizedBox(
                                                width: size.width * 0.15,
                                                height: size.width * 0.15,
                                                child: const Icon(
                                                  Icons.image,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                      ),
                                      title: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              size.width * 0.035, // réduit
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: size.width *
                                                    0.03), // réduit
                                          ),
                                          SizedBox(height: size.height * 0.003),
                                          const Icon(
                                            Icons.favorite_border,
                                            color: Colors.grey,
                                            size: 18, // réduit
                                          ),
                                        ],
                                      ),
                                      trailing: StatefulBuilder(
                                        builder: (context, setState) {
                                          return IconButton(
                                            icon: Icon(
                                              Icons.play_circle_fill,
                                              size: size.width * 0.07, // réduit
                                              color: Colors.black,
                                            ),
                                            onPressed: () {
                                              if (fullUrl.isEmpty ||
                                                  !fullUrl.startsWith("http")) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        '❌ Fichier audio introuvable !'),
                                                  ),
                                                );
                                                return;
                                              }
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PlayerScreen(
                                                    title: title,
                                                    description: description,
                                                    audioUrl: fullUrl,
                                                    transcription:
                                                        transcription,
                                                    imageUrl: imgUrl,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ],
          ),
        ),
      ),
    );
  }
}
*/