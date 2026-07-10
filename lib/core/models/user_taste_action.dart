import 'package:flutter/foundation.dart';
import 'physical_entity.dart';

/// 用户味觉行为事件
class UserTasteAction {
  final String userId;
  final String nodeId; // entity id
  final PhysicalEntityType nodeType;
  final double weightDelta;
  final DateTime timestamp;

  UserTasteAction({
    required this.userId,
    required this.nodeId,
    required this.nodeType,
    required this.weightDelta,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  UserTasteAction copyWith({
    String? userId,
    String? nodeId,
    PhysicalEntityType? nodeType,
    double? weightDelta,
    DateTime? timestamp,
  }) {
    return UserTasteAction(
      userId: userId ?? this.userId,
      nodeId: nodeId ?? this.nodeId,
      nodeType: nodeType ?? this.nodeType,
      weightDelta: weightDelta ?? this.weightDelta,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'nodeId': nodeId,
        'nodeType': describeEnum(nodeType),
        'weightDelta': weightDelta,
        'timestamp': timestamp.toIso8601String(),
      };

  factory UserTasteAction.fromJson(Map<String, dynamic> json) {
    return UserTasteAction(
      userId: json['userId'] as String,
      nodeId: json['nodeId'] as String,
      nodeType: PhysicalEntityType.values.firstWhere(
        (type) => describeEnum(type) == json['nodeType'],
        orElse: () => PhysicalEntityType.taste,
      ),
      weightDelta: (json['weightDelta'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
