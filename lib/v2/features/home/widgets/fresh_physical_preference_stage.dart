import 'dart:async';
import 'dart:ui';

import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
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
  });

  final TasteDeckSessionState? session;
  final bool isLoading;
  final String? category;
  final ValueChanged<BubbleSelectionState> onSelectionChanged;

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
  });

  final bool isLoading;
  final String? category;
  final Map<String, String> initialLikedTags;
  final Map<String, String> initialBlockedTags;
  final ValueChanged<BubbleSelectionState> onSelectionChanged;

  @override
  State<_PhysicalTasteHabitat> createState() => _PhysicalTasteHabitatState();
}

class _PhysicalTasteHabitatState extends State<_PhysicalTasteHabitat> {
  bool _showGestureHint = true;
  TasteStageWallpaper _wallpaper = TasteStageWallpaper.night;
  bool _wallpaperBadgeVisible = false;
  Timer? _wallpaperBadgeTimer;

  @override
  void initState() {
    super.initState();
    _loadStoredWallpaper();
  }

  @override
  void dispose() {
    _wallpaperBadgeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStoredWallpaper() async {
    final stored = await TasteStageWallpaper.loadStored();
    if (!mounted) return;
    setState(() => _wallpaper = stored);
  }

  void _cycleWallpaper() {
    final next = _wallpaper.next;
    setState(() {
      _wallpaper = next;
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
          decoration: _wallpaper.buildStageDecoration(),
          child: Stack(
            children: [
              Positioned.fill(
                child: widget.isLoading
                    ? const Center(
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
                        style: const TextStyle(
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
                bottom: 16,
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
                        child: const Text(
                          '点选 · 划过连选 · 按住抓起，顶部收下 / 底部拉黑',
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
      shape: const CircleBorder(
        side: BorderSide(color: AppPalette.nightDivider),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
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
