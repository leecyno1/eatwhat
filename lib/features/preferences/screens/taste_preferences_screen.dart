import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

import '../../../shared/themes/design_tokens.dart';
import '../../../core/models/bubble.dart';
import '../../../core/models/physical_entity.dart';
import '../../recommendation/screens/enhanced_recommendation_screen.dart';
import '../../recommendation/controllers/recommendation_controller.dart';
import '../state/taste_preferences_model.dart';
import '../widgets/taste_bubble_tile.dart';

/// 未来风格的「口味偏好选择」页面
/// - Masonry 瀑布流：卡片尺寸随权重变化
/// - 交互：点击选择，双击权重+1，长按弹出滑块微调，左滑标记为不吃
class TastePreferencesScreen extends StatefulWidget {
  const TastePreferencesScreen({super.key});

  @override
  State<TastePreferencesScreen> createState() => _TastePreferencesScreenState();
}

class _TastePreferencesScreenState extends State<TastePreferencesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 首次进入时初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TastePreferencesModel>().initializeWithDefaults();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text('选择你的口味'),
        actions: [
          IconButton(
            onPressed: () => context.read<TastePreferencesModel>().reset(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '重置',
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _CategoryTabs(),
            const SizedBox(height: 8),
            const Expanded(child: _MasonryBoard()),
            const _BottomBar(),
          ],
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  static const _tabs = [
    ('all', '全部'),
    ('taste', '味型'),
    ('method', '烹法'),
    ('ingredient', '食材'),
    ('texture', '口感'),
    ('avoid', '禁忌'),
  ];

  const _CategoryTabs();

  @override
  Widget build(BuildContext context) {
    return Consumer<TastePreferencesModel>(
      builder: (context, model, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final (key, label) in _tabs)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: model.activeCategory == key,
                    onSelected: (_) => model.setCategory(key),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MasonryBoard extends StatelessWidget {
  const _MasonryBoard();

  @override
  Widget build(BuildContext context) {
    return Consumer<TastePreferencesModel>(
      builder: (context, model, _) {
        final tags = model.visibleTags;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AnimationLimiter(
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: tags.length,
              itemBuilder: (context, i) {
                final t = tags[i];
                return AnimationConfiguration.staggeredList(
                  position: i,
                  delay: const Duration(milliseconds: 60),
                  duration: const Duration(milliseconds: 420),
                  child: ScaleAnimation(
                    scale: 0.9,
                    curve: Curves.easeOutBack,
                    child: FadeInAnimation(
                      child: TasteBubbleTile(
                        tag: t,
                        onToggle: () => model.toggle(t),
                        onAdjust: (v) => model.adjustWeight(t, v),
                        onDislike: () => model.dislike(t),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<TastePreferencesModel>(
      builder: (context, model, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: model.selectedCount > 0 ? model.reset : null,
                  icon: const Icon(Icons.clear_all_rounded),
                  label: Text('清空 (${model.selectedCount})'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: DesignTokens.pillRadius,
                    boxShadow: DesignTokens.softShadows(),
                  ),
                  child: ElevatedButton.icon(
                    onPressed:
                        model.selectedCount > 0 ? () => _generateAndGo(context, model) : null,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('生成推荐'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateAndGo(BuildContext context, TastePreferencesModel model) async {
    // 1) 将选中标签映射为 Bubble 列表（用于推荐引擎）
    final bubbles = model.all
        .where((t) => t.isSelected)
        .map((t) => Bubble(
              type: switch (t.category) {
                'taste' => BubbleType.taste,
                'ingredient' => BubbleType.ingredient,
                'method' => BubbleType.cuisine, // 暂借作为烹法分类
                'texture' => BubbleType.nutrition,
                'avoid' => BubbleType.cuisine,
                _ => BubbleType.taste,
              },
              name: t.name,
              color: Colors.orangeAccent,
              weight: (t.weight <= 0 ? 1 : t.weight) / 3.0, // 简单归一化
            ))
        .toList();

    // 2) 构造用于展示的 PhysicalEntity 列表（用于推荐页顶部“您的偏好”Chip）
    final prefs = model.all
        .where((t) => t.isSelected)
        .map((t) => PhysicalEntity(
              id: t.id,
              name: t.name,
              description: t.category,
              type: switch (t.category) {
                'taste' => PhysicalEntityType.taste,
                'ingredient' => PhysicalEntityType.ingredient,
                'method' => PhysicalEntityType.cuisine,
                'texture' => PhysicalEntityType.nutrition,
                'avoid' => PhysicalEntityType.cuisine,
                _ => PhysicalEntityType.taste,
              },
              emoji: t.emoji ?? '🍽️',
              primaryColor: Colors.orangeAccent,
              secondaryColor: Colors.amberAccent,
            ))
        .toList();

    // 3) 调用推荐控制器生成推荐结果
    final rec = context.read<RecommendationController>();
    await rec.generateRecommendations(bubbles);
    if (!context.mounted) return;

    // 4) 跳转到增强推荐页展示
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnhancedRecommendationScreen(
          recommendedFoods: rec.recommendations,
          selectedPreferences: prefs,
        ),
      ),
    );
  }
}
