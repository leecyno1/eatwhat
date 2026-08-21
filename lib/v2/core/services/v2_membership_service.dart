import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Membership purchase flow through the execution proxy.
///
/// The proxy signs the Alipay order server-side (merchant credentials never
/// reach the client); the app opens the cashier page, then polls the paid
/// status and upgrades the local account to a full member for one year.
class V2MembershipService {
  V2MembershipService({ExecutionProxyClient? client})
      : _client = client ?? ExecutionProxyClient();

  static final V2MembershipService instance = V2MembershipService();

  final ExecutionProxyClient _client;

  static const Duration _paidPollInterval = Duration(seconds: 2);
  static const int _paidPollAttempts = 15;

  bool get isConfigured => _client.isConfigured;

  /// Creates a membership order and opens the cashier page. Returns the
  /// order id when the cashier was launched, null otherwise.
  Future<String?> createOrderAndOpenCashier({String plan = 'yearly'}) async {
    final payload = await _client.postJson(
      '/api/v1/payment/alipay/orders',
      body: {'plan': plan},
    );
    final orderId = payload['orderId']?.toString() ?? '';
    final payUrl = payload['payUrl']?.toString() ?? '';
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
    return launched ? orderId : null;
  }

  /// Polls the proxy until the order is marked paid, then upgrades the
  /// signed-in account to a full member for one year.
  Future<bool> waitForPaymentAndUpgrade(String orderId) async {
    for (var i = 0; i < _paidPollAttempts; i++) {
      await Future<void>.delayed(_paidPollInterval);
      try {
        final payload = await _client.getJson(
          '/api/v1/payment/alipay/status?orderId=$orderId',
        );
        if (payload['status'] == 'paid') {
          await _upgradeCurrentUser();
          return true;
        }
      } catch (_) {
        // Transient failures keep polling until the attempt budget runs out.
      }
    }
    return false;
  }

  Future<void> _upgradeCurrentUser() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final upgraded = user.copyWith(
      isMember: true,
      memberSince: user.memberSince ?? now,
      memberExpiresAt: now.add(const Duration(days: 365)),
    );
    await AuthService.updateCurrentUser(upgraded);
    debugPrint('[Membership] 已升级为正式会员（1 年）');
  }
}
