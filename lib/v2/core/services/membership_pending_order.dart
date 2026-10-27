import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 已创建但尚未确认支付的会员订单。收银台在外部页面完成，轮询窗口结束后
/// 需要靠它做一次补对账，避免“付了钱但会员没生效”。
class MembershipPendingOrder {
  const MembershipPendingOrder({
    required this.orderId,
    required this.userId,
    required this.createdAt,
  });

  final String orderId;
  final String userId;
  final DateTime createdAt;

  static const Duration maxAge = Duration(hours: 24);

  bool isExpiredAt(DateTime now) => now.difference(createdAt) > maxAge;

  bool get isExpired => isExpiredAt(DateTime.now());

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'userId': userId,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  static MembershipPendingOrder? fromJson(Object? json) {
    if (json is! Map) return null;
    final orderId = json['orderId']?.toString() ?? '';
    final userId = json['userId']?.toString() ?? '';
    final createdAtMs = int.tryParse(json['createdAt']?.toString() ?? '');
    if (orderId.isEmpty || userId.isEmpty || createdAtMs == null) {
      return null;
    }
    return MembershipPendingOrder(
      orderId: orderId,
      userId: userId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }
}

class MembershipPendingOrderStore {
  const MembershipPendingOrderStore();

  static const String prefsKey = 'v2_membership_pending_order';

  Future<MembershipPendingOrder?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null) return null;
    try {
      return MembershipPendingOrder.fromJson(jsonDecode(raw));
    } catch (_) {
      await prefs.remove(prefsKey);
      return null;
    }
  }

  Future<void> save(MembershipPendingOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, jsonEncode(order.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
  }
}
