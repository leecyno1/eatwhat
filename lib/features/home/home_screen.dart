import 'package:flutter/material.dart';
import '../bubble/screens/bubble_screen.dart';
import '../delivery/delivery_screen.dart';
import '../favorites/screens/favorites_screen.dart';
import '../history/screens/history_screen.dart';
import '../user/screens/profile_screen.dart';
import '../../shared/widgets/page_transitions.dart';
import '../../core/ai/ai_service_test.dart';

/// 应用主屏幕 - 标准底部导航
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const BubbleScreen(),
    const DeliveryScreen(),
    const FavoritesScreen(),
    const HistoryScreen(),
    ProfileScreen(
      extraActions: [
        ElevatedButton(
          onPressed: () async {
            try {
              await AiServiceTest.runQuickTest();
              // 可在此处添加成功提示
            } catch (e) {
              // 可在此处添加失败提示
            }
          },
          child: const Text('AI服务快速测试'),
        ),
      ],
    ),
  ];

  final List<_NavigationItem> _navItems = [
    _NavigationItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: '探索'),
    _NavigationItem(icon: Icons.delivery_dining_outlined, activeIcon: Icons.delivery_dining, label: '外卖'),
    _NavigationItem(icon: Icons.favorite_border, activeIcon: Icons.favorite, label: '收藏'),
    _NavigationItem(icon: Icons.history, activeIcon: Icons.history, label: '历史'),
    _NavigationItem(icon: Icons.person_outline, activeIcon: Icons.person, label: '我的'),
  ];

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens.asMap().entries.map((entry) {
          final index = entry.key;
          final screen = entry.value;
          return BottomNavPageTransition(
            currentIndex: _currentIndex,
            previousIndex: _pageController.hasClients ? (_pageController.page?.round() ?? 0) : 0,
            child: screen,
          );
        }).toList(),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final bool isActive = index == _currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTabTapped(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isActive ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive ? colorScheme.primary : theme.bottomNavigationBarTheme.unselectedItemColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? colorScheme.primary : theme.bottomNavigationBarTheme.unselectedItemColor,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
} 