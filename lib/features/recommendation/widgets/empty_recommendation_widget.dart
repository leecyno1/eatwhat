import 'package:flutter/material.dart';

/// 空推荐状态组件
class EmptyRecommendationWidget extends StatefulWidget {
  const EmptyRecommendationWidget({Key? key}) : super(key: key);

  @override
  State<EmptyRecommendationWidget> createState() => _EmptyRecommendationWidgetState();
}

class _EmptyRecommendationWidgetState extends State<EmptyRecommendationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 动画图标
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Transform.rotate(
                    angle: _rotateAnimation.value * 0.2,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.purple.withOpacity(0.3),
                            Colors.blue.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        size: 60,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // 主标题
            const Text(
              '还没有推荐',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            // 副标题
            Text(
              '选择一些气泡来获取个性化推荐',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // 提示信息
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bubble_chart,
                        size: 20,
                        color: Colors.purple.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '如何获取推荐',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildStep('1', '在气泡页面选择你喜欢的口味、菜系等', Icons.touch_app),
                  const SizedBox(height: 12),
                  _buildStep('2', '点击"生成推荐"按钮', Icons.auto_awesome),
                  const SizedBox(height: 12),
                  _buildStep('3', '获得个性化的美食推荐', Icons.restaurant),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 返回按钮
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.bubble_chart),
              label: const Text('选择气泡偏好'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 8,
                shadowColor: Colors.purple.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建步骤项
  Widget _buildStep(String number, String description, IconData icon) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purple.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        Icon(
          icon,
          size: 16,
          color: Colors.white.withOpacity(0.6),
        ),
        
        const SizedBox(width: 8),
        
        Expanded(
          child: Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
} 