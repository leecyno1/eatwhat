import 'package:flutter/material.dart';
import '../../../shared/themes/design_tokens.dart';
import '../../bubble/screens/enhanced_physical_entity_screen.dart';
import '../../recipe/screens/recipe_demo_screen.dart';
import '../../recipe/screens/recipe_list_screen.dart';
import '../../../screens/phase3_demo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const EnhancedPhysicalEntityScreen(),
    const RecipeDemoScreen(),
    const RecipeListScreen(),
    const Phase3DemoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: DesignTokens.mint,
        unselectedItemColor: DesignTokens.inkMuted,
        backgroundColor: DesignTokens.surface,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bubble_chart),
            label: '偏好选择',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: '推荐菜谱',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '搜索菜谱',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'AI智能推荐',
          ),
        ],
      ),
    );
  }
}
