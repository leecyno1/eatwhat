import 'dart:async';
import 'dart:ui';

import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

import 'bubble_ocean.dart';
import 'taste_stage_wallpaper.dart';

/// The physical preference stage: a switchable wallpaper container that
/// hosts the falling entity pile.
class FreshPhysicalPreferenceStage extends StatelessWidget {
  const FreshPhysicalPreferenceStage({
    super.key,
    required this.session,
    required this.isLoading,
    required this.category,
    required this.onSelectionChanged,
    this.embedded = false,
  });

  final TasteDeckSessionState? session;
  final bool isLoading;
  final String? category;
  final ValueChanged<BubbleSelectionState> onSelectionChanged;

  /// When embedded inside the home storefront card the stage leans on the
  /// outer frame for its border and shadow; only the top corners stay round.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final current = session;
    final likedTags = _zipTags(
      current?.likedTagIds ?? const [],
      current?.likedTagLabels ?? const [],
    );
    final blockedTags = _zipTags(
      current?.dislikedTagIds ?? const [],
      current?.dislikedTagLabels ?? const [],
    );
    return _PhysicalTasteHabitat(
      isLoading: isLoading || current == null,
      category: category,
      initialLikedTags: likedTags,
      initialBlockedTags: blockedTags,
      onSelectionChanged: onSelectionChanged,
      embedded: embedded,
    );
  }

  Map<String, String> _zipTags(List<String> ids, List<String> labels) {
    return {
      for (var index = 0; index < ids.length; index++)
        ids[index]: index < labels.length ? labels[index] : ids[index],
    };
  }
}

class _PhysicalTasteHabitat extends StatefulWidget {
  const _PhysicalTasteHabitat({
    required this.isLoading,
    required this.category,
    required this.initialLikedTags,
    required this.initialBlockedTags,
    required this.onSelectionChanged,
    this.embedded = false,
  });

  final bool isLoading;
  final String? category;
  final Map<String, String> initialLikedTags;
  final Map<String, String> initialBlockedTags;
  final ValueChanged<BubbleSelectionState> onSelectionChanged;
  final bool embedded;

  @override
  State<_PhysicalTasteHabitat> createState() => _PhysicalTasteHabitatState();
}

class _PhysicalTasteHabitatState extends State<_PhysicalTasteHabitat> {
  bool _showGestureHint = true;
  TasteStageWallpaper _wallpaper = TasteStageWallpaper.night;
  bool _wallpaperBadgeVisible = false;
  bool _wallpaperPinnedByUser = false;
  Timer? _wallpaperBadgeTimer;

  @override
  void initState() {
    super.initState();
    _loadStoredWallpaper();
    AppThemeController.mode.addListener(_handleThemeModeChanged);
  }

  @override
  void dispose() {
    AppThemeController.mode.removeListener(_handleThemeModeChanged);
    _wallpaperBadgeTimer?.cancel();
    super.dispose();
  }

  void _handleThemeModeChanged() {
    if (_wallpaperPinnedByUser) return;
    final preferred = AppThemeController.isCream
        ? TasteStageWallpaper.garden
        : TasteStageWallpaper.night;
    if (_wallpaper == preferred) return;
    // Only auto-switch within the default light/dark pair; wallpapers the
    // user cycled to (broth/matcha) stay untouched.
    final isDefaultPair = _wallpaper == TasteStageWallpaper.garden ||
        _wallpaper == TasteStageWallpaper.night;
    if (!isDefaultPair) return;
    if (!mounted) return;
    setState(() => _wallpaper = preferred);
  }

  Future<void> _loadStoredWallpaper() async {
    final stored = await TasteStageWallpaper.loadStored();
    // Keep the stage in the same family as the page theme: a cream page
    // should not open on a black stage (and vice versa). Wallpapers the user
    // explicitly cycled to (broth/matcha) are always respected.
    final preferred = AppThemeController.isCream
        ? TasteStageWallpaper.garden
        : TasteStageWallpaper.night;
    final isDefaultPair = stored == TasteStageWallpaper.garden ||
        stored == TasteStageWallpaper.night;
    final resolved = !isDefaultPair || stored.isDark == preferred.isDark
        ? stored
        : preferred;
    if (!mounted) return;
    setState(() => _wallpaper = resolved);
  }

  void _cycleWallpaper() {
    final next = _wallpaper.next;
    setState(() {
      _wallpaper = next;
      _wallpaperPinnedByUser = true;
      _wallpaperBadgeVisible = true;
    });
    unawaited(next.persist());
    _wallpaperBadgeTimer?.cancel();
    _wallpaperBadgeTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _wallpaperBadgeVisible = false);
    });
  }

  void _handleInteraction() {
    if (!_showGestureHint) return;
    setState(() => _showGestureHint = false);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedContainer(
          key: const ValueKey('taste-physical-habitat'),
          duration: AppMotion.standard,
          curve: AppMotion.enter,
          decoration: _wallpaper.buildStageDecoration(
            borderRadius: widget.embedded
                ? const BorderRadius.vertical(top: Radius.circular(30))
                : null,
            withBorder: !widget.embedded,
            withShadow: !widget.embedded,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: widget.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppPalette.leaf,
                        ),
                      )
                    : BubbleOcean(
                        showDecisionButton: false,
                        category: widget.category,
                        initialLikedTags: widget.initialLikedTags,
                        initialBlockedTags: widget.initialBlockedTags,
                        onSelectionChanged: widget.onSelectionChanged,
                        onInteracted: _handleInteraction,
                      ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _WallpaperSwitchButton(
                  onTap: _cycleWallpaper,
                ),
              ),
              Positioned(
                top: 54,
                right: 10,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    key: const ValueKey('taste-stage-wallpaper-badge'),
                    opacity: _wallpaperBadgeVisible ? 1 : 0,
                    duration: AppMotion.fast,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.night.withValues(alpha: 0.86),
                        borderRadius: AppRadii.capsule,
                        border: Border.all(color: AppPalette.nightDivider),
                      ),
                      child: Text(
                        _wallpaper.label,
                        style: TextStyle(
                          color: AppPalette.moonlight,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 56,
                right: 56,
                bottom: 132,
                child: IgnorePointer(
                  child: AnimatedSlide(
                    offset:
                        _showGestureHint ? Offset.zero : const Offset(0, 0.35),
                    duration: AppMotion.fast,
                    child: AnimatedOpacity(
                      key: const ValueKey('taste-gesture-hint'),
                      opacity: _showGestureHint ? 1 : 0,
                      duration: AppMotion.fast,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.night.withValues(alpha: 0.82),
                          borderRadius: AppRadii.capsule,
                          border: Border.all(color: AppPalette.nightDivider),
                        ),
                        child: Text(
                          '点选收下 · 按住抓起，顶部收下 / 底部拉黑 · 摇一摇翻锅',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppPalette.moonlight,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WallpaperSwitchButton extends StatelessWidget {
  const _WallpaperSwitchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('taste-stage-wallpaper-switch'),
      color: AppPalette.nightSurface.withValues(alpha: 0.82),
      shape: CircleBorder(
        side: BorderSide(color: AppPalette.nightDivider),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            Icons.wallpaper_rounded,
            size: 17,
            color: AppPalette.moonlight,
          ),
        ),
      ),
    );
  }
}
