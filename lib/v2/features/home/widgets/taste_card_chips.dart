import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TasteCardReactionChip extends StatelessWidget {
  const TasteCardReactionChip({
    super.key,
    required this.reaction,
    required this.color,
    required this.compact,
  });

  final TasteCardReaction reaction;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          color: reaction == TasteCardReaction.disliked
              ? AppColors.textPrimary
              : Colors.white,
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _backgroundColor() {
    switch (reaction) {
      case TasteCardReaction.liked:
        return const Color(0xFFC94B2C);
      case TasteCardReaction.disliked:
        return const Color(0xFFE9E4E1);
      case TasteCardReaction.skipped:
        return color.withValues(alpha: 0.82);
    }
  }

  String _label() {
    switch (reaction) {
      case TasteCardReaction.liked:
        return '喜欢';
      case TasteCardReaction.disliked:
        return '不要';
      case TasteCardReaction.skipped:
        return '略过';
    }
  }
}

class TasteCardMicroCodePill extends StatelessWidget {
  const TasteCardMicroCodePill({
    super.key,
    required this.text,
    required this.accent,
  });

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textPrimary.withValues(alpha: 0.48),
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
