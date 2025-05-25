import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import '../Pages/video_page.dart';
import '../Pages/voice_page.dart';
import '../Pages/menu_page.dart';
import '../Pages/chat_page.dart';
import '../Pages/profile_page.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<CurvedNavigationBarState> _curvedNavigationKey = GlobalKey();
  int _currentPage = 0;
  bool _isMenuOpen = false;

  final List<Widget> pages = [
    VideoPage(),
    VoicePage(),
    MenuPage(),
    ChatPage(),
    ProfilePage(),
  ];

  final List<String> pageNames = ["Vidéo", "Audio", "Add", "Chat", "Profil"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_currentPage],
      bottomNavigationBar: CurvedNavigationBar(
        key: _curvedNavigationKey,
        index: _currentPage,
        height: 70.0,
        items: List.generate(5, (index) {
          bool isSelected =
              _currentPage == index || (_isMenuOpen && index == 2);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (index == 2) {
                  _isMenuOpen = !_isMenuOpen;
                  _currentPage = 2;
                } else {
                  _currentPage = index;
                  _isMenuOpen = false;
                }
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  [
                    Icons.videocam_outlined,
                    Icons.settings_voice_outlined,
                    _isMenuOpen
                        ? Icons.cancel_outlined
                        : Icons.add_circle_outline,
                    Icons.question_answer_outlined,
                    Icons.person_outlined
                  ][index],
                  size: index == 2 ? 30 : 25,
                  color: isSelected ? Colors.white : Colors.black,
                ),
                SizedBox(height: 2),
                Text(
                  pageNames[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
        color: Colors.transparent,
        buttonBackgroundColor: Colors.pink.shade300,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 600),
        onTap: (index) {
          setState(() {
            if (index == 2) {
              _isMenuOpen = !_isMenuOpen;
              _currentPage = 2;
            } else {
              _currentPage = index;
              _isMenuOpen = false;
            }
          });
        },
        letIndexChange: (index) => true,
      ),
      floatingActionButton: _isMenuOpen
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.pink.shade300,
                    child: const Icon(Icons.videocam, color: Colors.white),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.pink.shade300,
                    child: const Icon(Icons.mic, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
