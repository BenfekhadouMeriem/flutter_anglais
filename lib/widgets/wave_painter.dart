import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Peinture pour la vague rose (couleur principale)
    Paint pinkPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.pink.shade300, // Couleur principale de la vague rose
          Colors.pink.shade200,
          Colors.pink.shade100,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Peinture pour la vague violette (arrière-plan)
    Paint purplePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.purple
              .shade200, // Couleur de la vague violette (moins dominante)
          Colors.purple.shade100,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Vague rose : monte et descend (couleur principale)
    Path pinkPath = Path();
    pinkPath.moveTo(0, size.height * 0.35); // Départ à 45% de la hauteur
    pinkPath.quadraticBezierTo(
      size.width * 0.2, size.height * 0.23, // Contrôle
      size.width * 0.45,
      size.height * 0.3, // Point d'arrivée (mouvement vers le haut)
    );
    pinkPath.quadraticBezierTo(
      size.width * 0.8, size.height * 0.4, // Contrôle
      size.width, size.height * 0.3, // Retour à 45% de la hauteur
    );
    pinkPath.lineTo(size.width, 0); // Monter jusqu'en haut à droite
    pinkPath.lineTo(0, 0); // Retour au point de départ
    pinkPath.close();

    // Vague violette : suit la rose mais inversée, en arrière-plan
    Path purplePath = Path();
    purplePath.moveTo(
        0, size.height * 0.34); // Départ à 45% de la hauteur (même que la rose)
    purplePath.quadraticBezierTo(
      size.width * 0.13,
      size.height * 0.27, // Contrôle inversé : descend lorsque rose monte
      size.width * 0.47,
      size.height * 0.33, // Point d'arrivée (descend alors que la rose monte)
    );
    purplePath.quadraticBezierTo(
      size.width * 0.8, size.height * 0.4, // Contrôle inversé
      size.width, size.height * 0.25, // Retour à 45% de la hauteur
    );
    purplePath.lineTo(size.width, 0); // Monter jusqu'en haut à droite
    purplePath.lineTo(0, 0); // Retour au point de départ
    purplePath.close();

    // Dessiner les vagues
    canvas.drawPath(
        purplePath, purplePaint); // Dessiner la vague violette en arrière-plan
    canvas.drawPath(pinkPath, pinkPaint); // Dessiner la vague rose au-dessus
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
