import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_controller.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_skins.dart';

/// Compact appearance sheet. The page structure stays exactly as it is;
/// only the two color modes are presented with a small live preview.
Future<void> showAppThemeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => const _AppThemeSheet(),
  );
}

class _AppThemeSheet extends StatelessWidget {
  const _AppThemeSheet();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppThemeController.mode,
        AppThemeController.autoEnabled,
        AppThemeController.dayPreference,
        AppThemeController.nightPreference,
      ]),
      builder: (context, _) {
        final mode = AppThemeController.mode.value;
        final auto = AppThemeController.autoEnabled.value;
        return Container(
          key: const ValueKey('app-theme-sheet'),
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.lg),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.divider,
                    borderRadius: AppRadii.capsule,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '外观',
                      style: AppTypeNight.section,
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppPalette.inkSoft,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                auto
                    ? '自动已开启：点选下方主题会记为当前时段的偏好。'
                    : '选择看着舒服的底色；图标和强调色会一起切换。',
                style: AppTypeNight.body.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              // Not const: the card reads controller state in build, so it
              // must rebuild whenever the merged listenable above notifies.
              // ignore: prefer_const_constructors
              _AutoThemeCard(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ThemePreviewCard(
                      mode: AppThemeMode.cream,
                      selected: mode == AppThemeMode.cream,
                      title: '米白 · 日间',
                      subtitle: '暖象牙底，陶土强调',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThemePreviewCard(
                      mode: AppThemeMode.dark,
                      selected: mode == AppThemeMode.dark,
                      title: '墨夜 · 夜间',
                      subtitle: '炭黑底，珊瑚强调',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '美学主题',
                style: AppTypeNight.label.copyWith(
                  color: AppPalette.inkSoft,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
                  children: [
                    for (final skin in ThemeSkins.aesthetics)
                      _SkinPreviewCard(
                        skin: skin,
                        selected: mode == skin.mode,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('完成'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full-width opt-in card for day/night auto switching. The subtitle mirrors
/// the remembered per-slot preferences so users see what auto will do, and
/// the chip labels which slot a manual pick would land in right now.
class _AutoThemeCard extends StatelessWidget {
  const _AutoThemeCard();

  @override
  Widget build(BuildContext context) {
    final auto = AppThemeController.autoEnabled.value;
    final day = ThemeSkins.of(AppThemeController.dayPreference.value);
    final night = ThemeSkins.of(AppThemeController.nightPreference.value);
    final isDay = AppThemeController.systemBrightness == Brightness.light;
    final accent = AppPalette.leaf;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('theme-option-auto'),
        borderRadius: AppRadii.card,
        onTap: () => AppThemeController.setAuto(!auto),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppPalette.surfaceMuted,
            borderRadius: AppRadii.card,
            border: Border.all(
              color: auto ? accent : AppPalette.divider,
              width: auto ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.brightness_auto_rounded,
                size: 22,
                color: auto ? accent : AppPalette.inkSoft,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '自动 · 跟随昼夜',
                      style: TextStyle(
                        color: AppPalette.ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '白天 ${day.label} ｜ 夜晚 ${night.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppPalette.inkSoft,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.surface,
                  borderRadius: AppRadii.capsule,
                  border: Border.all(color: AppPalette.divider),
                ),
                child: Text(
                  isDay ? '当前：白天' : '当前：夜晚',
                  style: TextStyle(
                    color: AppPalette.inkSoft,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                auto ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 17,
                color: auto ? accent : AppPalette.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.mode,
    required this.selected,
    required this.title,
    required this.subtitle,
  });

  final AppThemeMode mode;
  final bool selected;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isCream = mode == AppThemeMode.cream;
    final background = isCream ? AppPalette.creamBase : AppPalette.nightBase;
    final surface = isCream ? AppPalette.creamPanel : AppPalette.nightPanel;
    final ink = isCream ? AppPalette.creamInk : AppPalette.nightText;
    final muted = isCream ? AppPalette.creamMutedInk : AppPalette.nightMuted;
    final accent = isCream ? AppPalette.accentCream : AppPalette.accentDark;
    final line = isCream ? AppPalette.creamLine : AppPalette.nightLine;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('theme-option-${mode.name}'),
        borderRadius: AppRadii.card,
        onTap: () => AppThemeController.setMode(mode),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadii.card,
            border: Border.all(
              color: selected ? accent : line,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isCream ? .08 : .22),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: .86),
                        borderRadius: AppRadii.capsule,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 17,
                    color: selected ? accent : muted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 54,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 6,
                            width: 54,
                            decoration: BoxDecoration(
                              color: ink.withValues(alpha: .8),
                              borderRadius: AppRadii.capsule,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: 5,
                            width: 38,
                            decoration: BoxDecoration(
                              color: muted.withValues(alpha: .7),
                              borderRadius: AppRadii.capsule,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: AppRadii.capsule,
                      ),
                      child: Text(
                        '开锅',
                        style: TextStyle(
                          color: isCream
                              ? AppPalette.creamPanel
                              : AppPalette.nightBase,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact swatch card for one of the nine image-backed aesthetics.
class _SkinPreviewCard extends StatelessWidget {
  const _SkinPreviewCard({required this.skin, required this.selected});

  final ThemeSkin skin;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('theme-option-${skin.id}'),
        borderRadius: AppRadii.card,
        onTap: () => AppThemeController.setMode(skin.mode),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: skin.base,
            borderRadius: AppRadii.card,
            border: Border.all(
              color: selected ? skin.accent : skin.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: skin.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: skin.panel,
                        borderRadius: AppRadii.capsule,
                        border: Border.all(color: skin.line),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 14,
                    color: selected ? skin.accent : skin.muted,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: skin.panel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: skin.line),
                ),
                child: Text(
                  '开锅',
                  style: TextStyle(
                    color: skin.accent,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                skin.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: skin.ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                skin.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: skin.muted,
                  fontSize: 9,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
