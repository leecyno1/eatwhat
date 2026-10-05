import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

/// 结果页分享卡片：预览 + 捕获 PNG + 唤起系统分享。
///
/// [cardCapture] 与 [shareLauncher] 用于测试注入；默认实现分别走
/// RepaintBoundary 截图与 share_plus。
class RecipeShareSheet extends StatefulWidget {
  const RecipeShareSheet({
    super.key,
    required this.recipe,
    required this.quote,
    this.cardCapture,
    this.shareLauncher,
  });

  final RecipeModel recipe;
  final String quote;
  final Future<Uint8List> Function()? cardCapture;
  final Future<void> Function(Uint8List bytes, String text)? shareLauncher;

  @override
  State<RecipeShareSheet> createState() => _RecipeShareSheetState();
}

class _RecipeShareSheetState extends State<RecipeShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;
  String? _error;

  Future<Uint8List> _capture() async {
    final boundary = _cardKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('share card not mounted');
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() {
      _sharing = true;
      _error = null;
    });
    try {
      final capture = widget.cardCapture ?? _capture;
      final launch = widget.shareLauncher ?? _launchSystemShare;
      final bytes = await capture();
      final text = '今天决定吃这个：${widget.recipe.name}';
      await launch(bytes, text);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '分享失败，请稍后再试');
      }
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  Future<void> _launchSystemShare(Uint8List bytes, String text) async {
    final file = File(
      '${Directory.systemTemp.path}/'
      'eatwhat_share_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('分享这道菜', style: AppType.section),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: RepaintBoundary(
                key: _cardKey,
                child: RecipeShareCard(
                  recipe: widget.recipe,
                  quote: widget.quote,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppType.body.copyWith(color: const Color(0xFFF46B40)),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const ValueKey('result-share-submit'),
              onPressed: _sharing ? null : _share,
              style: FilledButton.styleFrom(
                backgroundColor: GoldPalette.gold,
                foregroundColor: GoldPalette.nightDeep,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.capsule,
                ),
              ),
              icon: _sharing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_rounded, size: 19),
              label: Text(_sharing ? '生成中…' : '分享卡片'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分享出去的卡片本体：菜图 + 菜名 + 一句话理由 + 品牌落款。
class RecipeShareCard extends StatelessWidget {
  const RecipeShareCard({
    super.key,
    required this.recipe,
    required this.quote,
  });

  final RecipeModel recipe;
  final String quote;

  @override
  Widget build(BuildContext context) {
    final imageUrl = recipe.imageUrl?.trim();
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: GoldPalette.nightDeep,
        borderRadius: AppRadii.card,
        border: Border.all(color: GoldPalette.goldHairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 190,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _imagePlaceholder(),
                    errorWidget: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: const TextStyle(
                    color: GoldPalette.gold,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                if (quote.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    quote,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GoldPalette.creamText,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (recipe.tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in recipe.tags.take(3))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: GoldPalette.panel,
                            borderRadius: AppRadii.capsule,
                            border: Border.all(color: GoldPalette.goldHairline),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: GoldPalette.goldSoft,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                const Center(
                  child: Text(
                    '吃什么 · 今天也好好吃饭',
                    style: TextStyle(
                      color: GoldPalette.goldSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
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

  Widget _imagePlaceholder() {
    return Container(
      color: GoldPalette.panel,
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_rounded,
        size: 56,
        color: GoldPalette.goldDim,
      ),
    );
  }
}
