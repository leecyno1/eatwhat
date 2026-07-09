import 'package:eatwhat_app/core/data/taste_visual_mapping.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class TasteSignatureRail extends StatefulWidget {
  const TasteSignatureRail({super.key});

  @override
  State<TasteSignatureRail> createState() => _TasteSignatureRailState();
}

class _TasteSignatureRailState extends State<TasteSignatureRail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const entries = [
      _TasteSignatureEntry(
        keyLabel: '辣',
        title: '辣感升温',
        subtitle: '红椒轮廓 + 热气符号，适合重口与夜晚情绪。',
      ),
      _TasteSignatureEntry(
        keyLabel: '鲜',
        title: '海味提鲜',
        subtitle: '清透蓝绿玻璃层，给推荐增加轻亮和干净感。',
      ),
      _TasteSignatureEntry(
        keyLabel: '火锅',
        title: '火锅夜场',
        subtitle: '高饱和暖橙与厚重阴影，强调聚餐和爽感。',
      ),
      _TasteSignatureEntry(
        keyLabel: '清淡',
        title: '轻盈留白',
        subtitle: '奶白与雾蓝偏冷配色，用于午餐和控卡选择。',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '偏好实体库',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              'visual signatures',
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.42),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '每个偏好都应该是一种有形体、有情绪、有动画方向的视觉对象。先用一组代表性实体，把 UI 语言固定下来。',
          style: TextStyle(
            color: AppColors.textPrimary.withValues(alpha: 0.68),
            fontSize: 12.5,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 178,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final animation = CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  index * 0.12,
                  0.7 + index * 0.08,
                  curve: Curves.easeOutCubic,
                ),
              );
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final value = animation.value.clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(0, 18 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _TasteSignatureCard(entry: entry, index: index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TasteSignatureCard extends StatelessWidget {
  const _TasteSignatureCard({
    required this.entry,
    required this.index,
  });

  final _TasteSignatureEntry entry;
  final int index;

  @override
  Widget build(BuildContext context) {
    final visual = TasteVisualMapping.guess(entry.keyLabel);
    final accent = visual.color;
    final largeLabel = entry.keyLabel.substring(0, 1);
    final icon = visual.materialIcon ?? Icons.restaurant_rounded;

    return Container(
      width: 186,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(index.isEven ? 28 : 18),
          topRight: const Radius.circular(28),
          bottomLeft: const Radius.circular(28),
          bottomRight: Radius.circular(index.isEven ? 18 : 28),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.94),
            accent.withValues(alpha: 0.14),
            accent.withValues(alpha: 0.24),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.78),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 4,
            top: -6,
            child: Text(
              largeLabel,
              style: TextStyle(
                color: accent.withValues(alpha: 0.12),
                fontSize: 68,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                entry.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.subtitle,
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.68),
                  fontSize: 11.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF17131A),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  visual.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TasteSignatureEntry {
  const _TasteSignatureEntry({
    required this.keyLabel,
    required this.title,
    required this.subtitle,
  });

  final String keyLabel;
  final String title;
  final String subtitle;
}
