import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class TasteSignaturePanel extends StatelessWidget {
  const TasteSignaturePanel({
    super.key,
    required this.session,
    required this.onBack,
    required this.onStartInference,
    required this.onRemoveLiked,
    required this.onRemoveDisliked,
  });

  final TasteDeckSessionState session;
  final VoidCallback onBack;
  final VoidCallback onStartInference;
  final ValueChanged<String> onRemoveLiked;
  final ValueChanged<String> onRemoveDisliked;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 520;
        final containerPadding = compact ? 16.0 : 20.0;
        final titleSize = compact ? 20.0 : 24.0;
        final summarySize = compact ? 13.0 : 14.0;
        final sectionGap = compact ? 10.0 : 12.0;
        final buttonVerticalPadding = compact ? 12.0 : 14.0;

        return Container(
          key: const ValueKey('taste-signature-face'),
          padding: EdgeInsets.fromLTRB(
            containerPadding,
            containerPadding,
            containerPadding,
            containerPadding,
          ),
          decoration: AppDecorations.card(
            color: AppPalette.surface,
            radius: AppRadii.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '你的口味签名',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 8),
                      Text(
                        _buildSummary(),
                        style: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.64),
                          fontSize: summarySize,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 12),
                      _SignatureSummaryBand(
                        key: const ValueKey('taste-signature-summary-band'),
                        likedCount: session.likedTagIds.length,
                        dislikedCount: session.dislikedTagIds.length,
                        requirementCount:
                            session.freeformRequirement.trim().isEmpty ? 0 : 1,
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      _SignatureGroup(
                        title: '喜欢',
                        ids: session.likedTagIds,
                        items: session.likedTagLabels,
                        accent: const Color(0xFFC94B2C),
                        compact: compact,
                        onRemove: onRemoveLiked,
                      ),
                      SizedBox(height: sectionGap),
                      _SignatureGroup(
                        title: '不要',
                        ids: session.dislikedTagIds,
                        items: session.dislikedTagLabels,
                        accent: const Color(0xFF8B695F),
                        compact: compact,
                        onRemove: onRemoveDisliked,
                      ),
                      SizedBox(height: sectionGap),
                      _SignatureGroup(
                        title: '略过',
                        ids: session.skippedTagIds,
                        items: session.skippedTagLabels,
                        accent: const Color(0xFF667C79),
                        compact: compact,
                      ),
                      if (session.freeformRequirement.trim().isNotEmpty) ...[
                        SizedBox(height: sectionGap),
                        Text(
                          '补充要求',
                          style: TextStyle(
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.45),
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 6),
                        Text(
                          session.freeformRequirement.trim(),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: compact ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: compact ? 10 : 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppPalette.divider),
                        padding: EdgeInsets.symmetric(
                          vertical: buttonVerticalPadding,
                        ),
                      ),
                      child: const Text('返回实体池'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('start-inference-button'),
                      onPressed:
                          session.canStartInference ? onStartInference : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.chili,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: buttonVerticalPadding,
                        ),
                      ),
                      child: const Text('生成推荐'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _buildSummary() {
    final liked = session.likedTagLabels.take(3).join('、');
    final disliked = session.dislikedTagLabels.take(2).join('、');
    final base = liked.isEmpty ? '你还没有留下明确喜欢项。' : '今天更偏向 $liked';
    if (disliked.isEmpty) return base;
    return '$base，同时会主动避开 $disliked。';
  }
}

class _SignatureSummaryBand extends StatelessWidget {
  const _SignatureSummaryBand({
    super.key,
    required this.likedCount,
    required this.dislikedCount,
    required this.requirementCount,
  });

  final int likedCount;
  final int dislikedCount;
  final int requirementCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: AppDecorations.card(color: AppPalette.surfaceMuted),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SignatureMetricChip(
            label: '喜欢 $likedCount',
            color: const Color(0xFFC94B2C),
          ),
          _SignatureMetricChip(
            label: '排除 $dislikedCount',
            color: const Color(0xFF8B695F),
          ),
          _SignatureMetricChip(
            label: '补充 $requirementCount',
            color: const Color(0xFF667C79),
          ),
        ],
      ),
    );
  }
}

class _SignatureMetricChip extends StatelessWidget {
  const _SignatureMetricChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SignatureGroup extends StatelessWidget {
  const _SignatureGroup({
    required this.title,
    required this.ids,
    required this.items,
    required this.accent,
    required this.compact,
    this.onRemove,
  });

  final String title;
  final List<String> ids;
  final List<String> items;
  final Color accent;
  final bool compact;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: accent,
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: compact ? 6 : 8),
        Wrap(
          spacing: compact ? 6 : 8,
          runSpacing: compact ? 6 : 8,
          children: [
            for (var index = 0; index < items.length; index++)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 9 : 11,
                  vertical: compact ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      items[index],
                      style: TextStyle(
                        color: accent,
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (onRemove != null && index < ids.length) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        key: ValueKey('remove-taste-${ids[index]}'),
                        onTap: () => onRemove!.call(ids[index]),
                        borderRadius: BorderRadius.circular(99),
                        child: Icon(
                          Icons.close_rounded,
                          size: compact ? 15 : 16,
                          color: accent.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (items.isEmpty)
              Text(
                '还没有',
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
