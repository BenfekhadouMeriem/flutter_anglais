import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final double waveHeight; // Hauteur dynamique des vagues
  final double waveOffset; // Décalage dynamique des vagues

  WavePainter({required this.waveHeight, required this.waveOffset});

  @override
  void paint(Canvas canvas, Size size) {
    // Peinture pour la vague rose
    Paint pinkPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.pink.shade300,
          Colors.pink.shade200,
          Colors.pink.shade100,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Peinture pour la vague violette
    Paint purplePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.purple.shade200,
          Colors.purple.shade100,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Vague rose : proportion principale
    Path pinkPath = Path();
    pinkPath.moveTo(
        0,
        size.height * (waveHeight + 0.35) +
            waveOffset); // Départ à 35% de la hauteur
    pinkPath.quadraticBezierTo(
      size.width * 0.2,
      size.height * (waveHeight + 0.23) + waveOffset, // Contrôle
      size.width * 0.45,
      size.height * (waveHeight + 0.3) + waveOffset, // Point d'arrivée
    );
    pinkPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * (waveHeight + 0.4) + waveOffset, // Contrôle
      size.width,
      size.height * (waveHeight + 0.35) + waveOffset, // Retour
    );
    pinkPath.lineTo(size.width, 0); // Monter jusqu'en haut
    pinkPath.lineTo(0, 0); // Retour au point de départ
    pinkPath.close();

    // Vague violette : plus discrète
    Path purplePath = Path();
    purplePath.moveTo(
        0,
        size.height * (waveHeight + 0.34) +
            waveOffset); // Départ à 34% de la hauteur
    purplePath.quadraticBezierTo(
      size.width * 0.13,
      size.height * (waveHeight + 0.27) + waveOffset, // Contrôle
      size.width * 0.47,
      size.height * (waveHeight + 0.33) + waveOffset, // Point d'arrivée
    );
    purplePath.quadraticBezierTo(
      size.width * 0.8,
      size.height * (waveHeight + 0.4) + waveOffset, // Contrôle
      size.width,
      size.height * (waveHeight + 0.25) + waveOffset, // Retour
    );
    purplePath.lineTo(size.width, 0); // Monter jusqu'en haut
    purplePath.lineTo(0, 0); // Retour au point de départ
    purplePath.close();

    // Dessiner les vagues
    canvas.drawPath(purplePath, purplePaint); // Vague violette
    canvas.drawPath(pinkPath, pinkPaint); // Vague rose
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true; // Toujours repeindre pour refléter les changements dynamiques
  }
}

/*import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final double waveHeight; // Hauteur dynamique des vagues
  final double waveOffset; // Décalage dynamique des vagues

  WavePainter({required this.waveHeight, required this.waveOffset});

  @override
  void paint(Canvas canvas, Size size) {
    // Peinture pour la vague rose
    Paint pinkPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.pink.shade300,
          Colors.pink.shade200,
          Colors.pink.shade100,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Peinture pour la vague violette
    Paint purplePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.purple.shade200,
          Colors.purple.shade100,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Vague rose : proportion principale
    Path pinkPath = Path();
    pinkPath.moveTo(
        0,
        size.height * (waveHeight + 0.35) +
            waveOffset); // Départ à 35% de la hauteur
    pinkPath.quadraticBezierTo(
      size.width * 0.2,
      size.height * (waveHeight + 0.23) + waveOffset, // Contrôle
      size.width * 0.45,
      size.height * (waveHeight + 0.3) + waveOffset, // Point d'arrivée
    );
    pinkPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * (waveHeight + 0.4) + waveOffset, // Contrôle
      size.width,
      size.height * (waveHeight + 0.35) + waveOffset, // Retour
    );
    pinkPath.lineTo(size.width, 0); // Monter jusqu'en haut
    pinkPath.lineTo(0, 0); // Retour au point de départ
    pinkPath.close();

    // Vague violette : plus discrète
    Path purplePath = Path();
    purplePath.moveTo(
        0,
        size.height * (waveHeight + 0.34) +
            waveOffset); // Départ à 34% de la hauteur
    purplePath.quadraticBezierTo(
      size.width * 0.13,
      size.height * (waveHeight + 0.27) + waveOffset, // Contrôle
      size.width * 0.47,
      size.height * (waveHeight + 0.33) + waveOffset, // Point d'arrivée
    );
    purplePath.quadraticBezierTo(
      size.width * 0.8,
      size.height * (waveHeight + 0.4) + waveOffset, // Contrôle
      size.width,
      size.height * (waveHeight + 0.25) + waveOffset, // Retour
    );
    purplePath.lineTo(size.width, 0); // Monter jusqu'en haut
    purplePath.lineTo(0, 0); // Retour au point de départ
    purplePath.close();

    // Dessiner les vagues
    canvas.drawPath(purplePath, purplePaint); // Vague violette
    canvas.drawPath(pinkPath, pinkPaint); // Vague rose
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true; // Toujours repeindre pour refléter les changements dynamiques
  }
}
*/


/*class WavePainter extends CustomPainter {
  final double waveHeight; // Paramètre pour la hauteur dynamique des vagues
  final double waveOffset; // Paramètre pour le décalage dynamique des vagues

  WavePainter({required this.waveHeight, required this.waveOffset});

  @override
  void paint(Canvas canvas, Size size) {
    // Peinture pour la vague rose (couleur principale)
    Paint pinkPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.pink.shade300,
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
          Colors.purple.shade200,
          Colors.purple.shade100,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Vague rose : monte et descend (couleur principale)
    Path pinkPath = Path();
    pinkPath.moveTo(
        0, size.height * waveHeight + waveOffset); // Ajout du décalage
    pinkPath.quadraticBezierTo(
      size.width * 0.2,
      size.height * (waveHeight - 0.1) +
          waveOffset, // Contrôle : légèrement plus haut
      size.width * 0.45,
      size.height * (waveHeight - 0.05) + waveOffset, // Point d'arrivée
    );
    pinkPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * (waveHeight + 0.05) +
          waveOffset, // Contrôle : légèrement plus bas
      size.width,
      size.height * waveHeight + waveOffset, // Retour à la hauteur dynamique
    );
    pinkPath.lineTo(size.width, 0); // Monter jusqu'en haut à droite
    pinkPath.lineTo(0, 0); // Retour au point de départ
    pinkPath.close();

    // Vague violette : suit la vague rose mais inversée, en arrière-plan
    Path purplePath = Path();
    purplePath.moveTo(0,
        size.height * 0.80 + waveOffset); // Départ à 80% de la hauteur, ajusté
    purplePath.quadraticBezierTo(
      size.width * 0.13,
      size.height * 0.72 + waveOffset, // Contrôle inversé : point plus bas
      size.width * 0.47,
      size.height * 0.79 + waveOffset, // Point d'arrivée
    );
    purplePath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.85 + waveOffset, // Contrôle inversé : point plus bas
      size.width,
      size.height * 0.80 + waveOffset, // Retour à 80% de la hauteur
    );
    purplePath.lineTo(size.width, 0); // Monter jusqu'en haut à droite
    purplePath.lineTo(0, 0); // Retour au point de départ
    purplePath.close();

    // Dessiner les vagues
    canvas.drawPath(
        purplePath, purplePaint); // Dessiner la vague violette (arrière-plan)
    canvas.drawPath(pinkPath, pinkPaint); // Dessiner la vague rose (au-dessus)
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}*/



/*class WavePainter extends CustomPainter {
  final double waveHeight; // Paramètre pour la hauteur dynamique des vagues

  WavePainter({required this.waveHeight});

  @override
  void paint(Canvas canvas, Size size) {
    Paint pinkPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.pink.shade300,
          Colors.pink.shade200,
          Colors.pink.shade100
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    Path pinkPath = Path();
    pinkPath.moveTo(0, size.height * waveHeight); // Hauteur dynamique
    pinkPath.quadraticBezierTo(size.width * 0.5,
        size.height * (waveHeight - 0.1), size.width, size.height * waveHeight);
    pinkPath.lineTo(size.width, 0);
    pinkPath.lineTo(0, 0);
    pinkPath.close();

    canvas.drawPath(pinkPath, pinkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

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
          Colors.purple.shade200, // Couleur de la vague violette
          Colors.purple.shade100,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Vague rose : monte et descend (couleur principale)
    Path pinkPath = Path();
    pinkPath.moveTo(0, size.height * 0.8); // Départ à 80% de la hauteur
    pinkPath.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.7, // Contrôle : légèrement plus haut
      size.width * 0.45,
      size.height * 0.75, // Point d'arrivée
    );
    pinkPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.85, // Contrôle : légèrement plus bas
      size.width,
      size.height * 0.8, // Retour à 80% de la hauteur
    );
    pinkPath.lineTo(size.width, 0); // Monter jusqu'en haut à droite
    pinkPath.lineTo(0, 0); // Retour au point de départ
    pinkPath.close();

    // Vague violette : suit la rose mais inversée, en arrière-plan
    Path purplePath = Path();
    purplePath.moveTo(0, size.height * 0.80); // Départ à 78% de la hauteur
    purplePath.quadraticBezierTo(
      size.width * 0.13,
      size.height * 0.72, // Contrôle inversé
      size.width * 0.47,
      size.height * 0.79, // Point d'arrivée
    );
    purplePath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.85, // Contrôle inversé
      size.width,
      size.height * 0.8, // Retour à 80% de la hauteur
    );
    purplePath.lineTo(size.width, 0); // Monter jusqu'en haut à droite
    purplePath.lineTo(0, 0); // Retour au point de départ
    purplePath.close();

    // Dessiner les vagues
    canvas.drawPath(purplePath, purplePaint); // Dessiner la vague violette
    canvas.drawPath(pinkPath, pinkPaint); // Dessiner la vague rose
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}*/
