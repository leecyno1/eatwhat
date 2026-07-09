import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/execution/controllers/execution_completion_controller.dart';
import 'package:eatwhat_app/v2/features/execution/widgets/execution_widgets.dart';
import 'package:flutter/material.dart';

class ExecutionCompletionFeedbackPanel extends StatefulWidget {
  const ExecutionCompletionFeedbackPanel({
    super.key,
    required this.intent,
    required this.platform,
    this.controller,
  });

  final ExecutionIntent intent;
  final String platform;
  final ExecutionCompletionController? controller;

  @override
  State<ExecutionCompletionFeedbackPanel> createState() =>
      _ExecutionCompletionFeedbackPanelState();
}

class _ExecutionCompletionFeedbackPanelState
    extends State<ExecutionCompletionFeedbackPanel> {
  late final ExecutionCompletionController _controller =
      widget.controller ?? ExecutionCompletionController();

  ExecutionCompletionFeedback? _selection;

  Future<void> _recordCompleted() async {
    final message = await _controller.recordCompleted(
      intent: widget.intent,
      platform: widget.platform,
    );
    if (!mounted) return;
    setState(() {
      _selection = ExecutionCompletionFeedback.done;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _recordNotNow() async {
    final message = await _controller.recordNotNow(widget.intent);
    if (!mounted) return;
    setState(() {
      _selection = ExecutionCompletionFeedback.notNow;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const selectedColor = AppPalette.ocean;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: executionGlassBoxDecoration().copyWith(
        border: Border.all(color: AppPalette.ocean.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('吃完记一笔', style: AppType.label),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _ExecutionCompletionButton(
                  key: const ValueKey('execution-completion-done'),
                  label: '这次吃完了',
                  icon: Icons.check_circle_rounded,
                  selected: _selection == ExecutionCompletionFeedback.done,
                  accent: selectedColor,
                  onTap: _recordCompleted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ExecutionCompletionButton(
                  key: const ValueKey('execution-completion-not-now'),
                  label: '先不记完成',
                  icon: Icons.schedule_rounded,
                  selected: _selection == ExecutionCompletionFeedback.notNow,
                  accent: AppColors.textPrimary,
                  onTap: _recordNotNow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum ExecutionCompletionFeedback {
  done,
  notNow,
}

class _ExecutionCompletionButton extends StatelessWidget {
  const _ExecutionCompletionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppPalette.rice : AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.panel,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.white.withValues(alpha: 0.54),
            borderRadius: AppRadii.panel,
            border: Border.all(
              color: selected
                  ? accent
                  : AppColors.textPrimary.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.label.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
