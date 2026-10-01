import 'user_profile.dart';

class MatchCard {
  final UserProfile profile;
  final bool isNewHere;
  final List<String> commonInterests;
  final String compatibilityReason;

  MatchCard({
    required this.profile,
    this.isNewHere = true,
    this.commonInterests = const ['Healing & Growing', 'Reading', 'Nature'],
    this.compatibilityReason =
        'You both believe in kindness, personal growth and being a better version of yourself. 🌱',
  });
}
