import 'package:flutter/material.dart';
import 'advanced_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  bool _showLogo = false;
  bool _showTitle = false;
  bool _showContent = false;

  late AnimationController _animationController;
  late Animation<double> _waveAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start the wave animation after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      _animationController.forward();
    });

    // Show logo after 300ms
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _showLogo = true;
      });
    });

    // Show title after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showTitle = true;
      });
    });

    // Show content after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _showContent = true;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.45, end: 0.0),
              duration: const Duration(seconds: 2),
              builder: (context, double waveHeight, child) {
                return Stack(
                  children: [
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.0, end: 0.0),
                      duration: const Duration(seconds: 2),
                      builder: (context, double waveOffset, child) {
                        return CustomPaint(
                          size:
                              Size(constraints.maxWidth, constraints.maxHeight),
                          painter: WavePainter(
                            waveHeight: waveHeight,
                            waveOffset: waveOffset,
                          ),
                        );
                      },
                    ),
                    if (_showContent)
                      Positioned.fill(
                        child: _buildSquareButtons(context, constraints),
                      ),
                    AnimatedPositioned(
                      duration: const Duration(seconds: 2),
                      top: 40,
                      left: _showLogo
                          ? 20
                          : MediaQuery.of(context).size.width / 2 - 60,
                      child: _buildLogo(),
                    ),
                    if (_showTitle)
                      Positioned(
                        top: 70,
                        left: constraints.maxWidth / 2 - 40,
                        child: FadeTransition(
                          opacity: _waveAnimation,
                          child: const Text(
                            "About Us",
                            style: TextStyle(
                              fontSize: 41,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
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
          child: FadeTransition(
            opacity: _waveAnimation,
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
                                builder: (context) => AdvancedLearnersPage(),
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
      ),
    );
  }

  Widget _styledText(String text1, String text2, Color color,
      [String? text3, double fontSize = 18]) {
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        style: TextStyle(fontSize: fontSize, color: Colors.black),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RichText(
        textAlign: TextAlign.start,
        text: TextSpan(
          style: TextStyle(fontSize: fontSize, color: Colors.black),
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

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoAnimation,
      child: Container(
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
              _buildVerticalBar(15, 10, 35, Colors.pink.shade300,
                  Colors.pink.shade400, false),
              _buildVerticalBar(-15, 35, 10, Colors.pink.shade300,
                  Colors.pink.shade400, false),
              _buildVerticalBar(
                  30, 20, 10, Colors.pink.shade100, Colors.pink.shade200, true),
              _buildVerticalBar(-30, 10, 20, Colors.pink.shade100,
                  Colors.pink.shade200, true),
            ],
          ),
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
  final double waveHeight;
  final double waveOffset;

  WavePainter({required this.waveHeight, required this.waveOffset});

  @override
  void paint(Canvas canvas, Size size) {
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

    Path pinkPath = Path();
    pinkPath.moveTo(0, size.height * (waveHeight + 0.25) + waveOffset);
    pinkPath.quadraticBezierTo(
        size.width * 0.2,
        size.height * (waveHeight + 0.2) + waveOffset,
        size.width * 0.45,
        size.height * (waveHeight + 0.23) + waveOffset);
    pinkPath.quadraticBezierTo(
        size.width * 0.85,
        size.height * (waveHeight + 0.29) + waveOffset,
        size.width,
        size.height * (waveHeight + 0.23) + waveOffset);
    pinkPath.lineTo(size.width, 0);
    pinkPath.lineTo(0, 0);
    pinkPath.close();

    Path purplePath = Path();
    purplePath.moveTo(0, size.height * (waveHeight + 0.22) + waveOffset);
    purplePath.quadraticBezierTo(
        size.width * 0.13,
        size.height * (waveHeight + 0.21) + waveOffset,
        size.width * 0.45,
        size.height * (waveHeight + 0.25) + waveOffset);
    purplePath.quadraticBezierTo(
        size.width * 0.85,
        size.height * (waveHeight + 0.3) + waveOffset,
        size.width,
        size.height * (waveHeight + 0.18) + waveOffset);
    purplePath.lineTo(size.width, 0);
    purplePath.lineTo(0, 0);
    purplePath.close();

    canvas.drawPath(purplePath, purplePaint);
    canvas.drawPath(pinkPath, pinkPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}