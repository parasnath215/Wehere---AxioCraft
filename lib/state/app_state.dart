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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppState extends ChangeNotifier {
  // Current Logged-in User
  UserProfile _currentUser = UserProfile(
    id: 'user_alex',
    name: 'Alex',
    age: 24,
    location: 'Mumbai, India',
    bio: 'Learning to be kind to myself one day at a time. 🌱',
    avatarUrl: 'assets/mockups/user_dashboard_alex.jpeg',
    isVerified: true,
    isOnline: true,
    moodStatus: 'Healing & Growing 💜',
    matchPercentage: 92,
    interests: ['Mental Health', 'Personal Growth', 'Relationships', 'Mindfulness'],
    lookingFor: 'Someone to Talk To & Accountability Partner',
    values: ['Honesty', 'Empathy', 'Respect', 'Growth'],
    isAnonymous: false,
    trustLevel: 1,
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

  // Onboarding temporary state
  String onboardingName = 'Alex';
  String onboardingDob = '14 / 08 / 1999';
  String onboardingLocation = 'Mumbai, India';
  List<String> selectedInterests = ['Mental Health', 'Personal Growth', 'Relationships'];
  List<String> selectedFeelings = ['Lonely', 'Burnout'];
  List<String> selectedSupportTypes = ['Someone to Talk To', 'Emotional Support'];
  bool isAnonymousMode = false;
  bool pushNotifications = true;
  bool emailNotifications = true;
  bool smsNotifications = false;

  // Active Swipe Card Deck & Filtering
  List<MatchCard> _cards = [];
  final List<MatchCard> _swipedHistory = [];
  String _activeDiscoveryFilter = 'For You';

  List<MatchCard> get cards => _cards;
  String get activeDiscoveryFilter => _activeDiscoveryFilter;
  bool get canRewind => _swipedHistory.isNotEmpty;

  List<MatchCard> get filteredCards {
    if (_activeDiscoveryFilter == 'New') {
      return _cards.where((c) => c.isNewHere).toList();
    } else if (_activeDiscoveryFilter == 'Active Now') {
      return _cards.where((c) => c.profile.isOnline).toList();
    } else if (_activeDiscoveryFilter == 'Near You') {
      return _cards.where((c) => c.profile.location.contains('Mumbai')).toList();
    }
    return _cards;
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
  String _todayMood = 'Good';
  String get todayMood => _todayMood;

  // Day streak & Weekly check-ins (Mon-Sun)
  int _dayStreak = 16;
  int get dayStreak => _dayStreak;
  final List<bool> _weekDaysCheckIn = [true, true, true, true, true, false, false];
  List<bool> get weekDaysCheckIn => _weekDaysCheckIn;

  // Gamification XP & Level
  int _currentXp = 2350;
  final int _targetXp = 3000;
  final int _userLevel = 12;
  int get currentXp => _currentXp;
  int get targetXp => _targetXp;
  int get userLevel => _userLevel;

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
  final List<EmergencyContact> _emergencyContacts = [
    EmergencyContact(
      id: 'ec1',
      name: 'Neha Verma (Peer Supporter)',
      phone: '+91 98200 12345',
      relationship: 'Certified Peer Supporter',
    ),
    EmergencyContact(
      id: 'ec2',
      name: 'Priya (Sister)',
      phone: '+91 98111 54321',
      relationship: 'Family Member',
    ),
  ];
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;

  AppState() {
    _initMockData();
  }

  void _initMockData() {
    // All mock data has been removed.
    // The app will now rely purely on live data fetched from the backend.
  }

  // --- ACTIONS ---

  bool isLoadingData = false;

  Future<void> fetchBackendData() async {
    isLoadingData = true;
    notifyListeners();
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      if (token != null) {
        initSocket(token);
      }

      // Fetch User Progress
      final progressRes = await apiClient.get('/progress');
      _currentXp = progressRes.data['xp'] ?? _currentXp;
      // Fetch Journals
      final journalRes = await apiClient.get('/journal');
      _journalEntries.clear();
      for (var entry in journalRes.data) {
        _journalEntries.add(JournalEntry(
          id: entry['id'],
          date: DateTime.parse(entry['createdAt']),
          mood: entry['moodScore'].toString(),
          thought: entry['content'],
          gratitude: '', // backend does not have gratitude currently
          category: entry['category'] ?? 'General',
        ));
      }
      
      // Fetch User Profile
      try {
        final meRes = await apiClient.get('/users/me');
        final data = meRes.data;
        final avatar = (data['images'] != null && data['images'].isNotEmpty) 
          ? '${AppConstants.apiBaseUrl}${data['images'][0]}'
          : 'assets/mockups/user_dashboard_alex.jpeg';
          
        _currentUser = _currentUser.copyWith(
          id: data['id'],
          name: data['pseudonym'] ?? 'Anonymous',
          isAnonymous: data['isAnonymous'] ?? false,
          avatarUrl: avatar,
          bio: data['bio'] ?? '',
          location: data['location'] ?? '',
          lookingFor: data['lookingFor'] ?? '',
        );
        _currentXp = data['xp'] ?? 0;
        _targetXp = _calculateTargetXp(_userLevel);
        notifyListeners();
      } catch (e) {
        print("Failed to fetch user profile: $e");
      }

      // Fetch Conversations
      try {
        final convRes = await apiClient.get('/conversations');
        _messages.clear();
        for (var c in convRes.data) {
          _conversationIds[c['peerId']] = c['id'];
          // fetch messages for conversation
          try {
             final msgRes = await apiClient.get('/conversations/${c['id']}/messages');
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
             _messages[c['peerId']] = chatMessages;
             
             // Also ensure matchedUsers has the peer
             if (!_matchedUsers.any((u) => u.id == c['peerId'])) {
               _matchedUsers.add(UserProfile(
                 id: c['peerId'],
                 name: c['peerName'],
                 age: 24,
                 location: '',
                 bio: '',
                 avatarUrl: c['peerAvatar'] ?? 'assets/mockups/discover_swipe.jpeg',
                 isVerified: true,
                 isOnline: true,
                 moodStatus: '',
                 matchPercentage: 90,
                 interests: [],
                 lookingFor: '',
                 values: [],
               ));
             }
          } catch(e) {
             print("Failed to fetch messages for conv ${c['id']}: $e");
          }
        }
      } catch (e) {
        print("Failed to fetch conversations: $e");
      }

      // Fetch Matches
      final discoverRes = await apiClient.get('/match/discover');
      _cards.clear();
      for (var peer in discoverRes.data) {
         _cards.add(MatchCard(
            profile: UserProfile(
              id: peer['id'],
              name: peer['pseudonym'] ?? 'Anonymous',
              age: 24, // Not tracked on backend
              location: 'Remote',
              bio: peer['bio'] ?? '',
              avatarUrl: peer['avatar'] ?? 'assets/mockups/discover_swipe.jpeg',
              isVerified: true,
              isOnline: true,
              moodStatus: '',
              matchPercentage: 90,
              interests: [],
              lookingFor: '',
              values: [],
            ),
            isNewHere: true,
            commonInterests: [],
         ));
      }
      
      // Fetch Community Posts
      try {
        final communityRes = await apiClient.get('/community');
        _communityPosts.clear();
        for (var p in communityRes.data) {
          _communityPosts.add(CommunityPost(
            id: p['id'],
            authorName: p['author']['pseudonym'] ?? 'Anonymous',
            authorBadge: p['author']['isAnonymous'] ? 'Anonymous Peer' : 'Member',
            authorAvatar: (p['author']['images'] != null && p['author']['images'].isNotEmpty) ? p['author']['images'][0] : 'assets/mockups/user_dashboard_alex.jpeg',
            timeAgo: _formatTimeAgo(DateTime.parse(p['createdAt'])),
            topic: p['topic'],
            content: p['content'],
            likesCount: p['likesCount'] ?? 0,
            commentsCount: p['_count']['comments'] ?? 0,
            isLiked: false,
          ));
        }
      } catch (e) {
        print("Failed to fetch community posts: $e");
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
        print("Failed to fetch goals: $e");
      }

      // Fetch SOS Contacts
      try {
        final sosRes = await apiClient.get('/sos/contacts');
        _emergencyContacts.clear();
        for (var c in sosRes.data) {
          _emergencyContacts.add(EmergencyContact(
            id: c['id'],
            name: c['name'],
            phone: c['phone'],
            relationship: c['relationship'] ?? '',
          ));
        }
      } catch (e) {
        print("Failed to fetch SOS contacts: $e");
      }
    } catch (e) {
      print("Failed to fetch backend data: $e");
    }
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
  }

  void checkInMood(String mood) {
    _todayMood = mood;
    _currentXp += 25;
    notifyListeners();
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
        print("Error swiping left: $e");
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
        _matchedUsers.insert(0, popped.profile);
        _lastMatch = popped;
        // _currentXp += 50; // XP is now updated from backend. You could fetch profile again or just add locally for optimistic update.
        _currentXp += 50; 
        notifyListeners();
        return true; 
      } else {
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("Error swiping right: $e");
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

  void refreshDeck() {
    _initMockData();
    notifyListeners();
  }

  void clearLastMatch() {
    _lastMatch = null;
    notifyListeners();
  }

  // --- SOCKET.IO CHAT INTEGRATION ---
  io.Socket? _socket;

  void initSocket(String token) {
    if (_socket != null) return;
    
    _socket = io.io(AppConstants.apiBaseUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .build());

    _socket?.onConnect((_) {
      print('Socket connected');
      // Ideally, the backend emits conversation IDs or we join them based on matches.
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
        notifyListeners();
      }
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

  void reportAndBlockPeer(String peerId, String reason) {
    _matchedUsers.removeWhere((u) => u.id == peerId);
    _messages.remove(peerId);
    _cards.removeWhere((c) => c.profile.id == peerId);
    notifyListeners();
  }

  Future<void> addJournalEntry(String mood, String thought, String gratitude, String category) async {
    try {
      final res = await apiClient.post('/journal/create', data: {
        'content': thought,
        'moodScore': 5, // mock mood score calculation
        'category': category,
        'isPrivate': true,
      });

      final entry = JournalEntry(
        id: res.data['entry']['id'],
        date: DateTime.parse(res.data['entry']['createdAt']),
        mood: mood,
        thought: thought,
        gratitude: gratitude,
        category: category,
      );
      _journalEntries.insert(0, entry);
      
      // Update XP from backend
      if (res.data['user'] != null) {
        _currentXp = res.data['user']['xp'] ?? _currentXp;
        _dayStreak = res.data['user']['currentStreak'] ?? _dayStreak;
      }
      
      notifyListeners();
    } catch (e) {
      print("Error creating journal: $e");
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

  void toggleWeekCheckIn(int dayIndex) {
    if (dayIndex >= 0 && dayIndex < _weekDaysCheckIn.length) {
      _weekDaysCheckIn[dayIndex] = !_weekDaysCheckIn[dayIndex];
      _dayStreak += _weekDaysCheckIn[dayIndex] ? 1 : -1;
      _currentXp += _weekDaysCheckIn[dayIndex] ? 30 : -30;
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

      try {
        await apiClient.put('/goals/$goalId/toggle');
      } catch (e) {
        // Revert on failure
        _goals[idx] = current;
        _currentXp -= newStatus ? 50 : -50;
        notifyListeners();
        print("Error toggling goal: $e");
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
      print("Error adding goal: $e");
    }
  }

  void setCommunityFilter(String filter) {
    _communityFilter = filter;
    notifyListeners();
  }

  void togglePostLike(String postId) {
    final idx = _communityPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final post = _communityPosts[idx];
      post.isLiked = !post.isLiked;
      post.likesCount += post.isLiked ? 1 : -1;
      notifyListeners();
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
        authorAvatar: (p['author']['images'] != null && p['author']['images'].isNotEmpty) ? p['author']['images'][0] : 'assets/mockups/user_dashboard_alex.jpeg',
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
      print("Error creating post: $e");
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
        authorAvatar: (c['author']['images'] != null && c['author']['images'].isNotEmpty) ? c['author']['images'][0] : 'assets/mockups/user_dashboard_alex.jpeg',
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
      print("Error adding comment: $e");
    }
  }

  Future<void> addEmergencyContact(String name, String phone, String relationship) async {
    try {
      final res = await apiClient.post('/sos/contacts', data: {
        'name': name,
        'phone': phone,
        'relationship': relationship,
      });
      final contact = EmergencyContact(
        id: res.data['id'],
        name: res.data['name'],
        phone: res.data['phone'],
        relationship: res.data['relationship'] ?? '',
      );
      _emergencyContacts.add(contact);
      notifyListeners();
    } catch (e) {
      print("Failed to add SOS contact: $e");
    }
  }

  Future<void> removeEmergencyContact(String id) async {
    try {
      await apiClient.delete('/sos/contacts/$id');
      _emergencyContacts.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      print("Failed to delete SOS contact: $e");
    }
  }

  void setAnonymity(bool val) {
    isAnonymousMode = val;
    _currentUser = _currentUser.copyWith(
      isAnonymous: val,
      name: val ? 'Kind Peer' : (onboardingName.isNotEmpty ? onboardingName : 'Alex'),
    );
    notifyListeners();
  }

  Future<void> updateProfile({required String name, required String bio, required String location, required String lookingFor}) async {
    try {
      final res = await apiClient.put('/users/me', data: {
        'pseudonym': name,
        'bio': bio,
        'location': location,
        'lookingFor': lookingFor,
      });
      final data = res.data;
      final avatar = (data['images'] != null && data['images'].isNotEmpty) 
          ? '${AppConstants.apiBaseUrl}${data['images'][0]}'
          : _currentUser.avatarUrl;
          
      _currentUser = _currentUser.copyWith(
        name: data['pseudonym'] ?? _currentUser.name,
        bio: data['bio'] ?? _currentUser.bio,
        location: data['location'] ?? _currentUser.location,
        lookingFor: data['lookingFor'] ?? _currentUser.lookingFor,
        avatarUrl: avatar,
      );
      onboardingName = name;
      notifyListeners();
    } catch (e) {
      print("Failed to update profile: $e");
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
    String? location,
    int? age,
    List<String>? interests,
    List<String>? feelings,
    List<String>? supportTypes,
    bool? isAnonymous,
    String? bio,
  }) {
    if (name != null && name.trim().isNotEmpty) onboardingName = name.trim();
    if (location != null && location.trim().isNotEmpty) onboardingLocation = location.trim();
    if (interests != null && interests.isNotEmpty) selectedInterests = interests;
    if (feelings != null && feelings.isNotEmpty) selectedFeelings = feelings;
    if (supportTypes != null && supportTypes.isNotEmpty) selectedSupportTypes = supportTypes;
    if (isAnonymous != null) isAnonymousMode = isAnonymous;

    final derivedBio = bio != null && bio.trim().isNotEmpty
        ? bio.trim()
        : (selectedFeelings.isNotEmpty
            ? 'Navigating ${selectedFeelings.join(' & ')} one day at a time. Here for kind peer support. 🌱'
            : _currentUser.bio);

    _currentUser = _currentUser.copyWith(
      name: isAnonymousMode ? 'Kind Peer' : (onboardingName.isNotEmpty ? onboardingName : 'Alex'),
      age: age ?? _currentUser.age,
      location: onboardingLocation.isNotEmpty ? onboardingLocation : 'Mumbai, India',
      interests: selectedInterests,
      lookingFor: selectedSupportTypes.isNotEmpty ? selectedSupportTypes.join(' & ') : _currentUser.lookingFor,
      isAnonymous: isAnonymousMode,
      bio: derivedBio,
    );

    _recalculateMatchScores();
    notifyListeners();
  }
}
