import 'package:flutter/material.dart';

import 'young_screen.dart' as young_screen;
import 'advanced_screen.dart' as advances_screen;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _showLogo = false;
  bool _showCategories = false;
  bool _showLoginFields = false;

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

    Future.delayed(const Duration(seconds: 1), () {
      _animationController.forward();
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _showLogo = true;
      });
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _showCategories = true;
      });
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _showLoginFields = true;
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
                          size:
                              Size(constraints.maxWidth, constraints.maxHeight),
                          painter: WavePainter(
                            waveHeight: waveHeight,
                            waveOffset: waveOffset,
                          ),
                        );
                      },
                    ),
                    if (_showLoginFields)
                      _buildSquareButtons(context, constraints),
                    AnimatedPositioned(
                      duration: const Duration(seconds: 2),
                      top: 40,
                      left: _showLogo
                          ? 20
                          : MediaQuery.of(context).size.width / 2 - 60,
                      child: _buildLogo(),
                    ),
                    if (_showCategories)
                      Positioned(
                        top: 70,
                        left: MediaQuery.of(context).size.width / 2 - 40,
                        child: Column(
                          children: [
                            Text(
                              "Category",
                              style: TextStyle(
                                fontSize: 41,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
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

  Widget _buildCategoryButton(String title, BoxConstraints constraints) {
    return Container(
      width: constraints.maxWidth * 0.4,
      height: constraints.maxHeight * 0.06,
      decoration: BoxDecoration(
        color: Colors.pink.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: constraints.maxWidth * 0.05,
          ),
        ),
      ),
    );
  }

  Widget _buildSquareButtons(BuildContext context, BoxConstraints constraints) {
    final buttonSize = constraints.maxWidth * 0.3;
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth * 0.05,
            vertical: constraints.maxHeight * 0.02,
          ),
          child: OrientationBuilder(
            builder: (context, orientation) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: constraints.maxHeight * 0.15),
                  Text(
                    'Choose your category to start improving your accent:',
                    style: TextStyle(
                      fontSize: constraints.maxWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.03),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: constraints.maxWidth * 0.04,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(
                          text: 'Young Explorers : ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                        const TextSpan(
                          text:
                              'This category is for beginners who want to explore the basics of the English accent.\n\n',
                        ),
                        TextSpan(
                          text: 'Advanced Learners : ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                        const TextSpan(
                          text:
                              'This category is for those who want to perfect their accent with advanced exercises.',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.05),
                  orientation == Orientation.portrait
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              young_screen.YoungExplorersPage(),
                                        ),
                                      );
                                    },
                                    child: _buildSquareButton(
                                        'assets/kids.jpg', buttonSize),
                                  ),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.01),
                                  Text(
                                    "Young",
                                    style: TextStyle(
                                      fontSize: constraints.maxWidth * 0.05,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: constraints.maxWidth * 0.05),
                            Expanded(
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => advances_screen
                                              .AdvancedLearnersPage(),
                                        ),
                                      );
                                    },
                                    child: _buildSquareButton(
                                        'assets/adults1.jpg', buttonSize),
                                  ),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.01),
                                  Text(
                                    "Advanced",
                                    style: TextStyle(
                                      fontSize: constraints.maxWidth * 0.05,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => young_screen
                                                .YoungExplorersPage(),
                                          ),
                                        );
                                      },
                                      child: _buildSquareButton(
                                          'assets/kids.jpg', buttonSize),
                                    ),
                                    SizedBox(
                                        height: constraints.maxHeight * 0.01),
                                    Text(
                                      "Young Explorers",
                                      style: TextStyle(
                                        fontSize: constraints.maxWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: constraints.maxWidth * 0.05),
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                advances_screen
                                                    .AdvancedLearnersPage(),
                                          ),
                                        );
                                      },
                                      child: _buildSquareButton(
                                          'assets/adults1.jpg', buttonSize),
                                    ),
                                    SizedBox(
                                        height: constraints.maxHeight * 0.01),
                                    Text(
                                      "Advanced Learners",
                                      style: TextStyle(
                                        fontSize: constraints.maxWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSquareButton(String imagePath, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(imagePath, fit: BoxFit.cover),
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
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
