import 'dart:convert';

import 'package:eatwhat_app/core/contracts/alipay_payment_contract.dart';
import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_exceptions.dart';
import 'package:eatwhat_app/v2/core/services/membership_credential.dart';
import 'package:eatwhat_app/v2/core/services/membership_pending_order.dart';
import 'package:eatwhat_app/v2/core/services/membership_verification.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Membership purchase flow through the execution proxy.
///
/// The proxy signs the Alipay order server-side (merchant credentials never
/// reach the client); the app opens the cashier page, then polls the paid
/// status and upgrades the local account to a full member for one year.
class V2MembershipService {
  V2MembershipService({
    ExecutionProxyClient? client,
    MembershipPendingOrderStore? pendingOrders,
  })  : _client = client ?? ExecutionProxyClient(),
        _pendingOrders = pendingOrders ?? const MembershipPendingOrderStore();

  static final V2MembershipService instance = V2MembershipService();

  final ExecutionProxyClient _client;
  final MembershipPendingOrderStore _pendingOrders;

  static const Duration _paidPollInterval = Duration(seconds: 2);
  static const int _paidPollAttempts = 15;

  String _statusPath(String orderId) {
    final query = Uri(queryParameters: {'orderId': orderId}).query;
    return '/api/v1/payment/alipay/status?$query';
  }

  bool get isConfigured => _client.isConfigured;

  /// 付费链路是否完整可用：代理可达 + 客户端持有验签公钥。
  /// 缺任一项都不能展示购买入口，否则会出现「扣款成功但会员不生效」。
  bool get canCompletePurchase =>
      isConfigured && MembershipVerification.hasVerificationKey();

  /// Creates a membership order and opens the cashier page. Returns the
  /// order id when the cashier was launched, null otherwise.
  Future<String?> createOrderAndOpenCashier({String plan = 'yearly'}) async {
    final payload = await _client.postJson(
      '/api/v1/payment/alipay/orders',
      body: AlipayPaymentOrderRequest(
        plan: plan,
        // 服务端签发会员凭证时绑定到这个账号；服务端应以鉴权身份为准，
        // 这里的 userId 只是本地联调（mock）通道。
        userId: AuthService.currentUser?.id,
      ).toJson(),
    );
    final order = AlipayPaymentOrderResponse.fromJson(payload);
    final orderId = order.orderId;
    final payUrl = order.payUrl;
    if (orderId.isEmpty || payUrl.isEmpty) {
      throw PlatformApiException(
        'alipay',
        '服务端没有返回可用的支付地址',
        code: 'payment_order_invalid',
      );
    }
    final uri = Uri.tryParse(payUrl);
    if (uri == null) return null;
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) return null;
    final user = AuthService.currentUser;
    if (user != null) {
      await _pendingOrders.save(
        MembershipPendingOrder(
          orderId: orderId,
          userId: user.id,
          createdAt: DateTime.now(),
        ),
      );
    }
    return orderId;
  }

  /// Polls the proxy until the order is marked paid, then verifies the
  /// server-signed membership credential before upgrading locally.
  Future<bool> waitForPaymentAndUpgrade(String orderId) async {
    for (var i = 0; i < _paidPollAttempts; i++) {
      await Future<void>.delayed(_paidPollInterval);
      try {
        final payload = AlipayPaymentStatusResponse.fromJson(
          await _client.getJson(_statusPath(orderId)),
        );
        if (payload.status == 'paid') {
          final upgraded = await _verifyAndUpgrade(payload);
          if (upgraded) {
            await _pendingOrders.clear();
          }
          return upgraded;
        }
      } catch (_) {
        // Transient failures keep polling until the attempt budget runs out.
      }
    }
    return false;
  }

  /// 收银台轮询超时后，在下次打开账号页时补一次对账。
  /// 只处理当前账号、24 小时内的待确认订单；其余情况直接清理。
  Future<bool> resumePendingPurchase() async {
    final pending = await _pendingOrders.read();
    if (pending == null) return false;
    if (pending.isExpired) {
      await _pendingOrders.clear();
      return false;
    }
    final user = AuthService.currentUser;
    // 未登录时保留记录：用户重新登录后仍可补回已支付的会员。
    if (user == null) return false;
    if (pending.userId != user.id) {
      await _pendingOrders.clear();
      return false;
    }
    try {
      final payload = AlipayPaymentStatusResponse.fromJson(
        await _client.getJson(_statusPath(pending.orderId)),
      );
      if (payload.status != 'paid') return false;
      final upgraded = await _verifyAndUpgrade(payload);
      if (upgraded) {
        await _pendingOrders.clear();
      }
      return upgraded;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _verifyAndUpgrade(AlipayPaymentStatusResponse payload) async {
    // fail closed：支付成功 ≠ 会员生效，必须拿到并验过服务端签名凭证。
    final credential = MembershipCredential.fromJson(
      payload.membershipCredential,
    );
    final user = AuthService.currentUser;
    final valid = credential != null &&
        user != null &&
        await MembershipVerification.verify(
          credential,
          expectedUserId: user.id,
        );
    if (!valid) {
      debugPrint('[Membership] 支付成功但会员凭证缺失或验签失败，拒绝本地升级');
      return false;
    }
    await _upgradeCurrentUser(credential);
    return true;
  }

  Future<void> _upgradeCurrentUser(MembershipCredential credential) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final upgraded = user.copyWith(
      isMember: true,
      memberSince: user.memberSince ?? now,
      memberExpiresAt: credential.expiresAt,
      membershipCredential: jsonEncode(credential.toJson()),
    );
    await AuthService.updateCurrentUser(upgraded);
    debugPrint('[Membership] 已升级为正式会员（凭证验签通过）');
  }
}
