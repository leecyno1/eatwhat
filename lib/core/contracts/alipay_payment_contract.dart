class AlipayPaymentOrderRequest {
  const AlipayPaymentOrderRequest({
    required this.plan,
    this.userId,
  });

  factory AlipayPaymentOrderRequest.fromJson(Map<String, dynamic> json) =>
      AlipayPaymentOrderRequest(
        plan: json['plan']?.toString() ?? '',
        userId: json['userId']?.toString(),
      );

  final String plan;
  final String? userId;

  Map<String, dynamic> toJson() => {
        'plan': plan,
        if (userId != null) 'userId': userId,
      };
}

class AlipayPaymentOrderResponse {
  const AlipayPaymentOrderResponse({
    required this.status,
    required this.orderId,
    required this.plan,
    required this.payUrl,
  });

  factory AlipayPaymentOrderResponse.fromJson(Map<String, dynamic> json) =>
      AlipayPaymentOrderResponse(
        status: json['status']?.toString() ?? '',
        orderId: json['orderId']?.toString() ?? '',
        plan: json['plan']?.toString() ?? '',
        payUrl: json['payUrl']?.toString() ?? '',
      );

  final String status;
  final String orderId;
  final String plan;
  final String payUrl;

  Map<String, dynamic> toJson() => {
        'status': status,
        'orderId': orderId,
        'plan': plan,
        'payUrl': payUrl,
      };
}

class AlipayPaymentStatusResponse {
  const AlipayPaymentStatusResponse({
    required this.status,
    required this.orderId,
    this.membershipCredential,
  });

  factory AlipayPaymentStatusResponse.fromJson(Map<String, dynamic> json) =>
      AlipayPaymentStatusResponse(
        status: json['status']?.toString() ?? '',
        orderId: json['orderId']?.toString() ?? '',
        membershipCredential: json['membershipCredential'] is Map
            ? Map<String, dynamic>.from(json['membershipCredential'] as Map)
            : null,
      );

  final String status;
  final String orderId;
  final Map<String, dynamic>? membershipCredential;

  Map<String, dynamic> toJson() => {
        'status': status,
        'orderId': orderId,
        if (membershipCredential != null)
          'membershipCredential': membershipCredential,
      };
}
