import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Screens/welcome_screen.dart';
import 'Screens/login_screen.dart';
import 'Screens/register_screen.dart';
import 'Screens/main_screen.dart';
import 'Screens/main_y_screen.dart';
import 'PagesY/games_page.dart';
import 'PagesY/memory_game.dart';
import 'PagesY/word_puzzle.dart';
import 'PagesY/flashcards.dart';
import 'PagesY/catch_the_word.dart';
import 'PagesY/spelling_bee.dart';
import 'PagesY/simon_says.dart';
import 'PagesY/color_the_word.dart';
import 'PagesY/create_monster.dart';
import 'PagesY/story_builder.dart';
import 'PagesY/find_object.dart';
import 'PagesY/repeat_after_me.dart';
import 'PagesY/sing_along.dart';
import 'PagesY/tap_and_learn.dart';
import 'PagesY/animal_sounds.dart';
import 'PagesY/placeholder_game.dart';

// Placeholder for video/audio creation
class PlaceholderCreationScreen extends StatelessWidget {
  final String title;

  const PlaceholderCreationScreen({Key? key, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.pink.shade300,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade100, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            '$title\n(This is a placeholder)',
            style: const TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    runApp(const MyApp());
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => MainScreen(),
        '/mainScreen': (context) => MainYScreen(),
        '/games': (context) => const GamesPage(),
        '/memory_game': (context) => const MemoryGameScreen(),
        '/word_puzzle': (context) => const WordPuzzleScreen(),
        '/flashcards': (context) => const FlashcardsScreen(),
        '/catch_the_word': (context) => const CatchTheWordScreen(),
        '/spelling_bee': (context) => const SpellingBeeScreen(),
        '/simon_says': (context) => const SimonSaysScreen(),
        '/color_the_word': (context) => const ColorTheWordScreen(),
        '/create_monster': (context) => const MonsterCreatorScreen(),
        '/story_builder': (context) => const StoryBuilderScreen(),
        '/find_object': (context) => const FindObjectScreen(),
        '/repeat_after_me': (context) => const RepeatAfterMeScreen(),
        '/sing_along': (context) => const SingAlongScreen(),
        '/tap_and_learn': (context) => const TapAndLearnScreen(),
        '/animal_sounds': (context) => const AnimalSoundsScreen(),
        '/video_creation': (context) =>
            const PlaceholderCreationScreen(title: 'Video Creation'),
        '/audio_recording': (context) =>
            const PlaceholderCreationScreen(title: 'Audio Recording'),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Route not found!')),
          ),
        );
      },
    );
  }
}
