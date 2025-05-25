import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../widgets/wave_painter.dart';
import '../widgets/text_styles.dart'; // Importer les styles de texte

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _welcomeTextAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    // Animation du logo, texte et boutons
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _welcomeTextAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _buttonAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Forme ondulée d'arrière-plan
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(),
              child: Container(),
            ),
          ),
          // Contenu principal
          Column(
            children: [
              // Section Logo et Titre
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animation du logo
                    FadeTransition(
                      opacity: _logoAnimation,
                      child: _buildLogo(),
                    ),
                    const SizedBox(height: 15),
                    FadeTransition(
                      opacity: _logoAnimation,
                      child: _buildAppName(),
                    ),
                  ],
                ),
              ),
              // Section Bienvenue et Boutons
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 130),
                    // Animation du texte de bienvenue
                    FadeTransition(
                      opacity: _welcomeTextAnimation,
                      child: _buildWelcomeText(),
                    ),
                    const SizedBox(height: 50),
                    // Animation des boutons
                    FadeTransition(
                      opacity: _buttonAnimation,
                      child: _buildButtons(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget pour le logo
  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Barres avec une partie supérieure et une partie inférieure
            _buildVerticalBar(0, 70, 10, Colors.pink.shade200,
                Colors.pink.shade100, true), // Attachée
            _buildVerticalBar(15, 10, 35, Colors.pink.shade300,
                Colors.pink.shade400, false), // Pas attachée
            _buildVerticalBar(-15, 35, 10, Colors.pink.shade300,
                Colors.pink.shade400, false), // Pas attachée
            _buildVerticalBar(30, 20, 10, Colors.pink.shade100,
                Colors.pink.shade200, true), // Attachée
            _buildVerticalBar(-30, 10, 20, Colors.pink.shade100,
                Colors.pink.shade200, true), // attachée
          ],
        ),
      ),
    );
  }

  // Méthode pour une barre avec partie supérieure et inférieure de hauteurs spécifiées
  Widget _buildVerticalBar(double offsetX, double topHeight,
      double bottomHeight, Color topColor, Color bottomColor, bool isAttached) {
    return Positioned(
      left: 57 + offsetX, // Décalage horizontal
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Centrer les barres
        children: [
          // Partie supérieure de la barre
          Container(
            width: 10,
            height: topHeight,
            decoration: BoxDecoration(
              color: topColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          // Si les barres doivent être attachées, on ne met pas d'espace
          // Partie inférieure de la barre
          isAttached
              ? Container(
                  width: 10,
                  height: bottomHeight,
                  decoration: BoxDecoration(
                    color: bottomColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                )
              : SizedBox(
                  height: 5), // Espacement entre les parties si non attachée
          // Partie inférieure de la barre (si pas attachée, un petit espace est mis)
          if (!isAttached)
            Container(
              width: 10,
              height: bottomHeight,
              decoration: BoxDecoration(
                color: bottomColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
        ],
      ),
    );
  }

  // Widget pour le nom de l'application
  Widget _buildAppName() {
    return Text(
      "Accent Flow",
      style: AppTextStyles.appName,
    );
  }

  // Widget pour le texte de bienvenue
  Widget _buildWelcomeText() {
    return Text(
      "Welcome!",
      style: AppTextStyles.welcomeText,
    );
  }

  // Widget pour les boutons (Login et Create Account)
  Widget _buildButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        children: [
          // Bouton Login
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              "Login",
              style: AppTextStyles.buttonText,
            ),
          ),
          const SizedBox(height: 25),
          // Bouton Create Account
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.pink.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              "Create Account",
              style: AppTextStyles.outlinedButtonText,
            ),
          ),
        ],
      ),
    );
  }
}
