import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'home_screen.dart';

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
                        decorationColor: const Color.fromARGB(255, 241, 107, 151),
                      ),
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.03),
                  _buildButtonRow(
                    labels: ['Podcast', 'Choose'],
                    imageAssets: ['assets/podcast.jpg', 'assets/chose.jpg'],
                    videoAssets: ['assets/videos/podcast.mp4', 'assets/videos/choose.mp4'],
                    constraints: constraints,
                    isPortrait: orientation == Orientation.portrait,
                    context: context,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.03),
                  _buildButtonRow(
                    labels: ['Recording', 'Audio'],
                    imageAssets: ['assets/recording.jpg', 'assets/audio.jpg'],
                    videoAssets: ['assets/videos/recording.mp4', 'assets/videos/audio.mp4'],
                    constraints: constraints,
                    isPortrait: orientation == Orientation.portrait,
                    context: context,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.03),
                  _buildButtonRow(
                    labels: ['Games', 'Amy'],
                    imageAssets: ['assets/games.jpg', 'assets/amy.jpg'],
                    videoAssets: ['assets/videos/games.mp4', 'assets/videos/amy.mp4'],
                    constraints: constraints,
                    isPortrait: orientation == Orientation.portrait,
                    context: context,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.03),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(),
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
    required List<String> imageAssets,
    required List<String> videoAssets,
    required BoxConstraints constraints,
    required bool isPortrait,
    required BuildContext context,
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
                child: _buildButtonWithLabel(
                  labels[i],
                  imageAssets[i],
                  videoAssets[i],
                  buttonSize,
                  context,
                ),
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
                child: _buildButtonWithLabel(
                  labels[i],
                  imageAssets[i],
                  videoAssets[i],
                  buttonSize,
                  context,
                ),
              ),
            ),
          );
  }

  Widget _buildButtonWithLabel(
    String label,
    String imagePath,
    String videoPath,
    double size,
    BuildContext context,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerPage(videoPath: videoPath),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: size,
                    height: size,
                    color: Colors.grey,
                    child: const Center(child: Icon(Icons.error)),
                  ),
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

class VideoPlayerPage extends StatefulWidget {
  final String videoPath;

  const VideoPlayerPage({Key? key, required this.videoPath}) : super(key: key);

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        setState(() {
          _controller.play();
        });
      }).catchError((error) {
        setState(() {
          _isError = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _isError
            ? const Text(
                'Erreur lors du chargement de la vidéo',
                style: TextStyle(color: Colors.white, fontSize: 18),
              )
            : _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_controller),
                        _VideoControls(controller: _controller),
                      ],
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  final VideoPlayerController controller;

  const _VideoControls({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
            },
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow ,         
              color: Colors.white,
              size: 30,
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