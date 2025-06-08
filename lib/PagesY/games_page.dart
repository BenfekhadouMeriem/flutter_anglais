import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({Key? key}) : super(key: key);

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  final List<Map<String, dynamic>> games = const [
    {
      'title': 'Memory Game',
      'description': '', //Match images with English words.
      'image': 'assets/games/memory.png',
      'route': '/memory_game',
    },
    {
      'title': 'Word Puzzle',
      'description': '', //Unscramble letters to form words.
      'image': 'assets/games/puzzle.png',
      'route': '/word_puzzle',
    },
    {
      'title': 'Flashcards',
      'description': '', //See image, hear word, select it.
      'image': 'assets/games/flashcards.png',
      'route': '/flashcards',
    },
    {
      'title': 'Catch the Word',
      'description': '', //Catch falling words that match images.
      'image': 'assets/games/catch.png',
      'route': '/catch_the_word',
    },
    {
      'title': 'Spelling Bee',
      'description': '', //Spell words after hearing them.
      'image': 'assets/games/spelling.png',
      'route': '/spelling_bee',
    },
    {
      'title': 'Simon Says',
      'description': '', //Follow instructions like "Simon says...".
      'image': 'assets/games/simon.png',
      'route': '/simon_says',
    },
    {
      'title': 'Color the Word',
      'description': '', //Color objects based on words.
      'image': 'assets/games/color.png',
      'route': '/color_the_word',
    },
    {
      'title': 'Create your Monster',
      'description': '', //Build a monster with parts.
      'image': 'assets/games/monster.png',
      'route': '/create_monster',
    },
    {
      'title': 'Story Builder',
      'description': '', //Create fun short stories.
      'image': 'assets/games/story.png',
      'route': '/story_builder',
    },
    {
      'title': 'Find the Object',
      'description': '', //Find objects in scenes.
      'image': 'assets/games/find.png',
      'route': '/find_object',
    },
    {
      'title': 'Repeat After Me',
      'description': '', //Repeat short English phrases.
      'image': 'assets/games/repeat.png',
      'route': '/repeat_after_me',
    },
    {
      'title': 'Sing Along Karaoke',
      'description': '', //Sing songs with lyrics.
      'image': 'assets/games/karaoke.png',
      'route': '/sing_along',
    },
    {
      'title': 'Tap and Learn',
      'description': '', //Tap images to learn words.
      'image': 'assets/games/tap.png',
      'route': '/tap_and_learn',
    },
    {
      'title': 'Animal Sounds',
      'description': '', //Match animal sounds to names.
      'image': 'assets/games/animals.png',
      'route': '/animal_sounds',
    },
  ];

  String _searchQuery = '';
  String? _lastPlayedGame;

  @override
  void initState() {
    super.initState();
    _loadLastPlayedGame();
  }

  Future<void> _loadLastPlayedGame() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastPlayedGame = prefs.getString('last_played_game');
    });
  }

  Future<void> _saveLastPlayedGame(String title) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_played_game', title);
    setState(() {
      _lastPlayedGame = title;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredGames = games
        .where((game) =>
            game['title'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fun Games',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.pink.shade300,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade100, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search games...',
                  prefixIcon: Icon(Icons.search, color: Colors.pink.shade300),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.75,
                ),
                itemCount: filteredGames.length,
                itemBuilder: (context, index) {
                  final game = filteredGames[index];
                  return GameCard(
                    title: game['title'],
                    description: game['description'],
                    imagePath: game['image'],
                    route: game['route'],
                    isLastPlayed: game['title'] == _lastPlayedGame,
                    onTap: () => _saveLastPlayedGame(game['title']),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final String route;
  final bool isLastPlayed;
  final VoidCallback onTap;

  const GameCard({
    Key? key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.route,
    this.isLastPlayed = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        Navigator.pushNamed(context, route);
      },
      child: Card(
        elevation: 6.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: isLastPlayed
              ? const BorderSide(color: Colors.green, width: 2.0)
              : BorderSide.none,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(
                  imagePath,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (isLastPlayed)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Last Played',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
