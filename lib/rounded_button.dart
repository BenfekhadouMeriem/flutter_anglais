import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final String btnText; // Texte du bouton
  final Color btnColor; // Couleur du bouton
  final Color textColor; // Couleur du texte
  final VoidCallback onPressed; // Fonction appelée lors de l'appui

  const RoundedButton({
    Key? key,
    required this.btnText,
    this.btnColor = Colors.blue, // Couleur par défaut
    this.textColor = Colors.white, // Couleur du texte par défaut
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor, // Couleur du bouton
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Arrondi
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 32, vertical: 12), // Espacement
      ),
      onPressed: onPressed, // Action à effectuer
      child: Text(
        btnText,
        style: TextStyle(
          color: textColor, // Couleur du texte
          fontSize: 16, // Taille de la police
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
