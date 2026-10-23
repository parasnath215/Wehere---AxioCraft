import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routing/app_routes.dart';
import '../../state/app_state.dart';
import '../../widgets/shared/avatar_widget.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().fetchConversations();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allMatchedUsers = appState.matchedUsers;
    final matchedUsers = _searchQuery.isEmpty
        ? allMatchedUsers
        : allMatchedUsers
            .where((u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (Serif Editorial "Messages")
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Messages',
                        style: GoogleFonts.newsreader(
                          fontSize: 29,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'A safe, private space to talk and heal.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEDFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: Color(0xFF4F46E5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Encrypted',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    hintText: 'Search peers or messages...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),

            // 3. New Matches Carousel
            if (matchedUsers.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                child: Text(
                  'Connected Peers',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                height: 94,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: matchedUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final user = matchedUsers[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.chatConversation,
                          arguments: user,
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                                  ),
                                ),
                                child: AvatarWidget(
                                  imageUrl: user.avatarUrl.isNotEmpty
                                      ? user.avatarUrl
                                      : 'assets/images/peer_test.jpg',
                                  radius: 26,
                                ),
                              ),
                              if (user.isOnline)
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    width: 11,
                                    height: 11,
                                    decoration: BoxDecoration(
                                      color: AppColors.onlineGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            user.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 16, color: AppColors.cardBorder),
              ),
            ],

            // 4. Conversations List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => appState.fetchConversations(),
                color: const Color(0xFF4F46E5),
                child: matchedUsers.isNotEmpty
                    ? ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: matchedUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = matchedUsers[index];
                          final userMessages = appState.messages[user.id] ?? [];
                          final lastMsg = userMessages.isNotEmpty
                              ? userMessages.last.text
                              : 'Connected! Say hello and start your conversation 💜';

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.chatConversation,
                                  arguments: user,
                                );
                              },
                              leading: Stack(
                                children: [
                                  AvatarWidget(
                                    imageUrl: user.avatarUrl.isNotEmpty
                                        ? user.avatarUrl
                                        : 'assets/images/peer_test.jpg',
                                    radius: 24,
                                  ),
                                  if (user.isOnline)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: AppColors.onlineGreen,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    user.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (user.isVerified)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 15,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  const Spacer(),
                                  Text(
                                    '10:41 AM',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  lastMsg,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEEEDFC),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        color: Color(0xFF4F46E5),
                                        size: 34,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'No active conversations yet',
                                      style: GoogleFonts.newsreader(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Swipe on Discover to connect with an empathetic peer.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        appState.setTabIndex(1); // Explore tab
                                      },
                                      icon: const Icon(Icons.explore_outlined, size: 18),
                                      label: const Text(
                                        'Find Peers to Connect',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4F46E5),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(22),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
