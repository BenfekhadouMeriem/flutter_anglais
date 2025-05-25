import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'player_screen.dart';
import 'dart:ui';

import '../Pages/video_page.dart';
import '../Pages/voice_page.dart';
import '../Pages/menu_page.dart';
import '../Pages/chat_page.dart';
import '../Pages/profile_page.dart';

class AccueilScreen extends StatefulWidget {
  const AccueilScreen({Key? key}) : super(key: key);

  @override
  _AccueilScreenState createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  List podcasts = [];
  List filteredPodcasts = [];
  bool isLoading = true;
  String errorMessage = '';
  String searchQuery = '';

  final GlobalKey<CurvedNavigationBarState> _curvedNavigationKey = GlobalKey();
  int _intpage = 0;
  bool _isMenuOpen = false; // Contrôle du menu contextuel

  bool _isSearching = false; // Contrôle de la recherche
  final TextEditingController _searchController = TextEditingController();

  List<String> pageNames = ["Vidéo", "Audio", "Add", "Ai Chat", "Profil"];

  @override
  void initState() {
    super.initState();
    fetchPodcasts();
  }

  Future<void> fetchPodcasts() async {
    const String apiUrl = 'http://192.168.100.186:8000/api/contents';

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          podcasts = jsonData['contents'] ?? [];
          filteredPodcasts = podcasts;
          isLoading = false;
        });
        print("📢 Podcasts récupérés: $podcasts");
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.pink.shade200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.account_circle, size: 60, color: Colors.white),
                SizedBox(height: 10),
                Text("Bienvenue !",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                Text("user@example.com",
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.black),
            title: const Text("Accueil"),
            onTap: () {
              Navigator.pop(context); // Ferme le menu
              print("Accueil sélectionné");
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.black),
            title: const Text("Profil"),
            onTap: () {
              Navigator.pop(context);
              print("Profil sélectionné");
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.black),
            title: const Text("Paramètres"),
            onTap: () {
              Navigator.pop(context);
              print("Paramètres sélectionnés");
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Déconnexion"),
            onTap: () {
              Navigator.pop(context);
              print("Déconnexion effectuée");
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher...',
                  border: InputBorder.none,
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
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
          const SizedBox(width: 16),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      drawer: _buildDrawer(context), // Menu latéral

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            // 🎥 Section Vidéo Principale
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                image: const DecorationImage(
                  image: AssetImage('assets/microphone.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: ClipRRect(
                      // Nécessaire pour appliquer le flou
                      borderRadius: BorderRadius.circular(8),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: 7, sigmaY: 7), // Flou de 5px
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black
                                .withOpacity(0.2), // Légère transparence
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Practice your English',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.play_circle_fill,
                        size: 50, color: Colors.white),
                  ),
                  const Positioned(
                    bottom: 16,
                    right: 16,
                    child: Icon(Icons.favorite_border, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 📢 Trending Podcasts
            const Text('Trending Podcast',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // 📻 Liste de Podcasts
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Text(errorMessage,
                            style: const TextStyle(color: Colors.red)),
                      )
                    : ListView.builder(
                        shrinkWrap:
                            true, // Important pour éviter l'erreur de dimension
                        physics:
                            const NeverScrollableScrollPhysics(), // Empêche le scroll dans un `SingleChildScrollView`
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

                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imagePath.isNotEmpty
                                  ? Image.network(
                                      imgUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: Icon(Icons.image_not_supported,
                                              size: 50, color: Colors.grey),
                                        );
                                      },
                                    )
                                  : const SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: Icon(Icons.image,
                                          size: 50, color: Colors.grey),
                                    ),
                            ),
                            title: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 2.0,
                                    color: Colors.grey,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(
                                    height:
                                        5), // Espace entre la description et l'icône ❤️
                                const Icon(Icons.favorite_border,
                                    color: Colors.grey, size: 20),
                              ],
                            ),
                            trailing: StatefulBuilder(
                              builder: (context, setState) {
                                return IconButton(
                                  icon: Icon(
                                    Icons.play_circle_fill,
                                    size: 37,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    if (fullUrl.isEmpty ||
                                        !fullUrl.startsWith("http")) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                '❌ Fichier audio introuvable !')),
                                      );
                                      return;
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlayerScreen(
                                          title: title,
                                          description: description,
                                          audioUrl: fullUrl,
                                          transcription: transcription,
                                          imageUrl: imgUrl,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),

      // 🏠 Bottom Navigation Bar Stylisée
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Fond arrondi
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(35)), // Arrondi en haut
              child: Container(
                height: 70.0,
                color: Colors.white, // Même couleur que la navbar
              ),
            ),
          ),

          // Barre de navigation courbée
          CurvedNavigationBar(
            key: _curvedNavigationKey,
            index: _intpage,
            height: 70.0,
            items: List.generate(5, (index) {
              bool isSelected = _intpage == index ||
                  (_isMenuOpen && index == 2 && _isMenuOpen);

              return GestureDetector(
                onTap: () {
                  // Définis ici les pages correspondant à chaque index
                  List<Widget> pages = [
                    VideoPage(), // Page pour l'icône videocam
                    VoicePage(), // Page pour l'icône settings_voice
                    MenuPage(), // Page pour l'icône add/cancel
                    ChatPage(), // Page pour l'icône question_answer
                    ProfilePage(), // Page pour l'icône person
                  ];

                  // Vérifie que l'index est valide avant de naviguer
                  if (index >= 0 && index < pages.length) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => pages[index]),
                    );
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      [
                        Icons.videocam_outlined,
                        Icons.settings_voice_outlined,
                        _isMenuOpen
                            ? Icons.cancel_outlined
                            : Icons.add_circle_outline,
                        Icons.question_answer_outlined,
                        Icons.person_outlined
                      ][index],
                      size: index == 2 ? 30 : 25,
                      color: isSelected
                          ? Colors.white
                          : (_intpage == index ? Colors.white : Colors.black),
                    ),
                    SizedBox(height: 2),
                    Text(
                      pageNames[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            color: Colors.transparent, // Transparent pour afficher l'arrondi
            buttonBackgroundColor: Colors.pink.shade300,
            backgroundColor: Colors.transparent,
            animationCurve: Curves.easeInOut,
            animationDuration: Duration(milliseconds: 600),
            onTap: (index) {
              setState(() {
                if (index == 2) {
                  _isMenuOpen =
                      !_isMenuOpen; // Ouvrir/Fermer le menu vidéo/micro
                  _intpage =
                      2; // Forcer la sélection pour que seul "Ajouter" reste blanc
                } else {
                  _intpage = index;
                  _isMenuOpen = false; // Cacher le menu si on clique ailleurs
                }
              });
            },
            letIndexChange: (index) => true,
          ),
        ],
      ),

      // 🎛️ Floating Action Button (Menu Flottant)
      floatingActionButton: _isMenuOpen
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.pink.shade300,
                    child: const Icon(Icons.videocam, color: Colors.white),
                    onPressed: () {
                      // Action pour vidéo
                    },
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.pink.shade300,
                    child: const Icon(Icons.mic, color: Colors.white),
                    onPressed: () {
                      // Action pour micro
                    },
                  ),
                ],
              ),
            )
          : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // 🎭 Fonction pour récupérer l'icône selon l'index
  IconData _getIconForPage(int index) {
    switch (index) {
      case 0:
        return Icons.videocam;
      case 1:
        return Icons.settings_voice;
      case 2:
        return Icons.add_circle;
      case 3:
        return Icons.question_answer;
      case 4:
        return Icons.person;
      default:
        return Icons.help;
    }
  }

  // 🎵 Widget pour un élément de podcast
  Widget podcastTile(
      String title, String subtitle, String imagePath, bool isPink) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.asset(imagePath, width: 90, height: 90, fit: BoxFit.cover),
      ),
      title: Text(title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 35,
          )),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12, // Taille du sous-titre
        ),
      ),
      trailing: Icon(Icons.play_circle_fill,
          color: isPink ? Colors.pink : Colors.black),
    );
  }
}

// fonction pour ouvrir le menu
void _openMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.home, color: Colors.black),
            title: Text("Accueil"),
            onTap: () {
              Navigator.pop(context);
              print("Accueil sélectionné");
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: Colors.black),
            title: Text("Profil"),
            onTap: () {
              Navigator.pop(context);
              print("Profil sélectionné");
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.black),
            title: Text("Paramètres"),
            onTap: () {
              Navigator.pop(context);
              print("Paramètres sélectionnés");
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Déconnexion"),
            onTap: () {
              Navigator.pop(context);
              print("Déconnexion effectuée");
            },
          ),
        ],
      );
    },
  );
}
