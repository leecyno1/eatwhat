import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _youngSans = 'PingFang SC';
const _youngDisplay = 'Hiragino Sans GB';
const _youngNumbers = 'DIN Alternate';

enum YoungFoodStyleConcept {
  mealFm,
  biteLab,
  biteClub,
}

extension YoungFoodStyleConceptCopy on YoungFoodStyleConcept {
  String get shortLabel => switch (this) {
        YoungFoodStyleConcept.mealFm => 'D',
        YoungFoodStyleConcept.biteLab => 'E',
        YoungFoodStyleConcept.biteClub => 'F',
      };

  String get title => switch (this) {
        YoungFoodStyleConcept.mealFm => '饭点电台',
        YoungFoodStyleConcept.biteLab => '食运研究所',
        YoungFoodStyleConcept.biteClub => '饭搭子俱乐部',
      };

  String get tone => switch (this) {
        YoungFoodStyleConcept.mealFm => '音乐潮流 · 高频品牌感',
        YoungFoodStyleConcept.biteLab => 'AI 原生 · 可分享食运',
        YoungFoodStyleConcept.biteClub => '朋友投票 · 社交饭局',
      };

  Color get accent => switch (this) {
        YoungFoodStyleConcept.mealFm => const Color(0xFF2446D8),
        YoungFoodStyleConcept.biteLab => const Color(0xFFD8FF4F),
        YoungFoodStyleConcept.biteClub => const Color(0xFFFF5D72),
      };

  Color get background => switch (this) {
        YoungFoodStyleConcept.mealFm => const Color(0xFFF5EECF),
        YoungFoodStyleConcept.biteLab => const Color(0xFF0D100F),
        YoungFoodStyleConcept.biteClub => const Color(0xFFD8ECFF),
      };

  String get dishName => switch (this) {
        YoungFoodStyleConcept.mealFm => '热辣炸酱面',
        YoungFoodStyleConcept.biteLab => '地三鲜',
        YoungFoodStyleConcept.biteClub => '香辣鸡翅',
      };
}

class YoungFoodStyleLabPage extends StatefulWidget {
  const YoungFoodStyleLabPage({
    super.key,
    this.initialConcept = YoungFoodStyleConcept.mealFm,
  });

  final YoungFoodStyleConcept initialConcept;

  @override
  State<YoungFoodStyleLabPage> createState() => _YoungFoodStyleLabPageState();
}

class _YoungFoodStyleLabPageState extends State<YoungFoodStyleLabPage> {
  late YoungFoodStyleConcept _concept;

  @override
  void initState() {
    super.initState();
    _concept = widget.initialConcept;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _concept.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: YoungFoodHomeConceptPage(
                key: ValueKey(_concept),
                concept: _concept,
                bottomClearance: 108,
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: SafeArea(
              top: false,
              child: _YoungConceptSwitcher(
                selected: _concept,
                onSelected: (concept) {
                  if (concept == _concept) return;
                  HapticFeedback.selectionClick();
                  setState(() {
                    _concept = concept;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class YoungFoodHomeConceptPage extends StatefulWidget {
  const YoungFoodHomeConceptPage({
    required this.concept,
    this.bottomClearance = 24,
    super.key,
  });

  final YoungFoodStyleConcept concept;
  final double bottomClearance;

  @override
  State<YoungFoodHomeConceptPage> createState() =>
      _YoungFoodHomeConceptPageState();
}

class _YoungFoodHomeConceptPageState extends State<YoungFoodHomeConceptPage> {
  final Set<String> _selectedTastes = {'热辣', '有肉'};

  void _toggleTaste(String label) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedTastes.add(label)) {
        _selectedTastes.remove(label);
      }
    });
  }

  void _previewGeneration() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('收到，今天先锁定：${widget.concept.dishName}'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: widget.concept.background,
      body: switch (widget.concept) {
        YoungFoodStyleConcept.mealFm => _MealFmTemplate(
            selectedTastes: _selectedTastes,
            bottomClearance: widget.bottomClearance,
            onTasteTap: _toggleTaste,
            onGenerate: _previewGeneration,
          ),
        YoungFoodStyleConcept.biteLab => _BiteLabTemplate(
            selectedTastes: _selectedTastes,
            bottomClearance: widget.bottomClearance,
            onTasteTap: _toggleTaste,
            onGenerate: _previewGeneration,
          ),
        YoungFoodStyleConcept.biteClub => _BiteClubTemplate(
            selectedTastes: _selectedTastes,
            bottomClearance: widget.bottomClearance,
            onTasteTap: _toggleTaste,
            onGenerate: _previewGeneration,
          ),
      },
    );
  }
}

class _YoungConceptSwitcher extends StatelessWidget {
  const _YoungConceptSwitcher({
    required this.selected,
    required this.onSelected,
  });

  final YoungFoodStyleConcept selected;
  final ValueChanged<YoungFoodStyleConcept> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7EF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x24111111)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35110D09),
            blurRadius: 24,
            offset: Offset(0, 11),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            for (final concept in YoungFoodStyleConcept.values)
              Expanded(
                child: _YoungConceptSwitcherItem(
                  concept: concept,
                  isSelected: selected == concept,
                  onTap: () => onSelected(concept),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _YoungConceptSwitcherItem extends StatelessWidget {
  const _YoungConceptSwitcherItem({
    required this.concept,
    required this.isSelected,
    required this.onTap,
  });

  final YoungFoodStyleConcept concept;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = concept == YoungFoodStyleConcept.biteLab
        ? const Color(0xFF101210)
        : Colors.white;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${concept.shortLabel} ${concept.title}',
      child: InkWell(
        key: ValueKey('young-style-concept-${concept.name}'),
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? concept.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${concept.shortLabel} · ${concept.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? foreground : const Color(0xFF25231F),
                  fontFamily: _youngSans,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                concept.tone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? foreground.withValues(alpha: 0.7)
                      : const Color(0xFF8D8981),
                  fontFamily: _youngSans,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealFmTemplate extends StatelessWidget {
  const _MealFmTemplate({
    required this.selectedTastes,
    required this.bottomClearance,
    required this.onTasteTap,
    required this.onGenerate,
  });

  final Set<String> selectedTastes;
  final double bottomClearance;
  final ValueChanged<String> onTasteTap;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFF5EECF);
    const ink = Color(0xFF17191F);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: cream,
        child: Stack(
          children: [
            const Positioned.fill(child: _FmBackground()),
            SafeArea(
              child: SingleChildScrollView(
                key: const ValueKey('meal-fm-template'),
                padding: EdgeInsets.fromLTRB(18, 10, 18, bottomClearance),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FmHeader(),
                    const SizedBox(height: 20),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            '调到你\n想吃的频率',
                            style: TextStyle(
                              color: ink,
                              fontFamily: _youngDisplay,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.02,
                              letterSpacing: -1.6,
                            ),
                          ),
                        ),
                        _FmFrequencyBadge(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _FmTunerPanel(selectedCount: selectedTastes.length),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final taste in const [
                          '热辣',
                          '有肉',
                          '浓香',
                          '碳水',
                          '夜宵',
                        ])
                          _FmTasteChip(
                            label: taste,
                            isSelected: selectedTastes.contains(taste),
                            onTap: () => onTasteTap(taste),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _FmNowPlayingCard(),
                    const SizedBox(height: 14),
                    _FmActionBar(onGenerate: onGenerate),
                    const SizedBox(height: 13),
                    const _FmNavRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FmBackground extends StatelessWidget {
  const _FmBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _FmBackgroundPainter());
  }
}

class _FmBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF2446D8).withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var y = 128.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 70), linePaint);
    }

    final redPaint = Paint()
      ..color = const Color(0xFFFF5038).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22;
    canvas.drawCircle(Offset(size.width + 18, 132), 72, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FmHeader extends StatelessWidget {
  const _FmHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFF2446D8),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '饭点电台',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF17191F),
                  fontFamily: _youngDisplay,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'MEAL FM · TUNE IN',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF6D6D73),
                  fontFamily: _youngNumbers,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5038),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 6, height: 6),
              ),
              SizedBox(width: 5),
              Text(
                'LIVE 19:20',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: _youngNumbers,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FmFrequencyBadge extends StatelessWidget {
  const _FmFrequencyBadge();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.06,
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 8, 11, 7),
        decoration: BoxDecoration(
          color: const Color(0xFF2446D8),
          border: Border.all(color: const Color(0xFF17191F), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0xFF17191F), offset: Offset(3, 3)),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FM',
              style: TextStyle(
                color: Color(0xFFAFC0FF),
                fontFamily: _youngNumbers,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '88.6',
              style: TextStyle(
                color: Colors.white,
                fontFamily: _youngNumbers,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 0.95,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FmTunerPanel extends StatelessWidget {
  const _FmTunerPanel({required this.selectedCount});

  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9E8),
        border: Border.all(color: const Color(0xFF17191F), width: 1.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'TASTE TUNER',
                style: TextStyle(
                  color: Color(0xFF17191F),
                  fontFamily: _youngNumbers,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Text(
                '$selectedCount 个信号已接收',
                style: const TextStyle(
                  color: Color(0xFF2446D8),
                  fontFamily: _youngSans,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Row(
            children: [
              Expanded(
                child: _FmSignal(
                    label: '热度', value: 0.88, color: Color(0xFFFF5038)),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _FmSignal(
                    label: '满足', value: 0.76, color: Color(0xFF2446D8)),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _FmSignal(
                    label: '新鲜', value: 0.42, color: Color(0xFFFFC93D)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FmSignal extends StatelessWidget {
  const _FmSignal({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5F6067),
                fontFamily: _youngSans,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}',
              style: const TextStyle(
                color: Color(0xFF17191F),
                fontFamily: _youngNumbers,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            color: color,
            backgroundColor: const Color(0xFFE4DEC6),
          ),
        ),
      ],
    );
  }
}

class _FmTasteChip extends StatelessWidget {
  const _FmTasteChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFF2446D8) : const Color(0xFFFDF9E8),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        key: ValueKey('fm-taste-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF17191F), width: 1.2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.graphic_eq_rounded,
                    size: 12, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF17191F),
                  fontFamily: _youngSans,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FmNowPlayingCard extends StatelessWidget {
  const _FmNowPlayingCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            right: 0,
            top: 8,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2446D8),
                border: Border.all(color: const Color(0xFF17191F), width: 1.4),
                borderRadius: BorderRadius.circular(23),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 8,
            top: 0,
            bottom: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/prebuilt_dishes/dish-32-dish_768.jpg',
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xCC111218)],
                        stops: [0.42, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5038),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: _youngNumbers,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '热辣炸酱面',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: _youngDisplay,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                '浓香 · 碳水满足 · 18 分钟',
                                style: TextStyle(
                                  color: Color(0xFFE4E7FF),
                                  fontFamily: _youngSans,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _FmPlayButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FmPlayButton extends StatelessWidget {
  const _FmPlayButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFFFF5038),
        shape: BoxShape.circle,
      ),
      child:
          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 25),
    );
  }
}

class _FmActionBar extends StatelessWidget {
  const _FmActionBar({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 51,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF9E8),
              border: Border.all(color: const Color(0xFF17191F), width: 1.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.mic_none_rounded,
                    size: 18, color: Color(0xFF2446D8)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '说一句：想吃热的',
                    style: TextStyle(
                      color: Color(0xFF6B6C72),
                      fontFamily: _youngSans,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 9),
        SizedBox(
          height: 51,
          child: FilledButton(
            key: const ValueKey('meal-fm-generate'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF5038),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF17191F), width: 1.3),
              ),
              elevation: 0,
            ),
            onPressed: onGenerate,
            child: const Text(
              '就吃这首',
              style: TextStyle(
                fontFamily: _youngSans,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FmNavRow extends StatelessWidget {
  const _FmNavRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _FmNavItem(icon: Icons.radio_rounded, label: '直播', active: true),
        _FmNavItem(icon: Icons.queue_music_rounded, label: '口味歌单'),
        _FmNavItem(icon: Icons.favorite_border_rounded, label: '收藏'),
        _FmNavItem(icon: Icons.person_outline_rounded, label: '我的'),
      ],
    );
  }
}

class _FmNavItem extends StatelessWidget {
  const _FmNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF2446D8) : const Color(0xFF77766F);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontFamily: _youngSans,
            fontSize: 8.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BiteLabTemplate extends StatelessWidget {
  const _BiteLabTemplate({
    required this.selectedTastes,
    required this.bottomClearance,
    required this.onTasteTap,
    required this.onGenerate,
  });

  final Set<String> selectedTastes;
  final double bottomClearance;
  final ValueChanged<String> onTasteTap;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    const black = Color(0xFF0D100F);
    const lime = Color(0xFFD8FF4F);
    const white = Color(0xFFF2F2EA);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: black,
        child: Stack(
          children: [
            const Positioned.fill(child: _LabGridBackground()),
            SafeArea(
              child: SingleChildScrollView(
                key: const ValueKey('bite-lab-template'),
                padding: EdgeInsets.fromLTRB(16, 10, 16, bottomClearance),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LabHeader(),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '今日食运\n检测完成',
                                style: TextStyle(
                                  color: white,
                                  fontFamily: _youngDisplay,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  height: 1.02,
                                  letterSpacing: -1.1,
                                ),
                              ),
                              SizedBox(height: 7),
                              Text(
                                '你的胃口信号很明确：\n想吃热的、浓的、能下饭的。',
                                style: TextStyle(
                                  color: Color(0xFF969E99),
                                  fontFamily: _youngSans,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: lime,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '87',
                                style: TextStyle(
                                  color: black,
                                  fontFamily: _youngNumbers,
                                  fontSize: 43,
                                  fontWeight: FontWeight.w900,
                                  height: 0.85,
                                ),
                              ),
                              SizedBox(height: 7),
                              Text(
                                'LUCK INDEX',
                                style: TextStyle(
                                  color: Color(0xFF4E5B1B),
                                  fontFamily: _youngNumbers,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _LabSignalPanel(
                      selectedTastes: selectedTastes,
                      onTasteTap: onTasteTap,
                    ),
                    const SizedBox(height: 14),
                    const _LabScanCard(),
                    const SizedBox(height: 13),
                    _LabPromptBar(onGenerate: onGenerate),
                    const SizedBox(height: 13),
                    const _LabNavRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabGridBackground extends StatelessWidget {
  const _LabGridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LabGridPainter());
  }
}

class _LabGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7C8C83).withValues(alpha: 0.1)
      ..strokeWidth = 0.7;
    const gap = 26.0;
    for (var x = 0.0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LabHeader extends StatelessWidget {
  const _LabHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: const Color(0xFFD8FF4F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.science_rounded,
            color: Color(0xFF0D100F),
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '食运研究所',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFF2F2EA),
                  fontFamily: _youngDisplay,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'BITE LAB / SESSION 0711',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF727B76),
                  fontFamily: _youngNumbers,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF46504A)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'AI ONLINE',
            style: TextStyle(
              color: Color(0xFFD8FF4F),
              fontFamily: _youngNumbers,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _LabSignalPanel extends StatelessWidget {
  const _LabSignalPanel({
    required this.selectedTastes,
    required this.onTasteTap,
  });

  final Set<String> selectedTastes;
  final ValueChanged<String> onTasteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171B19),
        border: Border.all(color: const Color(0xFF3D4641)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sensors_rounded, color: Color(0xFFD8FF4F), size: 15),
              SizedBox(width: 6),
              Text(
                'INPUT SIGNALS',
                style: TextStyle(
                  color: Color(0xFFF2F2EA),
                  fontFamily: _youngNumbers,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final taste in const ['热辣', '有肉', '锅气', '软糯', '下饭', '少等'])
                _LabTasteChip(
                  label: taste,
                  isSelected: selectedTastes.contains(taste),
                  onTap: () => onTasteTap(taste),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabTasteChip extends StatelessWidget {
  const _LabTasteChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFD8FF4F) : const Color(0xFF222824),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        key: ValueKey('lab-taste-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFD8FF4F)
                  : const Color(0xFF4B5650),
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF0D100F)
                  : const Color(0xFFCCD2CE),
              fontFamily: _youngSans,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _LabScanCard extends StatelessWidget {
  const _LabScanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2EA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 224,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/prebuilt_dishes/dish-23-dish_768.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                const Positioned.fill(child: _ScanCornerOverlay()),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    color: const Color(0xFFD8FF4F),
                    child: const Text(
                      'SCAN COMPLETE',
                      style: TextStyle(
                        color: Color(0xFF0D100F),
                        fontFamily: _youngNumbers,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 9,
                  bottom: 9,
                  child: Container(
                    width: 57,
                    height: 57,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF673D),
                      shape: BoxShape.circle,
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '94%',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: _youngNumbers,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'MATCH',
                          style: TextStyle(
                            color: Color(0xFFFFD8CB),
                            fontFamily: _youngNumbers,
                            fontSize: 6,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 10, 4, 5),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '地三鲜',
                        style: TextStyle(
                          color: Color(0xFF0D100F),
                          fontFamily: _youngDisplay,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '茄子 + 土豆 + 青椒｜浓香下饭｜22 分钟',
                        style: TextStyle(
                          color: Color(0xFF5F6863),
                          fontFamily: _youngSans,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_outward_rounded,
                    color: Color(0xFF0D100F), size: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanCornerOverlay extends StatelessWidget {
  const _ScanCornerOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScanCornerPainter());
  }
}

class _ScanCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8FF4F)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    const length = 18.0;
    const inset = 8.0;

    canvas
      ..drawPath(
        Path()
          ..moveTo(inset, inset + length)
          ..lineTo(inset, inset)
          ..lineTo(inset + length, inset),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(size.width - inset - length, inset)
          ..lineTo(size.width - inset, inset)
          ..lineTo(size.width - inset, inset + length),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(inset, size.height - inset - length)
          ..lineTo(inset, size.height - inset)
          ..lineTo(inset + length, size.height - inset),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(size.width - inset - length, size.height - inset)
          ..lineTo(size.width - inset, size.height - inset)
          ..lineTo(size.width - inset, size.height - inset - length),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LabPromptBar extends StatelessWidget {
  const _LabPromptBar({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF171B19),
        border: Border.all(color: const Color(0xFF3D4641)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                children: [
                  Text(
                    '›_',
                    style: TextStyle(
                      color: Color(0xFFD8FF4F),
                      fontFamily: _youngNumbers,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '再加一句限制条件',
                      style: TextStyle(
                        color: Color(0xFF8A938E),
                        fontFamily: _youngSans,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 45,
            child: FilledButton(
              key: const ValueKey('bite-lab-generate'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD8FF4F),
                foregroundColor: const Color(0xFF0D100F),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: onGenerate,
              child: const Text(
                '生成食运',
                style: TextStyle(
                  fontFamily: _youngSans,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabNavRow extends StatelessWidget {
  const _LabNavRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _LabNavItem(code: '00', label: '检测', active: true)),
        Expanded(child: _LabNavItem(code: '01', label: '菜库')),
        Expanded(child: _LabNavItem(code: '02', label: '报告')),
        Expanded(child: _LabNavItem(code: '03', label: '账户')),
      ],
    );
  }
}

class _LabNavItem extends StatelessWidget {
  const _LabNavItem({
    required this.code,
    required this.label,
    this.active = false,
  });

  final String code;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFD8FF4F) : const Color(0xFF667069);
    return Column(
      children: [
        Text(
          code,
          style: TextStyle(
            color: color,
            fontFamily: _youngNumbers,
            fontSize: 7,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFF2F2EA) : color,
            fontFamily: _youngSans,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BiteClubTemplate extends StatelessWidget {
  const _BiteClubTemplate({
    required this.selectedTastes,
    required this.bottomClearance,
    required this.onTasteTap,
    required this.onGenerate,
  });

  final Set<String> selectedTastes;
  final double bottomClearance;
  final ValueChanged<String> onTasteTap;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    const sky = Color(0xFFD8ECFF);
    const navy = Color(0xFF172651);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: sky,
        child: Stack(
          children: [
            const Positioned.fill(child: _ClubBackground()),
            SafeArea(
              child: SingleChildScrollView(
                key: const ValueKey('bite-club-template'),
                padding: EdgeInsets.fromLTRB(17, 10, 17, bottomClearance),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ClubHeader(),
                    const SizedBox(height: 19),
                    const Text(
                      '今天这顿，\n大家一起拍板。',
                      style: TextStyle(
                        color: navy,
                        fontFamily: _youngDisplay,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.03,
                        letterSpacing: -1.3,
                      ),
                    ),
                    const SizedBox(height: 9),
                    const _ClubOnlineRow(),
                    const SizedBox(height: 15),
                    _ClubTasteStickers(
                      selectedTastes: selectedTastes,
                      onTasteTap: onTasteTap,
                    ),
                    const SizedBox(height: 15),
                    const _ClubPollCard(),
                    const SizedBox(height: 14),
                    _ClubActionBar(onGenerate: onGenerate),
                    const SizedBox(height: 13),
                    const _ClubNavRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubBackground extends StatelessWidget {
  const _ClubBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ClubBackgroundPainter());
  }
}

class _ClubBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final yellow = Paint()
      ..color = const Color(0xFFFFD84B).withValues(alpha: 0.52);
    final coral = Paint()
      ..color = const Color(0xFFFF5D72).withValues(alpha: 0.2);
    canvas
      ..drawCircle(Offset(size.width + 10, 138), 86, yellow)
      ..drawOval(
        Rect.fromCenter(
          center: Offset(-24, size.height * 0.58),
          width: 180,
          height: 125,
        ),
        coral,
      );

    final doodle = Paint()
      ..color = const Color(0xFF172651).withValues(alpha: 0.08)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var x = 0.0; x <= size.width; x += 8) {
      final y = 260 + math.sin(x / 22) * 6;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, doodle);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClubHeader extends StatelessWidget {
  const _ClubHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Transform.rotate(
          angle: -0.04,
          child: Container(
            padding: const EdgeInsets.fromLTRB(11, 7, 11, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5D72),
              border: Border.all(color: const Color(0xFF172651), width: 1.6),
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(color: Color(0xFF172651), offset: Offset(3, 3)),
              ],
            ),
            child: const Text(
              '饭搭子 CLUB',
              style: TextStyle(
                color: Colors.white,
                fontFamily: _youngDisplay,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF9CB9D2)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 14, color: Color(0xFF172651)),
              SizedBox(width: 3),
              Text(
                '邀请饭搭子',
                style: TextStyle(
                  color: Color(0xFF172651),
                  fontFamily: _youngSans,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClubOnlineRow extends StatelessWidget {
  const _ClubOnlineRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _ClubAvatarStack(),
        const SizedBox(width: 9),
        const Expanded(
          child: Text(
            '小鱼、阿豪和你正在选今晚吃什么',
            style: TextStyle(
              color: Color(0xFF4D6286),
              fontFamily: _youngSans,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD84B),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF172651)),
          ),
          child: const Text(
            '3 人在线',
            style: TextStyle(
              color: Color(0xFF172651),
              fontFamily: _youngSans,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClubAvatarStack extends StatelessWidget {
  const _ClubAvatarStack();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 72,
      height: 31,
      child: Stack(
        children: [
          _ClubAvatar(left: 0, color: Color(0xFFFFD84B), label: '鱼'),
          _ClubAvatar(left: 22, color: Color(0xFFFF8DA0), label: '豪'),
          _ClubAvatar(left: 44, color: Color(0xFF6EA8FF), label: '你'),
        ],
      ),
    );
  }
}

class _ClubAvatar extends StatelessWidget {
  const _ClubAvatar({
    required this.left,
    required this.color,
    required this.label,
  });

  final double left;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      child: Container(
        width: 31,
        height: 31,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF172651), width: 1.5),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF172651),
            fontFamily: _youngSans,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ClubTasteStickers extends StatelessWidget {
  const _ClubTasteStickers({
    required this.selectedTastes,
    required this.onTasteTap,
  });

  final Set<String> selectedTastes;
  final ValueChanged<String> onTasteTap;

  @override
  Widget build(BuildContext context) {
    const tastes = ['热辣', '有肉', '能分享', '30 元内', '别太远'];
    return Wrap(
      spacing: 7,
      runSpacing: 8,
      children: [
        for (var index = 0; index < tastes.length; index++)
          Transform.rotate(
            angle: index.isEven ? -0.025 : 0.025,
            child: _ClubTasteChip(
              label: tastes[index],
              isSelected: selectedTastes.contains(tastes[index]),
              onTap: () => onTasteTap(tastes[index]),
            ),
          ),
      ],
    );
  }
}

class _ClubTasteChip extends StatelessWidget {
  const _ClubTasteChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('club-taste-$label'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5D72) : const Color(0xFFFFF7D7),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFF172651), width: 1.3),
          boxShadow: const [
            BoxShadow(color: Color(0xFF172651), offset: Offset(2, 2)),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF172651),
            fontFamily: _youngSans,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ClubPollCard extends StatelessWidget {
  const _ClubPollCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF172651), width: 1.6),
        boxShadow: const [
          BoxShadow(color: Color(0xFF172651), offset: Offset(5, 5)),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 224,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Image.asset(
                    'assets/images/prebuilt_dishes/dish-205-howtocook-real_768.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(17)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xA6172651)],
                      stops: [0.55, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 11,
                  top: 11,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD84B),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF172651)),
                    ),
                    child: const Text(
                      '当前领先 · 4 票',
                      style: TextStyle(
                        color: Color(0xFF172651),
                        fontFamily: _youngSans,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 13,
                  right: 13,
                  bottom: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '香辣鸡翅',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: _youngDisplay,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '人均 ¥26 · 28 分钟 · 适合一起分',
                              style: TextStyle(
                                color: Color(0xFFE4EEFF),
                                fontFamily: _youngSans,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ClubVoteButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 10, 4, 4),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_rounded,
                    size: 15, color: Color(0xFFFF5D72)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '阿豪：这个可以！小鱼：我要微辣',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF566789),
                      fontFamily: _youngSans,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
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

class _ClubVoteButton extends StatelessWidget {
  const _ClubVoteButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFFF5D72),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child:
          const Icon(Icons.thumb_up_alt_rounded, color: Colors.white, size: 19),
    );
  }
}

class _ClubActionBar extends StatelessWidget {
  const _ClubActionBar({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF172651),
                backgroundColor: Colors.white.withValues(alpha: 0.62),
                side: const BorderSide(color: Color(0xFF172651), width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Icons.ios_share_rounded, size: 17),
              label: const Text(
                '发群里投票',
                style: TextStyle(
                  fontFamily: _youngSans,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: SizedBox(
            height: 50,
            child: FilledButton(
              key: const ValueKey('bite-club-generate'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF172651),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              onPressed: onGenerate,
              child: const Text(
                'AI 帮我们定',
                style: TextStyle(
                  fontFamily: _youngSans,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClubNavRow extends StatelessWidget {
  const _ClubNavRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ClubNavItem(icon: Icons.people_alt_rounded, label: '饭局', active: true),
        _ClubNavItem(icon: Icons.explore_outlined, label: '发现'),
        _ClubNavItem(icon: Icons.bookmark_border_rounded, label: '收藏'),
        _ClubNavItem(icon: Icons.person_outline_rounded, label: '我的'),
      ],
    );
  }
}

class _ClubNavItem extends StatelessWidget {
  const _ClubNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFFF5D72) : const Color(0xFF7385A1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontFamily: _youngSans,
            fontSize: 8.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
