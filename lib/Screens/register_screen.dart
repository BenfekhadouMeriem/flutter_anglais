import 'package:flutter/material.dart';
import 'package:flutter_anglais/Services/auth_services.dart';
import 'package:flutter_anglais/Services/globals.dart';

// Utilisation d'un alias pour home_screen.dart
import 'home_screen.dart' as home_screen;
import 'login_screen.dart';
import '../widgets/wave_login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();

  bool _isLoading = false;
  bool _showRegisterFields = false;

  registerPressed() async {
    String _name = _nameController.text.trim();
    String _email = _emailController.text.trim();
    String _password = _passwordController.text.trim();
    String _passwordConfirmation = _passwordConfirmationController.text.trim();

    if (_name.isNotEmpty &&
        _email.isNotEmpty &&
        _password.isNotEmpty &&
        _password == _passwordConfirmation) {
      setState(() {
        _isLoading = true;
      });

      try {
        await AuthServices.register(_name, _email, _password);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inscription réussie !')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const home_screen.HomeScreen(),
          ),
        );
      } catch (e) {
        errorSnackBar(context, e.toString());
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      errorSnackBar(
          context,
          _password == _passwordConfirmation
              ? 'Veuillez remplir tous les champs requis.'
              : 'Les mots de passe ne correspondent pas.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 0.45),
        duration: const Duration(seconds: 2),
        onEnd: () {
          setState(() {
            _showRegisterFields = true;
          });
        },
        builder: (context, double waveHeight, child) {
          return Stack(
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 0.0),
                duration: const Duration(seconds: 2),
                builder: (context, double waveOffset, child) {
                  return CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: WavePainter(
                      waveHeight: waveHeight,
                      waveOffset: waveOffset,
                    ),
                  );
                },
              ),
              if (_showRegisterFields) _buildRegisterFields(),
              Positioned(
                top: 70,
                left: MediaQuery.of(context).size.width / 2 - 60,
                child: _buildLogo(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRegisterFields() {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = screenWidth * 0.05;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: screenHeight * 0.25),
          Text(
            'Register',
            style: TextStyle(
              fontSize: screenWidth * 0.1,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          _buildTextField(
            controller: _nameController,
            hintText: 'Enter your name',
            icon: Icons.person,
          ),
          SizedBox(height: screenHeight * 0.02),
          _buildTextField(
            controller: _emailController,
            hintText: 'Enter your email',
            icon: Icons.email,
          ),
          SizedBox(height: screenHeight * 0.02),
          _buildTextField(
            controller: _passwordController,
            hintText: 'Enter your password',
            icon: Icons.lock,
            obscureText: true,
          ),
          SizedBox(height: screenHeight * 0.02),
          _buildTextField(
            controller: _passwordConfirmationController,
            hintText: 'Confirm your password',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          SizedBox(height: screenHeight * 0.03),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: registerPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    minimumSize: Size(screenWidth * 0.9, screenHeight * 0.06),
                  ),
                  child: Text(
                    'Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                ),
          SizedBox(height: screenHeight * 0.12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: const Color(0xFFE57373),
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
            _buildVerticalBar(
                0, 70, 10, Colors.pink.shade200, Colors.pink.shade100, true),
            _buildVerticalBar(
                15, 10, 35, Colors.pink.shade300, Colors.pink.shade400, false),
            _buildVerticalBar(
                -15, 35, 10, Colors.pink.shade300, Colors.pink.shade400, false),
            _buildVerticalBar(
                30, 20, 10, Colors.pink.shade100, Colors.pink.shade200, true),
            _buildVerticalBar(
                -30, 10, 20, Colors.pink.shade100, Colors.pink.shade200, true),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalBar(double offsetX, double topHeight,
      double bottomHeight, Color topColor, Color bottomColor, bool isAttached) {
    return Positioned(
      left: 57 + offsetX,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: topHeight,
            decoration: BoxDecoration(
              color: topColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          isAttached
              ? Container(
                  width: 10,
                  height: bottomHeight,
                  decoration: BoxDecoration(
                    color: bottomColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                )
              : SizedBox(height: 5),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        prefixIcon: Icon(icon, color: Colors.pink.shade300),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.pink.shade300),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.pink.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.pink),
        ),
      ),
    );
  }
}


/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_anglais/Services/auth_services.dart';
/*import 'package:flutter_anglais/Services/globals.dart';
import '../rounded_button.dart';*/

// Utilisation d'un alias pour home_screen.dart
import 'home_screen.dart' as home_screen;

import 'login_screen.dart';
import 'package:http/http.dart' as http;

import '../widgets/wave_login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();

  bool _isLoading = false;
  bool _showRegisterFields = false;

  registerPressed() async {
    String _name = _nameController.text.trim();
    String _email = _emailController.text.trim();
    String _password = _passwordController.text.trim();
    String _passwordConfirmation = _passwordConfirmationController.text
        .trim(); // Récupérer la confirmation du mot de passe

    // Vérifier que tous les champs sont remplis et que les mots de passe correspondent
    if (_name.isNotEmpty &&
        _email.isNotEmpty &&
        _password.isNotEmpty &&
        _password == _passwordConfirmation) {
      setState(() {
        _isLoading = true;
      });

      try {
        http.Response response = await AuthServices.register(
            _name, _email, _password, _passwordConfirmation);

        // Affiche la réponse complète dans la console
        print('Response Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful!')));
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const home_screen.HomeScreen()));
        } else {
          // Affichage du message d'erreur détaillé
          try {
            Map responseMap = jsonDecode(response.body);
            String errorMessage =
                responseMap['message'] ?? 'Unknown error occurred';
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Error: $errorMessage')));
          } catch (e) {
            // Gestion des erreurs dans le cas où la réponse n'est pas au format JSON
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('An error occurred. Please try again later.')));
          }
        }
      } catch (e) {
        print("Error during registration: $e");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('An error occurred. Please try again.')));
      }
    } else {
      // Afficher un message si les mots de passe ne correspondent pas
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 0.45),
        duration: const Duration(seconds: 2),
        onEnd: () {
          setState(() {
            _showRegisterFields = true;
          });
        },
        builder: (context, double waveHeight, child) {
          return Stack(
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 0.0),
                duration: const Duration(seconds: 2),
                builder: (context, double waveOffset, child) {
                  return CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: WavePainter(
                      waveHeight: waveHeight,
                      waveOffset: waveOffset,
                    ),
                  );
                },
              ),
              if (_showRegisterFields) _buildRegisterFields(),
              Positioned(
                top: 70,
                left: MediaQuery.of(context).size.width / 2 - 60,
                child: _buildLogo(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRegisterFields() {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = screenWidth * 0.05;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: screenHeight * 0.25), // Was 215
          Text(
            'Register',
            style: TextStyle(
              fontSize: screenWidth * 0.1, // Was 45
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenHeight * 0.03), // Was MediaQuery-based
          _buildTextField(
            controller: _nameController,
            hintText: 'Enter your name',
            icon: Icons.person,
          ),
          SizedBox(height: screenHeight * 0.02), // Was 15
          _buildTextField(
            controller: _emailController,
            hintText: 'Enter your email',
            icon: Icons.email,
          ),
          SizedBox(height: screenHeight * 0.02), // Was 15
          _buildTextField(
            controller: _passwordController,
            hintText: 'Enter your password',
            icon: Icons.lock,
            obscureText: true,
          ),
          SizedBox(height: screenHeight * 0.02), // Was 15
          _buildTextField(
            controller: _passwordConfirmationController,
            hintText: 'Confirm your password',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          SizedBox(height: screenHeight * 0.03), // Was 25
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: registerPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02), // Was 15
                    minimumSize: Size(screenWidth * 0.9,
                        screenHeight * 0.06), // Was Size.fromHeight(50)
                  ),
                  child: Text(
                    'Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.04, // Was 16
                    ),
                  ),
                ),
          SizedBox(height: screenHeight * 0.12), // Was 100
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  fontSize: screenWidth * 0.035, // Responsive font size
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: const Color(0xFFE57373),
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.035, // Responsive font size
                  ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        prefixIcon: Icon(icon, color: Colors.pink.shade300),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.pink.shade300),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.pink.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.pink),
        ),
      ),
    );
  }
}
*/