import 'package:flutter/material.dart';
import '../../../core/models/recipe.dart';

/// 菜谱详情页面
class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.recipe.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.name),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              // TODO: 保存收藏状态
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorite ? '已添加到收藏' : '已移除收藏'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 菜谱图片
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.recipe.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.star),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 基本信息
            Text(
              widget.recipe.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 16),

            // 标签和信息
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(widget.recipe.cuisine),
                  backgroundColor: Colors.orange[100],
                ),
                Chip(
                  label: Text(widget.recipe.difficulty.label),
                  backgroundColor: Colors.blue[100],
                ),
                Chip(
                  label: Text('${widget.recipe.totalTime}分钟'),
                  backgroundColor: Colors.green[100],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 食材列表
            const Text(
              '所需食材',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...widget.recipe.ingredients.map((ingredient) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: ingredient.isMain ? Colors.orange : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(ingredient.name)),
                    Text(
                      '${ingredient.amount}${ingredient.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // 制作步骤
            const Text(
              '制作步骤',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...widget.recipe.steps.map((step) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(step.description),
                    ),
                  ],
                ),
              );
            }),

            if (widget.recipe.tips != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '制作小贴士',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.recipe.tips!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
