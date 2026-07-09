import 'package:eatwhat_app/v2/core/data/models/tag_art_spec.dart';
import 'package:eatwhat_app/v2/core/data/schema/unified_tag_model.dart';

class TasteSignal {
  const TasteSignal({
    required this.tag,
    required this.artSpec,
    this.dbTagId,
    this.recallLabels = const [],
  });

  final UnifiedTagModel tag;
  final TagArtSpec artSpec;
  final String? dbTagId;
  final List<String> recallLabels;

  String get id => tag.id;
  String get label => tag.label;
  String get category => tag.category;

  bool get hasDbTag => dbTagId != null && dbTagId!.isNotEmpty;
}
