import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/physical_entity.dart';
import '../models/user_preference.dart';
import '../models/user_taste_action.dart';
import '../repositories/user_preference_repository.dart';

/// 服务: 记录用户味觉行为事件并广播变更
class PreferenceEventService {
  static const String _eventBoxName = 'user_taste_events';

  final UserPreferenceRepository _preferenceRepository;
  Box<Map<String, dynamic>>? _eventBox;
  final StreamController<UserTasteAction> _eventController = StreamController.broadcast();

  PreferenceEventService(this._preferenceRepository);

  Stream<UserTasteAction> get eventStream => _eventController.stream;

  Future<void> init() async {
    debugPrint('PreferenceEventService init');
    _eventBox ??= await Hive.openBox<Map<String, dynamic>>(_eventBoxName);
  }

  Future<void> dispose() async {
    await _eventController.close();
    await _eventBox?.close();
  }

  Future<UserPreference> recordAction(UserTasteAction action) async {
    await init();
    await _eventBox!.add(action.toJson());

    final preference = await _preferenceRepository.getOrCreate();
    final updatedPreference = await _applyAction(preference, action);

    _eventController.add(action);
    return updatedPreference;
  }

  Future<void> replayEvents() async {
    await init();
    var preference = await _preferenceRepository.getOrCreate();

    for (final entry in _eventBox!.values) {
      final action = UserTasteAction.fromJson(entry);
      preference = await _applyAction(preference, action, persist: false);
    }
    await _preferenceRepository.save(preference);
  }

  Future<UserPreference> _applyAction(
    UserPreference preference,
    UserTasteAction action, {
    bool persist = true,
  }) async {
    final updatedPreference = _updatePreference(preference, action);
    if (persist) {
      await _preferenceRepository.save(updatedPreference);
    }
    return updatedPreference;
  }

  UserPreference _updatePreference(
    UserPreference preference,
    UserTasteAction action,
  ) {
    final key = action.nodeId;
    switch (action.nodeType) {
      case PhysicalEntityType.taste:
        final updatedMap = Map<String, double>.from(preference.tastePreferences);
        final oldWeight = updatedMap[key] ?? 0.0;
        updatedMap[key] = (oldWeight + action.weightDelta).clamp(-10.0, 10.0);
        return preference.copyWith(
          tastePreferences: updatedMap,
          lastUpdated: action.timestamp,
        );
      case PhysicalEntityType.cuisine:
        final updatedMap = Map<String, double>.from(preference.cuisinePreferences);
        final oldWeight = updatedMap[key] ?? 0.0;
        updatedMap[key] = (oldWeight + action.weightDelta).clamp(-10.0, 10.0);
        return preference.copyWith(
          cuisinePreferences: updatedMap,
          lastUpdated: action.timestamp,
        );
      default:
        final updatedMap = Map<String, double>.from(preference.bubbleWeights);
        final oldWeight = updatedMap[key] ?? 0.0;
        updatedMap[key] = (oldWeight + action.weightDelta).clamp(-10.0, 10.0);
        return preference.copyWith(
          bubbleWeights: updatedMap,
          lastUpdated: action.timestamp,
        );
    }
  }
}
