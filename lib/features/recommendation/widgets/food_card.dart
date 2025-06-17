import 'package:flutter/material.dart';
import '../../../core/models/food.dart';

/// 食物推荐卡片
class FoodCard extends StatelessWidget {
  final Food food;
  final VoidCallback? onTap;
  final bool isCompact;

  const FoodCard({
    super.key,
    required this.food,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: isCompact ? _buildCompactLayout() : _buildFullLayout(),
        ),
      ),
    );
  }

  Widget _buildCompactLayout() {
    return Row(
      children: [
        _buildFoodImage(60),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                food.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                food.cuisineType,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              _buildRatingRow(),
            ],
          ),
        ),
        _buildCaloriesBadge(),
      ],
    );
  }

  Widget _buildFullLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildFoodImage(80),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    food.cuisineType,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRatingRow(),
                ],
              ),
            ),
            _buildCaloriesBadge(),
          ],
        ),
        if (food.description != null) ...[
          const SizedBox(height: 12),
          Text(
            food.description!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildTagsRow(),
        if (food.nutritionFacts?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _buildNutritionRow(),
        ],
      ],
    );
  }

  Widget _buildFoodImage(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade200,
            Colors.orange.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: food.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                food.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFoodIcon(size),
              ),
            )
          : _buildFoodIcon(size),
    );
  }

  Widget _buildFoodIcon(double size) {
    return Center(
      child: Icon(
        Icons.restaurant,
        size: size * 0.4,
        color: Colors.white,
      ),
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < food.rating.floor()
                ? Icons.star
                : (index < food.rating ? Icons.star_half : Icons.star_border),
            size: 16,
            color: Colors.amber,
          );
        }),
        const SizedBox(width: 4),
        Text(
          '${food.rating.toStringAsFixed(1)} (${food.ratingCount})',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCaloriesBadge() {
    if (food.calories == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCalorieColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${food.calories} 卡',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getCalorieColor() {
    if (food.calories == null) return Colors.grey;
    if (food.calories! < 200) return Colors.green;
    if (food.calories! < 400) return Colors.orange;
    return Colors.red;
  }

  Widget _buildTagsRow() {
    final allTags = [
      ...food.tasteAttributes,
      ...food.ingredients.take(3),
      if (food.scenarios?.isNotEmpty == true) ...food.scenarios!.take(2),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: allTags.take(6).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNutritionRow() {
    if (food.nutritionFacts?.isEmpty != false) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      children: food.nutritionFacts!.entries.take(3).map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.eco,
                size: 12,
                color: Colors.green[700],
              ),
              const SizedBox(width: 4),
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
} 