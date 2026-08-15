import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _foodSans = 'PingFang SC';
const _foodSerif = 'Songti SC';

enum FoodStyleConcept {
  warmEditorial,
  streetCanteen,
  seasonalFresh,
}

extension FoodStyleConceptCopy on FoodStyleConcept {
  String get shortLabel => switch (this) {
        FoodStyleConcept.warmEditorial => 'A',
        FoodStyleConcept.streetCanteen => 'B',
        FoodStyleConcept.seasonalFresh => 'C',
      };

  String get title => switch (this) {
        FoodStyleConcept.warmEditorial => '暖食编辑部',
        FoodStyleConcept.streetCanteen => '街巷食堂',
        FoodStyleConcept.seasonalFresh => '清鲜本味',
      };

  String get tone => switch (this) {
        FoodStyleConcept.warmEditorial => '温暖、克制、有食欲',
        FoodStyleConcept.streetCanteen => '直接、有烟火气、记忆鲜明',
        FoodStyleConcept.seasonalFresh => '轻盈、自然、重视食材',
      };

  Color get accent => switch (this) {
        FoodStyleConcept.warmEditorial => const Color(0xFFC94B2C),
        FoodStyleConcept.streetCanteen => const Color(0xFFF04B2F),
        FoodStyleConcept.seasonalFresh => const Color(0xFF48644A),
      };
}

/// 非侵入式视觉实验室。三套模板使用相同的信息结构，只改变视觉语言。
class FoodStyleLabPage extends StatefulWidget {
  const FoodStyleLabPage({
    super.key,
    this.initialConcept = FoodStyleConcept.warmEditorial,
  });

  final FoodStyleConcept initialConcept;

  @override
  State<FoodStyleLabPage> createState() => _FoodStyleLabPageState();
}

class _FoodStyleLabPageState extends State<FoodStyleLabPage> {
  late FoodStyleConcept _concept;

  @override
  void initState() {
    super.initState();
    _concept = widget.initialConcept;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: FoodHomeConceptPage(
                key: ValueKey(_concept),
                concept: _concept,
                bottomClearance: 104,
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: SafeArea(
              top: false,
              child: _ConceptSwitcher(
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

/// 可独立渲染的模板页面，供截图、评审与后续首页重构复用。
class FoodHomeConceptPage extends StatefulWidget {
  const FoodHomeConceptPage({
    required this.concept,
    this.bottomClearance = 24,
    super.key,
  });

  final FoodStyleConcept concept;
  final double bottomClearance;

  @override
  State<FoodHomeConceptPage> createState() => _FoodHomeConceptPageState();
}

class _FoodHomeConceptPageState extends State<FoodHomeConceptPage> {
  final Set<String> _selectedTastes = {'热辣', '下饭'};

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
    final dishName = switch (widget.concept) {
      FoodStyleConcept.warmEditorial => '麻婆豆腐',
      FoodStyleConcept.streetCanteen => '糖醋排骨',
      FoodStyleConcept.seasonalFresh => '原味牛油果沙拉',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('口味已收好，先为你推荐：$dishName'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: switch (widget.concept) {
        FoodStyleConcept.warmEditorial => const Color(0xFFF5EFE4),
        FoodStyleConcept.streetCanteen => const Color(0xFF171614),
        FoodStyleConcept.seasonalFresh => const Color(0xFFF1F4E9),
      },
      body: switch (widget.concept) {
        FoodStyleConcept.warmEditorial => _WarmEditorialTemplate(
            selectedTastes: _selectedTastes,
            bottomClearance: widget.bottomClearance,
            onTasteTap: _toggleTaste,
            onGenerate: _previewGeneration,
          ),
        FoodStyleConcept.streetCanteen => _StreetCanteenTemplate(
            selectedTastes: _selectedTastes,
            bottomClearance: widget.bottomClearance,
            onTasteTap: _toggleTaste,
            onGenerate: _previewGeneration,
          ),
        FoodStyleConcept.seasonalFresh => _SeasonalFreshTemplate(
            selectedTastes: _selectedTastes,
            bottomClearance: widget.bottomClearance,
            onTasteTap: _toggleTaste,
            onGenerate: _previewGeneration,
          ),
      },
    );
  }
}

class _ConceptSwitcher extends StatelessWidget {
  const _ConceptSwitcher({
    required this.selected,
    required this.onSelected,
  });

  final FoodStyleConcept selected;
  final ValueChanged<FoodStyleConcept> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1F1A1714)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29160F0A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            for (final concept in FoodStyleConcept.values)
              Expanded(
                child: _ConceptSwitcherItem(
                  concept: concept,
                  isSelected: concept == selected,
                  onTap: () => onSelected(concept),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConceptSwitcherItem extends StatelessWidget {
  const _ConceptSwitcherItem({
    required this.concept,
    required this.isSelected,
    required this.onTap,
  });

  final FoodStyleConcept concept;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${concept.shortLabel} ${concept.title}',
      child: InkWell(
        key: ValueKey('style-concept-${concept.name}'),
        borderRadius: BorderRadius.circular(19),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? concept.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${concept.shortLabel} · ${concept.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF29231F),
                  fontFamily: _foodSans,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                concept.tone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.74)
                      : const Color(0xFF8A817A),
                  fontFamily: _foodSans,
                  fontSize: 8,
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

class _WarmEditorialTemplate extends StatelessWidget {
  const _WarmEditorialTemplate({
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
    const background = Color(0xFFF5EFE4);
    const ink = Color(0xFF241A16);
    const accent = Color(0xFFC94B2C);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: background,
        child: Stack(
          children: [
            const Positioned(
              right: -54,
              top: 68,
              child: _EditorialSunMark(),
            ),
            SafeArea(
              child: SingleChildScrollView(
                key: const ValueKey('warm-editorial-template'),
                padding: EdgeInsets.fromLTRB(20, 12, 20, bottomClearance),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _EditorialHeader(),
                    const SizedBox(height: 24),
                    const Text(
                      '今晚，\n吃点真的想吃的',
                      style: TextStyle(
                        color: ink,
                        fontFamily: _foodSerif,
                        fontSize: 33,
                        fontWeight: FontWeight.w700,
                        height: 1.13,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '不用翻一百道菜。告诉我此刻的胃口，\n我替你把选择收窄到刚刚好。',
                      style: TextStyle(
                        color: Color(0xFF756A63),
                        fontFamily: _foodSans,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 21),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '此刻的胃口',
                            style: TextStyle(
                              color: ink,
                              fontFamily: _foodSans,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '已选 ${selectedTastes.length}',
                          style: const TextStyle(
                            color: accent,
                            fontFamily: _foodSans,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final taste in const [
                          '热辣',
                          '下饭',
                          '清淡',
                          '酥脆',
                          '汤汤水水',
                          '有肉',
                        ])
                          _EditorialTasteChip(
                            label: taste,
                            isSelected: selectedTastes.contains(taste),
                            onTap: () => onTasteTap(taste),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _EditorialDishFeature(),
                    const SizedBox(height: 16),
                    _EditorialDecisionBar(onGenerate: onGenerate),
                    const SizedBox(height: 14),
                    const _EditorialNavRow(),
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

class _EditorialHeader extends StatelessWidget {
  const _EditorialHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFF241A16),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.restaurant_rounded,
            size: 19,
            color: Color(0xFFFFF7EB),
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '吃什么',
              style: TextStyle(
                color: Color(0xFF241A16),
                fontFamily: _foodSans,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'EAT WHAT · DAILY',
              style: TextStyle(
                color: Color(0xFF9B8F87),
                fontFamily: _foodSans,
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD9CEC2)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 13,
                color: Color(0xFF645A54),
              ),
              SizedBox(width: 4),
              Text(
                '上海 · 晚餐',
                style: TextStyle(
                  color: Color(0xFF645A54),
                  fontFamily: _foodSans,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditorialSunMark extends StatelessWidget {
  const _EditorialSunMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      height: 142,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFC94B2C).withValues(alpha: 0.11),
          width: 20,
        ),
      ),
    );
  }
}

class _EditorialTasteChip extends StatelessWidget {
  const _EditorialTasteChip({
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
      color: isSelected ? const Color(0xFF2B201B) : const Color(0xFFFFFBF5),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        key: ValueKey('editorial-taste-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2B201B)
                  : const Color(0xFFE2D7CC),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF514741),
              fontFamily: _foodSans,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorialDishFeature extends StatelessWidget {
  const _EditorialDishFeature();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 236,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/prebuilt_dishes/dish-1-dish_768.jpg',
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x14000000),
                    Color(0xE6231711),
                  ],
                  stops: [0, 0.48, 1],
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7EA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '今晚候选 01',
                  style: TextStyle(
                    color: Color(0xFF6A2C1E),
                    fontFamily: _foodSans,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '麻婆豆腐',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: _foodSerif,
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '热、香、下饭，25 分钟就能吃上。',
                          style: TextStyle(
                            color: Color(0xFFEEDFD5),
                            fontFamily: _foodSans,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RoundSaveButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundSaveButton extends StatelessWidget {
  const _RoundSaveButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: const Icon(
        Icons.bookmark_border_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _EditorialDecisionBar extends StatelessWidget {
  const _EditorialDecisionBar({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4D8CC)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Color(0xFF8A7D74),
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '30 元内，一个人，想吃热的',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF6F635B),
                      fontFamily: _foodSans,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.mic_none_rounded,
                  size: 18,
                  color: Color(0xFF8A7D74),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 54,
          child: FilledButton(
            key: const ValueKey('warm-editorial-generate'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC94B2C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            onPressed: onGenerate,
            child: const Text(
              '帮我决定',
              style: TextStyle(
                fontFamily: _foodSans,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorialNavRow extends StatelessWidget {
  const _EditorialNavRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _EditorialNavItem(icon: Icons.home_rounded, label: '今天', active: true),
        _EditorialNavItem(icon: Icons.favorite_border_rounded, label: '收藏'),
        _EditorialNavItem(icon: Icons.history_rounded, label: '吃过'),
        _EditorialNavItem(icon: Icons.person_outline_rounded, label: '我的'),
      ],
    );
  }
}

class _EditorialNavItem extends StatelessWidget {
  const _EditorialNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFC94B2C) : const Color(0xFF978B83);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontFamily: _foodSans,
              fontSize: 9,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreetCanteenTemplate extends StatelessWidget {
  const _StreetCanteenTemplate({
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
    const charcoal = Color(0xFF171614);
    const paper = Color(0xFFF2E7D1);
    const red = Color(0xFFF04B2F);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: charcoal,
        child: SafeArea(
          child: SingleChildScrollView(
            key: const ValueKey('street-canteen-template'),
            padding: EdgeInsets.fromLTRB(16, 10, 16, bottomClearance),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CanteenHeader(),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: Text(
                        '饿了就别\n绕弯子',
                        style: TextStyle(
                          color: paper,
                          fontFamily: _foodSans,
                          fontSize: 35,
                          fontWeight: FontWeight.w900,
                          height: 0.98,
                          letterSpacing: -1.4,
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: -0.06,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: red,
                          border: Border.all(color: paper, width: 1.4),
                        ),
                        child: const Text(
                          '今天就定一口',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: _foodSans,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: paper,
                    border:
                        Border.all(color: const Color(0xFF050505), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: red,
                        offset: Offset(5, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 14, 15, 11),
                        child: Row(
                          children: [
                            const Text(
                              '口味点菜单',
                              style: TextStyle(
                                color: charcoal,
                                fontFamily: _foodSans,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${selectedTastes.length.toString().padLeft(2, '0')} 项',
                              style: const TextStyle(
                                color: red,
                                fontFamily: _foodSans,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _DashedRule(color: charcoal),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            for (final taste in const [
                              '热辣',
                              '下饭',
                              '锅气',
                              '酸甜',
                              '带肉',
                              '夜宵',
                            ])
                              _CanteenTasteChip(
                                label: taste,
                                isSelected: selectedTastes.contains(taste),
                                onTap: () => onTasteTap(taste),
                              ),
                          ],
                        ),
                      ),
                      const _CanteenDishFeature(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Expanded(
                                  child: _CanteenConstraint(
                                    index: '01',
                                    label: '30 元内',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _CanteenConstraint(
                                    index: '02',
                                    label: '25 分钟',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _CanteenConstraint(
                                    index: '03',
                                    label: '叫外卖',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 11),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                key: const ValueKey('street-canteen-generate'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: charcoal,
                                  foregroundColor: paper,
                                  shape: const RoundedRectangleBorder(),
                                  elevation: 0,
                                ),
                                onPressed: onGenerate,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '就 吃 这 个',
                                      style: TextStyle(
                                        fontFamily: _foodSans,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _CanteenNavRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CanteenHeader extends StatelessWidget {
  const _CanteenHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          '吃啥 / CHI SHA',
          style: TextStyle(
            color: Color(0xFFF2E7D1),
            fontFamily: _foodSans,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        Spacer(),
        Icon(Icons.wb_twilight_rounded, size: 15, color: Color(0xFFF04B2F)),
        SizedBox(width: 6),
        Text(
          '周五 19:20',
          style: TextStyle(
            color: Color(0xFFBAAD99),
            fontFamily: _foodSans,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DashedRule extends StatelessWidget {
  const _DashedRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 1,
      child: CustomPaint(painter: _DashedRulePainter(color)),
    );
  }
}

class _DashedRulePainter extends CustomPainter {
  const _DashedRulePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 6.0;
    const dashGap = 4.0;
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset((startX + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRulePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _CanteenTasteChip extends StatelessWidget {
  const _CanteenTasteChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('canteen-taste-$label'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF04B2F) : Colors.transparent,
          border: Border.all(color: const Color(0xFF171614), width: 1.4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF171614),
            fontFamily: _foodSans,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CanteenDishFeature extends StatelessWidget {
  const _CanteenDishFeature();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 205,
            width: double.infinity,
            child: Image.asset(
              'assets/images/prebuilt_dishes/dish-13-dish_768.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              color: const Color(0xEAF2E7D1),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '糖醋排骨',
                          style: TextStyle(
                            color: Color(0xFF171614),
                            fontFamily: _foodSans,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '酸甜亮口 · 肉香扎实 · 不会选错',
                          style: TextStyle(
                            color: Color(0xFF62594D),
                            fontFamily: _foodSans,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '¥ 28',
                    style: TextStyle(
                      color: Color(0xFFF04B2F),
                      fontFamily: _foodSans,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: -4,
            top: -8,
            child: Transform.rotate(
              angle: 0.08,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                color: const Color(0xFFF04B2F),
                child: const Text(
                  '匹配 92%',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: _foodSans,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CanteenConstraint extends StatelessWidget {
  const _CanteenConstraint({
    required this.index,
    required this.label,
  });

  final String index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF171614)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index,
            style: const TextStyle(
              color: Color(0xFFF04B2F),
              fontFamily: _foodSans,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFF171614),
              fontFamily: _foodSans,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CanteenNavRow extends StatelessWidget {
  const _CanteenNavRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
            child: _CanteenNavItem(index: '01', label: '今天吃啥', active: true)),
        Expanded(child: _CanteenNavItem(index: '02', label: '口味档案')),
        Expanded(child: _CanteenNavItem(index: '03', label: '吃过的')),
      ],
    );
  }
}

class _CanteenNavItem extends StatelessWidget {
  const _CanteenNavItem({
    required this.index,
    required this.label,
    this.active = false,
  });

  final String index;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFF04B2F) : const Color(0xFF857B6C);
    return Column(
      children: [
        Text(
          index,
          style: TextStyle(
            color: color,
            fontFamily: _foodSans,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFF2E7D1) : color,
            fontFamily: _foodSans,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SeasonalFreshTemplate extends StatelessWidget {
  const _SeasonalFreshTemplate({
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
    const background = Color(0xFFF1F4E9);
    const green = Color(0xFF48644A);
    const ink = Color(0xFF243127);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: background,
        child: Stack(
          children: [
            const Positioned.fill(child: _SeasonalBackground()),
            SafeArea(
              child: SingleChildScrollView(
                key: const ValueKey('seasonal-fresh-template'),
                padding: EdgeInsets.fromLTRB(20, 12, 20, bottomClearance),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SeasonalHeader(),
                    const SizedBox(height: 22),
                    const Text(
                      '顺着今天的胃口，\n吃一顿轻松的。',
                      style: TextStyle(
                        color: ink,
                        fontFamily: _foodSerif,
                        fontSize: 31,
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '时令食材、真实图片、清楚的营养信息，\n让“吃什么”变成一件舒服的小事。',
                      style: TextStyle(
                        color: Color(0xFF718071),
                        fontFamily: _foodSans,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _SeasonalDishFeature(),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '今天想要的感觉',
                            style: TextStyle(
                              color: ink,
                              fontFamily: _foodSans,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${selectedTastes.length}/6',
                          style: const TextStyle(
                            color: green,
                            fontFamily: _foodSans,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final taste in const [
                          '热辣',
                          '下饭',
                          '清爽',
                          '高蛋白',
                          '少油',
                          '有蔬菜',
                        ])
                          _SeasonalTasteChip(
                            label: taste,
                            isSelected: selectedTastes.contains(taste),
                            onTap: () => onTasteTap(taste),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SeasonalDecisionPanel(onGenerate: onGenerate),
                    const SizedBox(height: 14),
                    const _SeasonalNavRow(),
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

class _SeasonalBackground extends StatelessWidget {
  const _SeasonalBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SeasonalBackgroundPainter());
  }
}

class _SeasonalBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wash = Paint()..color = const Color(0xFFE1E9D5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width + 18, 126),
        width: 190,
        height: 250,
      ),
      wash,
    );

    final sun = Paint()
      ..color = const Color(0xFFE9BF5C).withValues(alpha: 0.28);
    canvas.drawCircle(Offset(18, size.height * 0.62), 70, sun);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SeasonalHeader extends StatelessWidget {
  const _SeasonalHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: const BoxDecoration(
            color: Color(0xFF48644A),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.eco_rounded,
            size: 18,
            color: Color(0xFFF4F7EE),
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '吃什么 · 本味',
              style: TextStyle(
                color: Color(0xFF243127),
                fontFamily: _foodSans,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'JULY · 盛夏时令',
              style: TextStyle(
                color: Color(0xFF7B897B),
                fontFamily: _foodSans,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD8E0CF)),
          ),
          child: const Icon(
            Icons.tune_rounded,
            size: 17,
            color: Color(0xFF48644A),
          ),
        ),
      ],
    );
  }
}

class _SeasonalDishFeature extends StatelessWidget {
  const _SeasonalDishFeature();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(74),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: Image.asset(
                'assets/images/prebuilt_dishes/dish-9-dish_768.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: _SeasonalMetric(
                    icon: Icons.timer_outlined,
                    value: '12',
                    unit: '分钟',
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: _SeasonalMetric(
                    icon: Icons.spa_outlined,
                    value: '6',
                    unit: '种食材',
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: _SeasonalMetric(
                    icon: Icons.bolt_outlined,
                    value: '320',
                    unit: '千卡',
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

class _SeasonalMetric extends StatelessWidget {
  const _SeasonalMetric({
    required this.icon,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E0CF)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF6B806C)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF243127),
              fontFamily: _foodSans,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: const TextStyle(
              color: Color(0xFF7C897C),
              fontFamily: _foodSans,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonalTasteChip extends StatelessWidget {
  const _SeasonalTasteChip({
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
      color: isSelected ? const Color(0xFF48644A) : const Color(0xD9FFFFFF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('seasonal-taste-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF48644A)
                  : const Color(0xFFD5DFCF),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF586958),
              fontFamily: _foodSans,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SeasonalDecisionPanel extends StatelessWidget {
  const _SeasonalDecisionPanel({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xAFFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6DFCE)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 7),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 17,
                    color: Color(0xFF6B7C6B),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '还可以说：不吃香菜',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF7B897B),
                        fontFamily: _foodSans,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: FilledButton(
              key: const ValueKey('seasonal-fresh-generate'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF48644A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: onGenerate,
              child: const Text(
                '生成这一餐',
                style: TextStyle(
                  fontFamily: _foodSans,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonalNavRow extends StatelessWidget {
  const _SeasonalNavRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _SeasonalNavItem(icon: Icons.eco_rounded, label: '今日', active: true),
        _SeasonalNavItem(icon: Icons.grid_view_rounded, label: '菜库'),
        _SeasonalNavItem(icon: Icons.favorite_border_rounded, label: '喜欢'),
        _SeasonalNavItem(icon: Icons.person_outline_rounded, label: '我的'),
      ],
    );
  }
}

class _SeasonalNavItem extends StatelessWidget {
  const _SeasonalNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF48644A) : const Color(0xFF8A9787);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontFamily: _foodSans,
            fontSize: 9,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
