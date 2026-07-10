import 'package:flutter/material.dart';
import '../../shared/widgets/ai_generated_loading_animation.dart';
import '../recommendation/widgets/ai_enhanced_food_card.dart';
import '../../core/models/food.dart';

/// AI组件演示页面
/// 展示所有AI增强的界面效果
class AIDemoScreen extends StatefulWidget {
  const AIDemoScreen({super.key});

  @override
  State<AIDemoScreen> createState() => _AIDemoScreenState();
}

class _AIDemoScreenState extends State<AIDemoScreen>
    with TickerProviderStateMixin {
  late AnimationController _pageController;
  late Animation<double> _fadeAnimation;

  bool _showLoading = false;
  bool _isFavorite = false;

  // 示例食物数据
  final Food demoFood = Food(
    id: 'demo_kung_pao_chicken',
    name: '宫保鸡丁',
    description: '经典川菜，酸甜微辣，鸡肉嫩滑配花生',
    cuisineType: '川菜',
    tasteAttributes: ['甜', '酸', '辣'],
    ingredients: ['鸡肉', '花生', '青椒', '红椒'],
    calories: 280,
    rating: 4.5,
    ratingCount: 128,
    price: 25.0,
    imageUrl: 'https://via.placeholder.com/300x200?text=宫保鸡丁',
  );

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeInOut,
    ));

    _pageController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleLoading() {
    setState(() => _showLoading = !_showLoading);
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 演示用的食物数据
    final demoFood = Food(
      id: 'demo_1',
      name: 'AI推荐：红烧肉',
      description: '经典家常菜，肥瘦相间，入口即化。采用传统工艺精心制作，色泽红亮，香甜可口。',
      cuisineType: '中式菜品',
      price: 32.0,
      imageUrl:
          'https://images.unsplash.com/photo-1555126634-323283e090fa?ixlib=rb-4.0.3',
      rating: 4.5,
      ratingCount: 128,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AIParticleBackground(
        particleCount: 30,
        particleColor: theme.primaryColor,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  children: [
                    // 标题栏
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    theme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.star),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI界面演示',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '体验AI增强的现代界面',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 内容区域
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // AI加载动画演示
                            _buildSectionCard(
                              title: '🤖 AI加载动画',
                              subtitle: '智能脉冲与旋转效果',
                              child: Column(
                                children: [
                                  if (_showLoading)
                                    const AIGeneratedLoadingAnimation(
                                      text: 'AI正在为您推荐美食...',
                                      size: 100,
                                    )
                                  else
                                    Container(
                                      height: 140,
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor
                                            .withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: theme.primaryColor
                                              .withValues(alpha: 0.2),
                                          style: BorderStyle.solid,
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.star),
                                            const SizedBox(height: 8),
                                            Text(
                                              '点击下方按钮查看动画',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  AIButtonAnimation(
                                    onTap: _toggleLoading,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.primaryColor,
                                            theme.colorScheme.secondary,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _showLoading ? '停止动画' : '开始AI动画',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // AI食物卡片演示
                            _buildSectionCard(
                              title: '🍜 AI增强食物卡片',
                              subtitle: '悬停效果与智能交互',
                              child: Column(
                                children: [
                                  Center(
                                    child: AIEnhancedFoodCard(
                                      food: demoFood,
                                      isFavorite: _isFavorite,
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('查看 ${demoFood.name} 详情'),
                                            backgroundColor: theme.primaryColor,
                                          ),
                                        );
                                      },
                                      onFavorite: _toggleFavorite,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '✨ AI增强特性',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildFeatureItem('悬停时自动放大和阴影效果'),
                                        _buildFeatureItem('收藏按钮弹性动画'),
                                        _buildFeatureItem('图片渐入加载动画'),
                                        _buildFeatureItem('点击涟漪反馈效果'),
                                        _buildFeatureItem('智能渐变背景'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // AI工具推荐
                            _buildSectionCard(
                              title: '🛠️ 推荐的AI工具',
                              subtitle: '提升界面设计效率',
                              child: Column(
                                children: [
                                  _buildToolItem(
                                    icon: Icons.animation,
                                    name: 'LottieFiles AI',
                                    description:
                                        'Motion Copilot + AI Prompt to Vector',
                                    url: 'lottiefiles.com/ai',
                                  ),
                                  _buildToolItem(
                                    icon: Icons.design_services,
                                    name: 'Figma AI',
                                    description: 'AI驱动的设计工具',
                                    url: 'figma.com',
                                  ),
                                  _buildToolItem(
                                    icon: Icons.phone_android,
                                    name: 'Galileo AI',
                                    description: '移动应用UI生成器',
                                    url: 'usegalileo.ai',
                                  ),
                                  _buildToolItem(
                                    icon: Icons.code,
                                    name: 'FlutterFlow AI',
                                    description: '可视化Flutter开发',
                                    url: 'flutterflow.io',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.star),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String name,
    required String description,
    required String url,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  url,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.star),
        ],
      ),
    );
  }
}
