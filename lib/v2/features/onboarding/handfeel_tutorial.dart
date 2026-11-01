import 'dart:async';

import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/onboarding/tutorial_gesture_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 唯一首启教学层：只教真实存在的三种手感动作。
class HandfeelTutorial extends StatefulWidget {
  const HandfeelTutorial({
    super.key,
    required this.onFinished,
  });

  final Future<void> Function() onFinished;

  @override
  State<HandfeelTutorial> createState() => _HandfeelTutorialState();
}

class _HandfeelTutorialState extends State<HandfeelTutorial>
    with TickerProviderStateMixin {
  static const _steps = <_TutorialStepData>[
    _TutorialStepData(
      gesture: TutorialGesture.tap,
      title: '轻点\n收下这一口',
      description: '喜欢的气泡，点一下就会进锅。',
    ),
    _TutorialStepData(
      gesture: TutorialGesture.drag,
      title: '按住，拖一拖\n上收下，下拉黑',
      description: '拖到顶部收下；拖到底部，就暂时不选它。',
    ),
    _TutorialStepData(
      gesture: TutorialGesture.shake,
      title: '摇一摇\n让锅翻个身',
      description: '堆叠的食材会重新散开，再看看有没有新灵感。',
    ),
  ];

  late final AnimationController _entryController;
  late final AnimationController _exitController;
  int _index = 0;
  bool _started = false;
  bool _finishing = false;

  _TutorialStepData get _step => _steps[_index];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _entryController.duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 520);
    _exitController.duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 360);
    if (reduceMotion) {
      _entryController.value = 1;
    } else {
      _entryController.forward();
    }
    unawaited(HapticFeedback.selectionClick());
  }

  @override
  void dispose() {
    _entryController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _advance() {
    if (_finishing) return;
    if (_index == _steps.length - 1) {
      unawaited(_finish(lightHaptic: true));
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    setState(() => _index += 1);
  }

  Future<void> _finish({bool lightHaptic = false}) async {
    if (_finishing) return;
    _finishing = true;
    if (lightHaptic) {
      unawaited(HapticFeedback.lightImpact());
    }
    if (_exitController.duration != Duration.zero) {
      await _exitController.forward();
    }
    await widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Material(
      key: const ValueKey('handfeel-tutorial'),
      type: MaterialType.transparency,
      // 整层吸收触摸，避免点穿到真实气泡舞台；舞台与说明卡自身可点推进。
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: () {},
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _entryController,
            _exitController,
          ]),
          builder: (context, child) {
            final entry = _entryController.value;
            final exit = _exitController.value;
            return Opacity(
              opacity: (entry * (1 - exit)).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - entry)),
                child: child,
              ),
            );
          },
          child: Stack(
            children: [
              const Positioned.fill(child: _TutorialScrim()),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stageHeight =
                        (constraints.maxHeight * 0.38).clamp(190.0, 310.0);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 32,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildHeader(),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              excludeFromSemantics: true,
                              onTap: _advance,
                              child: SizedBox(
                                height: stageHeight,
                                child: Semantics(
                                  label:
                                      '当前教学：${_step.title.replaceAll('\n', '')}',
                                  child: AnimatedSwitcher(
                                    duration: reduceMotion
                                        ? Duration.zero
                                        : const Duration(milliseconds: 280),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    child: TutorialGestureStage(
                                      key: ValueKey(_step.gesture),
                                      gesture: _step.gesture,
                                      animationsEnabled: !reduceMotion,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              excludeFromSemantics: true,
                              onTap: _advance,
                              child: _buildInstruction(reduceMotion),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: GoldPalette.goldHairline),
          ),
          child: const Icon(
            Icons.dinner_dining_rounded,
            size: 16,
            color: GoldPalette.goldSoft,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            '开席之前 · 三式就够',
            style: TextStyle(
              color: GoldPalette.gold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextButton(
          key: const ValueKey('handfeel-tutorial-skip'),
          style: TextButton.styleFrom(
            minimumSize: const Size(64, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          onPressed: _finishing ? null : () => unawaited(_finish()),
          child: const Text(
            '跳过',
            style: TextStyle(
              color: GoldPalette.creamMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstruction(bool reduceMotion) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: AppDecorations.nightCard(
        color: GoldPalette.panel,
        borderColor: GoldPalette.goldHairline,
        radius: AppRadii.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 280),
            child: Column(
              key: ValueKey(_index),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _step.title,
                  style: const TextStyle(
                    color: GoldPalette.creamText,
                    fontFamily: 'serif',
                    fontSize: 27,
                    height: 1.18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _step.description,
                  style: const TextStyle(
                    color: GoldPalette.creamMuted,
                    fontSize: 13,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var index = 0; index < _steps.length; index++)
                AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  width: index == _index ? 28 : 8,
                  height: 3,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: index == _index
                        ? GoldPalette.gold
                        : GoldPalette.goldHairline,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const Spacer(),
              Text(
                '${_index + 1} / ${_steps.length}',
                style: const TextStyle(
                  color: GoldPalette.creamMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const ValueKey('handfeel-tutorial-next'),
              onPressed: _finishing ? null : _advance,
              style: FilledButton.styleFrom(
                backgroundColor: GoldPalette.gold,
                foregroundColor: GoldPalette.nightDeep,
                shape: const StadiumBorder(),
              ),
              child: Text(
                _index == _steps.length - 1 ? '开始挑第一口' : '下一步',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialScrim extends StatelessWidget {
  const _TutorialScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GoldPalette.nightDeep.withValues(alpha: 0.90),
            GoldPalette.nightDeep.withValues(alpha: 0.76),
            GoldPalette.nightDeep.withValues(alpha: 0.95),
          ],
          stops: const [0, 0.48, 1],
        ),
      ),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 0.8,
            colors: [Color(0x1634D277), Color(0x00000000)],
          ),
        ),
      ),
    );
  }
}

class _TutorialStepData {
  const _TutorialStepData({
    required this.gesture,
    required this.title,
    required this.description,
  });

  final TutorialGesture gesture;
  final String title;
  final String description;
}
