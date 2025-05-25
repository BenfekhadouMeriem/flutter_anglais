import 'package:flutter/material.dart';
import 'dart:ui';

import 'about_screen.dart';

class AdvancedLearnersPage extends StatelessWidget {
  const AdvancedLearnersPage({Key? key}) : super(key: key);

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
          child: OrientationBuilder(
            builder: (context, orientation) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: constraints.maxHeight * 0.25),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth * 0.04),
                    child: Text(
                      "Tutorial",
                      style: TextStyle(
                        fontSize: constraints.maxWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                        decorationColor:
                            const Color.fromARGB(255, 241, 107, 151),
                      ),
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.03),
                  _buildButtonRow(
                    labels: ['Podcast', 'Choose'],
                    assets: ['assets/podcast.jpg', 'assets/chose.jpg'],
                    constraints: constraints,
                    isPortrait: orientation == Orientation.portrait,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.03),
                  _buildButtonRow(
                    labels: ['Recording', 'Audio'],
                    assets: ['assets/recording.jpg', 'assets/audio.jpg'],
                    constraints: constraints,
                    isPortrait: orientation == Orientation.portrait,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.03),
                  _buildButtonRow(
                    labels: ['Video', 'Amy'],
                    assets: ['assets/video.jpg', 'assets/amy.jpg'],
                    constraints: constraints,
                    isPortrait: orientation == Orientation.portrait,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.03),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutScreen(),
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow({
    required List<String> labels,
    required List<String> assets,
    required BoxConstraints constraints,
    required bool isPortrait,
  }) {
    final buttonSize = constraints.maxWidth * 0.35;
    return isPortrait
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              labels.length,
              (i) => Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.03),
                child: _buildButtonWithLabel(labels[i], assets[i], buttonSize),
              ),
            ),
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              labels.length,
              (i) => Padding(
                padding: EdgeInsets.symmetric(
                    vertical: constraints.maxHeight * 0.01),
                child: _buildButtonWithLabel(labels[i], assets[i], buttonSize),
              ),
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
