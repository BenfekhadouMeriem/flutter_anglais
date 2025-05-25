import 'package:flutter/material.dart';

//import 'accueil_screen.dart';
import 'main_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: WavePainter(),
                ),
                Positioned.fill(
                  child: _buildSquareButtons(context, constraints),
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  child: _buildLogo(),
                ),
                Positioned(
                  top: 70,
                  left: constraints.maxWidth / 2 - 40,
                  child: const Text(
                    "Tutorial",
                    style: TextStyle(
                      fontSize: 41,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSquareButtons(BuildContext context, BoxConstraints constraints) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: constraints.maxHeight * 0.25),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.04),
                child: Text(
                  "Description",
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                    decorationColor: const Color.fromARGB(255, 241, 107, 151),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: constraints.maxHeight * 0.03),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.04),
                      child: _styledText(
                        "Welcome to ",
                        "AccentFlow!",
                        Colors.pink,
                        null,
                        constraints.maxWidth * 0.055,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.04),
                      child: _styledText(
                        "Ready to ",
                        "join us",
                        Colors.purple,
                        " in transforming your",
                        constraints.maxWidth * 0.05,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.04),
                      child: _styledText(
                        "English",
                        " accent?",
                        Colors.pink,
                        null,
                        constraints.maxWidth * 0.05,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.04),
                      child: Text(
                        "This journey will be fun, interactive, and effective!",
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.045,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.04),
                      child: _listItem(
                        "Podcasts",
                        "Dive into engaging ",
                        "audio",
                        Colors.pink,
                        " content to sharpen your listening skills.",
                        constraints.maxWidth * 0.045,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.04),
                      child: _listItem(
                        "Videos",
                        "Watch and learn with ",
                        "visuals",
                        Colors.pink,
                        " to guide your practice.",
                        constraints.maxWidth * 0.045,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.04),
                      child: _listItem(
                        "Shadowing Practice",
                        "Start following along and perfect your ",
                        "pronunciation.",
                        Colors.pink,
                        null,
                        constraints.maxWidth * 0.045,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.04),
                      child: _listItem(
                        "Your Friend,",
                        " Amy -",
                        "SmartHelper",
                        Colors.purple,
                        " is here to answer any questions you have.",
                        constraints.maxWidth * 0.045,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.04),
                      child: _styledText(
                        "All your progress and information will be ",
                        "securely saved.",
                        Colors.pink,
                        null,
                        constraints.maxWidth * 0.045,
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.03),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: constraints.maxWidth * 0.04,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _styledText(String text1, String text2, Color color,
      [String? text3, double fontSize = 18]) {
    // Ajout du paramètre fontSize
    return RichText(
      textAlign: TextAlign.start, // Centrer le texte
      text: TextSpan(
        style: TextStyle(
            fontSize: fontSize, color: Colors.black), // Utilise fontSize ici
        children: [
          TextSpan(text: text1),
          TextSpan(
              text: text2,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize)),
          if (text3 != null) TextSpan(text: text3),
        ],
      ),
    );
  }

  Widget _listItem(String title, String text1, String highlighted, Color color,
      [String? text2, double fontSize = 18]) {
    // Ajout du paramètre fontSize
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RichText(
        textAlign: TextAlign.start, // Centrer le texte
        text: TextSpan(
          style: TextStyle(
              fontSize: fontSize, color: Colors.black), // Utilise fontSize ici
          children: [
            TextSpan(
                text: "• ",
                style:
                    TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
            TextSpan(
                text: "$title - ",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: fontSize)),
            TextSpan(text: text1),
            TextSpan(
                text: highlighted,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize)),
            if (text2 != null) TextSpan(text: text2),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareButton(String imagePath) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildButtonWithLabel(String label, String assetPath, double size) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {},
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  assetPath,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
                Container(
                  width: size,
                  height: size,
                  color: Colors.black.withOpacity(0.3),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: size * 0.1,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: size * 0.05),
      ],
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
}

class WavePainter extends CustomPainter {
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

    Paint purplePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.purple.shade200, Colors.purple.shade100],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    Path pinkPath = Path();
    pinkPath.moveTo(0, size.height * 0.25);
    pinkPath.quadraticBezierTo(size.width * 0.2, size.height * 0.2,
        size.width * 0.5, size.height * 0.24);
    pinkPath.quadraticBezierTo(
        size.width * 0.85, size.height * 0.29, size.width, size.height * 0.24);
    pinkPath.lineTo(size.width, 0);
    pinkPath.lineTo(0, 0);
    pinkPath.close();

    Path purplePath = Path();
    purplePath.moveTo(0, size.height * 0.25);
    purplePath.quadraticBezierTo(size.width * 0.0, size.height * 0.2,
        size.width * 0.4, size.height * 0.25);
    purplePath.quadraticBezierTo(
        size.width * 0.85, size.height * 0.3, size.width, size.height * 0.2);
    purplePath.lineTo(size.width, 0);
    purplePath.lineTo(0, 0);
    purplePath.close();

    canvas.drawPath(purplePath, purplePaint);
    canvas.drawPath(pinkPath, pinkPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
