import 'package:flutter/material.dart';
import 'package:flutter_anglais/Services/auth_services.dart';
import 'package:flutter_anglais/Services/globals.dart';

// Utilisation d'un alias pour home_screen.dart
import 'about_screen.dart' as about_screen;
import 'register_screen.dart';
import '../widgets/wave_login.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showLoginFields = false; // Pour afficher les champs après l'animation

  loginPressed() async {
    String _email = _emailController.text.trim();
    String _password = _passwordController.text.trim();

    if (_email.isNotEmpty && _password.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        await AuthServices.login(_email, _password);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const about_screen.AboutScreen(),
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
      errorSnackBar(context, 'Veuillez remplir tous les champs requis.');
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
            _showLoginFields = true;
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
              if (_showLoginFields) _buildLoginFields(),
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

  Widget _buildLoginFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        shrinkWrap: true,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.21),
          const Text(
            'Login',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 45, fontWeight: FontWeight.w500, color: Colors.white),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          _buildTextField(
              controller: _emailController,
              hintText: 'Enter your email',
              icon: Icons.email),
          const SizedBox(height: 20),
          _buildTextField(
              controller: _passwordController,
              hintText: 'Enter your password',
              icon: Icons.lock,
              obscureText: true),
          const SizedBox(height: 30),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: loginPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Forgot your password?',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.07),
          const Center(
            child: Text(
              '_____ Or connect with _____',
              style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                icon: Icons.email,
                text: 'Google',
                onPressed: _signInWithGoogle,
              ),
              const SizedBox(width: 20),
              _buildSocialButton(
                icon: Icons.facebook,
                text: 'Facebook',
                onPressed: _signInWithFacebook,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account? "),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  'Register',
                  style: TextStyle(
                    color: Color(0xFFE57373),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hintText,
      required IconData icon,
      bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.pink.shade300),
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildSocialButton(
      {required IconData icon,
      required String text,
      required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink.shade300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      //await AuthServices.signInWithGoogle();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const about_screen.AboutScreen(),
        ),
      );
    } catch (e) {
      errorSnackBar(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);
    try {
      //await AuthServices.signInWithFacebook();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const about_screen.AboutScreen(),
        ),
      );
    } catch (e) {
      errorSnackBar(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
