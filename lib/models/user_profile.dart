class UserProfile {
  final String id;
  final String name;
  final int age;
  final String location;
  final String bio;
  final String avatarUrl;
  final bool isVerified;
  final bool isOnline;
  final String moodStatus;
  final int matchPercentage;
  final List<String> interests;
  final String lookingFor;
  final List<String> values;
  final bool isAnonymous;
  final bool isSafeSpacePledged;
  final int trustLevel;
  final bool hasVoiceIntro;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.bio,
    required this.avatarUrl,
    this.isVerified = true,
    this.isOnline = true,
    this.moodStatus = 'Healing & Growing 💜',
    this.matchPercentage = 92,
    this.interests = const [],
    this.lookingFor = 'Meaningful conversations & emotional support',
    this.values = const ['Honesty', 'Empathy', 'Respect', 'Growth'],
    this.isAnonymous = false,
    this.isSafeSpacePledged = true,
    this.trustLevel = 1,
    this.hasVoiceIntro = true,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? location,
    String? bio,
    String? avatarUrl,
    bool? isVerified,
    bool? isOnline,
    String? moodStatus,
    int? matchPercentage,
    List<String>? interests,
    String? lookingFor,
    List<String>? values,
    bool? isAnonymous,
    bool? isSafeSpacePledged,
    int? trustLevel,
    bool? hasVoiceIntro,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      moodStatus: moodStatus ?? this.moodStatus,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      interests: interests ?? this.interests,
      lookingFor: lookingFor ?? this.lookingFor,
      values: values ?? this.values,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isSafeSpacePledged: isSafeSpacePledged ?? this.isSafeSpacePledged,
      trustLevel: trustLevel ?? this.trustLevel,
      hasVoiceIntro: hasVoiceIntro ?? this.hasVoiceIntro,
    );
  }
}
