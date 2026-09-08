import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PreferenceGestureHint extends StatelessWidget {
  const PreferenceGestureHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _HintCard(
            title: '上滑收进偏爱',
            subtitle: '喜欢的味道向上推，优先进入下一轮推荐。',
            icon: Icons.arrow_upward_rounded,
            accent: Color(0xFFF35C38),
            background: Color(0xFFFDE2D8),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _HintCard(
            title: '下滑略过这味',
            subtitle: '今天不想碰的口味直接压下去，降低命中概率。',
            icon: Icons.arrow_downward_rounded,
            accent: Color(0xFF1A181D),
            background: Color(0xFFF4EDE7),
          ),
        ),
      ],
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.background,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.75),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F241110),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accent.computeLuminance() > 0.6
                  ? AppColors.textPrimary
                  : Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.65),
              fontSize: 11.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
