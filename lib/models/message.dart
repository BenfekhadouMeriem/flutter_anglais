class Message {
  final String text;
  final String sender;
  final DateTime timestamp;
  final String? feedback;
  final int? dialogueStep;
  final String? dialogueContext;

  Message({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.feedback,
    this.dialogueStep,
    this.dialogueContext,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'],
      sender: json['sender'],
      timestamp: DateTime.parse(json['timestamp']),
      feedback: json['feedback'],
      dialogueStep: json['dialogueStep'] != null ? int.tryParse(json['dialogueStep'].toString()) : null,
      dialogueContext: json['dialogueContext'],
    );
  }

  Map<String, String> toJson() {
    return {
      'text': text,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
      'feedback': feedback ?? '',
      'dialogueStep': dialogueStep?.toString() ?? '',
      'dialogueContext': dialogueContext ?? '',
    };
  }
}