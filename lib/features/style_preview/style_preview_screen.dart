import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/models/physical_entity.dart';
import '../../features/bubble/controllers/physical_entity_controller.dart';
import '../../features/bubble/widgets/text_physical_entity_widget.dart';
import '../../shared/themes/design_tokens.dart';
import '../../shared/widgets/ui/greeting_header.dart';
import '../../shared/widgets/ui/rounded_card.dart';
import '../../shared/widgets/ui/stat_pill.dart';
import '../../shared/widgets/ui/primary_cta_button.dart';
import '../../shared/widgets/ui/percent_card.dart';
import '../../shared/widgets/ui/progress_arc.dart';
import '../../shared/widgets/ui/mini_curve_chart.dart';

/// 将全新的柔和风格与气泡互动体验融合的示例页面。
class StylePreviewScreen extends StatefulWidget {
  const StylePreviewScreen({super.key});

  @override
  State<StylePreviewScreen> createState() => _StylePreviewScreenState();
}

class _StylePreviewScreenState extends State<StylePreviewScreen> {
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PhysicalEntityController>().initializeEntities();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.cream,
      body: SafeArea(
        child: Consumer<PhysicalEntityController>(
          builder: (context, controller, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GreetingHeader(
                    title: 'Hi, Elizabeth 👋',
                    subtitle: 'Mon, 23 July',
                    avatarUrl: null,
                  ),
                  const SizedBox(height: DesignTokens.md),
                  Row(
                    children: const [
                      Expanded(
                        child: StatPill(
                          icon: Icons.local_fire_department_rounded,
                          value: '44',
                          label: 'Total',
                          color: DesignTokens.mint,
                        ),
                      ),
                      SizedBox(width: DesignTokens.md),
                      Expanded(
                        child: StatPill(
                          icon: Icons.menu_book_rounded,
                          value: '12',
                          label: 'Completed',
                          color: DesignTokens.orange,
                        ),
                      ),
                      SizedBox(width: DesignTokens.md),
                      Expanded(
                        child: StatPill(
                          icon: Icons.schedule_rounded,
                          value: '34',
                          label: 'Upcoming',
                          color: DesignTokens.pink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.xl),
                  const PercentCard(
                    percent: 78,
                    title: 'Taste learning progress',
                    subtitle: '偏好探索进度',
                  ),
                  const SizedBox(height: DesignTokens.lg),
                  RoundedCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Padding(
                          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text('Monthly vibe', style: DesignTokens.h3),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: MiniCurveChart(
                            points: [0.2, 0.35, 0.6, 0.42, 0.8, 0.54, 0.7, 0.66, 0.9],
                            highlightIndex: 4,
                          ),
                        ),
                        SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.lg),
                  RoundedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Flavor focus', style: DesignTokens.h3),
                        SizedBox(height: 8),
                        ProgressArc(value: 0.65),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.xl),
                  _BubbleInteractionCard(controller: controller),
                  const SizedBox(height: DesignTokens.xl),
                  _PreferenceRecap(controller: controller),
                  const SizedBox(height: DesignTokens.xl),
                  Center(
                    child: PrimaryCtaButton(
                      label: controller.selectedCount > 0 ? '生成今日菜谱' : '先挑几个口味',
                      icon: controller.selectedCount > 0
                          ? Icons.restaurant_menu_rounded
                          : Icons.touch_app_rounded,
                      onPressed: controller.selectedCount > 0
                          ? () => controller.generateRecommendations()
                          : null,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.xxl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BubbleInteractionCard extends StatefulWidget {
  const _BubbleInteractionCard({required this.controller});

  final PhysicalEntityController controller;

  @override
  State<_BubbleInteractionCard> createState() => _BubbleInteractionCardState();
}

class _BubbleInteractionCardState extends State<_BubbleInteractionCard> {
  final GlobalKey _boardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return RoundedCard(
      color: DesignTokens.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('互动口味气泡', style: DesignTokens.h3),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                color: DesignTokens.inkMuted,
                tooltip: '重置布局',
                onPressed: controller.resetEntities,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.md),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: DesignTokens.bigRadius,
              child: Container(
                key: _boardKey,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DesignTokens.surfaceMuted,
                      Colors.white,
                    ],
                  ),
                ),
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          controller.updateContainerSize(constraints.biggest);
                          return Stack(
                            clipBehavior: Clip.none,
                            children: controller.entities
                                .map(
                                  (entity) => Positioned(
                                    left: entity.position.dx - entity.radius,
                                    top: entity.position.dy - entity.radius,
                                    child: _BubbleEntityTile(
                                      entity: entity,
                                      controller: controller,
                                      boardKey: _boardKey,
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleEntityTile extends StatelessWidget {
  const _BubbleEntityTile({
    required this.entity,
    required this.controller,
    required this.boardKey,
  });

  final PhysicalEntity entity;
  final PhysicalEntityController controller;
  final GlobalKey boardKey;

  void _handleTap() {
    HapticFeedback.mediumImpact();
    controller.toggleEntitySelection(entity.id);
  }

  void _handleLongPress(BuildContext context) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entity.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(entity.name, style: DesignTokens.h2),
              const SizedBox(height: 8),
              Text(entity.description, style: DesignTokens.body),
            ],
          ),
        );
      },
    );
  }

  void _handlePanStart() {
    HapticFeedback.selectionClick();
    controller.pausePhysics();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final renderBox = boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final local = renderBox.globalToLocal(details.globalPosition);
    controller.updateEntityPosition(entity.id, local);
  }

  void _handlePanEnd(DragEndDetails details, BuildContext context) {
    final velocity = details.velocity.pixelsPerSecond;
    controller.applyVelocityToEntity(entity.id, velocity);

    if (velocity.distance < 200) {
      controller.restartPhysics();
      return;
    }

    if (velocity.dx.abs() > velocity.dy.abs()) {
      if (velocity.dx > 150) {
        controller.favoriteEntity(entity.id);
        _showFeedback(context, '⭐ 收藏 ${entity.name}');
      } else if (velocity.dx < -150) {
        controller.skipEntity(entity.id);
        _showFeedback(context, '⏭️ 跳过 ${entity.name}');
      }
    } else {
      if (velocity.dy < -150) {
        controller.likeEntity(entity.id);
        _showFeedback(context, '👍 喜欢 ${entity.name}');
      } else if (velocity.dy > 150) {
        controller.dislikeEntity(entity.id);
        _showFeedback(context, '👎 不喜欢 ${entity.name}');
      }
    }
  }

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        backgroundColor: DesignTokens.ink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = controller.likedEntities.any((e) => e.id == entity.id);
    final isDisliked = controller.dislikedEntities.any((e) => e.id == entity.id);

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: () => _handleLongPress(context),
      onPanStart: (_) => _handlePanStart(),
      onPanUpdate: _handlePanUpdate,
      onPanEnd: (details) => _handlePanEnd(details, context),
      child: TextPhysicalEntityWidget(
        entity: entity,
        isSelected: entity.isSelected,
        isLiked: isLiked,
        isDisliked: isDisliked,
        scale: 1.0,
      ),
    );
  }
}

class _PreferenceRecap extends StatelessWidget {
  const _PreferenceRecap({required this.controller});

  final PhysicalEntityController controller;

  @override
  Widget build(BuildContext context) {
    final liked = controller.likedEntities.map((e) => e.name).toList();
    final disliked = controller.dislikedEntities.map((e) => e.name).toList();

    if (liked.isEmpty && disliked.isEmpty) {
      return RoundedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('快速提示', style: DesignTokens.h3),
            SizedBox(height: DesignTokens.sm),
            Text('向上滑表示喜欢，向下滑表示不喜欢，左右滑可以收藏或跳过。', style: DesignTokens.body),
          ],
        ),
      );
    }

    return RoundedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('偏好记录', style: DesignTokens.h3),
          const SizedBox(height: DesignTokens.sm),
          if (liked.isNotEmpty) ...[
            const Text('喜欢的口味', style: DesignTokens.body),
            const SizedBox(height: DesignTokens.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: liked
                  .map(
                    (name) => Chip(
                      backgroundColor: DesignTokens.mint.withOpacity(0.15),
                      label: Text(name),
                      avatar: const Icon(Icons.thumb_up, size: 16, color: DesignTokens.mint),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: DesignTokens.md),
          ],
          if (disliked.isNotEmpty) ...[
            const Text('不喜欢的口味', style: DesignTokens.body),
            const SizedBox(height: DesignTokens.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: disliked
                  .map(
                    (name) => Chip(
                      backgroundColor: DesignTokens.pink.withOpacity(0.15),
                      label: Text(name),
                      avatar: const Icon(Icons.thumb_down, size: 16, color: DesignTokens.pink),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
