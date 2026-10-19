class UserProfile {
  final String id;
  final String name;
  final int age;
  final String location;
  final String? profession;
  final String bio;
  final String avatarUrl;
  final List<String> images;
  final bool isVerified;
  final bool isOnline;
  final String moodStatus;
  final int matchPercentage;
  final List<String> interests;
  final List<String> feelings;
  final List<String> supportTypes;
  final List<String> values;
  final bool isAnonymous;
  final bool isSafeSpacePledged;
  final int trustLevel;
  final bool hasVoiceIntro;

  final String? displayName;
  final String? realFirstName;
  final String? legalFullName;
  final String? handle;
  final String nameDisplayPreference; // 'DISPLAY_NAME_ONLY' or 'FIRST_NAME_PUBLIC'
  final bool isMutuallyRevealed;
  final bool myRevealed;
  final bool peerRevealed;

  UserProfile({
    required this.id,
    required this.name,
    this.displayName,
    this.realFirstName,
    this.legalFullName,
    this.handle,
    this.nameDisplayPreference = 'DISPLAY_NAME_ONLY',
    this.isMutuallyRevealed = false,
    this.myRevealed = false,
    this.peerRevealed = false,
    required this.age,
    required this.location,
    this.profession,
    required this.bio,
    required this.avatarUrl,
    this.images = const [],
    this.isVerified = true,
    this.isOnline = true,
    this.moodStatus = 'Healing & Growing 💜',
    this.matchPercentage = 92,
    this.interests = const [],
    this.feelings = const [],
    this.supportTypes = const [],
    this.values = const ['Honesty', 'Empathy', 'Respect', 'Growth'],
    this.isAnonymous = false,
    this.isSafeSpacePledged = true,
    this.trustLevel = 1,
    this.hasVoiceIntro = true,
  });

  String get cardName => (nameDisplayPreference == 'FIRST_NAME_PUBLIC' && realFirstName != null && realFirstName!.trim().isNotEmpty)
      ? realFirstName!.trim()
      : (displayName != null && displayName!.trim().isNotEmpty ? displayName!.trim() : name);

  String get displayAlias => (displayName != null && displayName!.trim().isNotEmpty) ? displayName!.trim() : name;

  UserProfile copyWith({
    String? id,
    String? name,
    String? displayName,
    String? realFirstName,
    String? legalFullName,
    String? handle,
    String? nameDisplayPreference,
    bool? isMutuallyRevealed,
    bool? myRevealed,
    bool? peerRevealed,
    int? age,
    String? location,
    String? profession,
    String? bio,
    String? avatarUrl,
    List<String>? images,
    bool? isVerified,
    bool? isOnline,
    String? moodStatus,
    int? matchPercentage,
    List<String>? interests,
    List<String>? feelings,
    List<String>? supportTypes,
    List<String>? values,
    bool? isAnonymous,
    bool? isSafeSpacePledged,
    int? trustLevel,
    bool? hasVoiceIntro,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      realFirstName: realFirstName ?? this.realFirstName,
      legalFullName: legalFullName ?? this.legalFullName,
      handle: handle ?? this.handle,
      nameDisplayPreference: nameDisplayPreference ?? this.nameDisplayPreference,
      isMutuallyRevealed: isMutuallyRevealed ?? this.isMutuallyRevealed,
      myRevealed: myRevealed ?? this.myRevealed,
      peerRevealed: peerRevealed ?? this.peerRevealed,
      age: age ?? this.age,
      location: location ?? this.location,
      profession: profession ?? this.profession,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      images: images ?? this.images,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      moodStatus: moodStatus ?? this.moodStatus,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      interests: interests ?? this.interests,
      feelings: feelings ?? this.feelings,
      supportTypes: supportTypes ?? this.supportTypes,
      values: values ?? this.values,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isSafeSpacePledged: isSafeSpacePledged ?? this.isSafeSpacePledged,
      trustLevel: trustLevel ?? this.trustLevel,
      hasVoiceIntro: hasVoiceIntro ?? this.hasVoiceIntro,
    );
  }
}
