import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../state/app_state.dart';
import 'home/home_screen.dart';
import 'discover/discover_swipe_screen.dart';
import 'journal/journal_home_screen.dart';
import 'chat/chat_list_screen.dart';

import 'profile/profile_screen.dart';
import '../widgets/subscription/subscription_sheet.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchBackendData();
    });
  }

  final List<Widget> _pages = const [
    HomeScreen(),
    DiscoverSwipeScreen(),
    JournalHomeScreen(),
    ChatListScreen(),
    ProfileScreen(),
    PricingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activeIndex = appState.currentTabIndex.clamp(0, _pages.length - 1);
    const unreadCount = 2;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (activeIndex != 0) {
          appState.setTabIndex(0);
          return;
        }

        final now = DateTime.now();
        if (_lastBackPressTime == null || 
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
        index: activeIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  activeIndex: activeIndex,
                  appState: appState,
                  icon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  activeIndex: activeIndex,
                  appState: appState,
                  icon: Icons.explore_rounded,
                  label: 'Explore',
                ),
                _buildNavItem(
                  index: 2,
                  activeIndex: activeIndex,
                  appState: appState,
                  icon: Icons.menu_book_rounded,
                  label: 'Journal',
                ),
                _buildNavItem(
                  index: 3,
                  activeIndex: activeIndex,
                  appState: appState,
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  badgeCount: unreadCount,
                ),
                _buildNavItem(
                  index: 4,
                  activeIndex: activeIndex,
                  appState: appState,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                ),
                if (!appState.isSubscribed)
                  _buildNavItem(
                    index: 5,
                    activeIndex: activeIndex,
                    appState: appState,
                    icon: Icons.workspace_premium_rounded,
                    label: 'Pricing',
                  ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int activeIndex,
    required AppState appState,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = activeIndex == index;

    return GestureDetector(
      onTap: () {
        appState.setTabIndex(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.sosRed,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
