import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'lire_player_screen.dart'; // Assurez-vous que LirePlayerScreen est défini ici

class CategoryPodcastsPage extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;

  const CategoryPodcastsPage({
    Key? key,
    required this.categoryId,
    required this.categoryTitle,
  }) : super(key: key);

  @override
  _CategoryPodcastsPageState createState() => _CategoryPodcastsPageState();
}

class _CategoryPodcastsPageState extends State<CategoryPodcastsPage> {
  List<dynamic> podcasts = [];
  bool isLoading = true;
  bool isRefreshing = false;
  String errorMessage = '';
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchCategoryPodcasts();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Implémenter le chargement supplémentaire si nécessaire
    }
  }

  String _convertGoogleDriveUrl(String url) {
    if (url.isEmpty) {
      print('⚠️ URL vide reçue');
      return '';
    }

    if (url.contains('drive.google.com/uc') ||
        !url.contains('drive.google.com')) {
      print('🔗 URL directe ou non-Google Drive : $url');
      return url;
    }

    final RegExp regex = RegExp(r'file/d/([a-zA-Z0-9_-]+)/view');
    final match = regex.firstMatch(url);
    if (match != null) {
      final fileId = match.group(1);
      final convertedUrl = 'https://drive.google.com/uc?id=$fileId';
      print('🔄 URL convertie : $url -> $convertedUrl');
      return convertedUrl;
    }

    print('⚠️ URL Google Drive non reconnue : $url');
    return '';
  }

  Future<void> fetchCategoryPodcasts() async {
    setState(() => isRefreshing = true);
    try {
      print(
          "🌐 Vérification de la connectivité pour la catégorie ID : ${widget.categoryId}");
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('Aucune connexion Internet.');
      }
      print("✅ Connectivité : $connectivityResult");

      print(
          "📡 Requête Firestore : select * from contents where categoryId = /categories/${widget.categoryId}");
      final querySnapshot = await _firestore
          .collection('contents')
          .where('categoryId',
              isEqualTo: _firestore.doc('categories/${widget.categoryId}'))
          .get();
      print(
          "📋 Réponse Firestore : ${querySnapshot.docs.length} podcasts reçus");

      if (querySnapshot.docs.isEmpty) {
        throw Exception(
            'Aucun podcast trouvé pour la catégorie ${widget.categoryTitle}.');
      }

      final convertedData = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title']?.toString() ?? 'Podcast',
          'description': data['description']?.toString() ?? '',
          'file_path':
              _convertGoogleDriveUrl(data['audioUrl']?.toString() ?? ''),
          'image_path':
              _convertGoogleDriveUrl(data['imageUrl']?.toString() ?? ''),
          'transcription': data['transcription']?.toString() ?? '',
          'isFree': data['isFree'] ?? false,
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate().toString() ?? '',
        };
      }).toList();

      setState(() {
        podcasts = convertedData;
        errorMessage = '';
        isLoading = false;
        isRefreshing = false;
      });
      print("✅ Podcasts récupérés avec succès : ${podcasts.length}");
    } catch (e, stackTrace) {
      print("❌ Erreur lors de la récupération des podcasts : $e");
      print("📜 StackTrace : $stackTrace");
      setState(() {
        errorMessage = 'Erreur : $e';
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Widget _buildBody(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: size.height * 0.02),
            Text(
              'Chargement des podcasts...',
              style: TextStyle(
                fontSize: size.width * 0.04,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: size.width * 0.15,
              color: Colors.red[400],
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: size.width * 0.04,
                color: Colors.red[400],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.03),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.06,
                  vertical: size.height * 0.015,
                ),
              ),
              onPressed: fetchCategoryPodcasts,
            ),
          ],
        ),
      );
    }

    if (podcasts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.audiotrack,
              size: size.width * 0.2,
              color: Colors.grey[400],
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              'Aucun podcast disponible',
              style: TextStyle(
                fontSize: size.width * 0.045,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'dans cette catégorie',
              style: TextStyle(
                fontSize: size.width * 0.045,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchCategoryPodcasts,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: size.height * 0.05),
          Padding(
            padding: EdgeInsets.fromLTRB(
              size.width * 0.05,
              size.height * 0.02,
              size.width * 0.05,
              size.height * 0.01,
            ),
            child: Text(
              'All Podcasts',
              style: TextStyle(
                fontSize: size.width * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: size.height * 0.015),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                left: size.width * 0.03,
                right: size.width * 0.03,
                bottom: size.height * 0.03,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: podcasts.length,
              itemBuilder: (context, index) => _buildPodcastItem(
                podcasts[index],
                context,
                index == podcasts.length - 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodcastItem(
      Map<String, dynamic> podcast, BuildContext context, bool isLastItem) {
    final size = MediaQuery.of(context).size;
    final title = podcast['title']?.toString() ?? 'Podcast';
    final description = podcast['description']?.toString() ?? '';
    final audioPath = podcast['file_path']?.toString() ?? '';
    final imagePath = podcast['image_path']?.toString() ?? '';
    final transcription = podcast['transcription']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(
        bottom: isLastItem ? size.height * 0.03 : size.height * 0.01,
      ),
      child: Card(
        elevation: 1,
        margin: EdgeInsets.symmetric(
          vertical: size.height * 0.005,
          horizontal: size.width * 0.02,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (audioPath.isEmpty || !Uri.parse(audioPath).isAbsolute) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Fichier audio invalide ou introuvable !'),
                ),
              );
              return;
            }
            print(
                "Navigating to LirePlayerScreen with: title=$title, audioUrl=$audioPath, transcription=$transcription, imageUrl=$imagePath");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LirePlayerScreen(
                  title: title,
                  audioUrl: audioPath,
                  transcription: transcription,
                  imageUrl: imagePath,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: size.height * 0.005,
              horizontal: size.width * 0.02,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: imagePath.isNotEmpty
                      ? Image.network(
                          imagePath,
                          width: size.width * 0.15,
                          height: size.width * 0.15,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print(
                                "❌ Erreur de chargement de l'image : $imagePath, erreur : $error");
                            return SizedBox(
                              width: size.width * 0.15,
                              height: size.width * 0.15,
                              child: Icon(
                                Icons.image_not_supported,
                                size: size.width * 0.05,
                                color: Colors.grey,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: size.width * 0.15,
                              height: size.width * 0.15,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        )
                      : SizedBox(
                          width: size.width * 0.15,
                          height: size.width * 0.15,
                          child: Icon(
                            Icons.audiotrack,
                            size: size.width * 0.05,
                            color: Colors.grey,
                          ),
                        ),
                ),
                SizedBox(width: size.width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: size.width * 0.035,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: size.height * 0.003),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: size.width * 0.03,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: size.height * 0.003),
                      Icon(
                        Icons.favorite_border,
                        color: Colors.grey,
                        size: size.width * 0.04,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.play_circle_fill,
                    size: size.width * 0.07,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    if (audioPath.isEmpty || !Uri.parse(audioPath).isAbsolute) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('❌ Fichier audio invalide ou introuvable !'),
                        ),
                      );
                      return;
                    }
                    print(
                        "Navigating to LirePlayerScreen with: title=$title, audioUrl=$audioPath, transcription=$transcription, imageUrl=$imagePath");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LirePlayerScreen(
                          title: title,
                          audioUrl: audioPath,
                          transcription: transcription,
                          imageUrl: imagePath,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(Size size) {
    return Container(
      width: size.width * 0.18,
      height: size.width * 0.18,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.audiotrack,
          size: size.width * 0.08,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isRefreshing ? Colors.grey : Colors.black,
            ),
            onPressed: isRefreshing ? null : fetchCategoryPodcasts,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }
}
