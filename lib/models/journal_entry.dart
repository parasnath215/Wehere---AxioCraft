class JournalEntry {
  final String id;
  final DateTime date;
  final String mood; // Amazing, Good, Okay, Tired, Stressed
  final String thought;
  final String gratitude;
  final String category; // General, Gratitude, Goal / Progress, Reflection, Dream / Idea
  final String? photoUrl;
  final bool isPrivate;

  JournalEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.thought,
    this.gratitude = '',
    this.category = 'General',
    this.photoUrl,
    this.isPrivate = true,
  });
}
