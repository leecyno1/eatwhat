import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../features/recipe/screens/recipe_search_screen.dart';
import '../features/recipe/screens/recipe_recommendation_screen.dart';
import '../features/recipe/screens/complete_recipe_detail_screen.dart';
import '../core/models/recipe.dart';
import '../core/services/smart_recipe_recommendation_service.dart';
import '../shared/widgets/glassmorphic_container.dart';

/// Phase 2 功能演示页面
/// 展示完整菜谱界面、搜索、推荐等新功能
class Phase2DemoScreen extends StatefulWidget {
  const Phase2DemoScreen({super.key});

  @override
  State<Phase2DemoScreen> createState() => _Phase2DemoScreenState();
}

class _Phase2DemoScreenState extends State<Phase2DemoScreen> {
  final SmartRecipeRecommendationService _recommendationService =
      SmartRecipeRecommendationService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _recommendationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Phase 2 功能演示',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 功能介绍
            _buildSectionTitle('🎯 Phase 2 核心功能'),
            SizedBox(height: 16.h),
            _buildFeatureDescription(),

            SizedBox(height: 32.h),

            // 功能演示按钮
            _buildSectionTitle('🚀 功能演示'),
            SizedBox(height: 16.h),
            _buildDemoButtons(),

            SizedBox(height: 32.h),

            // 技术亮点
            _buildSectionTitle('✨ 技术亮点'),
            SizedBox(height: 16.h),
            _buildTechnicalHighlights(),

            SizedBox(height: 32.h),

            // 示例菜谱
            _buildSectionTitle('📖 示例菜谱展示'),
            SizedBox(height: 16.h),
            _buildSampleRecipeDemo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFeatureDescription() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 200.h,
      borderRadius: 16.r,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phase 2 完成的核心功能：',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            _buildFeatureItem('🔍 智能菜谱搜索', '支持名称、食材、做法多维度搜索'),
            _buildFeatureItem('📱 完整菜谱详情', '美观的详情页面，包含营养信息'),
            _buildFeatureItem('🎯 个性化推荐', '基于用户偏好的智能推荐算法'),
            _buildFeatureItem('🏷️ 多维筛选', '难度、时间、分类、口味多重筛选'),
            _buildFeatureItem('💎 现代化UI', '玻璃态效果与流畅动画'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.orange,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoButtons() {
    return Column(
      children: [
        _buildDemoButton(
          '🔍 菜谱搜索功能',
          '体验智能搜索与分类导航',
          Icons.search,
          () => _openRecipeSearch(),
        ),
        SizedBox(height: 16.h),
        _buildDemoButton(
          '🎯 个性化推荐',
          '查看基于偏好的菜谱推荐',
          Icons.recommend,
          () => _openRecommendations(),
        ),
        SizedBox(height: 16.h),
        _buildDemoButton(
          '📖 菜谱详情页面',
          '查看完整的菜谱详情展示',
          Icons.book,
          () => _openSampleRecipe(),
        ),
      ],
    );
  }

  Widget _buildDemoButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 80.h,
        borderRadius: 12.r,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.red],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicalHighlights() {
    return Column(
      children: [
        _buildTechItem('🎨', '现代化UI设计', '玻璃态效果与深色主题'),
        _buildTechItem('⚡', '高性能优化', '懒加载与图片缓存'),
        _buildTechItem('🤖', '智能推荐算法', '多维度评分与学习机制'),
        _buildTechItem('🔄', '真实数据集成', '下厨房数据爬取与处理'),
        _buildTechItem('📱', '响应式设计', '多设备尺寸适配'),
      ],
    );
  }

  Widget _buildTechItem(String emoji, String title, String description) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 24)),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleRecipeDemo() {
    return GestureDetector(
      onTap: _openSampleRecipe,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 120.h,
        borderRadius: 16.r,
        child: Row(
          children: [
            // 示例图片
            Container(
              width: 100.w,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  bottomLeft: Radius.circular(16.r),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.withValues(alpha: 0.7),
                    Colors.red.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.restaurant,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

            // 菜谱信息
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '宫保鸡丁 (示例菜谱)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '经典川菜，麻辣鲜香，制作简单',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 12.sp,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.orange, size: 14),
                        SizedBox(width: 4.w),
                        Text(
                          '25分钟',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 4.w),
                        Text(
                          '4.8',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 导航方法
  void _openRecipeSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RecipeSearchScreen(),
      ),
    );
  }

  void _openRecommendations() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RecipeRecommendationScreen(),
      ),
    );
  }

  void _openSampleRecipe() {
    // 创建示例菜谱
    final sampleRecipe = Recipe(
      id: 'demo_recipe_001',
      name: '宫保鸡丁',
      description: '经典川菜，麻辣鲜香，鸡肉嫩滑，花生脆香，是一道下饭的经典菜肴。',
      cuisine: '川菜',
      cookingMethod: CookingMethod.stirFry,
      difficulty: RecipeDifficulty.medium,
      preparationTime: 15,
      cookingTime: 25,
      servings: 3,
      imageUrl: '',
      tags: ['川菜', '下饭菜', '家常菜'],
      ingredients: [
        RecipeIngredient(name: '鸡胸肉', amount: '300', unit: 'g', isMain: true),
        RecipeIngredient(name: '花生米', amount: '100', unit: 'g', isMain: true),
        RecipeIngredient(name: '干辣椒', amount: '10', unit: '个'),
        RecipeIngredient(name: '花椒', amount: '1', unit: '茶匙'),
        RecipeIngredient(name: '生抽', amount: '2', unit: '茶匙'),
        RecipeIngredient(name: '料酒', amount: '1', unit: '茶匙'),
        RecipeIngredient(name: '淀粉', amount: '1', unit: '茶匙'),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          description: '鸡胸肉切成丁，用生抽、料酒、淀粉腌制15分钟',
          estimatedTime: 15,
        ),
        CookingStep(
          stepNumber: 2,
          description: '热油爆炒花生米至微黄，盛起备用',
          estimatedTime: 3,
        ),
        CookingStep(
          stepNumber: 3,
          description: '热油下鸡丁炒至变色，加入干辣椒和花椒爆香',
          estimatedTime: 5,
        ),
        CookingStep(
          stepNumber: 4,
          description: '调入生抽翻炒，最后加入花生米炒匀即可',
          estimatedTime: 2,
        ),
      ],
      nutrition: NutritionInfo(
        calories: 320,
        protein: 28.5,
        fat: 18.2,
        carbs: 12.8,
        fiber: 3.2,
        sodium: 680,
      ),
      rating: 4.8,
      reviewCount: 1265,
      authorId: 'demo_author',
      authorName: 'Phase2演示厨师',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      tasteProfile: ['麻', '辣', '鲜', '香'],
      scenarioTags: ['下饭', '家常'],
      healthBenefits: ['高蛋白', '营养均衡'],
      seasonalInfo: SeasonalInfo(
        bestSeasons: ['春', '夏', '秋', '冬'],
        seasonalIngredients: ['花生'],
        seasonalScore: 0.8,
      ),
      equipment: CookingEquipment(
        required: ['炒锅', '锅铲'],
        optional: ['料酒壶'],
      ),
      tasteIntensity: {
        '咸': 0.7,
        '辣': 0.8,
        '麻': 0.6,
      },
      spiceLevel: '中辣',
      origin: '四川',
      isAuthentic: true,
      cookingTechniques: ['爆炒', '腌制'],
      ingredientSubstitutes: {
        '鸡胸肉': '鸡腿肉或鸭肉',
        '花生米': '腰果或杏仁',
      },
      costEstimate: 25.0,
      mealTypes: ['午餐', '晚餐'],
      tips: '鸡肉要先腌制，这样炒出来更嫩滑。花生米要先炒至微黄，口感更香脆。',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompleteRecipeDetailScreen(recipeId: sampleRecipe.id),
      ),
    );
  }
}
