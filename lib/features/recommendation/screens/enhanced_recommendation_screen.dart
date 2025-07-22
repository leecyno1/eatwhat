import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/recommendation_controller.dart';
import '../widgets/food_card.dart';
import '../../../shared/widgets/animated_title.dart';
import '../../../shared/widgets/like_dislike_controls.dart';
// 暂时移除动态主题服务以解决气泡乱窜问题
// import '../../../core/theme/dynamic_theme_service.dart';
import '../../../core/models/food.dart';
import '../../../core/models/physical_entity.dart';

/// 增强版推荐界面 - 匹配主界面风格
class EnhancedRecommendationScreen extends StatefulWidget {
  final List<Food> recommendedFoods;
  final List<PhysicalEntity> selectedPreferences;

  const EnhancedRecommendationScreen({
    super.key,
    required this.recommendedFoods,
    required this.selectedPreferences,
  });

  @override
  State<EnhancedRecommendationScreen> createState() => _EnhancedRecommendationScreenState();
}

class _EnhancedRecommendationScreenState extends State<EnhancedRecommendationScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _listController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _listAnimation;
  
  // 动态主题服务 - 暂时禁用
  // late DynamicThemeService _themeService;
  
  // 分页控制
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    
    // 初始化动态主题服务 - 暂时禁用
    // _themeService = DynamicThemeService();
    
    // 背景动画控制器（呼吸效果）
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    // 列表动画控制器
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    
    _listAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listController,
      curve: Curves.elasticOut,
    ));
    
    // 启动列表动画
    _listController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecommendationController(),
      child: Consumer<RecommendationController>(
        builder: (context, controller, child) {
          return AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Scaffold(
                body: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFFF8), // 固定淡色背景
                        Color(0xFFFFFAE6), 
                        Color(0xFFFFF8DC),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // 顶部区域：标题 + 控制
                        _buildTopSection(),
                        
                        // 偏好标签区域
                        _buildPreferencesSection(),
                        
                        // 推荐结果区域
                        Expanded(
                          child: _buildRecommendationsSection(),
                        ),
                        
                        // 底部操作区域
                        _buildBottomSection(),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 构建顶部区域
  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // 返回按钮和状态指示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
              ),
              StatusIndicator(
                text: '${widget.recommendedFoods.length} 个推荐',
                icon: Icons.restaurant_menu,
                color: const Color(0xFFFFD700),
                isActive: true,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 动画标题
          SimpleAnimatedTitle(
            title: '为您推荐',
            fontSize: 36,
            textColor: Colors.black87,
          ),
          
          const SizedBox(height: 8),
          
          // 副标题
          Text(
            '基于您的口味偏好精心挑选',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建偏好标签区域
  Widget _buildPreferencesSection() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '您的偏好',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.selectedPreferences.length,
              itemBuilder: (context, index) {
                final preference = widget.selectedPreferences[index];
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        preference.primaryColor.withValues(alpha: 0.8),
                        preference.secondaryColor.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: preference.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        preference.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        preference.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建推荐结果区域
  Widget _buildRecommendationsSection() {
    return AnimatedBuilder(
      animation: _listAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _listAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: widget.recommendedFoods.isEmpty
                    ? _buildEmptyState()
                    : _buildFoodList(),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建食物列表
  Widget _buildFoodList() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemCount: (widget.recommendedFoods.length / 2).ceil(),
      itemBuilder: (context, pageIndex) {
        final startIndex = pageIndex * 2;
        final endIndex = (startIndex + 2).clamp(0, widget.recommendedFoods.length);
        final pageItems = widget.recommendedFoods.sublist(startIndex, endIndex);
        
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: pageItems.asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final food = entry.value;
              
              return Expanded(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300 + itemIndex * 100),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: FoodCard(
                    food: food,
                    onTap: () => _onFoodTap(food),
                    onFavorite: () => _onFoodFavorite(food),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.black54,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无推荐',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请返回选择更多偏好',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部操作区域
  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 页面指示器
          if (widget.recommendedFoods.length > 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                (widget.recommendedFoods.length / 2).ceil(),
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? const Color(0xFFFFD700)
                        : Colors.black54.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // 操作按钮
          Row(
            children: [
              // 重新推荐按钮
              Expanded(
                child: _buildActionButton(
                  text: '重新推荐',
                  icon: Icons.refresh,
                  color: Colors.black54,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 查看详情按钮
              Expanded(
                flex: 2,
                child: _buildActionButton(
                  text: '查看全部',
                  icon: Icons.list_alt,
                  color: const Color(0xFFFFD700),
                  onPressed: widget.recommendedFoods.isNotEmpty
                      ? () => _showAllRecommendations()
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: isEnabled ? Colors.white : Colors.grey,
        size: 20,
      ),
      label: Text(
        text,
        style: TextStyle(
          color: isEnabled ? Colors.white : Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? color : Colors.grey.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: isEnabled ? 8 : 2,
        shadowColor: color.withValues(alpha: 0.3),
      ),
    );
  }

  // 事件处理方法
  void _onFoodTap(Food food) {
    HapticFeedback.lightImpact();
    // TODO: 显示食物详情
  }

  void _onFoodFavorite(Food food) {
    HapticFeedback.mediumImpact();
    // TODO: 收藏食物
  }

  void _showAllRecommendations() {
    // TODO: 显示全部推荐列表
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _listController.dispose();
    _pageController.dispose();
    // _themeService.dispose(); // 已禁用
    super.dispose();
  }
}