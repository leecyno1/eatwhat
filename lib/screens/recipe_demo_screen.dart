import 'package:flutter/material.dart';
import '../features/recipe/screens/modern_recipe_recommendation_screen.dart';

/// 菜谱功能演示页面
class RecipeDemoScreen extends StatelessWidget {
  const RecipeDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('菜谱功能演示'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '《吃什么》- 菜谱推荐系统',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '基于HowToCook数据，提供195+道精选菜谱',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // 功能卡片
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    context,
                    title: '现代化菜谱推荐',
                    subtitle: '195+ HowToCook 菜谱',
                    icon: Icons.restaurant_menu,
                    color: Colors.orange[600]!,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ModernRecipeRecommendationScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    title: '智能搜索',
                    subtitle: '按类别、难度筛选',
                    icon: Icons.search,
                    color: Colors.blue[600]!,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ModernRecipeRecommendationScreen(
                            searchKeyword: '',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    title: '分类浏览',
                    subtitle: '荤菜、素菜、主食',
                    icon: Icons.category,
                    color: Colors.green[600]!,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ModernRecipeRecommendationScreen(
                            preferredCategories: ['荤菜'],
                          ),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    title: '美观UI设计',
                    subtitle: '网格/列表切换',
                    icon: Icons.view_module,
                    color: Colors.purple[600]!,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ModernRecipeRecommendationScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 数据统计
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    '数据统计',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('195+', '菜谱数量'),
                      _buildStatItem('6+', '菜品类别'),
                      _buildStatItem('3', '难度等级'),
                      _buildStatItem('100%', '真实数据'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
