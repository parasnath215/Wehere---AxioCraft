import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/match_card.dart';
import '../models/chat_message.dart';
import '../models/journal_entry.dart';
import '../models/community_post.dart';
import '../models/emergency_contact.dart';
import '../core/network/api_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/app_constants.dart';
import '../core/utils/storage_helper.dart';
import '../models/notification.dart';
import '../models/config_options.dart';
import '../models/milestone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  // Current Logged-in User
  UserProfile _currentUser = UserProfile(
    id: 'user_paras_01',
    name: 'Paras',
    age: 24,
    location: 'Mumbai, India',
    profession: 'Product Designer',
    bio: '',
    avatarUrl: 'assets/images/paras_avatar.jpg',
    images: ['assets/images/paras_avatar.jpg'],
    isVerified: true,
    isOnline: true,
    moodStatus: 'Peaceful',
    matchPercentage: 100,
    interests: ['Career', 'Mindfulness', 'Relationships'],
    feelings: ['Family issues', 'Career pressure'],
    supportTypes: ['Emotional support', 'Accountability partner'],
    values: ['Empathy', 'Authenticity'],
    isAnonymous: false,
    trustLevel: 5,
  );


  UserProfile get currentUser => _currentUser;

  void updateUserMoodStatus(String newStatus) {
    _currentUser = _currentUser.copyWith(moodStatus: newStatus);
    notifyListeners();
  }

  void updateUserProfile(UserProfile updatedProfile) {
    _currentUser = updatedProfile;
    notifyListeners();
  }

  Future<void> fetchCurrentUser() async {
    try {
      final res = await apiClient.get('/users/me');
      if (res.statusCode == 200) {
        final data = res.data;
        final baseUrl = AppConstants.apiBaseUrl.replaceAll('/api', '');
        String parsedAvatarUrl = data['avatarUrl'] ?? '';
        if (parsedAvatarUrl.isNotEmpty && !parsedAvatarUrl.startsWith('http')) {
          parsedAvatarUrl = baseUrl + parsedAvatarUrl;
        }

        int effectiveAge = _currentUser.age;
        if (data['age'] != null && data['age'] is int && (data['age'] as int) > 0) {
          effectiveAge = data['age'];
        }

        _currentUser = UserProfile(
          id: data['id'],
          name: data['pseudonym'] ?? 'Anonymous',
          displayName: data['displayName'],
          realFirstName: data['realFirstName'],
          legalFullName: data['legalFullName'],
          handle: data['handle'],
          nameDisplayPreference: data['nameDisplayPreference'] ?? 'DISPLAY_NAME_ONLY',
          age: effectiveAge,
          location: data['location'] ?? '',
          profession: data['profession'],
          bio: data['bio'] ?? '',
          avatarUrl: parsedAvatarUrl,
          images: List<String>.from(data['images'] ?? []),
          isVerified: true,
          isOnline: true,
          moodStatus: '',
          matchPercentage: 0,
          interests: List<String>.from(data['interests'] ?? []),
          feelings: List<String>.from(data['feelings'] ?? []),
          supportTypes: List<String>.from(data['supportTypes'] ?? []),
          values: [],
          isAnonymous: data['isAnonymous'] ?? false,
          trustLevel: 1,
        );
        notifyListeners();
      }
    } catch (e) {
      _currentUser = _currentUser.copyWith(name: 'Guest (Offline)');
      notifyListeners();
    }
  }

  // Config Options
  List<ConfigOption> availableInterests = [];
  List<ConfigOption> availableFeelings = [];
  List<ConfigOption> availableSupportTypes = [];
  ConfigLimits? configLimits;
  bool isConfigLoaded = false;
  bool configLoadError = false;

  Future<void> fetchConfigOptions() async {
    try {
      configLoadError = false;
      notifyListeners();
      
      final response = await apiClient.get('/config/options');
      if (response.statusCode == 200) {
        final data = response.data;
        
        final options = data['options'] as Map<String, dynamic>;
        availableInterests = (options['interests'] as List).map((o) => ConfigOption.fromJson(o)).toList();
        availableFeelings = (options['feelings'] as List).map((o) => ConfigOption.fromJson(o)).toList();
        availableSupportTypes = (options['supportTypes'] as List).map((o) => ConfigOption.fromJson(o)).toList();
        
        configLimits = ConfigLimits.fromJson(data['limits']);
        isConfigLoaded = true;
      } else {
        configLoadError = true;
      }
    } catch (e) {
      configLoadError = true;
    }
    notifyListeners();
  }

  // Onboarding temporary state
  String onboardingName = '';
  String onboardingDob = '14 / 08 / 1999';
  String onboardingLocation = 'Mumbai, India';
  String onboardingProfession = '';
  List<String> selectedInterests = ['Mental Health', 'Personal Growth', 'Relationships'];
  List<String> selectedFeelings = ['Lonely', 'Burnout'];
  List<String> selectedSupportTypes = ['Someone to Talk To', 'Emotional Support'];
  bool isAnonymousMode = false;
  bool pushNotifications = true;
  bool emailNotifications = true;
  bool smsNotifications = false;

  // Active Swipe Card Deck & Filtering
  final List<MatchCard> _cards = [];
  final List<MatchCard> _swipedHistory = [];
  String _activeDiscoveryFilter = 'For You';
  bool _isLoadingDeck = false;

  List<MatchCard> get cards => _cards;
  String get activeDiscoveryFilter => _activeDiscoveryFilter;
  bool get canRewind => _swipedHistory.isNotEmpty;
  bool get isLoadingDeck => _isLoadingDeck;

  List<MatchCard> get filteredCards {
    final available = _cards.where((c) => c.profile.id != _currentUser.id).toList();
    if (_activeDiscoveryFilter == 'New') {
      return available.where((c) => c.isNewHere).toList();
    } else if (_activeDiscoveryFilter == 'Active Now') {
      return available.where((c) => c.profile.isOnline).toList();
    } else if (_activeDiscoveryFilter == 'Near You') {
      return available.where((c) => c.profile.location.contains('Mumbai')).toList();
    }
    return available;
  }

  // Swiped history
  final List<UserProfile> _matchedUsers = [];
  List<UserProfile> get matchedUsers => _matchedUsers;

  // Last match that just happened (for celebration popup)
  MatchCard? _lastMatch;
  MatchCard? get lastMatch => _lastMatch;

  // Navigation shell current index
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  // Current selected mood today
  String? _todayMood;
  String? get todayMood => _todayMood;

  // Day streak & Weekly progress
  int _dayStreak = 0;
  int get dayStreak => _dayStreak;
  int _weeklyProgress = 0;
  int get weeklyProgress => _weeklyProgress;

  List<bool> get weekDaysCheckIn {
    return List.generate(7, (i) => i < _weeklyProgress);
  }
  
  void toggleWeekCheckIn(int idx) {
    // Deprecated: UI now reads weeklyProgress from backend
  }

  // Unread counts
  int _unreadNotifications = 0;
  int get unreadNotifications {
    if (_notifications.isNotEmpty) {
      return _notifications.where((n) => !n.isRead).length;
    }
    return _unreadNotifications;
  }
  
  int _unreadMessages = 0;
  int get unreadMessages => _unreadMessages;

  // Gamification XP & Level
  int _currentXp = 0;
  int _targetXp = 250;
  int _userLevel = 1;
  int get currentXp => _currentXp;
  int get targetXp => _targetXp;
  int get userLevel => _userLevel;

  int _calculateTargetXp(int level) {
    return level * 250;
  }

  // Subscription & Free Tier Limits
  bool isSubscribed = false;
  int _swipeCount = 0;
  DateTime? _lastPreferencesChangeDate;
  
  int get swipeCount => _swipeCount;

  void setSubscribed(bool value) {
    isSubscribed = value;
    notifyListeners();
  }
  
  bool canSwipe() {
    if (isSubscribed) return true;
    return _swipeCount < 5;
  }
  
  void incrementSwipe() {
    if (!isSubscribed) {
      _swipeCount++;
      notifyListeners();
    }
  }

  bool canChangePreferences() {
    if (isSubscribed) return true;
    if (_lastPreferencesChangeDate == null) return true;
    return DateTime.now().difference(_lastPreferencesChangeDate!).inDays >= 7;
  }

  void recordPreferencesChange() {
    if (!isSubscribed) {
      _lastPreferencesChangeDate = DateTime.now();
      notifyListeners();
    }
  }
  // Chats: map from userId -> list of ChatMessages
  final Map<String, List<ChatMessage>> _messages = {};
  Map<String, List<ChatMessage>> get messages => _messages;
  
  final Map<String, String> _conversationIds = {};
  String? getConversationId(String peerId) => _conversationIds[peerId];

  // Typing status per peer
  final Map<String, bool> _typingStatus = {};
  bool isPeerTyping(String peerId) => _typingStatus[peerId] ?? false;

  // Crisis detection flag
  bool _crisisDetected = false;
  bool get crisisDetected => _crisisDetected;

  // Journals & Filters
  final List<JournalEntry> _journalEntries = [];
  List<JournalEntry> get journalEntries => _journalEntries;
  String _selectedJournalFilter = 'All';
  String get selectedJournalFilter => _selectedJournalFilter;
  DateTime? _selectedJournalDate;
  DateTime? get selectedJournalDate => _selectedJournalDate;

  List<JournalEntry> get filteredJournalEntries {
    var filtered = _journalEntries;
    
    if (_selectedJournalFilter != 'All') {
      filtered = filtered.where((j) => j.category.toLowerCase() == _selectedJournalFilter.toLowerCase()).toList();
    }
    
    if (_selectedJournalDate != null) {
      filtered = filtered.where((j) => 
        j.date.year == _selectedJournalDate!.year && 
        j.date.month == _selectedJournalDate!.month && 
        j.date.day == _selectedJournalDate!.day
      ).toList();
    }
    
    return filtered;
  }
  
  void setJournalDate(DateTime? date) {
    _selectedJournalDate = date;
    notifyListeners();
  }

  // Community Posts, Filters & Comments
  final List<CommunityPost> _communityPosts = [];
  List<CommunityPost> get communityPosts => _communityPosts;
  String _communityFilter = 'Discussions';
  String get communityFilter => _communityFilter;

  final Map<String, List<CommunityComment>> _postComments = {};
  List<CommunityComment> getComments(String postId) => _postComments[postId] ?? [];

  // Wellness Goals
  final List<WellnessGoal> _goals = [];
  List<WellnessGoal> get goals => _goals;

  // Trusted Emergency Contacts
  final List<EmergencyContact> _emergencyContacts = [];
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  // Notifications
  final List<UserNotification> _notifications = [];
  List<UserNotification> get notifications => _notifications;

  AppState() {
    _loadPersistedMilestones();
  }

  // --- MILESTONES SYSTEM ---
  final Set<String> _persistedUnlockedMilestoneIds = {};
  Milestone? _latestUnlockedMilestone;
  Milestone? get latestUnlockedMilestone => _latestUnlockedMilestone;

  Future<void> _loadPersistedMilestones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _persistedUnlockedMilestoneIds.clear();
      final userId = _currentUser.id.isNotEmpty
          ? _currentUser.id
          : (await StorageHelper.read(key: 'user_id'));
      if (userId == null || userId.isEmpty) {
        notifyListeners();
        return;
      }
      final prefix = 'milestone_${userId}_unlocked_';
      final keys = prefs.getKeys();
      for (var k in keys) {
        if (k.startsWith(prefix) && prefs.getBool(k) == true) {
          _persistedUnlockedMilestoneIds.add(k.replaceFirst(prefix, ''));
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  List<Milestone> get milestones => _computeMilestones();

  List<Milestone> _computeMilestones() {
    final journalCount = _journalEntries.length;
    final completedGoals = _goals.where((g) => g.isCompleted).length;
    final totalGoals = _goals.isEmpty ? 1 : _goals.length;
    final streak = _dayStreak;
    final chatsCount = _messages.length;

    return [
      Milestone(
        id: 'first_journal',
        title: 'First Reflection',
        description: 'Wrote your first personal reflection in the journal',
        emoji: '📖',
        category: 'Journal',
        currentProgress: journalCount.clamp(0, 1),
        targetProgress: 1,
        isUnlocked: journalCount >= 1,
      ),
      Milestone(
        id: 'dedicated_journal',
        title: 'Mindful Explorer',
        description: 'Penned 3 heartfelt journal entries to process your thoughts',
        emoji: '✍️',
        category: 'Journal',
        currentProgress: journalCount.clamp(0, 3),
        targetProgress: 3,
        isUnlocked: journalCount >= 3,
      ),
      Milestone(
        id: 'journal_7',
        title: 'Deep Healer',
        description: 'Cultivated deep self-reflection with 7 journal entries',
        emoji: '🌟',
        category: 'Journal',
        currentProgress: journalCount.clamp(0, 7),
        targetProgress: 7,
        isUnlocked: journalCount >= 7,
      ),
      Milestone(
        id: 'streak_3',
        title: 'Consistency Spark',
        description: 'Built momentum by holding an active 3-day reflection streak',
        emoji: '🔥',
        category: 'Streak',
        currentProgress: streak.clamp(0, 3),
        targetProgress: 3,
        isUnlocked: streak >= 3,
      ),
      Milestone(
        id: 'streak_7',
        title: 'Weekly Champion',
        description: 'Nurtured daily mental wellness across a full 7-day streak',
        emoji: '⚡',
        category: 'Streak',
        currentProgress: streak.clamp(0, 7),
        targetProgress: 7,
        isUnlocked: streak >= 7,
      ),
      Milestone(
        id: 'first_goal',
        title: 'Goal Achiever',
        description: 'Conquered and completed your first weekly self-care goal',
        emoji: '🎯',
        category: 'Goals',
        currentProgress: completedGoals.clamp(0, 1),
        targetProgress: 1,
        isUnlocked: completedGoals >= 1,
      ),
      Milestone(
        id: 'all_goals',
        title: 'Master of Habits',
        description: 'Checked off all active wellness goals for the week',
        emoji: '🏆',
        category: 'Goals',
        currentProgress: _goals.isEmpty ? 0 : completedGoals.clamp(0, totalGoals),
        targetProgress: _goals.isEmpty ? 1 : totalGoals,
        isUnlocked: _goals.isNotEmpty && completedGoals >= totalGoals,
      ),
      Milestone(
        id: 'peer_connector',
        title: 'Empathetic Heart',
        description: 'Reached out to connect and chat with a supportive peer',
        emoji: '💬',
        category: 'Connection',
        currentProgress: chatsCount.clamp(0, 1),
        targetProgress: 1,
        isUnlocked: chatsCount >= 1,
      ),
    ];
  }

  Future<void> checkMilestones() async {
    final list = _computeMilestones();
    Milestone? newlyUnlocked;
    final userId = _currentUser.id.isNotEmpty
        ? _currentUser.id
        : (await StorageHelper.read(key: 'user_id'));

    for (final m in list) {
      if (m.isUnlocked && !_persistedUnlockedMilestoneIds.contains(m.id)) {
        _persistedUnlockedMilestoneIds.add(m.id);
        newlyUnlocked = m;
        if (userId != null && userId.isNotEmpty) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('milestone_${userId}_unlocked_${m.id}', true);
          } catch (_) {}
        }
      }
    }

    if (newlyUnlocked != null) {
      _latestUnlockedMilestone = newlyUnlocked;
      notifyListeners();
    }
  }

  void resetUserSession() {
    _cards.clear();
    _swipedHistory.clear();
    _lastMatch = null;
    _matchedUsers.clear();
    _journalEntries.clear();
    _emergencyContacts.clear();
    _goals.clear();
    _notifications.clear();
    _messages.clear();
    _conversationIds.clear();
    _persistedUnlockedMilestoneIds.clear();
    _latestUnlockedMilestone = null;
    _dayStreak = 0;
    _weeklyProgress = 0;
    _currentXp = 0;
    _targetXp = 250;
    _userLevel = 1;
    _unreadNotifications = 0;
    _unreadMessages = 0;
    _todayMood = null;
    _currentUser = UserProfile(
      id: '',
      name: 'Anonymous',
      age: 24,
      location: '',
      bio: '',
      avatarUrl: '',
      isVerified: false,
      isOnline: true,
      moodStatus: 'Peaceful',
      matchPercentage: 0,
    );
    notifyListeners();
  }

  // --- ACTIONS ---

  bool isLoadingData = false;

  Future<void> fetchConversations() async {
    try {
      final convRes = await apiClient.get('/conversations');
      _unreadMessages = 0;
      for (var c in convRes.data) {
        final peerId = c['peerId']?.toString() ?? '';
        if (peerId.isEmpty) continue;

        final convId = c['id']?.toString() ?? '';
        if (convId.isNotEmpty) {
          _conversationIds[peerId] = convId;
          joinConversation(convId);
        }

        _unreadMessages += (c['unreadCount'] as int? ?? 0);
        // fetch messages for conversation
        try {
          final msgRes = await apiClient.get('/conversations/$convId/messages');
          List<ChatMessage> chatMessages = [];
          for (var m in msgRes.data) {
            chatMessages.add(ChatMessage(
              id: m['id'],
              senderId: m['senderId'],
              text: m['content'],
              timestamp: DateTime.parse(m['createdAt']),
              isMine: m['senderId'] == _currentUser.id,
            ));
          }
          _messages[peerId] = chatMessages;
        } catch (_) {}

        final existingIdx = _matchedUsers.indexWhere((u) => u.id == peerId);
        String pAvatar = c['peerAvatar'] ?? '';
        if (pAvatar.isNotEmpty && !pAvatar.startsWith('http') && !pAvatar.startsWith('assets/')) {
          pAvatar = AppConstants.apiBaseUrl.replaceAll('/api', '') + (pAvatar.startsWith('/') ? pAvatar : '/$pAvatar');
        }
        if (pAvatar.isEmpty) pAvatar = 'assets/images/peer_test.jpg';

        final peerProfile = UserProfile(
          id: peerId,
          name: c['peerName'] ?? 'Anonymous',
          displayName: c['peerDisplayName'],
          realFirstName: c['peerRealFirstName'],
          handle: c['peerHandle'],
          isMutuallyRevealed: c['isMutuallyRevealed'] ?? false,
          myRevealed: c['myRevealed'] ?? false,
          peerRevealed: c['peerRevealed'] ?? false,
          age: 24,
          location: '',
          bio: '',
          avatarUrl: pAvatar,
          isVerified: true,
          isOnline: true,
          moodStatus: '',
          matchPercentage: 90,
          interests: [],
          values: [],
        );

        if (existingIdx != -1) {
          _matchedUsers[existingIdx] = _matchedUsers[existingIdx].copyWith(
            name: peerProfile.name,
            displayName: peerProfile.displayName,
            realFirstName: peerProfile.realFirstName,
            handle: peerProfile.handle,
            isMutuallyRevealed: peerProfile.isMutuallyRevealed,
            myRevealed: peerProfile.myRevealed,
            peerRevealed: peerProfile.peerRevealed,
            avatarUrl: (peerProfile.avatarUrl.isNotEmpty && !peerProfile.avatarUrl.contains('peer_test.jpg'))
                ? peerProfile.avatarUrl
                : _matchedUsers[existingIdx].avatarUrl,
          );
        } else {
          _matchedUsers.insert(0, peerProfile);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('fetchConversations error: $e');
    }
  }

  Future<void> fetchBackendData() async {
    isLoadingData = true;
    notifyListeners();
    try {
      final token = await StorageHelper.read(key: 'jwt_token');
      if (token != null) {
        initSocket(token);
      }

      await fetchConfigOptions();
      await fetchCurrentUser();

      // Fetch User Progress
      try {
        final progressRes = await apiClient.get('/progress');
        _currentXp = progressRes.data['xp'] ?? _currentXp;
        _dayStreak = progressRes.data['currentStreak'] ?? _dayStreak;
        _weeklyProgress = progressRes.data['weeklyProgress'] ?? _weeklyProgress;
      } catch(e) {
      }
      
      // Fetch Today's Mood
      try {
        final moodRes = await apiClient.get('/progress/mood/today');
        _todayMood = moodRes.data['mood'];
      } catch(e) {
      }
      
      // Fetch Unread Notifications
      try {
        final notifRes = await apiClient.get('/notifications/unread');
        _unreadNotifications = notifRes.data['unreadCount'] ?? 0;
      } catch(e) {
      }
      // Fetch Journals
      try {
        final journalRes = await apiClient.get('/journal');
        _journalEntries.clear();
        for (var entry in journalRes.data) {
          _journalEntries.add(JournalEntry(
            id: entry['id'],
            date: DateTime.parse(entry['createdAt']),
            mood: mapScoreToMood(entry['moodScore']),
            thought: entry['content'],
            gratitude: '', // backend does not have gratitude currently
            category: entry['category'] ?? 'General',
            isPrivate: entry['isPrivate'] ?? true,
          ));
        }
      } catch (e) {}
      
      // Fetch User Profile
      try {
        final meRes = await apiClient.get('/users/me');
        final data = meRes.data;
        final baseUrl = AppConstants.apiBaseUrl.replaceAll('/api', '');
        final avatar = (data['images'] != null && data['images'].isNotEmpty) 
          ? '$baseUrl${data['images'][0]}'
          : '';
          
        _currentUser = _currentUser.copyWith(
          id: data['id'],
          name: data['name'] ?? data['displayName'] ?? data['pseudonym'] ?? 'Anonymous',
          displayName: data['displayName'] ?? data['pseudonym'],
          realFirstName: data['realFirstName'],
          legalFullName: data['legalFullName'],
          handle: data['handle'],
          nameDisplayPreference: data['nameDisplayPreference'] ?? 'DISPLAY_NAME_ONLY',
          isAnonymous: data['isAnonymous'] ?? false,
          avatarUrl: avatar,
          bio: data['bio'] ?? '',
          profession: data['profession'],
          location: data['location'] ?? '',
          images: List<String>.from(data['images'] ?? []),
          interests: List<String>.from(data['interests'] ?? []),
          feelings: List<String>.from(data['feelings'] ?? []),
          supportTypes: List<String>.from(data['supportTypes'] ?? []),
        );
        _currentXp = data['xp'] ?? 0;
        _targetXp = _calculateTargetXp(_userLevel);
        notifyListeners();
        await _loadPersistedMilestones();
      } catch (e) {
        if (_currentUser.name == 'Loading...') {
          _currentUser = _currentUser.copyWith(name: 'Guest (Offline)');
          notifyListeners();
        }
      }

      // Fetch Conversations
      await fetchConversations();

      // Fetch Matches
      await fetchDiscoverDeck();
      // Fetch Community Posts
      try {
        final communityRes = await apiClient.get('/community');
        _communityPosts.clear();
        for (var p in communityRes.data) {
          _communityPosts.add(CommunityPost(
            id: p['id'],
            authorName: p['author']['pseudonym'] ?? 'Anonymous',
            authorBadge: p['author']['isAnonymous'] ? 'Anonymous Peer' : 'Member',
            authorAvatar: (p['author']['images'] != null && p['author']['images'].isNotEmpty) ? p['author']['images'][0] : '',
            timeAgo: _formatTimeAgo(DateTime.parse(p['createdAt'])),
            topic: p['topic'],
            content: p['content'],
            likesCount: p['_count'] != null ? (p['_count']['likes'] ?? 0) : 0,
            commentsCount: p['_count'] != null ? (p['_count']['comments'] ?? 0) : 0,
            isLiked: p['isLikedByMe'] ?? false,
          ));
        }
      } catch (e) {
      }
      // Fetch Goals
      try {
        final goalsRes = await apiClient.get('/goals');
        _goals.clear();
        for (var g in goalsRes.data) {
          _goals.add(WellnessGoal(
            id: g['id'],
            title: g['title'],
            subtitle: g['subtitle'] ?? '',
            progress: g['progress'] ?? 0.0,
            categoryColor: g['categoryColor'] ?? '0xFF5E4BEE',
            isCompleted: g['isCompleted'] ?? false,
          ));
        }
      } catch (e) {
      }


      // Fetch Notifications
      try {
        final notifRes = await apiClient.get('/notifications');
        _notifications.clear();
        for (var n in notifRes.data) {
          _notifications.add(UserNotification(
            id: n['id'],
            title: n['title'],
            content: n['content'],
            type: n['type'],
            isRead: n['isRead'] ?? false,
            createdAt: DateTime.parse(n['createdAt']),
          ));
        }
      } catch (e) {
      }
    } catch (e) {
    }
    await checkMilestones();
    isLoadingData = false;
    notifyListeners();
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
    if (index == 3) {
      fetchConversations();
    }
  }



  void setDiscoveryFilter(String filter) {
    _activeDiscoveryFilter = filter;
    notifyListeners();
  }

  Future<void> swipeLeft() async {
    if (_cards.isNotEmpty) {
      incrementSwipe();
      final popped = _cards.removeAt(0);
      _swipedHistory.add(popped);
      notifyListeners();
      
      try {
        await apiClient.post('/match/swipe', data: {
          'targetUserId': popped.profile.id,
          'action': 'pass'
        });
      } catch (e) {
      }
    }
  }

  Future<bool> swipeRight() async {
    if (_cards.isEmpty) return false;
    incrementSwipe();
    final popped = _cards.removeAt(0);
    _swipedHistory.add(popped);
    
    try {
      final res = await apiClient.post('/match/swipe', data: {
        'targetUserId': popped.profile.id,
        'action': 'connect'
      });
      
      if (res.data['isMatch'] == true) {
        final convData = res.data['conversation'];
        if (convData != null && convData['id'] != null) {
          final convId = convData['id'].toString();
          _conversationIds[popped.profile.id] = convId;
          joinConversation(convId);
        }

        final existingIdx = _matchedUsers.indexWhere((u) => u.id == popped.profile.id);
        if (existingIdx != -1) {
          _matchedUsers[existingIdx] = popped.profile;
        } else {
          _matchedUsers.insert(0, popped.profile);
        }
        _lastMatch = popped;
        _currentXp += 50; 
        notifyListeners();
        // Trigger live conversation sync in background
        fetchConversations();
        return true; 
      } else {
        notifyListeners();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  void superSupport() {
    if (_cards.isEmpty) return;
    incrementSwipe();
    final popped = _cards.removeAt(0);
    _swipedHistory.add(popped);
    _matchedUsers.insert(0, popped.profile);
    _lastMatch = popped;
    _currentXp += 100;
    if (!_messages.containsKey(popped.profile.id)) {
      _messages[popped.profile.id] = [
        ChatMessage(
          id: 'super_${DateTime.now().millisecondsSinceEpoch}',
          senderId: popped.profile.id,
          text: '⭐ Wow! Thank you for the Super Support star! Sending you so much warmth and positivity today. 💜',
          timestamp: DateTime.now(),
          isMine: false,
          isIcebreaker: true,
        ),
      ];
    }
    notifyListeners();
  }

  void rewindLastSwipe() {
    if (_swipedHistory.isNotEmpty) {
      final restored = _swipedHistory.removeLast();
      _cards.insert(0, restored);
      if (_matchedUsers.contains(restored.profile)) {
        _matchedUsers.remove(restored.profile);
      }
      notifyListeners();
    }
  }

  Future<void> fetchDiscoverDeck() async {
    _isLoadingDeck = true;
    notifyListeners();

    try {
      final discoverRes = await apiClient.get('/match/discover');
      _cards.clear();
      final List matchesData = discoverRes.data['matches'] ?? [];

      final currentUserId = _currentUser.id;
      final savedUserId = await StorageHelper.read(key: 'user_id');
      final savedEmail = (await StorageHelper.read(key: 'user_email'))?.toLowerCase();
      final currentHandle = _currentUser.handle;

      for (var peer in matchesData) {
        final peerId = peer['id']?.toString() ?? '';
        // 1. Strictly filter out own profile
        if (peerId.isEmpty || peerId == currentUserId || (savedUserId != null && peerId == savedUserId)) {
          continue;
        }
        if (savedEmail != null && peer['email'] != null && peer['email'].toString().toLowerCase() == savedEmail) {
          continue;
        }
        if (currentHandle != null && currentHandle.isNotEmpty && peer['handle'] == currentHandle) {
          continue;
        }

        String pAvatar = peer['avatar'] ?? '';
        if (pAvatar.isEmpty && peer['images'] != null && (peer['images'] as List).isNotEmpty) {
          pAvatar = peer['images'][0];
        }
        if (pAvatar.isNotEmpty && !pAvatar.startsWith('http') && !pAvatar.startsWith('assets/')) {
          pAvatar = AppConstants.apiBaseUrl.replaceAll('/api', '') + (pAvatar.startsWith('/') ? pAvatar : '/$pAvatar');
        }

        final cardName = peer['cardName'] ?? peer['card_name'] ?? peer['name'] ?? peer['displayName'] ?? peer['pseudonym'] ?? 'Anonymous';
        final cardAlias = peer['displayName'] ?? peer['display_name'] ?? peer['pseudonym'];

        int peerAge = 24;
        if (peer['age'] != null && peer['age'] is int && peer['age'] > 0) {
          peerAge = peer['age'];
        }

        _cards.add(MatchCard(
          profile: UserProfile(
            id: peerId,
            name: cardName,
            displayName: cardAlias,
            handle: peer['handle'],
            age: peerAge,
            location: peer['location'] ?? 'Remote',
            bio: peer['bio'] ?? '',
            avatarUrl: pAvatar,
            images: peer['images'] != null ? List<String>.from(peer['images']) : (pAvatar.isNotEmpty ? [pAvatar] : []),
            isVerified: true,
            isOnline: true,
            moodStatus: '',
            matchPercentage: peer['score'] != null ? (peer['score'] * 10).clamp(50, 99).toInt() : 90,
            interests: peer['interests'] != null ? List<String>.from(peer['interests']) : [],
            supportTypes: peer['supportTypes'] != null ? List<String>.from(peer['supportTypes']) : [],
            feelings: peer['feelings'] != null ? List<String>.from(peer['feelings']) : [],
            values: peer['supportTypes'] != null ? List<String>.from(peer['supportTypes']) : [],
          ),
          isNewHere: true,
          commonInterests: peer['interests'] != null ? List<String>.from(peer['interests']).take(3).toList() : [],
        ));
      }
    } catch (e) {
      debugPrint('fetchDiscoverDeck error: $e');
    } finally {
      _isLoadingDeck = false;
      notifyListeners();
    }
  }

  Future<void> refreshDeck() async {
    await fetchDiscoverDeck();
  }

  void clearLastMatch() {
    _lastMatch = null;
    notifyListeners();
  }

  // --- SOCKET.IO CHAT INTEGRATION ---
  io.Socket? _socket;

  void initSocket(String token) {
    if (_socket != null) return;
    
    _socket = io.io(AppConstants.socketUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .build());

    _socket?.onConnect((_) {
      debugPrint('[Socket] Connected to server successfully');
    });

    _socket?.on('new_match', (data) {
      debugPrint('[Socket] Live new_match received: $data');
      fetchConversations();
    });

    _socket?.on('receive_message', (data) {
      final msg = ChatMessage(
        id: data['id'],
        senderId: data['senderId'],
        text: data['content'],
        timestamp: DateTime.parse(data['createdAt']),
        isMine: data['senderId'] == _currentUser.id,
      );
      // We need to know which peer this belongs to. 
      // If we sent it, it's already in UI, but to avoid duplication we could ignore if isMine
      if (!msg.isMine) {
        _messages.putIfAbsent(data['senderId'], () => []).add(msg);
        if (!_matchedUsers.any((u) => u.id == data['senderId'])) {
          fetchConversations();
        } else {
          notifyListeners();
        }
      }
    });

    _socket?.on('identity_revealed', (data) {
      final convId = data['conversationId'];
      final userAFirstName = data['userAFirstName'] as String?;
      final userBFirstName = data['userBFirstName'] as String?;
      final userAId = data['userAId'] as String?;
      final userBId = data['userBId'] as String?;

      for (int i = 0; i < _matchedUsers.length; i++) {
        final u = _matchedUsers[i];
        final matchConvId = _conversationIds[u.id];
        if (matchConvId == convId || u.id == userAId || u.id == userBId) {
          String? peerName;
          if (u.id == userAId) {
            peerName = userAFirstName;
          } else if (u.id == userBId) {
            peerName = userBFirstName;
          } else {
            peerName = (_currentUser.id == userAId) ? userBFirstName : userAFirstName;
          }

          _matchedUsers[i] = u.copyWith(
            isMutuallyRevealed: true,
            myRevealed: true,
            peerRevealed: true,
            realFirstName: peerName ?? u.realFirstName,
          );
        }
      }
      notifyListeners();
    });

    _socket?.on('name_reveal_requested', (data) {
      final convId = data['conversationId'];
      final requesterId = data['requesterId'];

      for (int i = 0; i < _matchedUsers.length; i++) {
        final u = _matchedUsers[i];
        if (_conversationIds[u.id] == convId || u.id == requesterId) {
          if (requesterId == _currentUser.id) {
            _matchedUsers[i] = u.copyWith(myRevealed: true);
          } else {
            _matchedUsers[i] = u.copyWith(peerRevealed: true);
          }
        }
      }
      notifyListeners();
    });

    _socket?.on('name_reveal_declined', (data) {
      final convId = data['conversationId'];
      final declinerId = data['declinerId'];

      for (int i = 0; i < _matchedUsers.length; i++) {
        final u = _matchedUsers[i];
        if (_conversationIds[u.id] == convId || u.id == declinerId) {
          _matchedUsers[i] = u.copyWith(peerRevealed: false);
        }
      }
      notifyListeners();
    });
  }

  void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', conversationId);
  }

  void sendMessage(String receiverId, String text, String conversationId, {bool isIcebreaker = false}) {
    if (text.trim().isEmpty) return;
    final cleanText = text.trim();

    // Check crisis keywords
    final lower = cleanText.toLowerCase();
    const crisisKeywords = ['suicide', 'kill myself', 'end it all', 'self-harm', 'self harm', 'hurt myself', 'want to die', 'hopeless', "can't go on", 'no reason to live'];
    final isCrisis = crisisKeywords.any((keyword) => lower.contains(keyword));

    if (isCrisis) {
      _crisisDetected = true;
    }

    final msg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUser.id,
      text: cleanText,
      timestamp: DateTime.now(),
      isMine: true,
      isIcebreaker: isIcebreaker,
      isCrisisIntervention: isCrisis,
    );
    _messages.putIfAbsent(receiverId, () => []).add(msg);
    _currentXp += 10;
    notifyListeners();

    // Emit to backend
    _socket?.emit('send_message', {
      'conversationId': conversationId,
      'content': cleanText
    });
  }

  void sendVoiceNote(String receiverId, int durationSeconds) {
    final msg = ChatMessage(
      id: 'voice_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUser.id,
      text: 'Voice note (${durationSeconds}s)',
      timestamp: DateTime.now(),
      isMine: true,
      isVoiceNote: true,
      voiceDurationSeconds: durationSeconds,
    );
    _messages.putIfAbsent(receiverId, () => []).add(msg);
    _currentXp += 15;
    notifyListeners();

    // Simulate peer reply to voice note
    Timer(const Duration(milliseconds: 1800), () {
      final replyMsg = ChatMessage(
        id: 'reply_voice_${DateTime.now().millisecondsSinceEpoch}',
        senderId: receiverId,
        text: "Hearing your voice makes this feel so much more connected and comforting! Thank you for sharing. 💜",
        timestamp: DateTime.now(),
        isMine: false,
      );
      _messages.putIfAbsent(receiverId, () => []).add(replyMsg);
      notifyListeners();
    });
  }

  void resetCrisisDetected() {
    _crisisDetected = false;
    notifyListeners();
  }

  Future<void> reportAndBlockPeer(String peerId, String reason) async {
    _matchedUsers.removeWhere((u) => u.id == peerId);
    _messages.remove(peerId);
    _cards.removeWhere((c) => c.profile.id == peerId);
    notifyListeners();
    
    try {
      await apiClient.post('/users/$peerId/block');
      await apiClient.post('/users/$peerId/report', data: {
        'reason': reason,
        'description': 'User reported from chat'
      });
    } catch (e) {
    }
  }

  // --- PROGRESSIVE IDENTITY DISCLOSURE ---
  Future<void> fetchConversationDisclosure(String peerId) async {
    final convId = _conversationIds[peerId];
    if (convId == null) return;
    try {
      final res = await apiClient.get('/conversations/$convId/disclosure');
      if (res.statusCode == 200) {
        final data = res.data;
        final isMutuallyRevealed = data['isMutuallyRevealed'] == true;
        final myRevealed = data['myRevealed'] == true;
        final peerRevealed = data['peerRevealed'] == true;
        final peerRealFirstName = data['peerRealFirstName'] as String?;

        for (int i = 0; i < _matchedUsers.length; i++) {
          if (_matchedUsers[i].id == peerId) {
            _matchedUsers[i] = _matchedUsers[i].copyWith(
              isMutuallyRevealed: isMutuallyRevealed,
              myRevealed: myRevealed,
              peerRevealed: peerRevealed,
              realFirstName: peerRealFirstName ?? _matchedUsers[i].realFirstName,
            );
            break;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching disclosure: $e');
    }
  }

  Future<bool> revealName(String peerId, String conversationId, {String? realFirstName}) async {
    try {
      final res = await apiClient.post(
        '/conversations/$conversationId/reveal-name',
        data: {
          if (realFirstName != null && realFirstName.trim().isNotEmpty)
            'realFirstName': realFirstName.trim(),
        },
      );
      if (res.statusCode == 200) {
        final data = res.data;
        final isMutuallyRevealed = data['isMutuallyRevealed'] == true;
        final myRevealed = data['myRevealed'] == true;
        final peerRevealed = data['peerRevealed'] == true;
        final peerRealFirstName = data['peerRealFirstName'] as String?;

        if (realFirstName != null && realFirstName.trim().isNotEmpty) {
          _currentUser = _currentUser.copyWith(realFirstName: realFirstName.trim());
        }

        for (int i = 0; i < _matchedUsers.length; i++) {
          if (_matchedUsers[i].id == peerId) {
            _matchedUsers[i] = _matchedUsers[i].copyWith(
              isMutuallyRevealed: isMutuallyRevealed,
              myRevealed: myRevealed,
              peerRevealed: peerRevealed,
              realFirstName: peerRealFirstName ?? _matchedUsers[i].realFirstName,
            );
            break;
          }
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error revealing name: $e');
    }
    return false;
  }

  Future<void> declineReveal(String peerId, String conversationId) async {
    try {
      await apiClient.post('/conversations/$conversationId/decline-reveal');
      for (int i = 0; i < _matchedUsers.length; i++) {
        if (_matchedUsers[i].id == peerId) {
          _matchedUsers[i] = _matchedUsers[i].copyWith(peerRevealed: false);
          break;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error declining reveal: $e');
    }
  }

  Future<bool> updateNameDisplayPreference(String preference) async {
    try {
      final res = await apiClient.put(
        '/users/me',
        data: {'nameDisplayPreference': preference},
      );
      if (res.statusCode == 200) {
        _currentUser = _currentUser.copyWith(nameDisplayPreference: preference);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating name display preference: $e');
    }
    return false;
  }

  static String mapScoreToMood(dynamic score) {
    final s = score?.toString();
    switch (s) {
      case '5': return 'Amazing';
      case '4': return 'Good';
      case '3': return 'Okay';
      case '2': return 'Tired';
      case '1': return 'Stressed';
      default:
        if (['Amazing', 'Good', 'Okay', 'Tired', 'Stressed', 'Great', 'Not Good', 'Struggling'].contains(s)) return s!;
        return 'Okay';
    }
  }

  static int mapMoodToScore(String mood) {
    switch (mood) {
      case 'Amazing':
      case 'Great':
        return 5;
      case 'Good':
        return 4;
      case 'Okay':
        return 3;
      case 'Tired':
      case 'Not Good':
        return 2;
      case 'Stressed':
      case 'Struggling':
        return 1;
      default:
        return 3;
    }
  }

  Future<JournalEntry?> addJournalEntry(String mood, String thought, String gratitude, String category, {bool isPrivate = true}) async {
    try {
      final score = mapMoodToScore(mood);
      final res = await apiClient.post('/journal/create', data: {
        'content': thought,
        'moodScore': score,
        'category': category,
        'isPrivate': isPrivate,
      });

      final entryId = res.data != null && res.data['entry'] != null && res.data['entry']['id'] != null
          ? res.data['entry']['id'].toString()
          : 'j_${DateTime.now().millisecondsSinceEpoch}';
      final createdAt = res.data != null && res.data['entry'] != null && res.data['entry']['createdAt'] != null
          ? DateTime.tryParse(res.data['entry']['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now();

      final entry = JournalEntry(
        id: entryId,
        date: createdAt,
        mood: mood,
        thought: thought,
        gratitude: gratitude,
        category: category,
        isPrivate: isPrivate,
      );
      _journalEntries.insert(0, entry);

      if (!isPrivate) {
        _communityPosts.insert(0, CommunityPost(
          id: entryId,
          authorName: _currentUser.isAnonymous ? 'Anonymous' : _currentUser.name,
          authorBadge: _currentUser.isAnonymous ? 'Anonymous Peer' : 'Member',
          authorAvatar: _currentUser.isAnonymous ? '' : _currentUser.avatarUrl,
          timeAgo: 'Just now',
          topic: category,
          content: thought,
          likesCount: 0,
          commentsCount: 0,
          isLiked: false,
        ));
      }
      
      // Update XP from backend
      if (res.data != null && res.data['user'] != null) {
        _currentXp = res.data['user']['xp'] ?? _currentXp;
        _dayStreak = res.data['user']['currentStreak'] ?? _dayStreak;
      }
      
      // Sync today's mood check-in with journal reflection
      checkInMood(mood);

      notifyListeners();
      await checkMilestones();
      return entry;
    } catch (e) {
      final fallbackEntry = JournalEntry(
        id: 'j_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        mood: mood,
        thought: thought,
        gratitude: gratitude,
        category: category,
        isPrivate: isPrivate,
      );
      _journalEntries.insert(0, fallbackEntry);
      checkInMood(mood);
      notifyListeners();
      return fallbackEntry;
    }
  }

  Future<bool> updateJournalEntry(String id, String mood, String thought, String gratitude, String category, {required bool isPrivate}) async {
    try {
      final score = mapMoodToScore(mood);
      await apiClient.put('/journal/$id', data: {
        'content': thought,
        'moodScore': score,
        'category': category,
        'isPrivate': isPrivate,
      });

      final idx = _journalEntries.indexWhere((j) => j.id == id);
      if (idx != -1) {
        _journalEntries[idx] = JournalEntry(
          id: id,
          date: _journalEntries[idx].date,
          mood: mood,
          thought: thought,
          gratitude: gratitude,
          category: category,
          isPrivate: isPrivate,
          photoUrl: _journalEntries[idx].photoUrl,
        );
      }

      // Sync today's mood check-in
      checkInMood(mood);

      notifyListeners();
      await checkMilestones();
      return true;
    } catch (e) {
      return false;
    }
  }

  void deleteJournalEntry(String id) {
    _journalEntries.removeWhere((j) => j.id == id);
    notifyListeners();
  }

  void setJournalFilter(String filter) {
    _selectedJournalFilter = filter;
    notifyListeners();
  }

  Future<void> checkInMood(String mood) async {
    final oldMood = _todayMood;
    _todayMood = mood;
    notifyListeners();
    try {
      await apiClient.post('/progress/mood', data: {'mood': mood});
      fetchBackendData(); // refresh streaks
    } catch(e) {
      _todayMood = oldMood;
      notifyListeners();
    }
  }

  Future<void> toggleGoal(String goalId) async {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx != -1) {
      final current = _goals[idx];
      final newStatus = !current.isCompleted;
      
      // Optimistic update
      _goals[idx] = current.copyWith(
        isCompleted: newStatus,
        progress: newStatus ? 1.0 : 0.5,
      );
      _currentXp += newStatus ? 50 : -50;
      notifyListeners();
      await checkMilestones();

      try {
        await apiClient.put('/goals/$goalId/toggle');
      } catch (e) {
        // Revert on failure
        _goals[idx] = current;
        _currentXp -= newStatus ? 50 : -50;
        notifyListeners();
      }
    }
  }

  Future<void> addGoal(String title, String subtitle, String categoryColor) async {
    try {
      final res = await apiClient.post('/goals', data: {
        'title': title,
        'subtitle': subtitle,
        'categoryColor': categoryColor,
      });
      final g = res.data;
      final goal = WellnessGoal(
        id: g['id'],
        title: g['title'],
        subtitle: g['subtitle'],
        progress: g['progress'] ?? 0.1,
        categoryColor: g['categoryColor'] ?? categoryColor,
        isCompleted: g['isCompleted'] ?? false,
      );
      _goals.add(goal);
      _currentXp += 40;
      notifyListeners();
    } catch (e) {
    }
  }

  void setCommunityFilter(String filter) {
    _communityFilter = filter;
    notifyListeners();
  }

  void togglePostLike(String postId) async {
    final idx = _communityPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final post = _communityPosts[idx];
      post.isLiked = !post.isLiked;
      post.likesCount += post.isLiked ? 1 : -1;
      notifyListeners();

      try {
        await apiClient.post('/community/$postId/like');
      } catch (e) {
        // revert on error
        post.isLiked = !post.isLiked;
        post.likesCount += post.isLiked ? 1 : -1;
        notifyListeners();
      }
    }
  }

  void togglePostSave(String postId) {
    final idx = _communityPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final post = _communityPosts[idx];
      post.isSaved = !post.isSaved;
      notifyListeners();
    }
  }

  Future<void> addCommunityPost(String topic, String content) async {
    try {
      final res = await apiClient.post('/community', data: {
        'topic': topic,
        'content': content,
      });
      
      final p = res.data;
      final post = CommunityPost(
        id: p['id'],
        authorName: p['author']['pseudonym'] ?? 'Anonymous',
        authorBadge: p['author']['isAnonymous'] ? 'Anonymous Peer' : 'Member',
        authorAvatar: (p['author']['images'] != null && p['author']['images'].isNotEmpty) ? p['author']['images'][0] : '',
        timeAgo: 'Just now',
        topic: p['topic'],
        content: p['content'],
        likesCount: p['likesCount'] ?? 0,
        commentsCount: 0,
        isLiked: false,
      );
      _communityPosts.insert(0, post);
      _currentXp += 75;
      notifyListeners();
    } catch (e) {
    }
  }

  Future<void> toggleCommunityPostLike(String postId) async {
    final idx = _communityPosts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    
    final post = _communityPosts[idx];
    final originalState = post.isLiked;
    
    post.isLiked = !originalState;
    post.likesCount += post.isLiked ? 1 : -1;
    notifyListeners();

    try {
      final res = await apiClient.post('/community/$postId/like');
      if (res.data['liked'] != post.isLiked) {
        post.isLiked = res.data['liked'];
        post.likesCount += post.isLiked ? 1 : -1;
        notifyListeners();
      }
    } catch (e) {
      post.isLiked = originalState;
      post.likesCount += originalState ? 1 : -1;
      notifyListeners();
    }
  }

  Future<void> addComment(String postId, String commentText) async {
    if (commentText.trim().isEmpty) return;
    
    try {
      final res = await apiClient.post('/community/$postId/comments', data: {
        'text': commentText.trim(),
      });
      
      final c = res.data;
      final comment = CommunityComment(
        id: c['id'],
        authorName: c['author']['pseudonym'] ?? 'Anonymous',
        authorAvatar: (c['author']['images'] != null && c['author']['images'].isNotEmpty) ? c['author']['images'][0] : '',
        text: c['text'],
        timeAgo: 'Just now',
      );
      
      _postComments.putIfAbsent(postId, () => []).add(comment);
      final idx = _communityPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        _communityPosts[idx].commentsCount += 1;
      }
      _currentXp += 20;
      notifyListeners();
    } catch (e) {
    }
  }

  Future<void> addEmergencyContact(String name, String phone, String relationship) async {}

  Future<void> removeEmergencyContact(String id) async {}

  Future<bool> setAnonymity(bool val) async {
    final oldVal = isAnonymousMode;
    isAnonymousMode = val;
    _currentUser = _currentUser.copyWith(
      isAnonymous: val,
    );
    notifyListeners();
    try {
      await apiClient.put('/users/me', data: {'isAnonymous': val});
      return true;
    } catch (e) {
      isAnonymousMode = oldVal;
      _currentUser = _currentUser.copyWith(isAnonymous: oldVal);
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      await apiClient.post('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount({required String password}) async {
    try {
      await apiClient.delete('/users/me', data: {'password': password});
      return true;
    } catch (e) {
      rethrow;
    }
  }



  /// Automatically initialize and hydrate user profile from newly created auth registration
  void initializeUserFromAuth({
    required String id,
    required String name,
    required String email,
  }) {
    onboardingName = name;
    _currentUser = _currentUser.copyWith(
      id: id,
      name: name,
    );
    _recalculateMatchScores();
    notifyListeners();
  }

  /// Dynamic match score calculator based on created user's actual selected interests & struggles
  void _recalculateMatchScores() {
    for (int i = 0; i < _cards.length; i++) {
      final card = _cards[i];
      final peer = card.profile;

      // Find real shared topics between new user's interests & peer's profile
      final userInterests = _currentUser.interests;
      final peerInterests = peer.interests;
      final common = userInterests.where((item) {
        return peerInterests.any((p) =>
            p.toLowerCase().contains(item.toLowerCase()) ||
            item.toLowerCase().contains(p.toLowerCase()));
      }).toList();

      // Check if peer mentions struggles matching user's selected feelings
      final feelingOverlap = selectedFeelings.any((f) =>
          peer.bio.toLowerCase().contains(f.toLowerCase()) ||
          peer.moodStatus.toLowerCase().contains(f.toLowerCase()));

      int baseScore = 80;
      baseScore += (common.length * 5).clamp(0, 14);
      if (feelingOverlap) baseScore += 5;
      if (peer.location.toLowerCase().contains(_currentUser.location.split(',').first.toLowerCase())) {
        baseScore += 3;
      }
      final computedPercentage = baseScore.clamp(82, 98);

      final commonDisplay = common.isNotEmpty ? common : card.commonInterests;
      final reason = feelingOverlap
          ? 'You both share experience with ${selectedFeelings.join(' & ')}. Empathetic listener match 💜'
          : 'You both believe in ${commonDisplay.take(2).join(' & ')}. Kind growth alignment 🌱';

      _cards[i] = MatchCard(
        profile: peer.copyWith(matchPercentage: computedPercentage),
        isNewHere: card.isNewHere,
        commonInterests: commonDisplay,
        compatibilityReason: reason,
      );
    }
  }

  void completeOnboarding({
    String? name,
    String? displayName,
    String? realFirstName,
    String? handle,
    String? nameDisplayPreference,
    String? location,
    String? profession,
    int? age,
    List<String>? interests,
    List<String>? feelings,
    List<String>? supportTypes,
    bool? isAnonymous,
    String? bio,
  }) {
    final effectiveDisplayName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : (name != null && name.trim().isNotEmpty ? name.trim() : null);

    if (effectiveDisplayName != null) onboardingName = effectiveDisplayName;
    if (location != null && location.trim().isNotEmpty) onboardingLocation = location.trim();
    if (profession != null && profession.trim().isNotEmpty) onboardingProfession = profession.trim();
    if (interests != null && interests.isNotEmpty) selectedInterests = interests;
    if (feelings != null && feelings.isNotEmpty) selectedFeelings = feelings;
    if (supportTypes != null && supportTypes.isNotEmpty) selectedSupportTypes = supportTypes;
    if (isAnonymous != null) isAnonymousMode = isAnonymous;


    final derivedBio = (bio != null && bio.trim().isNotEmpty) ? bio.trim() : '';

    _currentUser = _currentUser.copyWith(
      name: isAnonymousMode ? 'Kind Peer' : (onboardingName.isNotEmpty ? onboardingName : 'User'),
      displayName: effectiveDisplayName ?? _currentUser.displayName,
      realFirstName: realFirstName != null && realFirstName.trim().isNotEmpty ? realFirstName.trim() : _currentUser.realFirstName,
      handle: handle ?? _currentUser.handle,
      nameDisplayPreference: nameDisplayPreference ?? _currentUser.nameDisplayPreference,
      age: age ?? _currentUser.age,
      location: onboardingLocation.isNotEmpty ? onboardingLocation : 'Mumbai, India',
      profession: onboardingProfession.isNotEmpty ? onboardingProfession : null,
      interests: selectedInterests,
      feelings: selectedFeelings,
      supportTypes: selectedSupportTypes,
      isAnonymous: isAnonymousMode,
      bio: derivedBio,
    );

    _recalculateMatchScores();
    notifyListeners();
  }

  Future<void> markNotificationsRead() async {
    try {
      await apiClient.put('/notifications/read-all');
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = UserNotification(
          id: _notifications[i].id,
          title: _notifications[i].title,
          content: _notifications[i].content,
          type: _notifications[i].type,
          isRead: true,
          createdAt: _notifications[i].createdAt,
        );
      }
      notifyListeners();
    } catch (e) {
    }
  }

  void resetAllData() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    _cards.clear();
    _swipedHistory.clear();
    _lastMatch = null;
    _messages.clear();
    _matchedUsers.clear();
    _conversationIds.clear();
    _notifications.clear();
    notifyListeners();
  }
}
