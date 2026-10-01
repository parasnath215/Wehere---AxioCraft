class CommunityPost {
  final String id;
  final String authorName;
  final String authorBadge;
  final String authorAvatar;
  final String timeAgo;
  final String topic;
  final String content;
  int likesCount;
  int commentsCount;
  bool isLiked;
  bool isSaved;

  CommunityPost({
    required this.id,
    required this.authorName,
    this.authorBadge = 'Top Contributor',
    required this.authorAvatar,
    required this.timeAgo,
    required this.topic,
    required this.content,
    required this.likesCount,
    required this.commentsCount,
    this.isLiked = false,
    this.isSaved = false,
  });
}

class CommunityComment {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String text;
  final String timeAgo;

  CommunityComment({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.text,
    required this.timeAgo,
  });
}

class WellnessGoal {
  final String id;
  final String title;
  final String subtitle;
  final double progress; // 0.0 to 1.0
  final String categoryColor;
  final bool isCompleted;

  WellnessGoal({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.categoryColor,
    this.isCompleted = false,
  });

  WellnessGoal copyWith({
    String? id,
    String? title,
    String? subtitle,
    double? progress,
    String? categoryColor,
    bool? isCompleted,
  }) {
    return WellnessGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      progress: progress ?? this.progress,
      categoryColor: categoryColor ?? this.categoryColor,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
