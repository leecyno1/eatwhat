import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/physical_entity_controller.dart';
import '../widgets/physical_entity_widget.dart';
import '../../recommendation/screens/enhanced_recommendation_screen.dart';
import '../../../shared/widgets/animated_title_simple.dart';
import '../../../shared/widgets/like_dislike_controls.dart';
import '../../../core/services/growth_engine.dart';

/// 增强版物理实体界面 - 新的UI设计
class EnhancedPhysicalEntityScreen extends StatefulWidget {
  const EnhancedPhysicalEntityScreen({super.key});

  @override
  State<EnhancedPhysicalEntityScreen> createState() =>
      _EnhancedPhysicalEntityScreenState();
}

class _EnhancedPhysicalEntityScreenState
    extends State<EnhancedPhysicalEntityScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _containerController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _containerAnimation;

  // 动态主题服务
  // late DynamicThemeService _themeService;

  @override
  void initState() {
    super.initState();

    // 禁用动态主题服务定时器以避免频繁重建导致的气泡乱窜
    // _themeService = DynamicThemeService();

    // 背景动画控制器（禁用呼吸效果以解决乱窜问题）
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    ); // 禁用 repeat 以停止动画

    // 容器动画控制器
    _containerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _containerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _containerController,
      curve: Curves.elasticOut,
    ));

    // 启动容器动画
    _containerController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PhysicalEntityController()..initialize(),
      child: Consumer<PhysicalEntityController>(
        builder: (context, controller, child) {
          // 移除AnimatedBuilder包装以避免频繁重建
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFFF8), // 固定的淡色背景
                    Color(0xFFFFFAE6),
                    Color(0xFFFFF8DC),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // 顶部：紧凑的标题和统计栏
                    _buildCompactHeader(controller),

                    // 中间：最大化的物理实体容器（占用绝大部分空间）
                    Expanded(
                      flex: 20, // 大幅增加容器空间权重
                      child: _buildExpandedPhysicsContainer(controller),
                    ),

                    // 底部：紧凑的操作按钮
                    _buildCompactBottomSection(controller),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建最小化的头部区域 - 统计栏移到右上角，标题可以溢出
  Widget _buildCompactHeader(PhysicalEntityController controller) {
    return SizedBox(
      height: 80, // 固定较小高度，允许标题动画溢出
      child: Stack(
        clipBehavior: Clip.none, // 允许子组件溢出
        children: [
          // 中心标题 - 扩大字体和动画范围
          Positioned.fill(
            child: OverflowBox(
              maxHeight: 200, // 限制垂直溢出
              maxWidth: 400, // 限制水平溢出
              child: Center(
                child: AnimatedTitleSimple(
                  title: '吃什么',
                  fontSize: 56, // 大幅增加字体大小
                  textColor: Colors.black87,
                  questionMarkColor: Colors.black54,
                  showQuestionMarks: true,
                ),
              ),
            ),
          ),

          // 右上角统计栏 - 确保在标题之上
          Positioned(
            top: 8,
            right: 16,
            child: _buildCornerStatsBar(controller),
          ),
        ],
      ),
    );
  }

  /// 构建右上角的紧凑统计栏
  Widget _buildCornerStatsBar(PhysicalEntityController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 喜欢统计
          _buildMiniStatItem(
            icon: Icons.favorite,
            count: controller.likedEntities.length,
            color: Colors.red,
            onTap: () => _showLikedEntities(controller),
          ),

          const SizedBox(width: 6),

          // 不喜欢统计
          _buildMiniStatItem(
            icon: Icons.thumb_down,
            count: controller.dislikedEntities.length,
            color: Colors.grey,
            onTap: () => _showDislikedEntities(controller),
          ),

          const SizedBox(width: 6),

          // 重置按钮
          GestureDetector(
            onTap: () => _resetSelections(controller),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.refresh,
                size: 16,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建迷你统计项
  Widget _buildMiniStatItem({
    required IconData icon,
    required int count,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 2),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建扩大的物理实体容器
  Widget _buildExpandedPhysicsContainer(PhysicalEntityController controller) {
    return AnimatedBuilder(
      animation: _containerAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _containerAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2), // 最大化减少边距
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25), // 稍微减小圆角
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15, // 减小阴影
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5, // 减细边框
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
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
                child: Stack(
                  children: [
                    // 背景粒子效果
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 物理实体区域 - 占满整个容器
                    if (controller.isInitialized)
                      _buildExpandedEntitiesArea(controller)
                    else
                      _buildLoadingState(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建扩大的实体区域
  Widget _buildExpandedEntitiesArea(PhysicalEntityController controller) {
    return Padding(
      padding: const EdgeInsets.all(4.0), // 极小内边距
      child: LayoutBuilder(
        builder: (context, constraints) {
          controller.updateContainerSize(constraints.biggest);

          return Stack(
            children: controller.entities.map((entity) {
              return Positioned(
                left: entity.position.dx - entity.radius, // 恢复使用radius
                top: entity.position.dy - entity.radius, // 恢复使用radius
                child: GestureDetector(
                  onTap: () => _handleEntityTap(controller, entity),
                  child: PhysicalEntityWidget(
                    entity: entity,
                    isSelected: controller.isEntitySelected(entity),
                    onTap: () => _handleEntityTap(controller, entity),
                    onSwipeUp: () => _handleSwipeUp(controller, entity),
                    onSwipeDown: () => _handleSwipeDown(controller, entity),
                    onSwipeLeft: () => _handleSwipeLeft(controller, entity),
                    onSwipeRight: () => _handleSwipeRight(controller, entity),
                    onLongPress: () => _handleLongPress(controller, entity),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  /// 构建实体区域（保留原方法作为备用）
  Widget _buildEntitiesArea(PhysicalEntityController controller) {
    return _buildExpandedEntitiesArea(controller);
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
          const SizedBox(height: 16),
          const Text(
            '正在初始化口味偏好...',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建紧凑的底部区域
  Widget _buildCompactBottomSection(PhysicalEntityController controller) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // 进一步减少边距
      child: Row(
        children: [
          // 重置按钮 - 更紧凑
          Expanded(
            child: _buildCompactActionButton(
              text: '重置',
              icon: Icons.refresh,
              color: Colors.grey,
              onPressed: () => _resetPhysics(controller),
            ),
          ),

          const SizedBox(width: 12), // 减少间距

          // 推荐按钮 - 更紧凑
          Expanded(
            flex: 2,
            child: _buildCompactActionButton(
              text: '获取推荐',
              icon: Icons.restaurant_menu,
              color: const Color(0xFFFFD700),
              onPressed: controller.selectedCount > 0
                  ? () => _generateRecommendations(controller)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部区域（保留原方法作为备用）
  Widget _buildBottomSection(PhysicalEntityController controller) {
    return _buildCompactBottomSection(controller);
  }

  /// 构建紧凑的操作按钮
  Widget _buildCompactActionButton({
    required String text,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isEnabled ? Colors.white : Colors.grey,
          size: 18, // 减小图标
        ),
        label: Text(
          text,
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 14, // 减小字体
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? color : Colors.grey.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 12), // 减少垂直边距
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // 减小圆角
          ),
          elevation: isEnabled ? 6 : 1, // 减小阴影
          shadowColor: color.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  /// 构建操作按钮（保留原方法作为备用）
  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return _buildCompactActionButton(
      text: text,
      icon: icon,
      color: color,
      onPressed: onPressed,
    );
  }

  // 事件处理方法 - 移除拖拽功能以避免干扰物理引擎
  void _handleEntityDrag(PhysicalEntityController controller, entity, details) {
    // 禁用拖拽功能，避免干扰物理引擎
    // controller.updateEntityPosition(entity.id, details.globalPosition);
  }

  void _handleEntityTap(PhysicalEntityController controller, entity) {
    HapticFeedback.lightImpact();
    controller.toggleEntity(entity);

    // 记录用户行为
    GrowthEngine().recordUserAction(
      userId: 'current_user',
      action: UserAction.bubbleSelection,
    );
  }

  void _handleSwipeUp(PhysicalEntityController controller, entity) {
    HapticFeedback.mediumImpact();
    controller.likeEntity(entity.id);

    // 添加触觉反馈效果
    HapticFeedback.mediumImpact();
  }

  void _handleSwipeDown(PhysicalEntityController controller, entity) {
    HapticFeedback.heavyImpact();
    controller.dislikeEntity(entity.id);
  }

  void _handleSwipeLeft(PhysicalEntityController controller, entity) {
    HapticFeedback.lightImpact();
    controller.ignoreEntity(entity);
  }

  void _handleSwipeRight(PhysicalEntityController controller, entity) {
    HapticFeedback.mediumImpact();
    controller.confirmEntity(entity);
  }

  void _handleLongPress(PhysicalEntityController controller, entity) {
    HapticFeedback.heavyImpact();
    // 显示实体详情
    _showEntityDetails(entity);
  }

  void _showLikedEntities(PhysicalEntityController controller) {
    // TODO: 实现显示喜欢的实体
  }

  void _showDislikedEntities(PhysicalEntityController controller) {
    // TODO: 实现显示不喜欢的实体
  }

  void _resetSelections(PhysicalEntityController controller) {
    controller.clearSelection();
    HapticFeedback.mediumImpact();
  }

  void _resetPhysics(PhysicalEntityController controller) {
    controller.resetEntities();
    HapticFeedback.mediumImpact();
  }

  void _generateRecommendations(PhysicalEntityController controller) async {
    await controller.generateRecommendations();

    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return EnhancedRecommendationScreen(
              recommendedFoods: controller.recommendedFoods,
              selectedPreferences: controller.getSelectedEntities(),
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        ),
      );
    }
  }

  void _showEntityDetails(entity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFF8).withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entity.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              entity.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTimePeriodIcon() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 10) {
      return Icons.wb_sunny_outlined;
    } else if (hour >= 10 && hour < 12) {
      return Icons.wb_sunny;
    } else if (hour >= 12 && hour < 14) {
      return Icons.wb_sunny_sharp;
    } else if (hour >= 14 && hour < 17) {
      return Icons.wb_cloudy;
    } else if (hour >= 17 && hour < 19) {
      return Icons.wb_cloudy_outlined;
    } else if (hour >= 19 && hour < 22) {
      return Icons.nights_stay;
    } else {
      return Icons.bedtime;
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _containerController.dispose();
    // _themeService.dispose();
    super.dispose();
  }
}

/// 简单的状态指示器组件
class StatusIndicator extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final bool isActive;

  const StatusIndicator({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? color : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: isActive ? color : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
