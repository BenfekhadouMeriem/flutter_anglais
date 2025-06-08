import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

class MonsterCreatorScreen extends StatefulWidget {
  const MonsterCreatorScreen({Key? key}) : super(key: key);

  @override
  _MonsterCreatorScreenState createState() => _MonsterCreatorScreenState();
}

class _MonsterCreatorScreenState extends State<MonsterCreatorScreen> {
  final FlutterTts tts = FlutterTts();
  final List<Map<String, dynamic>> bodyParts = [
    {'name': 'Round head', 'emoji': '⭕', 'color': Colors.yellow, 'size': 80.0, 'category': 'base'},
    {'name': 'Eyes', 'emoji': '👀', 'color': Colors.black, 'size': 40.0, 'category': 'face'},
    {'name': 'Big smile', 'emoji': '😃', 'color': Colors.black, 'size': 50.0, 'category': 'face'},
    {'name': 'Sharp teeth', 'emoji': '🦷', 'color': Colors.white, 'size': 30.0, 'category': 'face'},
    {'name': 'Blue body', 'emoji': '🟦', 'color': Colors.blue, 'size': 100.0, 'category': 'base'},
    {'name': 'Green arms', 'emoji': '💪', 'color': Colors.green, 'size': 60.0, 'category': 'limbs'},
    {'name': 'Red legs', 'emoji': '🦵', 'color': Colors.red, 'size': 70.0, 'category': 'limbs'},
    {'name': 'Wings', 'emoji': '🦋', 'color': Colors.purple, 'size': 90.0, 'category': 'accessories'},
    {'name': 'Hat', 'emoji': '🎩', 'color': Colors.black, 'size': 50.0, 'category': 'accessories'},
    {'name': 'Star', 'emoji': '⭐', 'color': Colors.yellow, 'size': 40.0, 'category': 'accessories'},
  ];

  List<Map<String, dynamic>> selectedParts = [];
  int currentScore = 0;
  Map<String, Offset> partPositions = {};

  @override
  void initState() {
    super.initState();
    initTTS();
  }

  Future<void> initTTS() async {
    await tts.setLanguage('en-US');
    await tts.setSpeechRate(0.5);
  }

  void addPart(Map<String, dynamic> part) {
    setState(() {
      selectedParts.add(part);
      currentScore += 10;
      // Set initial position at center
      partPositions[part['name']] = Offset(0, 0);
      tts.speak(part['name']);
    });
  }

  void removePart(int index) {
    setState(() {
      final partName = selectedParts[index]['name'];
      selectedParts.removeAt(index);
      partPositions.remove(partName);
      currentScore = max(0, currentScore - 5);
    });
  }

  void resetCreation() {
    setState(() {
      selectedParts.clear();
      partPositions.clear();
      currentScore = 0;
    });
  }

  void updatePartPosition(String partName, Offset newPosition) {
    setState(() {
      partPositions[partName] = newPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Monster Creator'),
        centerTitle: true,
        backgroundColor: Colors.pink.shade300,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetCreation,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Column(
        children: [
          // Monster display area
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (selectedParts.isEmpty)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 60, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text(
                          'Create your monster!',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  else
                    ...selectedParts.map((part) {
                      final position = partPositions[part['name']] ?? Offset.zero;
                      return Positioned(
                        left: 100 + position.dx,
                        top: 100 + position.dy,
                        child: Draggable(
                          feedback: Text(
                            part['emoji'],
                            style: TextStyle(
                              fontSize: part['size'],
                              color: part['color'],
                            ),
                          ),
                          childWhenDragging: Container(),
                          onDragEnd: (details) {
                            final renderBox = context.findRenderObject() as RenderBox;
                            final localPosition = renderBox.globalToLocal(details.offset);
                            updatePartPosition(
                              part['name'],
                              Offset(localPosition.dx - 100, localPosition.dy - 100),
                            );
                          },
                          child: GestureDetector(
                            onLongPress: () => removePart(selectedParts.indexOf(part)),
                            child: Text(
                              part['emoji'],
                              style: TextStyle(
                                fontSize: part['size'],
                                color: part['color'],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ).animate().shake(duration: 1000.ms, delay: 300.ms),
          ),

          // Score and actions
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.deepPurple[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'Score: $currentScore',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade300,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedParts.isNotEmpty) {
                      tts.speak('Awesome creation! Your monster looks amazing!');
                    }
                  },
                  child: const Text('Validate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Parts selection
          Expanded(
            flex: 1,
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: Colors.pink.shade300,
                    labelColor: Colors.pink.shade300,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Base'),
                      Tab(text: 'Face'),
                      Tab(text: 'Accessories'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildPartGrid('base'),
                        _buildPartGrid('face'),
                        _buildPartGrid('accessories'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartGrid(String category) {
    final categoryParts = bodyParts.where((part) => part['category'] == category).toList();
    
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: categoryParts.length,
      itemBuilder: (context, index) {
        final part = categoryParts[index];
        return ElevatedButton(
          onPressed: () => addPart(part),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 3,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                part['emoji'],
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(height: 5),
              Text(
                part['name'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().scale(delay: (index * 100).ms);
      },
    );
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }
}