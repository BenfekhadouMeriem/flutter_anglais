import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//const String baseURL = "http://192.168.100.186:8000/api/"; //emulator localhost

//Constantes pour Supabase
const String supabaseUrl =
    'https://rvgtqingqikiodtylcww.supabase.co'; // Remplace par ton URL Supabase
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ2Z3RxaW5ncWlraW9kdHlsY3d3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxODkwNTUsImV4cCI6MjA2MDc2NTA1NX0.LpxgRk9dbTeGbdCdIqladluaVJBlJQkbp_Mn4vh2ziM'; // Remplace par ta clé publique

const Map<String, String> headers = {"Content-Type": "application/json"};

errorSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: Colors.red,
    content: Text(text),
    duration: const Duration(seconds: 1),
  ));
}
