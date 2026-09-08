import 'package:eatwhat_app/v2/core/data/repositories/tag_repository_v2.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/decision/decision_page.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'bubble_ocean.dart';
import 'preference_gesture_hint.dart';
import 'requirement_input_panel.dart';

enum PreferenceWorkbenchMode {
  bubbles,
  prompt,
}

class PreferenceWorkbench extends StatefulWidget {
  const PreferenceWorkbench({
    super.key,
    required this.height,
  });

  final double height;

  @override
  State<PreferenceWorkbench> createState() => _PreferenceWorkbenchState();
}

class _PreferenceWorkbenchState extends State<PreferenceWorkbench> {
  final TextEditingController _controller = TextEditingController();
  final TagRepositoryV2 _tagRepository = TagRepositoryV2();
  PreferenceWorkbenchMode _mode = PreferenceWorkbenchMode.bubbles;
  List<_ResolvedPreference> _resolved = const [];

  static const List<String> _quickSuggestions = [
    '20 分钟内',
    '一个人吃',
    '不要太辣',
    '想喝热汤',
    '健身晚餐',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setMode(PreferenceWorkbenchMode mode) {
    setState(() {
      _mode = mode;
    });
  }

  void _handlePromptChanged(String value) {
    setState(() {
      _resolved = _extractPreferences(value);
    });
  }

  void _appendSuggestion(String value) {
    final current = _controller.text.trim();
    final next = current.isEmpty ? value : '$current，$value';
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _handlePromptChanged(next);
  }

  List<_ResolvedPreference> _extractPreferences(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const [];

    final allTags = _tagRepository.getAllTags();
    final matched = <_ResolvedPreference>[];
    final usedIds = <String>{};

    for (final tag in allTags) {
      if (text.contains(tag.label) && usedIds.add(tag.id)) {
        matched.add(
          _ResolvedPreference(
            id: tag.id,
            label: tag.label,
          ),
        );
      }
    }

    if (matched.isNotEmpty) {
      return matched.take(8).toList();
    }

    final fragments = text
        .split(RegExp(r'[，,。.!！？?、/\s]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .where((e) => e.length <= 12)
        .toList();

    return fragments
        .take(6)
        .map(
          (e) => _ResolvedPreference(
            id: 'freeform:$e',
            label: e,
          ),
        )
        .toList();
  }

  void _submitPromptMode() {
    final requirement = _controller.text.trim();
    if (requirement.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先输入今天的要求，再去决定口味')),
      );
      return;
    }

    final resolved =
        _resolved.isEmpty ? _extractPreferences(requirement) : _resolved;
    final labels = resolved.map((e) => e.label).toList();
    final ids = resolved
        .where((e) => !e.id.startsWith('freeform:'))
        .map((e) => e.id)
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DecisionPage(
          selectedTagLabels: labels.isEmpty ? [requirement] : labels,
          selectedTagIds: ids,
          customRequirement: requirement,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xE617141B),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4011141B),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '今日偏好工作台',
                  style: TextStyle(
                    color: AppPalette.moonlight,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'mode switch',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '今天想通过哪种方式缩小选择范围？',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeChip(
                    label: '气泡选味',
                    isActive: _mode == PreferenceWorkbenchMode.bubbles,
                    onTap: () => _setMode(PreferenceWorkbenchMode.bubbles),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeChip(
                    label: '文字要求',
                    isActive: _mode == PreferenceWorkbenchMode.prompt,
                    onTap: () => _setMode(PreferenceWorkbenchMode.prompt),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _mode == PreferenceWorkbenchMode.bubbles
                  ? const _BubbleModeBody(key: ValueKey('bubble-mode'))
                  : RequirementInputPanel(
                      key: const ValueKey('prompt-mode'),
                      controller: _controller,
                      onChanged: _handlePromptChanged,
                      onSubmit: _submitPromptMode,
                      quickSuggestions: _quickSuggestions,
                      resolvedLabels: _resolved.map((e) => e.label).toList(),
                      onSuggestionTap: _appendSuggestion,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleModeBody extends StatelessWidget {
  const _BubbleModeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PreferenceGestureHint(),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xE6FFF8EF),
                  Color(0xD1FFFFFF),
                  Color(0xE6FFE4D4),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.72),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x33111827).withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC121018),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'BUBBLE TASTE DECK',
                      style: TextStyle(
                        color: AppPalette.moonlight,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 16,
                  child: Text(
                    '上滑留下，下滑略过',
                    style: TextStyle(
                      color: const Color(0xFF1D1D1F).withValues(alpha: 0.54),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 40, 10, 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x26FFFFFF),
                                  Color(0x0DF65A32),
                                ],
                              ),
                            ),
                          ),
                          const BubbleOcean(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.sunsetOrange
                : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: AppPalette.moonlight,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResolvedPreference {
  const _ResolvedPreference({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}
