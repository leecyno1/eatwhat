import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_controller.dart';
import '../../../core/theme/app_tokens.dart';
import 'pot_button.dart';

/// The home storefront: the taste window sits on a quiet paper sill, with one
/// lacquered key in the middle and a recessed input slot below it.
///
/// Image-backed skins wrap the whole window in a 9-slice accessory frame and
/// texture the input well; painted-only skins keep the hairline border.
class HomeStorefront extends StatelessWidget {
  const HomeStorefront({
    super.key,
    required this.stage,
    required this.selectionCount,
    required this.canGenerate,
    required this.onGenerate,
    required this.requirementController,
    required this.requirementFocusNode,
    required this.isListening,
    required this.onPantry,
    required this.onVoiceStart,
    required this.onVoiceEnd,
    required this.onSubmitted,
  });

  final Widget stage;
  final int selectionCount;
  final bool canGenerate;
  final VoidCallback onGenerate;
  final TextEditingController requirementController;
  final FocusNode requirementFocusNode;
  final bool isListening;
  final VoidCallback onPantry;
  final VoidCallback onVoiceStart;
  final VoidCallback onVoiceEnd;
  final VoidCallback onSubmitted;

  /// Height of the flat sill below the window.
  static const double baseHeight = 72;

  /// Inner edge of the accessory frame ring, in logical pixels. The frame
  /// webp is 500px consumed at scale 3 (≈167 logical), ring ≈9% per side.
  static const Rect _frameSlice = Rect.fromLTRB(15.1, 15.5, 150.9, 147.5);

  /// Content inset inside the accessory frame ring.
  static const double _frameInset = 16;

  @override
  Widget build(BuildContext context) {
    final skin = AppThemeController.skin;
    final isCream = skin.isLight;
    final accent = AppPalette.leaf;
    final frameAsset = skin.assetPath('frame');
    return Container(
      padding: frameAsset == null
          ? null
          : const EdgeInsets.all(_frameInset),
      decoration: BoxDecoration(
        color: frameAsset == null ? null : skin.base,
        image: frameAsset == null
            ? null
            : DecorationImage(
                image: ExactAssetImage(frameAsset, scale: 3),
                centerSlice: _frameSlice,
                fit: BoxFit.fill,
              ),
        borderRadius: BorderRadius.circular(frameAsset == null ? 30 : 6),
        border: frameAsset == null
            ? Border.all(color: AppPalette.divider, width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isCream ? .10 : .16),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: baseHeight,
            child: stage,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SillPainter(
                  isCream: isCream,
                  accent: accent,
                  surface: AppPalette.surface,
                  surfaceDeep: isCream
                      ? AppPalette.surfaceMuted
                      : AppPalette.night,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            height: 46,
            child: _RequirementWell(
              controller: requirementController,
              focusNode: requirementFocusNode,
              isListening: isListening,
              onPantry: onPantry,
              onVoiceStart: onVoiceStart,
              onVoiceEnd: onVoiceEnd,
              onSubmitted: onSubmitted,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: baseHeight - 2,
            child: Center(
              child: PotButton(
                key: const ValueKey('home-start-inference-button'),
                selectionCount: selectionCount,
                enabled: canGenerate,
                onTap: onGenerate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SillPainter extends CustomPainter {
  _SillPainter({
    required this.isCream,
    required this.accent,
    required this.surface,
    required this.surfaceDeep,
  });

  final bool isCream;
  final Color accent;
  final Color surface;
  final Color surfaceDeep;

  @override
  void paint(Canvas canvas, Size size) {
    final sillY = size.height - HomeStorefront.baseHeight;
    final panel = Rect.fromLTRB(0, sillY, size.width, size.height);

    // A soft shadow on the glass just above the sill, then the paper panel
    // and its highlight, all in one pass.
    canvas
      ..drawRect(
        Rect.fromLTRB(0, sillY - 16, size.width, sillY),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0),
              Colors.black.withValues(alpha: isCream ? .10 : .34),
            ],
          ).createShader(
            Rect.fromLTRB(0, sillY - 16, size.width, sillY),
          ),
      )
      ..drawRect(
        panel,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [surface, surfaceDeep],
          ).createShader(panel),
      )
      ..drawLine(
        Offset(0, sillY),
        Offset(size.width, sillY),
        Paint()
          ..strokeWidth = 1
          ..color = (isCream ? Colors.white : accent).withValues(
            alpha: isCream ? .55 : .20,
          ),
      );
  }

  @override
  bool shouldRepaint(_SillPainter oldDelegate) {
    return oldDelegate.isCream != isCream ||
        oldDelegate.accent != accent ||
        oldDelegate.surface != surface ||
        oldDelegate.surfaceDeep != surfaceDeep;
  }
}

class _RequirementWell extends StatelessWidget {
  const _RequirementWell({
    required this.controller,
    required this.focusNode,
    required this.isListening,
    required this.onPantry,
    required this.onVoiceStart,
    required this.onVoiceEnd,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isListening;
  final VoidCallback onPantry;
  final VoidCallback onVoiceStart;
  final VoidCallback onVoiceEnd;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final isCream = AppThemeController.isCream;
    final accent = AppPalette.leaf;
    final wellAsset = AppThemeController.skin.assetPath('well');
    final wellBase =
        isCream ? AppPalette.creamElevatedBase : AppPalette.nightBase;
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: AppMotion.fast,
          key: const ValueKey('home-composer-dialog'),
          padding: const EdgeInsets.only(left: 16, right: 5),
          decoration: BoxDecoration(
            image: wellAsset == null
                ? null
                : DecorationImage(
                    image: AssetImage(wellAsset),
                    fit: BoxFit.fill,
                  ),
            gradient: wellAsset != null
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.alphaBlend(
                        Colors.black.withValues(alpha: isCream ? .05 : .24),
                        wellBase,
                      ),
                      wellBase,
                    ],
                  ),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: focused
                  ? accent.withValues(alpha: .55)
                  : wellAsset != null
                      ? Colors.transparent
                      : AppPalette.divider.withValues(alpha: .80),
              width: focused ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('home-requirement-input'),
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.done,
                  textAlignVertical: TextAlignVertical.center,
                  minLines: 1,
                  maxLines: 2,
                  cursorColor: accent,
                  style: TextStyle(
                    color: AppPalette.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: '忌口、想吃的、几个人，都可以直接写',
                    hintStyle: TextStyle(
                      color: AppPalette.inkSoft.withValues(alpha: .85),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onSubmitted: (_) => onSubmitted(),
                ),
              ),
              _ComposerAction(
                key: const ValueKey('home-pantry-entry'),
                icon: Icons.kitchen_rounded,
                tooltip: '冰箱里的食材',
                onTap: onPantry,
              ),
              const SizedBox(width: 2),
              _ComposerAction(
                key: const ValueKey('home-requirement-mode-pill'),
                icon: isListening
                    ? Icons.graphic_eq_rounded
                    : Icons.mic_none_rounded,
                tooltip: '按住说话',
                active: isListening,
                onLongPressStart: onVoiceStart,
                onLongPressEnd: onVoiceEnd,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComposerAction extends StatelessWidget {
  const _ComposerAction({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.active = false,
  }) : assert(
          onTap != null || onLongPressStart != null,
          'A composer action needs either a tap or a long-press handler.',
        );

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final bool active;

  @override
  Widget build(BuildContext context) {
    // A Tooltip here would steal the long-press gesture used for voice input.
    return Semantics(
      label: tooltip,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPressStart:
            onLongPressStart == null ? null : (_) => onLongPressStart!(),
        onLongPressEnd:
            onLongPressEnd == null ? null : (_) => onLongPressEnd!(),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? AppPalette.leaf.withValues(alpha: .16)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? AppPalette.leaf : AppPalette.inkSoft,
          ),
        ),
      ),
    );
  }
}
