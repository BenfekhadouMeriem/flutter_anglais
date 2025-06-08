import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Inscription avec email/mot de passe
  static Future<User?> register(
      String name, String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Mise à jour du nom d'utilisateur
      await userCredential.user?.updateDisplayName(name);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Erreur d'inscription: ${e.message}");
      return null;
    }
  }

  // Connexion avec email/mot de passe
  static Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Erreur de connexion: ${e.message}");
      return null;
    }
  }

  // Déconnexion
  static Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Erreur lors de la déconnexion: $e");
      rethrow; // Propager l'erreur pour la gérer dans l'appelant
    }
  }

  // Récupérer l'utilisateur actuel
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
}

/*import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthServices {
  static final supabase = Supabase.instance.client;

  // Inscription avec email et mot de passe
  static Future<void> register(
      String name, String email, String password) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name}, // Stocke le nom dans les métadonnées utilisateur
      );
      if (response.user == null) {
        throw Exception('Échec de l\'inscription : utilisateur non créé.');
      }
    } catch (e) {
      throw Exception('Erreur d\'inscription : $e');
    }
  }

  // Connexion avec email et mot de passe
  static Future<void> login(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw Exception('Échec de la connexion : utilisateur non trouvé.');
      }
    } catch (e) {
      throw Exception('Erreur de connexion : $e');
    }
  }

  // Connexion avec Google
  static Future<void> signInWithGoogle() async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.flutter_anglais://login-callback/',
      );
    } catch (e) {
      throw Exception('Erreur Google Sign-In : $e');
    }
  }

  // Connexion avec Facebook
  static Future<void> signInWithFacebook() async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'com.example.flutter_anglais://login-callback/',
      );
    } catch (e) {
      throw Exception('Erreur Facebook Sign-In : $e');
    }
  }
}*/

/*import 'dart:convert';

import 'package:flutter_anglais/Services/globals.dart';
import 'package:http/http.dart' as http;

class AuthServices {
  static Future<http.Response> register(String name, String email,
      String password, String passwordConfirmation) async {
    Map data = {
      "name": name,
      "email": email,
      "password": password,
      'password_confirmation': passwordConfirmation,
    };
    var body = json.encode(data);
    var url = Uri.parse(baseURL + 'auth/register');
    http.Response response = await http.post(
      url,
      headers: headers,
      body: body,
    );
    print(response.body);
    return response;
  }

  static Future<http.Response> login(String email, String password) async {
    Map data = {
      "email": email,
      "password": password,
    };
    var body = json.encode(data);
    var url = Uri.parse(baseURL + 'auth/login');
    http.Response response = await http.post(
      url,
      headers: headers,
      body: body,
    );
    print(response.body);
    return response;
  }
}
*/