import 'package:flutter/material.dart';
import '../../../core/services/delivery_recommendation_service.dart';

/// 餐次选择器组件
class MealTypeSelector extends StatelessWidget {
  final MealType selectedMealType;
  final Function(MealType) onMealTypeChanged;
  final bool showIcons;
  final bool compact;
  
  const MealTypeSelector({
    super.key,
    required this.selectedMealType,
    required this.onMealTypeChanged,
    this.showIcons = true,
    this.compact = false,
  });
  
  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactSelector(context);
    }
    return _buildFullSelector(context);
  }
  
  Widget _buildFullSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: MealType.values.map((mealType) {
          final isSelected = mealType == selectedMealType;
          return Expanded(
            child: GestureDetector(
              onTap: () => onMealTypeChanged(mealType),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showIcons) ..[
                      Icon(
                        _getMealTypeIcon(mealType),
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      mealType.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildCompactSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MealType.values.map((mealType) {
          final isSelected = mealType == selectedMealType;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onMealTypeChanged(mealType),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showIcons) ..[
                      Icon(
                        _getMealTypeIcon(mealType),
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      mealType.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  IconData _getMealTypeIcon(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.local_cafe;
      case MealType.lateNight:
        return Icons.nightlight;
    }
  }
}

/// 餐次时间指示器
class MealTimeIndicator extends StatelessWidget {
  final MealType currentMealType;
  final bool showTimeRange;
  
  const MealTimeIndicator({
    super.key,
    required this.currentMealType,
    this.showTimeRange = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final timeRange = _getMealTimeRange(currentMealType);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getMealTypeIcon(currentMealType),
            color: Colors.orange[700],
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            currentMealType.displayName,
            style: TextStyle(
              color: Colors.orange[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (showTimeRange && timeRange != null) ..[
            const SizedBox(width: 4),
            Text(
              timeRange,
              style: TextStyle(
                color: Colors.orange[600],
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  IconData _getMealTypeIcon(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.local_cafe;
      case MealType.lateNight:
        return Icons.nightlight;
    }
  }
  
  String? _getMealTimeRange(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return '6:00-10:00';
      case MealType.lunch:
        return '11:00-14:00';
      case MealType.dinner:
        return '17:00-21:00';
      case MealType.snack:
        return '14:00-17:00';
      case MealType.lateNight:
        return '21:00-2:00';
    }
  }
}

/// 智能餐次推荐器
class SmartMealTypeRecommender extends StatelessWidget {
  final Function(MealType) onMealTypeSelected;
  final bool showCurrentTime;
  
  const SmartMealTypeRecommender({
    super.key,
    required this.onMealTypeSelected,
    this.showCurrentTime = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final currentMealType = _getCurrentMealType();
    final currentTime = DateTime.now();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange[50]!,
            Colors.orange[100]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.orange[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '智能推荐',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (showCurrentTime) ..[
                const Spacer(),
                Text(
                  '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => onMealTypeSelected(currentMealType),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _getMealTypeIcon(currentMealType),
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '推荐${currentMealType.displayName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getMealTypeDescription(currentMealType),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  MealType _getCurrentMealType() {
    final hour = DateTime.now().hour;
    
    if (hour >= 6 && hour < 10) {
      return MealType.breakfast;
    } else if (hour >= 10 && hour < 14) {
      return MealType.lunch;
    } else if (hour >= 14 && hour < 17) {
      return MealType.snack;
    } else if (hour >= 17 && hour < 21) {
      return MealType.dinner;
    } else {
      return MealType.lateNight;
    }
  }
  
  IconData _getMealTypeIcon(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.local_cafe;
      case MealType.lateNight:
        return Icons.nightlight;
    }
  }
  
  String _getMealTypeDescription(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return '开启美好的一天';
      case MealType.lunch:
        return '补充能量，继续奋斗';
      case MealType.dinner:
        return '享受温馨的晚餐时光';
      case MealType.snack:
        return '下午茶时间，来点小食';
      case MealType.lateNight:
        return '夜宵时光，犒赏自己';
    }
  }
}