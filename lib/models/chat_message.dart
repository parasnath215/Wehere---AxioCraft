class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMine;
  final bool isDelivered;
  final bool isRead;
  final bool isIcebreaker;
  final bool isVoiceNote;
  final int voiceDurationSeconds;
  final bool isCrisisIntervention;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMine,
    this.isDelivered = true,
    this.isRead = true,
    this.isIcebreaker = false,
    this.isVoiceNote = false,
    this.voiceDurationSeconds = 0,
    this.isCrisisIntervention = false,
  });
}
