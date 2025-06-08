import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../widgets/text_styles.dart';
import '../chatbot/chatbot_screen.dart';
import '../chatbot/voice_chatbot_screen.dart';
import '../chatbot/translation_screen.dart';

enum ChatOption { textChatBot, voiceChatBot, translator }

extension ChatOptionExtension on ChatOption {
  String get title => switch (this) {
        ChatOption.textChatBot => 'Text Chatbot',
        ChatOption.voiceChatBot => 'Voice Chatbot',
        ChatOption.translator => 'Translation',
      };

  String get lottie => switch (this) {
        ChatOption.textChatBot => 'assets/lottie/ai_hand_waving.json',
        ChatOption.voiceChatBot => 'assets/lottie/ai_play.json',
        ChatOption.translator => 'assets/lottie/ai_ask_me.json',
      };

  VoidCallback onTap(BuildContext context) {
    switch (this) {
      case ChatOption.textChatBot:
        return () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ChatbotScreen()));
      case ChatOption.voiceChatBot:
        return () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const VoiceChatbotScreen()));
      case ChatOption.translator:
        return () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const TranslationScreen()));
    }
  }

  bool get isIceCream => switch (this) {
        ChatOption.textChatBot => true,
        ChatOption.voiceChatBot => false,
        ChatOption.translator => true,
      };
}

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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
      appBar: AppBar(
        title: const Text(
          'Amy - Smart Helper',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD81B60)),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: Container(
        child: SafeArea(
          child: FadeTransition(
            opacity: _buttonAnimation,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ChatOption.values.map((option) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 28.0),
                    child: Material(
                      color: Colors.pink.shade300,
                      borderRadius: BorderRadius.circular(30),
                      elevation: 6,
                      shadowColor: Colors.pink.withOpacity(0.4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: option.onTap(context),
                        splashColor: Colors.pink.shade200.withOpacity(0.4),
                        highlightColor: Colors.pink.shade700.withOpacity(0.3),
                        child: Container(
                          height: 130,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 25, vertical: 20),
                          child: Row(
                            mainAxisAlignment: option.isIceCream
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (option.isIceCream) ...[
                                Lottie.asset(
                                  option.lottie,
                                  height: 85,
                                  width: 85,
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    option.title,
                                    style: AppTextStyles.buttonText.copyWith(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      shadows: const [
                                        Shadow(
                                          blurRadius: 5,
                                          color: Colors.black26,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Expanded(
                                  child: Text(
                                    option.title,
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.buttonText.copyWith(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      shadows: const [
                                        Shadow(
                                          blurRadius: 5,
                                          color: Colors.black26,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Lottie.asset(
                                  option.lottie,
                                  height: 85,
                                  width: 85,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
        /*decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.pink.shade300,
              Colors.pink.shade700,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.shade700.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),*/
      ),
    );
  }
}
