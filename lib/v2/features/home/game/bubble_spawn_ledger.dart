/// 气泡发放台账。
///
/// 实体在 [world.add] 前先占位，因此排队等待贴图轮廓加载的实体也会参与
/// 去重；分类重载通过代次号让未挂载的旧实体失效。
class BubbleSpawnLedger {
  final Set<String> _issuedIds = <String>{};
  int _generation = 0;

  int get generation => _generation;

  Set<String> get issuedIds => Set<String>.unmodifiable(_issuedIds);

  bool reserve(String id) {
    if (id.isEmpty) return false;
    return _issuedIds.add(id);
  }

  Set<String> exclusions(Iterable<String> additionallyExcluded) {
    return <String>{
      ..._issuedIds,
      ...additionallyExcluded.where((id) => id.isNotEmpty),
    };
  }

  void beginGeneration({
    Iterable<String> preserve = const <String>[],
  }) {
    _generation += 1;
    _issuedIds
      ..clear()
      ..addAll(preserve.where((id) => id.isNotEmpty));
  }
}
