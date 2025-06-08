import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Screens/categorypodcasts.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<dynamic> categories = [];
  bool isLoading = true;
  String errorMessage = '';
  List<String> invalidCategories = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _clearCache();
    _loadCachedCategories();
    fetchCategories();
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('categories_cache');
    print('🗑️ Cache des catégories supprimé');
  }

  Future<void> _loadCachedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('categories_cache');
    if (cachedData != null) {
      try {
        setState(() {
          categories = json.decode(cachedData);
          isLoading = false;
        });
        print("📂 Données en cache chargées : ${categories.length} catégories");
      } catch (e) {
        print('❌ Erreur de décodage du cache: $e');
        await prefs.remove('categories_cache');
      }
    } else {
      print("📂 Aucun cache trouvé");
    }
  }

  Future<void> _cacheCategories(List categories) async {
    final validCategories =
        categories.where((c) => c['name']?.isNotEmpty ?? false).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('categories_cache', json.encode(validCategories));
    print("💾 Catégories mises en cache : ${validCategories.length}");
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

Future<void> fetchCategories() async {
  setState(() => isLoading = true);
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('Aucune connexion réseau.');
    }
    print("🌐 Connectivité vérifiée : $connectivityResult");

    print("📡 Requête Firestore : select * from categories");
    final querySnapshot = await _firestore.collection('categories').get();
    print("📋 Réponse Firestore : ${querySnapshot.docs.length} catégories reçues");
    if (querySnapshot.docs.isEmpty) {
      throw Exception('Aucune catégorie trouvée.');
    }

    List<Map<String, dynamic>> enrichedCategories = [];
    invalidCategories.clear();

    for (var doc in querySnapshot.docs) {
      final category = doc.data();
      final Map<String, dynamic> converted = _convertData(category);
      final title = converted['name']?.toString() ?? '';
      final id = doc.id;

      if (title.isEmpty) {
        String issue = 'Catégorie $id (sans nom) ignorée : champ name manquant ou vide';
        invalidCategories.add(issue);
        print('⚠️ $issue');
        continue;
      }

      String imageUrl = converted['imageUrl']?.toString() ?? '';
      if (imageUrl.isNotEmpty) {
        imageUrl = _convertGoogleDriveUrl(imageUrl);
        if (imageUrl.isEmpty) {
          print('⚠️ URL image non valide pour $title après conversion');
        }
      } else {
        print('⚠️ imageUrl vide pour $title');
      }

      print("🔍 Comptage des podcasts pour la catégorie : $title");
      // Essayer avec une référence Firestore
      Query query = _firestore
          .collection('contents')
          .where('categoryId', isEqualTo: _firestore.doc('categories/$id'));

      int contentsCount = 0;
      try {
        final countSnapshot = await query.count().get();
        contentsCount = countSnapshot.count ?? 0;
      } catch (e) {
        print("❌ Erreur lors du comptage pour $title avec référence : $e");
        // Essayer avec une chaîne
        query = _firestore.collection('contents').where('categoryId', isEqualTo: id);
        final countSnapshot = await query.count().get();
        contentsCount = countSnapshot.count ?? 0;
      }

      print("📊 $title : $contentsCount podcasts");

      enrichedCategories.add({
        ...converted,
        'id': id,
        'imageUrl': imageUrl,
        'contents_count': contentsCount,
      });
    }

    if (enrichedCategories.isEmpty && invalidCategories.isNotEmpty) {
      throw Exception(
          'Aucune catégorie valide trouvée. Problèmes détectés :\n${invalidCategories.join('\n')}');
    }

    setState(() {
      categories = enrichedCategories;
      isLoading = false;
      errorMessage = '';
    });
    await _cacheCategories(categories);
    print("✅ Catégories récupérées avec succès : ${categories.length}");
  } catch (e, stackTrace) {
    print("❌ Erreur lors de la récupération des catégories : $e");
    print("📜 StackTrace : $stackTrace");
    setState(() {
      errorMessage = 'Impossible de charger les catégories : $e';
      isLoading = false;
    });
  }
}
  Map<String, dynamic> _convertData(Map<String, dynamic> data) {
    final converted = <String, dynamic>{};
    for (final key in data.keys) {
      final value = data[key];
      if (value == null) {
        converted[key] = null;
      } else if (value is Timestamp) {
        converted[key] = value.toDate().toString();
      } else if (value is DocumentReference) {
        converted[key] = value.id; // Convertir la référence en ID
      } else if (value is GeoPoint) {
        converted[key] = {'lat': value.latitude, 'lng': value.longitude};
      } else if (value is List) {
        converted[key] = _convertList(value);
      } else if (value is Map) {
        converted[key] = _convertData(value as Map<String, dynamic>);
      } else {
        converted[key] = value;
      }
    }
    return converted;
  }

  dynamic _convertList(List list) {
    return list.map((item) {
      if (item is Timestamp) {
        return item.toDate().toString();
      } else if (item is DocumentReference) {
        return item.id;
      } else if (item is Map) {
        return _convertData(item as Map<String, dynamic>);
      }
      return item;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchCategories,
          child: _buildBody(size),
        ),
      ),
    );
  }

  Widget _buildBody(Size size) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage,
              style: TextStyle(color: Colors.red, fontSize: size.width * 0.04),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.02),
            ElevatedButton(
              onPressed: fetchCategories,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (categories.isEmpty) {
      return Center(
        child: Text(
          'Aucune catégorie disponible',
          style: TextStyle(fontSize: size.width * 0.04),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: size.height * 0.05),
        Padding(
          padding: EdgeInsets.only(left: size.width * 0.04),
          child: Text(
            'All Category',
            style: TextStyle(
              fontSize: size.width * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.015),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(size.width * 0.04),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: size.width * 0.03,
              mainAxisSpacing: size.height * 0.02,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) =>
                _buildCategoryCard(categories[index], size),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, Size size) {
    final title = category['name']?.toString() ?? 'Inconnue';
    final imageUrl = category['imageUrl']?.toString() ?? '';
    final contentsCount = category['contents_count'] ?? 0;
    final categoryId = category['id'];

    return GestureDetector(
      onTap: () {
        if (contentsCount > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryPodcastsPage(
                  categoryId: categoryId, categoryTitle: title),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aucun podcast disponible pour $title'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print(
                              "❌ Erreur de chargement de l'image : $imageUrl, erreur : $error");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Erreur de chargement de l\'image pour $title'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          return _buildPlaceholderIcon(size);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                      )
                    : _buildPlaceholderIcon(size),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size.width * 0.02),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: size.width * 0.04,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$contentsCount podcast${contentsCount > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: size.width * 0.03),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(Size size) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: size.width * 0.1,
          color: Colors.grey,
        ),
      ),
    );
  }
}
/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../Screens/categorypodcasts.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<dynamic> categories = [];
  bool isLoading = true;
  String errorMessage = '';
  List<String> invalidCategories =
      []; // Pour stocker les catégories problématiques
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _clearCache();
    _loadCachedCategories();
    fetchCategories();
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('categories_cache');
    print('🗑️ Cache des catégories supprimé');
  }

  Future<void> _loadCachedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('categories_cache');
    if (cachedData != null) {
      try {
        setState(() {
          categories = json.decode(cachedData);
          isLoading = false;
        });
        print("📂 Données en cache chargées : ${categories.length} catégories");
      } catch (e) {
        print('❌ Erreur de décodage du cache: $e');
        await prefs.remove('categories_cache');
      }
    } else {
      print("📂 Aucun cache trouvé");
    }
  }

  Future<void> _cacheCategories(List categories) async {
    final validCategories =
        categories.where((c) => c['name']?.isNotEmpty ?? false).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('categories_cache', json.encode(validCategories));
    print("💾 Catégories mises en cache : ${validCategories.length}");
  }

  Future<void> fetchCategories() async {
    setState(() => isLoading = true);
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('Aucune connexion réseau.');
      }
      print("🌐 Connectivité vérifiée : $connectivityResult");

      print("📡 Requête Supabase : select * from categories");
      final categoryData = await supabase.from('categories').select();
      print("📋 Réponse Supabase : ${categoryData.length} catégories reçues");
      if (categoryData.isEmpty) {
        throw Exception('Aucune catégorie trouvée.');
      }

      List<Map<String, dynamic>> enrichedCategories = [];
      invalidCategories.clear();

      for (var category in categoryData) {
        final Map<String, dynamic> converted =
            Map<String, dynamic>.from(category);
        final title = converted['name']?.toString() ?? '';
        final id = converted['id']?.toString() ?? converted.hashCode.toString();

        // Valider le nom de la catégorie
        if (title.isEmpty) {
          String issue =
              'Catégorie $id (sans nom) ignorée : champ name manquant ou vide';
          invalidCategories.add(issue);
          print('⚠️ $issue');
          continue;
        }

        // Résoudre l'URL de l'image
        String imageUrl = converted['image']?.toString() ?? '';
        if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          try {
            imageUrl = supabase.storage.from('images').getPublicUrl(imageUrl);
            print('✅ URL image résolue pour $title: $imageUrl');
          } catch (e) {
            print('❌ Erreur lors de la résolution de image pour $title: $e');
            imageUrl = '';
          }
        }

        // Compter les podcasts associés
        print("🔍 Comptage des podcasts pour la catégorie : $title");
        final countData = await supabase
            .from('contents')
            .select('id')
            .eq('category_id', converted['id'])
            .count();
        enrichedCategories.add({
          ...converted,
          'image': imageUrl,
          'contents_count': countData.count,
        });
        print("📊 $title : ${countData.count} podcasts");
      }

      if (enrichedCategories.isEmpty && invalidCategories.isNotEmpty) {
        throw Exception(
            'Aucune catégorie valide trouvée. Problèmes détectés :\n${invalidCategories.join('\n')}');
      }

      setState(() {
        categories = enrichedCategories;
        isLoading = false;
        errorMessage = '';
      });
      await _cacheCategories(categories);
      print("✅ Catégories récupérées avec succès : ${categories.length}");
    } catch (e, stackTrace) {
      print("❌ Erreur lors de la récupération des catégories : $e");
      print("📜 StackTrace : $stackTrace");
      setState(() {
        errorMessage = 'Impossible de charger les catégories : $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchCategories,
          child: _buildBody(size),
        ),
      ),
    );
  }

  Widget _buildBody(Size size) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage,
              style: TextStyle(color: Colors.red, fontSize: size.width * 0.04),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.02),
            ElevatedButton(
              onPressed: fetchCategories,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (categories.isEmpty) {
      return Center(
        child: Text(
          'Aucune catégorie disponible',
          style: TextStyle(fontSize: size.width * 0.04),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: size.height * 0.05),
        Padding(
          padding: EdgeInsets.only(left: size.width * 0.04),
          child: Text(
            'All Category',
            style: TextStyle(
              fontSize: size.width * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.015),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(size.width * 0.04),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: size.width * 0.03,
              mainAxisSpacing: size.height * 0.02,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) =>
                _buildCategoryCard(categories[index], size),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, Size size) {
    final title = category['name']?.toString() ?? 'Inconnue';
    final imageUrl = category['image']?.toString() ?? '';
    final contentsCount = category['contents_count'] ?? 0;
    final categoryId = category['id'];

    return GestureDetector(
      onTap: () {
        if (contentsCount > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryPodcastsPage(
                  categoryId: categoryId, categoryTitle: title),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aucun podcast disponible pour $title'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print(
                              "❌ Erreur de chargement de l'image : $imageUrl, erreur : $error");
                          return _buildPlaceholderIcon(size);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                      )
                    : _buildPlaceholderIcon(size),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size.width * 0.02),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: size.width * 0.04,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$contentsCount podcast${contentsCount > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: size.width * 0.03),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(Size size) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: size.width * 0.1,
          color: Colors.grey,
        ),
      ),
    );
  }
}*/
/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../Screens/categorypodcasts.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<dynamic> categories = [];
  bool isLoading = true;
  String errorMessage = '';
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadCachedCategories();
    fetchCategories();
  }

  Future<void> _loadCachedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('categories_cache');
    if (cachedData != null) {
      setState(() {
        categories = json.decode(cachedData);
        isLoading = false;
      });
      print("📂 Données en cache chargées : ${categories.length} catégories");
    } else {
      print("📂 Aucun cache trouvé");
    }
  }

  Future<void> _cacheCategories(List categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('categories_cache', json.encode(categories));
    print("💾 Catégories mises en cache : ${categories.length}");
  }

  Future<void> fetchCategories() async {
    setState(() => isLoading = true);
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('Aucune connexion réseau.');
      }
      print("🌐 Connectivité vérifiée : $connectivityResult");

      print("📡 Requête Supabase : select * from categories");
      final categoryData = await supabase.from('categories').select();
      print("📋 Réponse Supabase : ${categoryData.length} catégories reçues");
      if (categoryData.isEmpty) {
        throw Exception('Aucune catégorie trouvée.');
      }

      List<Map<String, dynamic>> enrichedCategories = [];
      for (var category in categoryData) {
        print(
            "🔍 Comptage des podcasts pour la catégorie : ${category['name']}");
        final countData = await supabase
            .from('contents')
            .select('id')
            .eq('category_id', category['id'])
            .count();
        enrichedCategories.add({
          ...category,
          'contents_count': countData.count,
        });
        print("📊 ${category['name']} : ${countData.count} podcasts");
      }

      setState(() {
        categories = enrichedCategories;
        isLoading = false;
        errorMessage = '';
      });
      await _cacheCategories(categories);
      print("✅ Catégories récupérées avec succès : ${categories.length}");
    } catch (e, stackTrace) {
      print("❌ Erreur lors de la récupération des catégories : $e");
      print("📜 StackTrace : $stackTrace");
      setState(() {
        errorMessage = 'Impossible de charger les catégories : $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchCategories,
          child: _buildBody(size),
        ),
      ),
    );
  }

  Widget _buildBody(Size size) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage,
              style: TextStyle(color: Colors.red, fontSize: size.width * 0.04),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.02),
            ElevatedButton(
              onPressed: fetchCategories,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (categories.isEmpty) {
      return Center(
        child: Text(
          'Aucune catégorie disponible',
          style: TextStyle(fontSize: size.width * 0.04),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: size.height * 0.05),
        Padding(
          padding: EdgeInsets.only(left: size.width * 0.04),
          child: Text(
            'All Category',
            style: TextStyle(
              fontSize: size.width * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.015),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(size.width * 0.04),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: size.width * 0.03,
              mainAxisSpacing: size.height * 0.02,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) =>
                _buildCategoryCard(categories[index], size),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, Size size) {
    final title = category['name']?.toString() ?? 'Inconnue';
    final imageUrl = category['image']?.toString() ?? '';
    final contentsCount = category['contents_count'] ?? 0;
    final categoryId = category['id'];

    return GestureDetector(
      onTap: () {
        if (contentsCount > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryPodcastsPage(
                  categoryId: categoryId, categoryTitle: title),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aucun podcast disponible pour $title'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print(
                              "❌ Erreur de chargement de l'image : $imageUrl, erreur : $error");
                          return _buildPlaceholderIcon(size);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                      )
                    : _buildPlaceholderIcon(size),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size.width * 0.02),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: size.width * 0.04,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$contentsCount podcast${contentsCount > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: size.width * 0.03),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(Size size) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: size.width * 0.1,
          color: Colors.grey,
        ),
      ),
    );
  }
}*/

/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../Screens/categorypodcasts.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<dynamic> categories = [];
  bool isLoading = true;
  String errorMessage = '';
  final String baseUrl = 'http://192.168.100.186:8000';

  @override
  void initState() {
    super.initState();
    _loadCachedCategories(); // Load cached data first
    fetchCategories();
  }

  // Load categories from cache
  Future<void> _loadCachedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('categories_cache');
    if (cachedData != null) {
      setState(() {
        categories = json.decode(cachedData);
        isLoading = false;
      });
    }
  }

  // Save categories to cache
  Future<void> _cacheCategories(List categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('categories_cache', json.encode(categories));
  }

  Future<void> fetchCategories() async {
    // Check network connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        errorMessage =
            'Aucune connexion réseau. Veuillez vérifier votre connexion.';
        isLoading = false;
      });
      return;
    }

    final String apiUrl = '$baseUrl/api/categories';
    const int maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final startTime = DateTime.now();
        final response = await http.get(Uri.parse(apiUrl)).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception(
                'Délai de connexion dépassé. Serveur lent ou inaccessible.');
          },
        );
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        print("⏱️ Temps de réponse: $duration ms");
        print("Réponse API: ${response.body}");

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          final categoryList = jsonData['categories'] ?? jsonData['data'] ?? [];

          if (categoryList.isEmpty) {
            throw Exception(
                'Aucune catégorie trouvée dans la réponse de l\'API.');
          }

          setState(() {
            categories = categoryList;
            isLoading = false;
            errorMessage = '';
          });
          await _cacheCategories(categories);
          print("📋 Catégories récupérées: ${categories.length}");
          return; // Success, exit the loop
        } else {
          throw Exception(
              'Erreur serveur: ${response.statusCode} - ${response.reasonPhrase}');
        }
      } catch (e, stackTrace) {
        print("❌ Tentative ${attempt + 1}: Erreur: $e");
        print("Stack trace: $stackTrace");
        attempt++;
        if (attempt == maxRetries) {
          setState(() {
            errorMessage = 'Impossible de charger les catégories : $e';
            isLoading = false;
          });
        }
        await Future.delayed(const Duration(seconds: 2)); // Delay before retry
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchCategories,
          child: _buildBody(size),
        ),
      ),
    );
  }

  Widget _buildBody(Size size) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage,
              style: TextStyle(color: Colors.red, fontSize: size.width * 0.04),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.02),
            ElevatedButton(
              onPressed: fetchCategories,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (categories.isEmpty) {
      return Center(
        child: Text(
          'Aucune catégorie disponible',
          style: TextStyle(fontSize: size.width * 0.04),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Alignement à gauche pour toute la colonne
      children: [
        SizedBox(height: size.height * 0.05),
        Padding(
          padding: EdgeInsets.only(
              left: size.width * 0.04), // Marge à gauche pour le texte
          child: Text(
            'All Category',
            style: TextStyle(
              fontSize: size.width * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.015),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(size.width * 0.04),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: size.width * 0.03,
              mainAxisSpacing: size.height * 0.02,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) =>
                _buildCategoryCard(categories[index], size),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, Size size) {
    final title = category['name']?.toString() ?? 'Inconnue';
    final imageUrl = category['image']?.toString() ?? '';
    final contentsCount = category['contents_count'] ?? 0;

    // Construct image URL
    final imgUrl = imageUrl.isNotEmpty
        ? imageUrl.startsWith('http')
            ? imageUrl
            : imageUrl.startsWith('/')
                ? '$baseUrl$imageUrl'
                : '$baseUrl/$imageUrl'
        : null;

    return GestureDetector(
      onTap: () {
        if (contentsCount > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryPodcastsPage(categoryTitle: title),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aucun podcast disponible pour $title'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: imgUrl != null
                    ? Image.network(
                        imgUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderIcon(size),
                      )
                    : _buildPlaceholderIcon(size),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size.width * 0.02),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: size.width * 0.04,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$contentsCount podcast${contentsCount > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: size.width * 0.03),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(Size size) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: size.width * 0.1,
          color: Colors.grey,
        ),
      ),
    );
  }
}
*/