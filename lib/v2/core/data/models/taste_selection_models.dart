enum TasteDeckFaceStage {
  deck,
  signature,
}

enum TasteCardReaction {
  liked,
  disliked,
  skipped,
}

enum TasteExecutionPreference {
  any,
  cook,
  delivery,
  dineIn,
}

enum TasteLocationPreference {
  any,
  nearby,
}

class TasteStructuredConstraints {
  const TasteStructuredConstraints({
    this.maxTimeMinutes,
    this.maxBudgetYuan,
    this.partySize,
    this.dietaryRestrictions = const [],
    this.executionPreference = TasteExecutionPreference.any,
    this.locationPreference = TasteLocationPreference.any,
  });

  final int? maxTimeMinutes;
  final int? maxBudgetYuan;
  final int? partySize;
  final List<String> dietaryRestrictions;
  final TasteExecutionPreference executionPreference;
  final TasteLocationPreference locationPreference;

  bool get isEmpty =>
      maxTimeMinutes == null &&
      maxBudgetYuan == null &&
      partySize == null &&
      dietaryRestrictions.isEmpty &&
      executionPreference == TasteExecutionPreference.any &&
      locationPreference == TasteLocationPreference.any;

  List<String> get labels => [
        if (maxTimeMinutes != null) '$maxTimeMinutes 分钟内',
        if (maxBudgetYuan != null) '$maxBudgetYuan 元内',
        if (partySize != null) '$partySize 人',
        ...dietaryRestrictions,
        if (executionPreference != TasteExecutionPreference.any)
          executionPreference.label,
        if (locationPreference != TasteLocationPreference.any)
          locationPreference.label,
      ];

  TasteStructuredConstraints copyWith({
    int? maxTimeMinutes,
    bool clearMaxTimeMinutes = false,
    int? maxBudgetYuan,
    bool clearMaxBudgetYuan = false,
    int? partySize,
    bool clearPartySize = false,
    List<String>? dietaryRestrictions,
    TasteExecutionPreference? executionPreference,
    TasteLocationPreference? locationPreference,
  }) {
    return TasteStructuredConstraints(
      maxTimeMinutes:
          clearMaxTimeMinutes ? null : maxTimeMinutes ?? this.maxTimeMinutes,
      maxBudgetYuan:
          clearMaxBudgetYuan ? null : maxBudgetYuan ?? this.maxBudgetYuan,
      partySize: clearPartySize ? null : partySize ?? this.partySize,
      dietaryRestrictions:
          dietaryRestrictions ?? List<String>.from(this.dietaryRestrictions),
      executionPreference: executionPreference ?? this.executionPreference,
      locationPreference: locationPreference ?? this.locationPreference,
    );
  }
}

extension TasteExecutionPreferenceLabel on TasteExecutionPreference {
  String get label {
    return switch (this) {
      TasteExecutionPreference.any => '都可以',
      TasteExecutionPreference.cook => '在家做',
      TasteExecutionPreference.delivery => '叫外卖',
      TasteExecutionPreference.dineIn => '去店里',
    };
  }
}

extension TasteLocationPreferenceLabel on TasteLocationPreference {
  String get label {
    return switch (this) {
      TasteLocationPreference.any => '不限位置',
      TasteLocationPreference.nearby => '附近',
    };
  }
}

class TasteDeckCard {
  const TasteDeckCard({
    required this.id,
    required this.label,
    required this.category,
    required this.accentHexes,
    required this.iconName,
    this.blurb,
    this.backTitle,
    this.examples = const [],
    this.artKey = 'default',
    this.surfacePattern = 'category',
    this.motionPreset = 'breathe',
    this.symbolLayout = 'stamp',
    this.headlineStyle = 'editorial',
  });

  final String id;
  final String label;
  final String category;
  final List<String> accentHexes;
  final String iconName;
  final String? blurb;
  final String? backTitle;
  final List<String> examples;
  final String artKey;
  final String surfacePattern;
  final String motionPreset;
  final String symbolLayout;
  final String headlineStyle;
}

class TasteDeckSessionState {
  const TasteDeckSessionState({
    required this.deck,
    required this.cardDeckSeed,
    required this.currentIndex,
    required this.currentPageCardIds,
    required this.nextDeckIndex,
    required this.seenTagIds,
    required this.faceStage,
    required this.freeformRequirement,
    required this.structuredConstraints,
    required this.likedTagIds,
    required this.dislikedTagIds,
    required this.skippedTagIds,
    required Map<String, String> tagLabelsById,
  }) : _tagLabelsById = tagLabelsById;

  factory TasteDeckSessionState.initial({
    required List<TasteDeckCard> deck,
    required int cardDeckSeed,
  }) {
    return TasteDeckSessionState(
      deck: deck,
      cardDeckSeed: cardDeckSeed,
      currentIndex: 0,
      currentPageCardIds: deck.take(pageSize).map((card) => card.id).toList(),
      nextDeckIndex: deck.length < pageSize ? deck.length : pageSize,
      seenTagIds: deck.take(pageSize).map((card) => card.id).toList(),
      faceStage: TasteDeckFaceStage.deck,
      freeformRequirement: '',
      structuredConstraints: const TasteStructuredConstraints(),
      likedTagIds: const [],
      dislikedTagIds: const [],
      skippedTagIds: const [],
      tagLabelsById: {
        for (final card in deck) card.id: card.label,
      },
    );
  }

  static const int pageSize = 16;

  final List<TasteDeckCard> deck;
  final int cardDeckSeed;
  final int currentIndex;
  final List<String> currentPageCardIds;
  final int nextDeckIndex;
  final List<String> seenTagIds;
  final TasteDeckFaceStage faceStage;
  final String freeformRequirement;
  final TasteStructuredConstraints structuredConstraints;
  final List<String> likedTagIds;
  final List<String> dislikedTagIds;
  final List<String> skippedTagIds;
  final Map<String, String> _tagLabelsById;

  TasteDeckCard? get currentCard {
    final cards = currentPageCards;
    if (cards.isEmpty) return null;
    return cards.first;
  }

  List<TasteDeckCard> get currentPageCards {
    if (deck.isEmpty || currentPageCardIds.isEmpty) {
      return const [];
    }
    final byId = {for (final card in deck) card.id: card};
    return currentPageCardIds
        .map((id) => byId[id])
        .whereType<TasteDeckCard>()
        .toList();
  }

  int get totalPageCount {
    if (deck.isEmpty) {
      return 0;
    }
    return (deck.length / pageSize).ceil();
  }

  int get currentPageNumber {
    if (deck.isEmpty) {
      return 0;
    }
    return (currentIndex ~/ pageSize) + 1;
  }

  int get reviewedCount =>
      likedTagIds.length + dislikedTagIds.length + skippedTagIds.length;

  bool get canStartInference =>
      likedTagIds.isNotEmpty ||
      dislikedTagIds.isNotEmpty ||
      freeformRequirement.trim().isNotEmpty;

  List<String> get likedTagLabels => _labelsFor(likedTagIds);
  List<String> get dislikedTagLabels => _labelsFor(dislikedTagIds);
  List<String> get skippedTagLabels => _labelsFor(skippedTagIds);

  List<String> _labelsFor(List<String> ids) {
    return ids.map((id) => _tagLabelsById[id] ?? id).toList();
  }

  TasteCardReaction? pageReactionFor(String cardId) {
    if (likedTagIds.contains(cardId)) {
      return TasteCardReaction.liked;
    }
    if (dislikedTagIds.contains(cardId)) {
      return TasteCardReaction.disliked;
    }
    if (skippedTagIds.contains(cardId)) {
      return TasteCardReaction.skipped;
    }
    return null;
  }

  bool isCardResolved(String cardId) => pageReactionFor(cardId) != null;

  bool get isCurrentPageFullyResolved =>
      currentPageCards.isNotEmpty &&
      currentPageCards.every((card) => isCardResolved(card.id));

  TasteDeckSessionState recordReaction(
    TasteDeckCard card,
    TasteCardReaction reaction,
  ) {
    final nextLiked = List<String>.from(likedTagIds);
    final nextDisliked = List<String>.from(dislikedTagIds);
    final nextSkipped = List<String>.from(skippedTagIds);

    void appendUnique(List<String> ids) {
      if (!ids.contains(card.id)) {
        ids.add(card.id);
      }
    }

    switch (reaction) {
      case TasteCardReaction.liked:
        nextDisliked.remove(card.id);
        nextSkipped.remove(card.id);
        appendUnique(nextLiked);
        break;
      case TasteCardReaction.disliked:
        nextLiked.remove(card.id);
        nextSkipped.remove(card.id);
        appendUnique(nextDisliked);
        break;
      case TasteCardReaction.skipped:
        nextLiked.remove(card.id);
        nextDisliked.remove(card.id);
        appendUnique(nextSkipped);
        break;
    }

    final replacement = _findNextAvailableCard(
      startIndex: nextDeckIndex,
      blockedIds: {
        ...likedTagIds,
        ...dislikedTagIds,
        ...skippedTagIds,
        ...seenTagIds,
        ...currentPageCardIds,
      }..remove(card.id),
    );
    final nextSeen = List<String>.from(seenTagIds);
    if (replacement != null && !nextSeen.contains(replacement.id)) {
      nextSeen.add(replacement.id);
    }

    return TasteDeckSessionState(
      deck: deck,
      cardDeckSeed: cardDeckSeed,
      currentIndex: currentIndex,
      currentPageCardIds: _replaceCardInCurrentPage(card.id, replacement),
      nextDeckIndex: _resolveNextDeckIndex(replacement),
      seenTagIds: nextSeen,
      faceStage: faceStage,
      freeformRequirement: freeformRequirement,
      structuredConstraints: structuredConstraints,
      likedTagIds: nextLiked,
      dislikedTagIds: nextDisliked,
      skippedTagIds: nextSkipped,
      tagLabelsById: {
        ..._tagLabelsById,
        card.id: card.label,
      },
    );
  }

  TasteDeckSessionState advancePage() {
    final nextSkipped = List<String>.from(skippedTagIds);
    final nextLabels = Map<String, String>.from(_tagLabelsById);

    for (final card in currentPageCards) {
      nextLabels[card.id] = card.label;
      if (!likedTagIds.contains(card.id) &&
          !dislikedTagIds.contains(card.id) &&
          !nextSkipped.contains(card.id)) {
        nextSkipped.add(card.id);
      }
    }

    final nextSeen = List<String>.from(seenTagIds);

    final nextPageCards = _collectNextPageCardIds(
      startIndex: nextDeckIndex,
      blockedIds: {
        ...likedTagIds,
        ...dislikedTagIds,
        ...nextSkipped,
        ...nextSeen,
      },
    );
    final hasMorePages = nextPageCards.ids.isNotEmpty;
    final nextIndex = hasMorePages ? currentIndex + pageSize : currentIndex;
    for (final id in nextPageCards.ids) {
      if (!nextSeen.contains(id)) {
        nextSeen.add(id);
      }
    }

    return TasteDeckSessionState(
      deck: deck,
      cardDeckSeed: cardDeckSeed,
      currentIndex: nextIndex,
      currentPageCardIds: hasMorePages ? nextPageCards.ids : currentPageCardIds,
      nextDeckIndex: nextPageCards.nextIndex,
      seenTagIds: nextSeen,
      faceStage: faceStage,
      freeformRequirement: freeformRequirement,
      structuredConstraints: structuredConstraints,
      likedTagIds: likedTagIds,
      dislikedTagIds: dislikedTagIds,
      skippedTagIds: nextSkipped,
      tagLabelsById: nextLabels,
    );
  }

  TasteDeckSessionState copyWith({
    List<TasteDeckCard>? deck,
    int? cardDeckSeed,
    int? currentIndex,
    List<String>? currentPageCardIds,
    int? nextDeckIndex,
    List<String>? seenTagIds,
    TasteDeckFaceStage? faceStage,
    String? freeformRequirement,
    TasteStructuredConstraints? structuredConstraints,
    List<String>? likedTagIds,
    List<String>? dislikedTagIds,
    List<String>? skippedTagIds,
    Map<String, String>? tagLabelsById,
  }) {
    return TasteDeckSessionState(
      deck: deck ?? this.deck,
      cardDeckSeed: cardDeckSeed ?? this.cardDeckSeed,
      currentIndex: currentIndex ?? this.currentIndex,
      currentPageCardIds: currentPageCardIds ?? this.currentPageCardIds,
      nextDeckIndex: nextDeckIndex ?? this.nextDeckIndex,
      seenTagIds: seenTagIds ?? this.seenTagIds,
      faceStage: faceStage ?? this.faceStage,
      freeformRequirement: freeformRequirement ?? this.freeformRequirement,
      structuredConstraints:
          structuredConstraints ?? this.structuredConstraints,
      likedTagIds: likedTagIds ?? this.likedTagIds,
      dislikedTagIds: dislikedTagIds ?? this.dislikedTagIds,
      skippedTagIds: skippedTagIds ?? this.skippedTagIds,
      tagLabelsById: tagLabelsById ?? _tagLabelsById,
    );
  }

  List<String> _replaceCardInCurrentPage(
    String cardId,
    TasteDeckCard? replacement,
  ) {
    final nextPageIds = List<String>.from(currentPageCardIds);
    final slotIndex = nextPageIds.indexOf(cardId);
    if (slotIndex == -1) return nextPageIds;

    if (replacement == null) {
      nextPageIds.removeAt(slotIndex);
      return nextPageIds;
    }

    nextPageIds[slotIndex] = replacement.id;
    return nextPageIds;
  }

  int _resolveNextDeckIndex(TasteDeckCard? replacement) {
    if (replacement == null) return nextDeckIndex;
    final replacementIndex =
        deck.indexWhere((card) => card.id == replacement.id);
    return replacementIndex == -1 ? nextDeckIndex : replacementIndex + 1;
  }

  TasteDeckCard? _findNextAvailableCard({
    required int startIndex,
    required Set<String> blockedIds,
  }) {
    for (var index = startIndex; index < deck.length; index++) {
      final candidate = deck[index];
      if (blockedIds.contains(candidate.id)) continue;
      return candidate;
    }
    return null;
  }

  ({List<String> ids, int nextIndex}) _collectNextPageCardIds({
    required int startIndex,
    required Set<String> blockedIds,
  }) {
    final ids = <String>[];
    var index = startIndex;
    while (index < deck.length && ids.length < pageSize) {
      final candidate = deck[index];
      if (!blockedIds.contains(candidate.id)) {
        ids.add(candidate.id);
      }
      index += 1;
    }
    return (ids: ids, nextIndex: index);
  }
}
