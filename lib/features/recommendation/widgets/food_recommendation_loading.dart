import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/widgets/modern_loading_animation.dart';

/// 食物推荐加载组件
class FoodRecommendationLoading extends StatelessWidget {
  final String? message;

  const FoodRecommendationLoading({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 加载动画
        ModernLoadingAnimation(
          size: 80.w,
          color: Colors.orange,
          showPercentage: false,
        ),

        SizedBox(height: 24.h),

        // 消息文本
        if (message != null) ...[
          Text(
            message!,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
        ],

        // 提示文本
        Text(
          '正在分析您的口味偏好...',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
