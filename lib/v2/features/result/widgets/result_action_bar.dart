import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class ResultPrimaryConfirmBar extends StatelessWidget {
  const ResultPrimaryConfirmBar({
    super.key,
    required this.onConfirm,
    this.confirmLabel = '就吃这个',
  });

  final VoidCallback onConfirm;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('result-primary-confirm-bar'),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: GoldPalette.panel,
        borderRadius: AppRadii.card,
        border: Border.all(color: GoldPalette.goldHairline),
      ),
      child: FilledButton.icon(
        key: const ValueKey('execution-entry-button'),
        onPressed: onConfirm,
        style: FilledButton.styleFrom(
          backgroundColor: GoldPalette.gold,
          foregroundColor: GoldPalette.nightDeep,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.capsule),
        ),
        icon: const Icon(Icons.arrow_forward_rounded, size: 19),
        label: Text(confirmLabel),
      ),
    );
  }
}
