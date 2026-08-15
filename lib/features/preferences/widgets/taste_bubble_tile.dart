import 'package:flutter/material.dart';
import '../../../shared/themes/design_tokens.dart';
import '../models/taste_tag.dart';

/// 单个“气泡”卡片。采用圆角矩形，支持点击、双击、长按弹出权重调节。
class TasteBubbleTile extends StatelessWidget {
  const TasteBubbleTile({
    super.key,
    required this.tag,
    required this.onToggle,
    required this.onAdjust,
    required this.onDislike,
  });

  final TasteTag tag;
  final VoidCallback onToggle;
  final ValueChanged<double> onAdjust; // 0..5
  final VoidCallback onDislike;

  Color _bgColor(BuildContext context) {
    final base = switch (tag.category) {
      'taste' => Colors.orange,
      'method' => Colors.teal,
      'ingredient' => Colors.amber,
      'texture' => Colors.lightBlue,
      'avoid' => Colors.pink,
      _ => Colors.grey,
    };

    if (tag.disliked) {
      return Colors.grey.shade300;
    }

    // 强度映射：根据权重调整透明度
    final opacity = 0.15 + (tag.weight / 5) * 0.65; // 0.15..0.8
    return base.withOpacity(opacity);
  }

  Color _fgColor(BuildContext context) {
    if (tag.disliked) return Colors.grey.shade600;
    return DesignTokens.ink;
  }

  double _height() => 84 + tag.weight * 18; // 基本高度随权重变化

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      onDoubleTap: () => onAdjust((tag.weight + 1).clamp(0, 5)),
      onLongPress: () async {
        final v = await showModalBottomSheet<double>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (context) => _WeightSheet(tag: tag),
        );
        if (v != null) onAdjust(v);
      },
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity != null && d.primaryVelocity! < -200) {
          // 左滑标记为不吃
          onDislike();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        height: _height(),
        decoration: BoxDecoration(
          color: _bgColor(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
          border: Border.all(
            color: tag.isSelected ? Colors.black.withOpacity(0.06) : Colors.transparent,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tag.emoji != null) Text(tag.emoji!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      tag.name,
                      style: DesignTokens.h3.copyWith(
                        color: _fgColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      tag.disliked
                          ? '不吃'
                          : tag.weight == 0
                              ? '未选'
                              : '${tag.weight.toStringAsFixed(0)}★',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightSheet extends StatefulWidget {
  const _WeightSheet({required this.tag});

  final TasteTag tag;

  @override
  State<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends State<_WeightSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.tag.weight;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('调整权重：${widget.tag.name}', style: DesignTokens.h2),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('0'),
              Expanded(
                child: Slider(
                  min: 0,
                  max: 5,
                  divisions: 5,
                  value: _value,
                  label: _value.toStringAsFixed(0),
                  onChanged: (v) => setState(() => _value = v),
                ),
              ),
              const Text('5'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, _value),
                  icon: const Icon(Icons.check),
                  label: const Text('确定'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => Navigator.pop(context, 0.0),
                icon: const Icon(Icons.refresh),
                tooltip: '重置',
              )
            ],
          )
        ],
      ),
    );
  }
}
