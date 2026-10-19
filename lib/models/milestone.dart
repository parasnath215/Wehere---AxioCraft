class Milestone {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String category; // 'Journal' | 'Streak' | 'Safety' | 'Goals' | 'Connection'
  final int currentProgress;
  final int targetProgress;
  final bool _isUnlockedFlag;
  final DateTime? unlockedAt;

  const Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.currentProgress,
    required this.targetProgress,
    required bool isUnlocked,
    this.unlockedAt,
  }) : _isUnlockedFlag = isUnlocked;

  /// A milestone is strictly unlocked ONLY when its conditions are completed (currentProgress >= targetProgress).
  bool get isUnlocked => _isUnlockedFlag && (targetProgress == 0 || currentProgress >= targetProgress);

  double get percent =>
      targetProgress == 0 ? 1.0 : (currentProgress / targetProgress).clamp(0.0, 1.0);
}
