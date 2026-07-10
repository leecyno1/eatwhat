import 'package:flutter/material.dart';
import '../../../core/services/recommendation_engine.dart';
import '../../../core/services/purchase_link_service.dart';
import '../../../core/models/food.dart';
import 'dart:math' as math;

/// 推荐展示组件
/// 目标：
/// 1. 轮播 (PageView) 展示 ScoredFood
/// 2. 显示总分 + 评分拆解 (展开/收起)
/// 3. 购买/跳转按钮 -> 调用 PurchaseLinkService
/// 4. 支持多平台快速切换
class RecommendationShowcase extends StatefulWidget {
  final List<ScoredFood> scoredFoods;
  final double height;
  final bool showRankBadge;

  const RecommendationShowcase({
    super.key,
    required this.scoredFoods,
    this.height = 380,
    this.showRankBadge = true,
  });

  @override
  State<RecommendationShowcase> createState() => _RecommendationShowcaseState();
}

class _RecommendationShowcaseState extends State<RecommendationShowcase> {
  final PageController _pageController = PageController(viewportFraction: 0.82);
  int _currentIndex = 0;
  bool _showBreakdown = false;
  PurchasePlatform _platform = PurchasePlatform.eleme;
  late final PurchaseLinkService _purchaseService;

  @override
  void initState() {
    super.initState();
    _purchaseService = PurchaseLinkService();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scoredFoods.isEmpty) {
      return const Center(child: Text('暂无推荐'));
    }

    return SizedBox(
      height: widget.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          Expanded(child: _buildCarousel()),
          const SizedBox(height: 8),
          _buildPlatformSelector(),
          const SizedBox(height: 4),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          '智能推荐',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            '第 ${_currentIndex + 1} / ${widget.scoredFoods.length} 个',
            key: ValueKey(_currentIndex),
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => setState(() => _showBreakdown = !_showBreakdown),
          icon: Icon(
            _showBreakdown ? Icons.analytics_outlined : Icons.analytics,
            size: 18,
          ),
          label: Text(_showBreakdown ? '收起' : '评分拆解'),
        )
      ],
    );
  }

  Widget _buildCarousel() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.scoredFoods.length,
      onPageChanged: (i) => setState(() => _currentIndex = i),
      itemBuilder: (context, index) {
        final data = widget.scoredFoods[index];
        final selected = index == _currentIndex;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 450),
          padding: EdgeInsets.symmetric(vertical: selected ? 2 : 20, horizontal: 6),
          child: _RecommendationCard(
            data: data,
            rank: index + 1,
            showBadge: widget.showRankBadge,
            showBreakdown: _showBreakdown,
          ),
        );
      },
    );
  }

  Widget _buildPlatformSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PurchasePlatform.values.map((p) {
          final active = p == _platform;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p.name),
              selected: active,
              onSelected: (_) => setState(() => _platform = p),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionBar() {
    if (widget.scoredFoods.isEmpty) return const SizedBox();
    final current = widget.scoredFoods[_currentIndex];
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              final result = _purchaseService.generateLink(
                platform: _platform,
                keyword: current.food.name,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已生成链接: ${result.url}')),
              );
            },
            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
            label: const Text('购买/外卖'),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 400), curve: Curves.easeOut),
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          onPressed: () => _pageController.nextPage(
              duration: const Duration(milliseconds: 400), curve: Curves.easeOut),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final ScoredFood data;
  final int rank;
  final bool showBadge;
  final bool showBreakdown;

  const _RecommendationCard({
    required this.data,
    required this.rank,
    required this.showBadge,
    required this.showBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final food = data.food;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade50,
              Colors.orange.shade100,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BackdropPainter(seed: rank),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBadge) _buildRankBadge(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              food.description ?? '美味佳肴',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildScore(data.score),
                    ],
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 6,
                    runSpacing: -6,
                    children: [
                      if (food.cuisineType != null) _chip(food.cuisineType!, Icons.ramen_dining),
                      ..._buildTasteChips(food),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: showBreakdown
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _ScoreBreakdownView(breakdown: data.scoreBreakdown),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.deepOrangeAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '#$rank',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildScore(double score) {
    return Column(
      children: [
        Text(score.toStringAsFixed(2),
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
        const Text('综合', style: TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  Iterable<Widget> _buildTasteChips(Food food) {
    final tastes = food.tasteAttributes ?? const [];
    return tastes.take(4).map((t) => _chip(t, Icons.local_fire_department));
  }

  Widget _chip(String label, IconData icon) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      avatar: Icon(icon, size: 14),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
    );
  }
}

class _ScoreBreakdownView extends StatelessWidget {
  final Map<String, double> breakdown;
  const _ScoreBreakdownView({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final entries = breakdown.entries.where((e) => e.key != 'total').toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('评分构成', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        ...entries.map((e) => _bar(e.key, e.value)),
      ],
    );
  }

  Widget _bar(String key, double value) {
    final percent = ((value + 1) / 2).clamp(0.0, 1.0); // 简易归一
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(key, style: const TextStyle(fontSize: 11))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(_colorForKey(key)),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Color _colorForKey(String k) {
    switch (k) {
      case 'history':
        return Colors.indigo;
      case 'cuisine':
        return Colors.teal;
      case 'taste':
        return Colors.deepOrange;
      case 'bubble':
        return Colors.pinkAccent;
      case 'quality':
        return Colors.blueAccent;
      case 'novelty':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

/// 背景装饰 Painter (简单噪声 + 圆形渐变)
class _BackdropPainter extends CustomPainter {
  final int seed;
  _BackdropPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(seed);
    final paint = Paint();

    for (int i = 0; i < 24; i++) {
      final dx = rand.nextDouble() * size.width;
      final dy = rand.nextDouble() * size.height;
      final radius = rand.nextDouble() * 40 + 10;
      final opacity = (rand.nextDouble() * 0.15).clamp(0.02, 0.15);
      paint.shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(opacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: radius));
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) => oldDelegate.seed != seed;
}
