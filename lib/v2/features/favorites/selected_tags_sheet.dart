import 'package:eatwhat_app/v2/core/services/v2_favorites_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class SelectedTagsSheet extends StatefulWidget {
  final List<SelectedTag> tags;

  const SelectedTagsSheet({
    super.key,
    required this.tags,
  });

  static Future<void> show(
    BuildContext context, {
    required List<SelectedTag> tags,
  }) async {
    if (tags.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectedTagsSheet(tags: tags),
    );
  }

  @override
  State<SelectedTagsSheet> createState() => _SelectedTagsSheetState();
}

class _SelectedTagsSheetState extends State<SelectedTagsSheet> {
  final V2FavoritesService _favorites = V2FavoritesService.instance;
  Set<String> _favorited = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fav = await _favorites.getFavoriteTagIds();
    if (!mounted) return;
    setState(() {
      _favorited = fav;
      _loading = false;
    });
  }

  Future<void> _toggle(String tagId) async {
    await _favorites.toggleFavoriteTag(tagId);
    await _load();
  }

  Future<void> _favoriteAll() async {
    final next = Set<String>.from(_favorited);
    for (final t in widget.tags) {
      next.add(t.id);
    }
    await _favorites.setFavoriteTagIds(next);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.62;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppPalette.rice,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '收藏这些偏好',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _favoriteAll,
                  child: const Text('收藏全部'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.tags.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tag = widget.tags[index];
                      final isFav = _favorited.contains(tag.id);
                      return Material(
                        color: AppPalette.rice,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 1,
                        child: ListTile(
                          title: Text(
                            tag.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            tag.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () => _toggle(tag.id),
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav
                                  ? AppColors.sunsetOrange
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sunsetOrange,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('完成'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectedTag {
  final String id;
  final String label;

  const SelectedTag({
    required this.id,
    required this.label,
  });
}
