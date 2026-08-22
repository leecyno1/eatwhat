import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_enrichment_controller.dart';
import 'package:flutter/material.dart';

class PairingSuggestion {
  const PairingSuggestion({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String category;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
}

class PairingBand extends StatelessWidget {
  const PairingBand({
    super.key,
    required this.pairings,
    required this.loadState,
  });

  final List<PairingSuggestion> pairings;
  final PairingLoadState loadState;

  @override
  Widget build(BuildContext context) {
    final visiblePairings = pairings.isEmpty ? _loadingPlaceholders : pairings;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.42),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.74),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '顺手搭一套',
                style: TextStyle(
                  color: AppPalette.moonlight,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (loadState == PairingLoadState.loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.sunsetOrange,
                    ),
                  ),
                )
              else
                Text(
                  loadState == PairingLoadState.fallback
                      ? '规则兜底 ${pairings.length} 条'
                      : '${pairings.length} 条搭配',
                  style: TextStyle(
                    color: AppPalette.moonlight.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            switch (loadState) {
              PairingLoadState.loading => '正在结合这道菜的口味结构补全饮品和配菜。',
              PairingLoadState.loaded => '不打断你的主选择，只给你几颗顺手就能一起选的搭配气泡。',
              PairingLoadState.fallback => 'AI 搭配暂时不可用，先用本地规则给你补一套顺手组合。',
            },
            style: TextStyle(
              color: AppPalette.moonlight.withValues(alpha: 0.52),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final pairing in visiblePairings)
                PairingBubble(pairing: pairing),
            ],
          ),
        ],
      ),
    );
  }

  List<PairingSuggestion> get _loadingPlaceholders => const [
        PairingSuggestion(
          category: '饮品',
          title: '正在匹配',
          subtitle: '先按这道菜的口味去找顺口的饮料。',
          accent: Color(0xFFF46B40),
          icon: Icons.local_drink_rounded,
        ),
        PairingSuggestion(
          category: '配菜',
          title: '正在补全',
          subtitle: '同时找一份顺手就能一起点的小菜。',
          accent: Color(0xFF7ABF88),
          icon: Icons.eco_rounded,
        ),
      ];
}

class PairingBubble extends StatelessWidget {
  const PairingBubble({
    super.key,
    required this.pairing,
  });

  final PairingSuggestion pairing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.78),
            pairing.accent.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.78),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pairing.accent.withValues(alpha: 0.18),
            ),
            child: Icon(
              pairing.icon,
              color: pairing.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pairing.category,
                  style: TextStyle(
                    color: pairing.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pairing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppPalette.moonlight,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  pairing.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppPalette.moonlight.withValues(alpha: 0.52),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
