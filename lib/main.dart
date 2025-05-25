import 'package:flutter/material.dart';
import 'package:flutter_anglais/Screens/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Fichier généré automatiquement

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:flutter_anglais/Screens/welcome_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async {
  // Assure que les widgets Flutter sont initialisés
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Supabase
  await Supabase.initialize(
    url:
        'https://rvgtqingqikiodtylcww.supabase.co', // Remplace par ton URL Supabase
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ2Z3RxaW5ncWlraW9kdHlsY3d3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxODkwNTUsImV4cCI6MjA2MDc2NTA1NX0.LpxgRk9dbTeGbdCdIqladluaVJBlJQkbp_Mn4vh2ziM', // Remplace par ta clé publique (anon key)
  );

  runApp(const MyApp());
}

/*void main() {
  runApp(const MyApp());
}*/

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}
*/