import 'package:eatwhat_app/core/contracts/alipay_payment_contract.dart';
import 'package:eatwhat_app/core/contracts/auth_session_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSessionResponse', () {
    const fixture = <String, dynamic>{
      'accessToken': 'header.payload.signature',
      'expiresAt': '2026-10-24T12:34:56.789Z',
      'user': <String, dynamic>{
        'id': 'user-1',
        'username': 'eatwhat_user',
        'email': 'user@eatwhat.test',
      },
    };

    test('parses and serializes the exact session JSON fields', () {
      final response = AuthSessionResponse.tryParse(fixture);

      expect(response, isNotNull);
      expect(response!.accessToken, 'header.payload.signature');
      expect(response.expiresAt, DateTime.utc(2026, 10, 24, 12, 34, 56, 789));
      expect(response.user, fixture['user']);
      expect(response.toJson(), fixture);
    });

    test('tryParse rejects malformed session payloads', () {
      final invalidPayloads = <dynamic>[
        'not-a-map',
        <String, dynamic>{...fixture, 'accessToken': ''},
        <String, dynamic>{...fixture}..remove('expiresAt'),
        <String, dynamic>{...fixture, 'expiresAt': 'not-a-date'},
        <String, dynamic>{...fixture, 'user': 'not-a-map'},
      ];

      for (final payload in invalidPayloads) {
        expect(
          AuthSessionResponse.tryParse(payload),
          isNull,
          reason: '$payload',
        );
      }
    });
  });

  group('AlipayPaymentOrderRequest', () {
    test('parses and serializes plan and local-development userId', () {
      const fixture = <String, dynamic>{
        'plan': 'yearly',
        'userId': 'local-user-42',
      };

      final request = AlipayPaymentOrderRequest.fromJson(fixture);

      expect(request.plan, 'yearly');
      expect(request.userId, 'local-user-42');
      expect(request.toJson(), fixture);
    });

    test('omits an absent userId without adding a null field', () {
      final request = AlipayPaymentOrderRequest.fromJson(
        const <String, dynamic>{'plan': 'yearly'},
      );

      expect(request.userId, isNull);
      expect(request.toJson(), const <String, dynamic>{'plan': 'yearly'});
      expect(request.toJson().containsKey('userId'), isFalse);
    });

    test('preserves raw plan semantics without trimming', () {
      final request = AlipayPaymentOrderRequest.fromJson(
        const <String, dynamic>{'plan': ' yearly '},
      );

      expect(request.plan, ' yearly ');
      expect(request.toJson(), const <String, dynamic>{'plan': ' yearly '});
    });
  });

  test('AlipayPaymentOrderResponse uses the exact order JSON fields', () {
    const fixture = <String, dynamic>{
      'status': 'payment_required',
      'orderId': 'EW202610240001',
      'plan': 'yearly',
      'payUrl': 'https://pay.test/cashier?out_trade_no=EW202610240001',
    };

    final response = AlipayPaymentOrderResponse.fromJson(fixture);

    expect(response.status, 'payment_required');
    expect(response.orderId, 'EW202610240001');
    expect(response.plan, 'yearly');
    expect(
      response.payUrl,
      'https://pay.test/cashier?out_trade_no=EW202610240001',
    );
    expect(response.toJson(), fixture);
  });

  group('AlipayPaymentStatusResponse', () {
    test('pending status omits membershipCredential', () {
      const fixture = <String, dynamic>{
        'status': 'pending',
        'orderId': 'EW202610240001',
      };

      final response = AlipayPaymentStatusResponse.fromJson(fixture);

      expect(response.status, 'pending');
      expect(response.orderId, 'EW202610240001');
      expect(response.membershipCredential, isNull);
      expect(response.toJson(), fixture);
      expect(response.toJson().containsKey('membershipCredential'), isFalse);
    });

    test('paid status round-trips membershipCredential', () {
      const fixture = <String, dynamic>{
        'status': 'paid',
        'orderId': 'EW202610240001',
        'membershipCredential': <String, dynamic>{
          'userId': 'user-1',
          'orderId': 'EW202610240001',
          'issuedAt': 1792835696789,
          'expiresAt': 1824371696789,
          'signature': 'c2lnbmF0dXJl',
        },
      };

      final response = AlipayPaymentStatusResponse.fromJson(fixture);

      expect(response.status, 'paid');
      expect(response.orderId, 'EW202610240001');
      expect(response.membershipCredential, fixture['membershipCredential']);
      expect(response.toJson(), fixture);
    });
  });
}
