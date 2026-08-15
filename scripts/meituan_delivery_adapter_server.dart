import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'meituan_oauth_service.dart';
import 'meituan_oauth_store.dart';

Future<void> main(List<String> args) async {
  final config = MeituanDeliveryAdapterConfig.fromEnvironment(
    Platform.environment,
    args: args,
  );
  final server = MeituanDeliveryAdapterServer(config);
  final httpServer = await server.start();

  stdout
    ..writeln(
      'Meituan delivery adapter listening on '
      'http://${httpServer.address.address}:${httpServer.port}',
    )
    ..writeln('POST /delivery-match')
    ..writeln('POST /merchants/search')
    ..writeln('POST /products/search')
    ..writeln('POST /order-previews')
    ..writeln('POST /orders')
    ..writeln('GET  /oauth/status')
    ..writeln('POST /oauth/authorize')
    ..writeln('GET  /oauth/callback');

  ProcessSignal.sigint.watch().listen((_) async {
    await httpServer.close(force: true);
    server.close();
    exit(0);
  });
}

class MeituanDeliveryAdapterServer {
  MeituanDeliveryAdapterServer(
    this.config, {
    MeituanDeliveryAdapter? adapter,
    MeituanOAuthService? oauthService,
  })  : oauthService = oauthService ?? _oauthService(config),
        adapter = adapter ?? MeituanDeliveryAdapter(config);

  final MeituanDeliveryAdapterConfig config;
  final MeituanDeliveryAdapter adapter;
  final MeituanOAuthService oauthService;

  Future<HttpServer> start() async {
    final server = await HttpServer.bind(config.bindAddress, config.port);
    server.listen((request) {
      unawaited(_handle(request));
    });
    return server;
  }

  void close() {
    adapter.close();
    oauthService.close();
  }

  Future<void> _handle(HttpRequest request) async {
    if (request.method == 'GET' && request.uri.path == '/health') {
      await _writeJson(request.response, HttpStatus.ok, {
        'status': 'ok',
        'configured': config.isConfigured,
        'orderEnabled': config.orderEnabled,
      });
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/oauth/callback') {
      await _handleOAuthCallback(request);
      return;
    }

    if (!_isAuthorized(request)) {
      await _writeError(
        request.response,
        HttpStatus.unauthorized,
        'unauthorized',
        '美团点餐适配器鉴权失败',
      );
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/oauth/status') {
      await _handleOAuthStatus(request);
      return;
    }

    if (request.method != 'POST') {
      await _writeError(
        request.response,
        HttpStatus.methodNotAllowed,
        'method_not_allowed',
        '该路由仅支持 POST',
      );
      return;
    }

    if (request.uri.path == '/oauth/authorize') {
      await _handleOAuthAuthorize(request);
      return;
    }

    if (!config.isConfigured) {
      await _writeError(
        request.response,
        HttpStatus.serviceUnavailable,
        'adapter_not_configured',
        '缺少美团 AppID、AppSecret 或用户 OAuth 凭证',
      );
      return;
    }

    final body = await _readJsonBody(request);
    if (body == null) {
      await _writeError(
        request.response,
        HttpStatus.badRequest,
        'invalid_json',
        '请求体必须是 JSON 对象',
      );
      return;
    }

    try {
      final userId = _eatWhatUserId(request);
      if (userId == null) {
        await _writeMissingUserIdentity(request.response);
        return;
      }
      final credential = await _credentialForRequest(userId);
      final scopedAdapter = adapter.withCredential(credential);
      try {
        final result = switch (request.uri.path) {
          '/delivery-match' => await scopedAdapter.match(body),
          '/merchants/search' => await scopedAdapter.searchMerchants(body),
          '/products/search' => await scopedAdapter.searchProducts(body),
          '/order-previews' => await scopedAdapter.previewOrder(body),
          '/orders' => await scopedAdapter.submitOrder(body),
          _ => null,
        };

        if (result == null) {
          await _writeError(
            request.response,
            HttpStatus.notFound,
            'route_not_found',
            '美团点餐适配器路由不存在',
          );
          return;
        }
        await _writeJson(request.response, HttpStatus.ok, result);
      } finally {
        scopedAdapter.close();
      }
    } on MeituanRequestException catch (error) {
      await _writeError(
        request.response,
        HttpStatus.unprocessableEntity,
        'validation_error',
        error.message,
      );
    } on MeituanOpenApiException catch (error) {
      await _writeError(
        request.response,
        HttpStatus.badGateway,
        error.code,
        error.message,
        details: {
          if (error.failCode != null) 'failCode': error.failCode,
          if (error.name != null) 'name': error.name,
        },
      );
    } on MeituanOAuthException catch (error) {
      await _writeError(
        request.response,
        HttpStatus.unauthorized,
        error.code,
        error.message,
      );
    }
  }

  Future<void> _handleOAuthStatus(HttpRequest request) async {
    final userId = _eatWhatUserId(request);
    if (userId == null) {
      await _writeMissingUserIdentity(request.response);
      return;
    }
    final credential = await oauthService.credentialFor(userId);
    await _writeJson(request.response, HttpStatus.ok, {
      'connected': credential != null,
      'requiresUserAuthorization': true,
      if (credential?.nickname?.isNotEmpty == true)
        'nickname': credential!.nickname,
      if (credential?.maskedPhone?.isNotEmpty == true)
        'maskedPhone': credential!.maskedPhone,
    });
  }

  Future<void> _handleOAuthAuthorize(HttpRequest request) async {
    final userId = _eatWhatUserId(request);
    if (userId == null) {
      await _writeMissingUserIdentity(request.response);
      return;
    }
    if (!config.oauthConfig.isConfigured) {
      await _writeError(
        request.response,
        HttpStatus.serviceUnavailable,
        'meituan_oauth_not_configured',
        '吃什么服务端尚未配置美团 OAuth 回调地址',
      );
      return;
    }
    await _readJsonBody(request);
    final authorizationUri = oauthService.createAuthorizationUri(userId);
    await _writeJson(request.response, HttpStatus.ok, {
      'authorizationUrl': authorizationUri.toString(),
    });
  }

  Future<void> _handleOAuthCallback(HttpRequest request) async {
    final code = request.uri.queryParameters['code'] ?? '';
    final state = request.uri.queryParameters['state'] ?? '';
    try {
      await oauthService.completeAuthorization(code: code, state: state);
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(_oauthCallbackHtml(success: true));
    } on MeituanOAuthException catch (error) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.html
        ..write(_oauthCallbackHtml(success: false, message: error.message));
    }
    await request.response.close();
  }

  Future<MeituanOAuthCredential> _credentialForRequest(String userId) async {
    final credential = await oauthService.credentialFor(userId);
    if (credential != null) return credential;
    if (config.accessToken.isNotEmpty || config.openId.isNotEmpty) {
      return MeituanOAuthCredential(
        accessToken: config.accessToken,
        refreshToken: '',
        openId: config.openId,
        expiresAt: DateTime.now().add(const Duration(days: 3650)),
      );
    }
    throw const MeituanOAuthException(
      'meituan_oauth_required',
      '首次点单需要授权吃什么调用美团配送服务',
    );
  }

  bool _isAuthorized(HttpRequest request) {
    if (config.requiredToken.isEmpty) return true;
    return request.headers.value(HttpHeaders.authorizationHeader) ==
        'Bearer ${config.requiredToken}';
  }

  String? _eatWhatUserId(HttpRequest request) {
    final value = request.headers.value('x-eatwhat-user-id')?.trim() ?? '';
    if (value.isNotEmpty) return value;
    if (config.allowLocalUserFallback) return config.localUserId;
    return null;
  }

  Future<void> _writeMissingUserIdentity(HttpResponse response) {
    return _writeError(
      response,
      HttpStatus.unauthorized,
      'eatwhat_user_required',
      '请先登录吃什么账号',
    );
  }
}

class MeituanDeliveryAdapter {
  MeituanDeliveryAdapter(
    this.config, {
    MeituanOpenApiClient? client,
  }) : client = client ?? MeituanOpenApiClient(config);

  final MeituanDeliveryAdapterConfig config;
  final MeituanOpenApiClient client;

  static const _reviewLatitude = 29.735952;
  static const _reviewLongitude = 95.369826;

  MeituanDeliveryAdapter withCredential(MeituanOAuthCredential credential) {
    final scopedConfig = config.copyWith(
      accessToken: credential.accessToken,
      openId: credential.openId,
    );
    return MeituanDeliveryAdapter(scopedConfig);
  }

  Future<Map<String, dynamic>> match(Map<String, dynamic> body) async {
    final response = await searchMerchants({
      'keyword': body['dishName'],
      'geo': body['geo'],
      'limit': body['limit'],
    });
    final merchants = (response['merchants'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();

    return {
      'status': merchants.isEmpty ? 'partial' : 'available',
      'providerState': {
        'platform': 'meituan',
        'displayName': '美团外卖',
        'supportsMerchantSearch': true,
        'supportsDishSearch': true,
        'supportsOrderPreview': config.orderEnabled,
        'supportsOrderSubmit': config.orderEnabled,
      },
      'matches': merchants.map((merchant) {
        final products = (merchant['products'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>();
        final product = products.isEmpty ? null : products.first;
        return {
          'merchantId': merchant['merchantId'],
          'merchantName': merchant['merchantName'],
          'dishName': product?['name'] ?? body['dishName'],
          'productId': product?['productId'],
          'price': product?['price'],
          'deliveryTimeMinutes': merchant['deliveryTimeMinutes'],
          'appUrl': merchant['appUrl'],
          'supportsPrefillCart': false,
          'source': 'meituan_open_api',
          'linkTarget': 'app',
          'capabilityReason': config.orderEnabled
              ? '已开通消费者点餐接口，可在 EatWhat 选择 SKU 后创建订单'
              : '当前仅返回真实门店和菜品；订单接口仍待美团审核开通',
        };
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> searchMerchants(
    Map<String, dynamic> body,
  ) async {
    final geo = _requestGeo(body);
    final limit = _limit(body['limit'] ?? body['pageSize']);
    final keyword = (body['keyword'] ?? body['dishName'] ?? '').toString();
    final payload = await client.post('/openapi/v1/poilist', {
      'longitude': _coordinate(geo.longitude),
      'latitude': _coordinate(geo.latitude),
      if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      'page_index': '${body['pageIndex'] ?? 1}',
      'page_size': '$limit',
    });
    final data = _data(payload);
    final merchants = _maps(data['openPoiBaseInfoList']).map((merchant) {
      return {
        'merchantId': '${merchant['wm_poi_id'] ?? ''}',
        'merchantName': '${merchant['name'] ?? ''}',
        'status': merchant['status'],
        'statusDescription': merchant['status_desc'],
        'imageUrl': merchant['pic_url'],
        'shippingFee': merchant['shipping_fee'],
        'minimumOrder': merchant['min_price'],
        'rating': merchant['wm_poi_score'],
        'deliveryTimeMinutes': merchant['avg_delivery_time'],
        'distance': merchant['distance'],
        'address': merchant['address'],
        'appUrl': _firstString(merchant, const ['wm_scheme', 'scheme']),
        'products': _maps(merchant['product_list'])
            .map(
              (product) => {
                'productId': '${product['id'] ?? ''}',
                'name': '${product['name'] ?? ''}',
                'price': product['price'],
                'imageUrl': product['picture'],
              },
            )
            .toList(),
      };
    }).toList();

    return {
      'status': merchants.isEmpty ? 'partial' : 'available',
      'merchants': merchants,
      'page': data['current_page_index'],
      'pageSize': data['page_size'],
      'hasNextPage': data['have_next_page'] == 1,
      'total': data['poi_total_num'],
    };
  }

  Future<Map<String, dynamic>> searchProducts(
    Map<String, dynamic> body,
  ) async {
    final geo = _requestGeo(body);
    final merchantId = _requiredString(body, 'merchantId');
    final keyword = (body['keyword'] ?? '').toString().trim().toLowerCase();
    final payload = await client.post('/openapi/v1/poi/food', {
      'longitude': _coordinate(geo.longitude),
      'latitude': _coordinate(geo.latitude),
      'wm_poi_id': merchantId,
    });
    final data = _data(payload);
    final products = <Map<String, dynamic>>[];

    for (final category in _maps(data['food_spu_tags'])) {
      for (final product in _maps(category['spus'])) {
        final name = '${product['name'] ?? ''}';
        if (keyword.isNotEmpty && !name.toLowerCase().contains(keyword)) {
          continue;
        }
        products.add({
          'productId': '${product['id'] ?? ''}',
          'name': name,
          'description': product['description'],
          'imageUrl': product['picture'],
          'minimumPrice': product['min_price'],
          'monthlySales': product['month_saled'],
          'status': product['status'],
          'categoryId': category['tag'],
          'categoryName': category['name'],
          'attributes': product['attrs'] ?? const [],
          'skus': _maps(product['skus'])
              .map(
                (sku) => {
                  'skuId': '${sku['id'] ?? ''}',
                  'specification': sku['spec'],
                  'price': sku['price'],
                  'originalPrice': sku['origin_price'],
                  'boxPrice': sku['box_price'],
                  'minimumOrderCount': sku['min_order_count'],
                  'stock': sku['stock'],
                  'status': sku['status'],
                },
              )
              .toList(),
        });
      }
    }

    final poi = _map(data['poi_info']);
    return {
      'status': products.isEmpty ? 'partial' : 'available',
      'merchant': {
        'merchantId': '${poi['wm_poi_id'] ?? merchantId}',
        'merchantName': '${poi['name'] ?? ''}',
        'status': poi['status'],
        'shippingFee': poi['shipping_fee'],
        'minimumOrder': poi['min_price'],
        'deliveryTimeMinutes': poi['avg_delivery_time'],
        'supportsOnlinePayment': poi['support_pay'] == 1,
      },
      'products': products,
    };
  }

  Future<Map<String, dynamic>> previewOrder(
    Map<String, dynamic> body,
  ) async {
    _ensureOrderingEnabled();
    final payload = await client.post('/openapi/v1/order/preview', {
      'payload': jsonEncode(_orderPayload(body)),
    });
    final data = _data(payload);
    final businessCode = _asInt(data['code']);
    if (businessCode != 0) {
      throw MeituanOpenApiException.fromPayload(
        data,
        fallbackMessage: '美团订单预览失败',
      );
    }
    final preview = _map(data['wm_ordering_preview_order_vo']);
    return {
      'status': 'available',
      'previewToken': '${data['token'] ?? ''}',
      'preview': {
        'merchantId': '${preview['wm_poi_id'] ?? ''}',
        'merchantName': '${preview['poi_name'] ?? ''}',
        'recipientName': preview['recipient_name'],
        'recipientPhone': preview['recipient_phone'],
        'recipientAddress': preview['recipient_address'],
        'shippingFee': preview['shipping_fee'],
        'boxFee': preview['box_total_price'],
        'total': preview['total'],
        'originalPrice': preview['original_price'],
        'estimatedArrivalTime': preview['estimate_arrival_time'],
        'items': data['wm_ordering_preview_detail_vo_list'] ?? const [],
        'discounts': data['discounts'] ?? const [],
      },
    };
  }

  Future<Map<String, dynamic>> submitOrder(
    Map<String, dynamic> body,
  ) async {
    _ensureOrderingEnabled();
    final previewToken = _requiredString(body, 'previewToken');
    final orderPayload = _orderPayload(body)
      ..['pay_source'] = 3
      ..['token'] = previewToken;
    final verifyCode = body['verifyCode']?.toString().trim() ?? '';
    if (verifyCode.isNotEmpty) orderPayload['verify_code'] = verifyCode;

    final payload = await client.post('/openapi/v1/order/submit', {
      'payload': jsonEncode(orderPayload),
    });
    final errorInfo = _map(payload['errorInfo']);
    if (_asInt(errorInfo['failCode']) == 13001) {
      return {
        'status': 'verification_required',
        'requiresVerification': true,
        'message': payload['msg'] ?? '请输入美团发送的验证码',
      };
    }
    if (errorInfo.isNotEmpty) {
      throw MeituanOpenApiException.fromPayload(
        payload,
        fallbackMessage: '美团提交订单失败',
      );
    }

    final data = _data(payload);
    final businessCode = _asInt(data['code']);
    if (businessCode != 0) {
      throw MeituanOpenApiException.fromPayload(
        data,
        fallbackMessage:
            data['msg']?.toString() ?? payload['msg']?.toString() ?? '美团提交订单失败',
      );
    }

    final rawPaymentUrl = '${data['payUrl'] ?? ''}';
    return {
      'status': 'payment_required',
      'orderId': '${data['order_id'] ?? ''}',
      'paymentUrl': _paymentUrl(
        rawPaymentUrl,
        successUrl: body['paymentSuccessUrl']?.toString(),
        failureUrl: body['paymentFailureUrl']?.toString(),
      ),
      'requiresVerification': false,
    };
  }

  Map<String, dynamic> _orderPayload(Map<String, dynamic> body) {
    final merchantId = _requiredString(body, 'merchantId');
    final rawItems = body['items'];
    if (rawItems is! List || rawItems.isEmpty) {
      throw const MeituanRequestException('items 不能为空');
    }
    final items = rawItems.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final skuId = _requiredString(item, 'skuId');
      final count = _asInt(item['count']);
      if (count < 1) {
        throw const MeituanRequestException('商品 count 必须大于 0');
      }
      return {
        'wm_food_sku_id': skuId,
        'count': count,
        if (item['attributeIds'] is List)
          'food_spu_attr_ids': item['attributeIds'],
      };
    }).toList();

    final recipient = _map(body['recipient']);
    final addressId = body['addressId'];
    if (addressId == null && recipient.isEmpty) {
      throw const MeituanRequestException('addressId 和 recipient 至少提供一个');
    }

    return {
      'wm_ordering_list': {
        'wm_poi_id': merchantId,
        'delivery_time': _asInt(body['deliveryTime']),
        'pay_type': 2,
        'food_list': items,
      },
      'wm_ordering_user': {
        if (recipient['currentLatitude'] != null)
          'user_latitude': _coordinateNumber(recipient['currentLatitude']),
        if (recipient['currentLongitude'] != null)
          'user_longitude': _coordinateNumber(recipient['currentLongitude']),
        if (recipient['name'] != null) 'user_name': recipient['name'],
        if (recipient['phone'] != null) 'user_phone': recipient['phone'],
        if (recipient['address'] != null) 'user_address': recipient['address'],
        if (recipient['addressLatitude'] != null)
          'addr_latitude': _coordinateNumber(recipient['addressLatitude']),
        if (recipient['addressLongitude'] != null)
          'addr_longitude': _coordinateNumber(recipient['addressLongitude']),
        if (recipient['houseNumber'] != null)
          'house_number': recipient['houseNumber'],
        if (recipient['note'] != null) 'user_caution': recipient['note'],
      },
      if (addressId != null) 'address_id': addressId,
    };
  }

  void _ensureOrderingEnabled() {
    if (!config.orderEnabled) {
      throw const MeituanRequestException('美团消费者下单权限尚未开通');
    }
  }

  _Geo _requestGeo(Map<String, dynamic> body) {
    if (config.reviewMode) {
      return const _Geo(_reviewLatitude, _reviewLongitude);
    }
    return _geo(body);
  }

  void close() => client.close();
}

class MeituanOpenApiClient {
  MeituanOpenApiClient(
    this.config, {
    HttpClient? httpClient,
    DateTime Function()? now,
  })  : _httpClient = httpClient ?? HttpClient(),
        _now = now ?? DateTime.now;

  final MeituanDeliveryAdapterConfig config;
  final HttpClient _httpClient;
  final DateTime Function() _now;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, String> businessParameters,
  ) async {
    final endpoint = config.apiBaseUrl.resolve(path);
    final authParameters = <String, String>{
      'app_id': config.appId,
      'timestamp': '${_now().millisecondsSinceEpoch ~/ 1000}',
      if (config.accessToken.isNotEmpty) 'access_token': config.accessToken,
      if (config.accessToken.isEmpty && config.openId.isNotEmpty)
        'open_id': config.openId,
    };
    final signingParameters = <String, String>{
      ...authParameters,
      ...businessParameters,
    };
    authParameters['sign'] = MeituanOpenApiSigner.sign(
      endpoint: endpoint,
      parameters: signingParameters,
      secret: config.appSecret,
    );
    final requestUri = endpoint.replace(queryParameters: authParameters);

    try {
      final request =
          await _httpClient.postUrl(requestUri).timeout(config.upstreamTimeout);
      request.headers
        ..contentType = ContentType(
          'application',
          'x-www-form-urlencoded',
          charset: 'utf-8',
        )
        ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.write(Uri(queryParameters: businessParameters).query);
      final response = await request.close().timeout(config.upstreamTimeout);
      final raw = await utf8.decoder
          .bind(response)
          .join()
          .timeout(config.upstreamTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw MeituanOpenApiException(
          '美团接口 HTTP ${response.statusCode}',
        );
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const MeituanOpenApiException('美团接口返回格式错误');
      }
      return Map<String, dynamic>.from(decoded);
    } on TimeoutException {
      throw const MeituanOpenApiException('美团接口响应超时');
    } on FormatException {
      throw const MeituanOpenApiException('美团接口返回格式错误');
    }
  }

  void close() => _httpClient.close(force: true);
}

class MeituanOpenApiSigner {
  static String sign({
    required Uri endpoint,
    required Map<String, String> parameters,
    required String secret,
  }) {
    final keys = parameters.keys.where((key) => key != 'sign').toList()..sort();
    final query = keys.map((key) => '$key=${parameters[key]}').join('&');
    final source = '${endpoint.toString()}?$query$secret';
    return md5.convert(utf8.encode(source)).toString();
  }
}

class MeituanDeliveryAdapterConfig {
  const MeituanDeliveryAdapterConfig({
    required this.bindAddress,
    required this.port,
    required this.requiredToken,
    required this.appId,
    required this.appSecret,
    required this.accessToken,
    required this.openId,
    required this.orderEnabled,
    required this.apiBaseUrl,
    required this.upstreamTimeout,
    required this.oauthRedirectUri,
    this.oauthStorePath = '.dart_tool/eatwhat/meituan_oauth.json',
    this.reviewMode = false,
    this.allowLocalUserFallback = false,
    this.localUserId = 'local-eatwhat-user',
  });

  factory MeituanDeliveryAdapterConfig.fromEnvironment(
    Map<String, String> environment, {
    List<String> args = const [],
  }) {
    return MeituanDeliveryAdapterConfig(
      bindAddress: InternetAddress.tryParse(
            environment['MEITUAN_DELIVERY_ADAPTER_BIND_ADDRESS'] ?? '',
          ) ??
          InternetAddress.loopbackIPv4,
      port: args.isNotEmpty
          ? int.tryParse(args.first) ?? 8788
          : int.tryParse(
                environment['MEITUAN_DELIVERY_ADAPTER_PORT'] ?? '',
              ) ??
              8788,
      requiredToken:
          environment['MEITUAN_DELIVERY_ADAPTER_REQUIRED_TOKEN']?.trim() ?? '',
      appId: environment['MEITUAN_OPEN_APP_ID']?.trim() ?? '',
      appSecret: environment['MEITUAN_OPEN_APP_SECRET']?.trim() ?? '',
      accessToken: environment['MEITUAN_OPEN_ACCESS_TOKEN']?.trim() ?? '',
      openId: environment['MEITUAN_OPEN_ID']?.trim() ?? '',
      orderEnabled:
          environment['MEITUAN_OPEN_ORDER_ENABLED']?.toLowerCase() == 'true',
      apiBaseUrl: Uri.parse(
        environment['MEITUAN_OPEN_API_BASE_URL']?.trim().isNotEmpty == true
            ? environment['MEITUAN_OPEN_API_BASE_URL']!.trim()
            : 'https://openapi.waimai.meituan.com',
      ),
      upstreamTimeout: Duration(
        milliseconds: int.tryParse(
              environment['MEITUAN_OPEN_UPSTREAM_TIMEOUT_MS'] ?? '',
            ) ??
            6000,
      ),
      oauthRedirectUri: Uri.tryParse(
            environment['MEITUAN_OAUTH_REDIRECT_URL']?.trim() ?? '',
          ) ??
          Uri(),
      oauthStorePath:
          environment['MEITUAN_OAUTH_STORE_PATH']?.trim().isNotEmpty == true
              ? environment['MEITUAN_OAUTH_STORE_PATH']!.trim()
              : '.dart_tool/eatwhat/meituan_oauth.json',
      reviewMode:
          environment['MEITUAN_OPEN_REVIEW_MODE']?.toLowerCase() == 'true',
      allowLocalUserFallback:
          environment['MEITUAN_ALLOW_LOCAL_USER_FALLBACK']?.toLowerCase() ==
              'true',
      localUserId:
          environment['MEITUAN_LOCAL_USER_ID']?.trim().isNotEmpty == true
              ? environment['MEITUAN_LOCAL_USER_ID']!.trim()
              : 'local-eatwhat-user',
    );
  }

  final InternetAddress bindAddress;
  final int port;
  final String requiredToken;
  final String appId;
  final String appSecret;
  final String accessToken;
  final String openId;
  final bool orderEnabled;
  final Uri apiBaseUrl;
  final Duration upstreamTimeout;
  final Uri oauthRedirectUri;
  final String oauthStorePath;
  final bool reviewMode;
  final bool allowLocalUserFallback;
  final String localUserId;

  MeituanOAuthConfig get oauthConfig => MeituanOAuthConfig(
        appId: appId,
        appSecret: appSecret,
        redirectUri: oauthRedirectUri,
        apiBaseUrl: apiBaseUrl,
        timeout: upstreamTimeout,
      );

  MeituanDeliveryAdapterConfig copyWith({
    String? accessToken,
    String? openId,
  }) {
    return MeituanDeliveryAdapterConfig(
      bindAddress: bindAddress,
      port: port,
      requiredToken: requiredToken,
      appId: appId,
      appSecret: appSecret,
      accessToken: accessToken ?? this.accessToken,
      openId: openId ?? this.openId,
      orderEnabled: orderEnabled,
      apiBaseUrl: apiBaseUrl,
      upstreamTimeout: upstreamTimeout,
      oauthRedirectUri: oauthRedirectUri,
      oauthStorePath: oauthStorePath,
      reviewMode: reviewMode,
      allowLocalUserFallback: allowLocalUserFallback,
      localUserId: localUserId,
    );
  }

  bool get isConfigured => appId.isNotEmpty && appSecret.isNotEmpty;
}

MeituanOAuthService _oauthService(MeituanDeliveryAdapterConfig config) {
  return MeituanOAuthService(
    config.oauthConfig,
    FileMeituanOAuthStore(config.oauthStorePath),
  );
}

String _oauthCallbackHtml({required bool success, String? message}) {
  final title = success ? '美团服务绑定成功' : '美团服务绑定失败';
  final detail =
      success ? '已经绑定到你的吃什么账号，可以返回 App 继续点单。' : (message ?? '请返回吃什么后重试。');
  return '<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width,initial-scale=1">'
      '<title>$title</title></head><body style="font-family:-apple-system;'
      'padding:32px"><h1>$title</h1><p>$detail</p></body></html>';
}

class _Geo {
  const _Geo(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class MeituanRequestException implements Exception {
  const MeituanRequestException(this.message);

  final String message;
}

class MeituanOpenApiException implements Exception {
  const MeituanOpenApiException(
    this.message, {
    this.code = 'meituan_open_api_error',
    this.failCode,
    this.name,
  });

  factory MeituanOpenApiException.fromPayload(
    Map<String, dynamic> payload, {
    required String fallbackMessage,
  }) {
    final errorInfo = _map(payload['errorInfo']);
    final failCode = _nullableInt(errorInfo['failCode']) ??
        (_asInt(payload['code']) == 0 ? null : _asInt(payload['code']));
    final name = errorInfo['name']?.toString().trim();
    final message = (name?.isNotEmpty == true ? name : null) ??
        payload['msg']?.toString() ??
        fallbackMessage;
    final normalizedMessage = message.toLowerCase();
    final code = failCode == 1 ||
            normalizedMessage.contains('无权访问') ||
            normalizedMessage.contains('permission denied')
        ? 'meituan_permission_denied'
        : switch (failCode) {
            401 || 40101 || 40102 => 'meituan_oauth_invalid',
            _ => 'meituan_open_api_error',
          };
    return MeituanOpenApiException(
      failCode == null ? message : '$message (failCode: $failCode)',
      code: code,
      failCode: failCode,
      name: name?.isEmpty == true ? null : name,
    );
  }

  final String message;
  final String code;
  final int? failCode;
  final String? name;
}

_Geo _geo(Map<String, dynamic> body) {
  final geo = _map(body['geo']);
  final latitude = _asDouble(geo['latitude']);
  final longitude = _asDouble(geo['longitude']);
  if (latitude == null || longitude == null) {
    throw const MeituanRequestException('geo.latitude 和 geo.longitude 必填');
  }
  return _Geo(latitude, longitude);
}

int _limit(dynamic value) {
  final parsed = _asInt(value);
  if (parsed <= 0) return 10;
  return parsed.clamp(1, 20);
}

String _coordinate(double value) => '${(value * 1000000).round()}';

int _coordinateNumber(dynamic value) {
  final parsed = _asDouble(value);
  if (parsed == null) {
    throw const MeituanRequestException('经纬度格式不正确');
  }
  return (parsed.abs() <= 180 ? parsed * 1000000 : parsed).round();
}

String _requiredString(Map<String, dynamic> body, String key) {
  final value = body[key]?.toString().trim() ?? '';
  if (value.isEmpty) throw MeituanRequestException('$key 不能为空');
  return value;
}

Map<String, dynamic> _data(Map<String, dynamic> payload) {
  if (_asInt(payload['code']) != 0) {
    throw MeituanOpenApiException.fromPayload(
      payload,
      fallbackMessage: '美团接口调用失败',
    );
  }
  return _map(payload['data']);
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

Iterable<Map<String, dynamic>> _maps(dynamic value) sync* {
  if (value is! List) return;
  for (final item in value) {
    if (item is Map) yield Map<String, dynamic>.from(item);
  }
}

String _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

String _paymentUrl(
  String raw, {
  String? successUrl,
  String? failureUrl,
}) {
  final uri = Uri.tryParse(raw);
  if (uri == null || raw.isEmpty) return raw;
  final query = Map<String, String>.from(uri.queryParameters);
  if (successUrl?.trim().isNotEmpty == true) {
    query['pay_success_url'] = successUrl!.trim();
  }
  if (failureUrl?.trim().isNotEmpty == true) {
    query['redr_url'] = failureUrl!.trim();
  }
  return uri.replace(queryParameters: query).toString();
}

Future<Map<String, dynamic>?> _readJsonBody(HttpRequest request) async {
  try {
    final decoded = jsonDecode(await utf8.decoder.bind(request).join());
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  } on FormatException {
    return null;
  }
}

Future<void> _writeError(
  HttpResponse response,
  int statusCode,
  String code,
  String message, {
  Map<String, dynamic> details = const {},
}) {
  return _writeJson(response, statusCode, {
    'error': {
      'code': code,
      'message': message,
      if (details.isNotEmpty) 'details': details,
    },
  });
}

Future<void> _writeJson(
  HttpResponse response,
  int statusCode,
  Map<String, dynamic> payload,
) async {
  response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(payload));
  await response.close();
}
