class AppConstants {
  static const String apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://200.97.165.22:4000/api');
  static const String appName = 'Wehere';
  static const String appTagline = 'A safe place to talk, connect and heal.';
  static const String safeSpaceNotice =
      'You are in a Safe Space. Be kind, respectful, and supportive. We are here for a positive conversation.';
  static const String therapyDisclaimer =
      'Disclaimer: Wehere is a peer-to-peer emotional support community, not a crisis service or licensed medical provider. If you or someone you know is in immediate physical danger or experiencing a medical or psychological emergency, please contact your local emergency services (112 in India) or reach out to a trusted professional immediately.';

  // Default support topics / interests
  static const List<String> interests = [
    'Mental Health',
    'Personal Growth',
    'Relationships',
    'Education',
    'Career',
    'Mindfulness',
    'Health & Fitness',
    'Hobbies',
    'Creativity',
    'Reading',
    'Nature',
    'Music',
    'Journaling',
    'Travel',
    'Coffee',
  ];

  // Feelings / Struggles from Onboarding Screen 3/5
  static const List<String> feelingOptions = [
    'Just Need Someone to Talk To',
    'Relationship Issues',
    'Friendship Issues',
    'Study Pressure',
    'Financial Stress',
    'Feeling Down',
    'Low Confidence',
    'Major Life Changes',
    'Grief / Loss',
    'Frustrated / Angry',
    'Feeling Lost',
    'Looking for Motivation',
  ];

  // Support Types from Onboarding Screen 4/5
  static const List<Map<String, String>> supportTypes = [
    {
      'title': 'Someone to Talk To',
      'subtitle': 'I want someone to listen and talk to me.',
    },
    {
      'title': 'New Friends',
      'subtitle': 'I want to make new friends and build meaningful bonds.',
    },
    {
      'title': 'Emotional Support',
      'subtitle': 'I need support and guidance through tough times.',
    },
    {
      'title': 'Accountability Partner',
      'subtitle': 'I want someone to stay motivated and achieve goals together.',
    },
    {
      'title': 'Motivation & Positivity',
      'subtitle': 'I want positive vibes and daily motivation.',
    },
  ];

  // Icebreaker Prompts tailored to mental wellness
  static const List<String> icebreakerPrompts = [
    "What's one good thing that happened today? ✨",
    "What is your favorite gentle way to recharge? 🌿",
    "If you could un-stress one thing right now, what would it be?",
    "What is a small win you are quietly proud of lately? 💜",
    "What song or podcast has brought you peace recently? 🎵",
  ];

  // Helplines - Focused on India (with International fallback)
  static const List<Map<String, String>> crisisHelplines = [
    {
      'name': 'Tele-MANAS (Govt of India Mental Health)',
      'number': '14416 / 1800 891 4416',
      'hours': '24/7 • Toll-Free • 20+ Indian Languages',
      'type': 'Call'
    },
    {
      'name': 'KIRAN Mental Health Helpline',
      'number': '1800-599-0019',
      'hours': '24/7 • Toll-Free • Ministry of Social Justice',
      'type': 'Call'
    },
    {
      'name': 'Vandrevala Foundation Helpline',
      'number': '+91 9999 666 555',
      'hours': '24/7 • Free Trained Counselors • Call & WhatsApp',
      'type': 'Call & WhatsApp'
    },
    {
      'name': 'AASRA Suicide Prevention & Crisis',
      'number': '+91 98204 66726',
      'hours': '24/7 • Free & Confidential Emotional Support',
      'type': 'Call'
    },
    {
      'name': 'NIMHANS Psychosocial Helpline',
      'number': '080-46110007',
      'hours': '24/7 • National Institute of Mental Health',
      'type': 'Call'
    },
    {
      'name': 'National Emergency Services (India)',
      'number': '112',
      'hours': '24/7 • Police, Fire & Medical Emergencies',
      'type': 'Emergency Call'
    },
    {
      'name': '988 Suicide & Crisis Lifeline (US & Intl)',
      'number': '988',
      'hours': '24/7 • Free & Confidential International',
      'type': 'Call & Text'
    },
  ];
}
