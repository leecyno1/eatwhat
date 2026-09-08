import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

Future<void> main(List<String> args) async {
  final config = EatWhatAuthServerConfig.fromEnvironment(
    Platform.environment,
    args: args,
  );
  final server = EatWhatAuthServer(config);
  final httpServer = await server.start();

  stdout
    ..writeln(
      'EatWhat auth server listening on '
      'http://${httpServer.address.address}:${httpServer.port}',
    )
    ..writeln('POST /api/v1/auth/register')
    ..writeln('POST /api/v1/auth/login')
    ..writeln('GET  /api/v1/auth/session');

  ProcessSignal.sigint.watch().listen((_) async {
    await httpServer.close(force: true);
    exit(0);
  });
}

class EatWhatAuthServer {
  EatWhatAuthServer(this.config)
      : _store = FileEatWhatUserStore(config.storePath);

  final EatWhatAuthServerConfig config;
  final FileEatWhatUserStore _store;

  Future<HttpServer> start() async {
    final server = await HttpServer.bind(config.bindAddress, config.port);
    server.listen((request) => unawaited(_handle(request)));
    return server;
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      if (request.method == 'GET' && request.uri.path == '/health') {
        await _writeJson(request.response, HttpStatus.ok, {'status': 'ok'});
        return;
      }

      if (request.method == 'GET' &&
          request.uri.path == '/api/v1/auth/session') {
        await _session(request);
        return;
      }

      if (request.method == 'GET' &&
          request.uri.path == '/api/v1/member/status') {
        await _memberStatus(request);
        return;
      }

      // 产品落地页（官网首页）。
      if (request.method == 'GET' &&
          (request.uri.path == '/' || request.uri.path == '/home')) {
        await _landingPage(request);
        return;
      }

      // 会员管理官网：浏览器直接打开。
      if (request.method == 'GET' && request.uri.path == '/portal') {
        await _memberPortal(request);
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

      final body = await _readJson(request);
      if (body == null) {
        await _writeError(
          request.response,
          HttpStatus.badRequest,
          'invalid_json',
          '请求体必须是 JSON 对象',
        );
        return;
      }

      switch (request.uri.path) {
        case '/api/v1/auth/register':
          await _register(request.response, body);
          return;
        case '/api/v1/auth/login':
          await _login(request.response, body);
          return;
        case '/api/v1/member/activate':
          await _memberActivate(request, body);
          return;
        default:
          await _writeError(
            request.response,
            HttpStatus.notFound,
            'route_not_found',
            '认证路由不存在',
          );
          return;
      }
    } on Object {
      try {
        await _writeError(
          request.response,
          HttpStatus.internalServerError,
          'internal_error',
          '认证服务暂时不可用',
        );
      } on Object {
        await request.response.close();
      }
    }
  }

  Future<void> _register(
    HttpResponse response,
    Map<String, dynamic> body,
  ) async {
    final username = _string(body['username']);
    final email = _string(body['email']).toLowerCase();
    final password = body['password']?.toString() ?? '';
    final nickname = _string(body['nickname']).isEmpty
        ? username
        : _string(body['nickname']);

    final validation = _validateRegistration(username, email, password);
    if (validation != null) {
      await _writeError(
        response,
        HttpStatus.unprocessableEntity,
        'validation_error',
        validation,
      );
      return;
    }

    final now = DateTime.now().toUtc();
    final user = EatWhatUser(
      id: _randomId(),
      username: username,
      email: email,
      nickname: nickname,
      passwordHash: EatWhatPasswordHasher.hash(password),
      createdAt: now,
      lastLoginAt: now,
    );
    if (!await _store.createIfAvailable(user)) {
      await _writeError(
        response,
        HttpStatus.conflict,
        'account_exists',
        '用户名或邮箱已注册',
      );
      return;
    }
    await _writeSession(response, user, HttpStatus.created);
  }

  Future<void> _login(
    HttpResponse response,
    Map<String, dynamic> body,
  ) async {
    final account = _string(body['account']).toLowerCase();
    final password = body['password']?.toString() ?? '';
    if (account.isEmpty || password.isEmpty) {
      await _writeError(
        response,
        HttpStatus.unprocessableEntity,
        'validation_error',
        '账号和密码不能为空',
      );
      return;
    }

    final current = await _store.find(account, account);
    if (current == null ||
        !EatWhatPasswordHasher.verify(password, current.passwordHash)) {
      await _writeError(
        response,
        HttpStatus.unauthorized,
        'invalid_credentials',
        '账号或密码错误',
      );
      return;
    }

    final user = current.copyWith(lastLoginAt: DateTime.now().toUtc());
    await _store.update(user);
    await _writeSession(response, user, HttpStatus.ok);
  }

  Future<void> _session(HttpRequest request) async {
    final token = _bearerToken(request);
    final userId = EatWhatJwt.verify(token, secret: config.jwtSecret);
    if (userId == null) {
      await _writeError(
        request.response,
        HttpStatus.unauthorized,
        'unauthorized',
        '吃什么登录已失效',
      );
      return;
    }
    final user = await _store.findById(userId);
    if (user == null) {
      await _writeError(
        request.response,
        HttpStatus.unauthorized,
        'unauthorized',
        '吃什么账号不存在',
      );
      return;
    }
    await _writeJson(
        request.response, HttpStatus.ok, {'user': user.publicJson});
  }

  /// 产品落地页（官网首页）。
  Future<void> _landingPage(HttpRequest request) async {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(_kLandingHtml);
    await request.response.close();
  }

  /// 会员管理官网：黑金单页，浏览器直接访问。
  Future<void> _memberPortal(HttpRequest request) async {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(_kMemberPortalHtml);
    await request.response.close();
  }

  /// 查询当前账号的会员状态（JWT 鉴权）。
  Future<void> _memberStatus(HttpRequest request) async {
    final user = await _userFromRequest(request);
    if (user == null) {
      await _writeError(
        request.response,
        HttpStatus.unauthorized,
        'unauthorized',
        '请先登录',
      );
      return;
    }
    await _writeJson(request.response, HttpStatus.ok, {
      'user': user.publicJson,
      'membership': {
        'isMember': user.isMember,
        'active': user.isMembershipActive,
        'since': user.memberSince?.toIso8601String(),
        'expiresAt': user.memberExpiresAt?.toIso8601String(),
        'daysLeft': user.membershipDaysLeft,
      },
    });
  }

  /// 开通/续费会员：默认开通一年；未到期则顺延一年。
  /// 未来接支付时，这里在支付回调确认后调用。
  Future<void> _memberActivate(
    HttpRequest request,
    Map<String, dynamic> body,
  ) async {
    final user = await _userFromRequest(request);
    if (user == null) {
      await _writeError(
        request.response,
        HttpStatus.unauthorized,
        'unauthorized',
        '请先登录',
      );
      return;
    }
    final now = DateTime.now().toUtc();
    final currentExpiry = user.memberExpiresAt;
    final base = (user.isMembershipActive && currentExpiry != null)
        ? currentExpiry
        : now;
    final updated = user.copyWith(
      isMember: true,
      memberSince: user.memberSince ?? now,
      memberExpiresAt: base.add(const Duration(days: 365)),
    );
    await _store.update(updated);
    await _writeJson(request.response, HttpStatus.ok, {
      'user': updated.publicJson,
      'membership': {
        'isMember': updated.isMember,
        'active': updated.isMembershipActive,
        'since': updated.memberSince?.toIso8601String(),
        'expiresAt': updated.memberExpiresAt?.toIso8601String(),
        'daysLeft': updated.membershipDaysLeft,
      },
    });
  }

  /// 从请求 Bearer token 解析当前用户。
  Future<EatWhatUser?> _userFromRequest(HttpRequest request) async {
    final token = _bearerToken(request);
    final userId = EatWhatJwt.verify(token, secret: config.jwtSecret);
    if (userId == null) return null;
    return _store.findById(userId);
  }

  Future<void> _writeSession(
    HttpResponse response,
    EatWhatUser user,
    int statusCode,
  ) {
    final expiresAt = DateTime.now().toUtc().add(config.tokenTtl);
    final token = EatWhatJwt.issue(
      userId: user.id,
      expiresAt: expiresAt,
      secret: config.jwtSecret,
    );
    return _writeJson(response, statusCode, {
      'accessToken': token,
      'expiresAt': expiresAt.toIso8601String(),
      'user': user.publicJson,
    });
  }
}

class EatWhatAuthServerConfig {
  const EatWhatAuthServerConfig({
    required this.bindAddress,
    required this.port,
    required this.jwtSecret,
    required this.storePath,
    this.tokenTtl = const Duration(hours: 24),
  });

  factory EatWhatAuthServerConfig.fromEnvironment(
    Map<String, String> environment, {
    List<String> args = const [],
  }) {
    final secret = environment['EATWHAT_AUTH_JWT_SECRET']?.trim() ?? '';
    if (secret.length < 32) {
      throw StateError('EATWHAT_AUTH_JWT_SECRET 至少需要 32 个字符');
    }
    return EatWhatAuthServerConfig(
      bindAddress: InternetAddress.tryParse(
            environment['EATWHAT_AUTH_BIND_ADDRESS'] ?? '',
          ) ??
          InternetAddress.loopbackIPv4,
      port: args.isNotEmpty
          ? int.tryParse(args.first) ?? 8790
          : int.tryParse(environment['EATWHAT_AUTH_PORT'] ?? '') ?? 8790,
      jwtSecret: secret,
      storePath:
          environment['EATWHAT_AUTH_STORE_PATH']?.trim().isNotEmpty == true
              ? environment['EATWHAT_AUTH_STORE_PATH']!.trim()
              : '.dart_tool/eatwhat/users.json',
      tokenTtl: Duration(
        hours:
            int.tryParse(environment['EATWHAT_AUTH_TOKEN_TTL_HOURS'] ?? '') ??
                24,
      ),
    );
  }

  final InternetAddress bindAddress;
  final int port;
  final String jwtSecret;
  final String storePath;
  final Duration tokenTtl;
}

class EatWhatJwt {
  const EatWhatJwt._();

  static String issue({
    required String userId,
    required DateTime expiresAt,
    required String secret,
  }) {
    final header = _encode({'alg': 'HS256', 'typ': 'JWT'});
    final payload = _encode({
      'sub': userId,
      'type': 'access',
      'iat': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
    });
    final signature = _base64(
      Hmac(sha256, utf8.encode(secret))
          .convert(utf8.encode('$header.$payload'))
          .bytes,
    );
    return '$header.$payload.$signature';
  }

  static String? verify(String token, {required String secret}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final expected = Hmac(sha256, utf8.encode(secret))
          .convert(utf8.encode('${parts[0]}.${parts[1]}'))
          .bytes;
      final actual = base64Url.decode(base64Url.normalize(parts[2]));
      if (!_equals(expected, actual)) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map || payload['type'] != 'access') return null;
      final expiresAt = _int(payload['exp']);
      if (expiresAt == null ||
          expiresAt <= DateTime.now().millisecondsSinceEpoch ~/ 1000) {
        return null;
      }
      final userId = payload['sub']?.toString().trim() ?? '';
      return userId.isEmpty ? null : userId;
    } on Object {
      return null;
    }
  }

  static String _encode(Map<String, dynamic> json) =>
      _base64(utf8.encode(jsonEncode(json)));

  static String _base64(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static bool _equals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }
}

class EatWhatPasswordHasher {
  const EatWhatPasswordHasher._();

  static const _iterations = 120000;
  static const _saltLength = 16;

  static String hash(String password) {
    final random = Random.secure();
    final salt = List<int>.generate(_saltLength, (_) => random.nextInt(256));
    final digest = _derive(password, salt);
    return 'pbkdf2-sha256\$$_iterations\$${base64Url.encode(salt)}\$${base64Url.encode(digest)}';
  }

  static bool verify(String password, String encoded) {
    try {
      final parts = encoded.split(r'$');
      if (parts.length != 4 || parts[0] != 'pbkdf2-sha256') return false;
      final salt = base64Url.decode(parts[2]);
      final expected = base64Url.decode(parts[3]);
      final actual = _derive(
        password,
        salt,
        iterations: int.parse(parts[1]),
      );
      return EatWhatJwt._equals(expected, actual);
    } on Object {
      return false;
    }
  }

  static List<int> _derive(
    String password,
    List<int> salt, {
    int iterations = _iterations,
  }) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = List<int>.from(block);
    for (var iteration = 1; iteration < iterations; iteration++) {
      block = hmac.convert(block).bytes;
      for (var index = 0; index < result.length; index++) {
        result[index] ^= block[index];
      }
    }
    return result;
  }
}

class FileEatWhatUserStore {
  FileEatWhatUserStore(String path) : _file = File(path);

  final File _file;
  Future<void> _writeQueue = Future.value();

  Future<EatWhatUser?> find(String username, String email) async {
    await _writeQueue;
    final normalizedUsername = username.toLowerCase();
    final normalizedEmail = email.toLowerCase();
    for (final user in await _all()) {
      if (user.username.toLowerCase() == normalizedUsername ||
          user.email.toLowerCase() == normalizedEmail) {
        return user;
      }
    }
    return null;
  }

  Future<EatWhatUser?> findById(String id) async {
    await _writeQueue;
    for (final user in await _all()) {
      if (user.id == id) return user;
    }
    return null;
  }

  Future<bool> createIfAvailable(EatWhatUser user) async {
    var created = false;
    await _write((users) {
      final username = user.username.toLowerCase();
      final email = user.email.toLowerCase();
      final exists = users.any(
        (current) =>
            current.username.toLowerCase() == username ||
            current.email.toLowerCase() == email,
      );
      if (!exists) {
        users.add(user);
        created = true;
      }
      return users;
    });
    return created;
  }

  Future<void> update(EatWhatUser user) async {
    await _write((users) {
      final index = users.indexWhere((item) => item.id == user.id);
      if (index >= 0) users[index] = user;
      return users;
    });
  }

  Future<void> _write(
    List<EatWhatUser> Function(List<EatWhatUser>) change,
  ) async {
    final operation = _writeQueue.then((_) async {
      final users = change(await _all());
      await _file.parent.create(recursive: true);
      final temporary = File('${_file.path}.tmp');
      await temporary.writeAsString(
        jsonEncode(users.map((user) => user.toJson()).toList()),
        flush: true,
      );
      await temporary.rename(_file.path);
    });
    _writeQueue = operation.catchError((_) {});
    await operation;
  }

  Future<List<EatWhatUser>> _all() async {
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(
                (json) => EatWhatUser.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
    } on FileSystemException {
      return [];
    } on FormatException {
      return [];
    }
    return [];
  }
}

class EatWhatUser {
  const EatWhatUser({
    required this.id,
    required this.username,
    required this.email,
    required this.nickname,
    required this.passwordHash,
    required this.createdAt,
    required this.lastLoginAt,
    this.isMember = false,
    this.memberSince,
    this.memberExpiresAt,
  });

  factory EatWhatUser.fromJson(Map<String, dynamic> json) => EatWhatUser(
        id: json['id']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        nickname: json['nickname']?.toString() ?? '',
        passwordHash: json['passwordHash']?.toString() ?? '',
        createdAt: DateTime.parse(json['createdAt'].toString()),
        lastLoginAt: DateTime.parse(json['lastLoginAt'].toString()),
        isMember: json['isMember'] == true,
        memberSince: _parseDate(json['memberSince']),
        memberExpiresAt: _parseDate(json['memberExpiresAt']),
      );

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  final String id;
  final String username;
  final String email;
  final String nickname;
  final String passwordHash;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isMember;
  final DateTime? memberSince;
  final DateTime? memberExpiresAt;

  /// 当前是否在会员有效期内。
  bool get isMembershipActive {
    if (!isMember) return false;
    final expires = memberExpiresAt;
    if (expires == null) return true;
    return expires.isAfter(DateTime.now().toUtc());
  }

  int? get membershipDaysLeft {
    final expires = memberExpiresAt;
    if (expires == null) return null;
    final left = expires.difference(DateTime.now().toUtc()).inHours;
    if (left <= 0) return 0;
    return (left / 24).ceil();
  }

  EatWhatUser copyWith({
    DateTime? lastLoginAt,
    bool? isMember,
    DateTime? memberSince,
    DateTime? memberExpiresAt,
  }) =>
      EatWhatUser(
        id: id,
        username: username,
        email: email,
        nickname: nickname,
        passwordHash: passwordHash,
        createdAt: createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        isMember: isMember ?? this.isMember,
        memberSince: memberSince ?? this.memberSince,
        memberExpiresAt: memberExpiresAt ?? this.memberExpiresAt,
      );

  Map<String, dynamic> get publicJson => {
        'id': id,
        'username': username,
        'email': email,
        'nickname': nickname,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt.toIso8601String(),
        'isMember': isMember,
        'membershipActive': isMembershipActive,
        'memberSince': memberSince?.toIso8601String(),
        'memberExpiresAt': memberExpiresAt?.toIso8601String(),
        'membershipDaysLeft': membershipDaysLeft,
      };

  Map<String, dynamic> toJson() => {
        ...publicJson,
        'passwordHash': passwordHash,
      };
}

String? _validateRegistration(String username, String email, String password) {
  if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username)) {
    return '用户名需要 3-20 位，只能包含字母、数字和下划线';
  }
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return '邮箱格式不正确';
  }
  if (password.length < 8 ||
      !password.contains(RegExp('[a-z]')) ||
      !password.contains(RegExp('[A-Z]')) ||
      !password.contains(RegExp('[0-9]'))) {
    return '密码至少 8 位，并包含大小写字母和数字';
  }
  return null;
}

String _randomId() {
  final random = Random.secure();
  final bytes = List<int>.generate(18, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

String _string(dynamic value) => value?.toString().trim() ?? '';

String _bearerToken(HttpRequest request) {
  final value = request.headers.value(HttpHeaders.authorizationHeader) ?? '';
  return value.startsWith('Bearer ') ? value.substring(7).trim() : '';
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

Future<Map<String, dynamic>?> _readJson(HttpRequest request) async {
  try {
    final decoded = jsonDecode(await utf8.decoder.bind(request).join());
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  } on FormatException {
    return null;
  }
}

Future<void> _writeError(
  HttpResponse response,
  int statusCode,
  String code,
  String message,
) {
  return _writeJson(response, statusCode, {
    'error': {'code': code, 'message': message},
  });
}

Future<void> _writeJson(
  HttpResponse response,
  int statusCode,
  Map<String, dynamic> body,
) async {
  response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
  await response.close();
}

/// 会员中心官网单页（黑金），由 /portal 直接 serve。
const String _kMemberPortalHtml = r'''
<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>吃什么 · 会员中心</title>
<style>
  :root{
    --bg:#0B0B0D; --panel:#141416; --gold:#E8C97D; --gold-soft:#C9A96E;
    --gold-dim:#8A6D2F; --hairline:rgba(232,201,125,.2); --text:#F5EEDC;
    --muted:#9C948A; --line:rgba(245,238,220,.08);
  }
  *{box-sizing:border-box;margin:0;padding:0}
  body{background:var(--bg);color:var(--text);font-family:-apple-system,"PingFang SC","Noto Sans SC",sans-serif;
       min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px;
       background-image:radial-gradient(ellipse 80% 50% at 50% -10%,rgba(232,201,125,.09),transparent)}
  .card{width:100%;max-width:420px;background:var(--panel);border:1px solid var(--hairline);
        border-radius:24px;padding:32px 28px;box-shadow:0 24px 64px rgba(0,0,0,.5)}
  .logo{display:flex;align-items:center;gap:12px;justify-content:center;margin-bottom:8px}
  .logo-mark{width:44px;height:44px;border-radius:12px;background:linear-gradient(135deg,var(--gold),var(--gold-soft));
             display:flex;align-items:center;justify-content:center;font-size:22px}
  .logo-text{font-size:22px;font-weight:800;letter-spacing:2px}
  .sub{text-align:center;color:var(--muted);font-size:13px;letter-spacing:3px;margin-bottom:28px}
  .tabs{display:flex;gap:8px;background:var(--bg);border-radius:999px;padding:4px;margin-bottom:22px}
  .tab{flex:1;text-align:center;padding:10px;border-radius:999px;font-size:14px;font-weight:700;
       color:var(--muted);cursor:pointer;transition:all .2s}
  .tab.on{background:var(--panel);color:var(--gold);border:1px solid var(--hairline)}
  .field{margin-bottom:16px}
  .field label{display:block;font-size:12px;color:var(--muted);margin-bottom:8px;letter-spacing:1px}
  .field input{width:100%;background:var(--bg);border:1px solid var(--line);border-radius:14px;
               padding:13px 16px;color:var(--text);font-size:15px;outline:none;transition:border .2s}
  .field input:focus{border-color:var(--gold)}
  .btn{width:100%;background:var(--gold);color:#0B0B0D;border:none;border-radius:999px;
       padding:15px;font-size:16px;font-weight:800;letter-spacing:4px;cursor:pointer;transition:opacity .2s}
  .btn:active{opacity:.85}
  .btn.ghost{background:transparent;color:var(--gold);border:1px solid var(--hairline)}
  .msg{margin-top:14px;text-align:center;font-size:13px;min-height:18px}
  .msg.err{color:#F08A80}.msg.ok{color:#9FD0AE}
  .member-badge{display:inline-flex;align-items:center;gap:6px;padding:6px 14px;border-radius:999px;
                font-size:12px;font-weight:800;letter-spacing:1px}
  .member-badge.on{background:rgba(232,201,125,.15);color:var(--gold);border:1px solid var(--gold)}
  .member-badge.off{background:var(--bg);color:var(--muted);border:1px solid var(--line)}
  .member-card{background:linear-gradient(160deg,#1C1A15,#141416);border:1px solid var(--hairline);
               border-radius:18px;padding:22px;margin-bottom:20px}
  .member-row{display:flex;justify-content:space-between;align-items:center;padding:9px 0;
              border-bottom:1px solid var(--line);font-size:14px}
  .member-row:last-child{border-bottom:none}
  .member-row .k{color:var(--muted)}.member-row .v{font-weight:700}
  .days{font-size:34px;font-weight:900;color:var(--gold);line-height:1}
  .days small{font-size:13px;color:var(--muted);font-weight:500}
  .hidden{display:none}
  .foot{margin-top:24px;text-align:center;color:var(--gold-dim);font-size:11px;letter-spacing:2px}
  .link{color:var(--gold);cursor:pointer;text-decoration:none}
</style>
</head>
<body>
<div class="card">
  <div class="logo"><div class="logo-mark">🍜</div><div class="logo-text">吃什么</div></div>
  <div class="sub">会 员 中 心</div>

  <!-- 登录/注册 -->
  <div id="authView">
    <div class="tabs">
      <div class="tab on" id="tabLogin" onclick="switchTab('login')">登录</div>
      <div class="tab" id="tabReg" onclick="switchTab('reg')">注册</div>
    </div>
    <div class="field"><label>用户名</label><input id="account" placeholder="请输入用户名" autocomplete="username"></div>
    <div class="field" id="emailField" style="display:none"><label>邮箱</label><input id="email" placeholder="name@example.com"></div>
    <div class="field"><label>密码</label><input id="password" type="password" placeholder="请输入密码" autocomplete="current-password"></div>
    <button class="btn" id="submitBtn" onclick="submitAuth()">登 录</button>
    <div class="msg" id="msg"></div>
  </div>

  <!-- 会员卡 -->
  <div id="memberView" class="hidden">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:18px">
      <div>
        <div style="font-size:18px;font-weight:800" id="nickName">—</div>
        <div style="font-size:12px;color:var(--muted)" id="userName">—</div>
      </div>
      <span class="member-badge off" id="memberBadge">未开通</span>
    </div>
    <div class="member-card">
      <div style="text-align:center;padding:8px 0 16px">
        <div class="days" id="daysLeft">—</div>
        <div style="font-size:12px;color:var(--muted);margin-top:6px" id="expiryText">会员有效期</div>
      </div>
      <div class="member-row"><span class="k">开通时间</span><span class="v" id="sinceText">—</span></div>
      <div class="member-row"><span class="k">到期时间</span><span class="v" id="expireText">—</span></div>
      <div class="member-row"><span class="k">状态</span><span class="v" id="statusText">—</span></div>
    </div>
    <button class="btn" id="activateBtn" onclick="activate()">开通会员 · ¥98/年</button>
    <button class="btn ghost" style="margin-top:10px" onclick="logout()">退出登录</button>
    <div class="msg" id="msg2"></div>
  </div>

  <div class="foot">EATWHAT MEMBERSHIP</div>
</div>

<script>
let mode = 'login';
const $ = id => document.getElementById(id);
const token = () => localStorage.getItem('ew_token') || '';

function switchTab(m){
  mode = m;
  $('tabLogin').className = 'tab' + (m==='login' ? ' on' : '');
  $('tabReg').className = 'tab' + (m==='reg' ? ' on' : '');
  $('emailField').style.display = m==='reg' ? 'block' : 'none';
  $('submitBtn').textContent = m==='login' ? '登 录' : '注 册';
  $('msg').textContent = '';
}
function toast(t, ok){ const el=$('msg'); el.textContent=t; el.className='msg '+(ok?'ok':'err'); }
function toast2(t, ok){ const el=$('msg2'); el.textContent=t; el.className='msg '+(ok?'ok':'err'); }

async function api(path, method, body){
  const res = await fetch(path, {
    method, headers:{'Content-Type':'application/json', ...(token()?{'Authorization':'Bearer '+token()}:{})},
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await res.json().catch(()=>({}));
  return {ok: res.ok, data};
}

async function submitAuth(){
  const account = $('account').value.trim(), password = $('password').value;
  if(!account || !password){ toast('请输入账号和密码'); return; }
  let r;
  if(mode==='login'){
    r = await api('/api/v1/auth/login','POST',{account, password});
  }else{
    const email = $('email').value.trim();
    r = await api('/api/v1/auth/register','POST',{username:account, email:email||account+'@eatwhat.local', password});
  }
  if(r.ok && r.data.accessToken){
    localStorage.setItem('ew_token', r.data.accessToken);
    showMember();
  }else{
    toast(r.data?.error?.message || '操作失败，请重试');
  }
}

function fmt(s){ if(!s) return '—'; const d=new Date(s); return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0'); }

async function showMember(){
  const r = await api('/api/v1/member/status','GET');
  if(!r.ok){ logout(); return; }
  const u = r.data.user, m = r.data.membership;
  $('authView').classList.add('hidden');
  $('memberView').classList.remove('hidden');
  $('nickName').textContent = u.nickname || u.username;
  $('userName').textContent = '@'+u.username;
  const active = m.active;
  const badge = $('memberBadge');
  badge.className = 'member-badge ' + (active?'on':'off');
  badge.textContent = active ? '会员中' : '未开通';
  $('sinceText').textContent = fmt(m.since);
  $('expireText').textContent = fmt(m.expiresAt);
  $('statusText').textContent = active ? '有效' : '未生效';
  if(active && m.daysLeft!=null){
    $('daysLeft').innerHTML = m.daysLeft + ' <small>天</small>';
    $('expiryText').textContent = '会员剩余';
    $('activateBtn').textContent = '续费一年 · ¥98';
  }else{
    $('daysLeft').innerHTML = '—';
    $('expiryText').textContent = '尚未开通会员';
    $('activateBtn').textContent = '开通会员 · ¥98/年';
  }
}

async function activate(){
  const r = await api('/api/v1/member/activate','POST',{});
  if(r.ok){ toast2('开通成功，会员已生效', true); showMember(); }
  else{ toast2(r.data?.error?.message || '开通失败'); }
}

function logout(){ localStorage.removeItem('ew_token'); $('memberView').classList.add('hidden'); $('authView').classList.remove('hidden'); }

if(token()) showMember();
</script>
</body>
</html>
''';

/// 产品落地页（官网首页），由 / 直接 serve。
const String _kLandingHtml = r'''
<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>吃什么 — 今晚这口，替你收好</title>
<style>
  :root{
    --bg:#0B0B0D; --panel:#141416; --gold:#E8C97D; --gold-soft:#C9A96E;
    --gold-dim:#8A6D2F; --hairline:rgba(232,201,125,.18); --text:#F5EEDC;
    --muted:#9C948A; --line:rgba(245,238,220,.08);
  }
  *{box-sizing:border-box;margin:0;padding:0}
  body{background:var(--bg);color:var(--text);font-family:-apple-system,"PingFang SC","Noto Sans SC",sans-serif;
       overflow-x:hidden}
  body::before{content:"";position:fixed;inset:0;pointer-events:none;
       background:radial-gradient(ellipse 70% 40% at 50% -5%,rgba(232,201,125,.10),transparent)}
  .wrap{max-width:760px;margin:0 auto;padding:0 24px}
  nav{display:flex;justify-content:space-between;align-items:center;padding:26px 0}
  .brand{display:flex;align-items:center;gap:10px;font-weight:800;font-size:18px;letter-spacing:2px}
  .brand-mark{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--gold),var(--gold-soft));
              display:flex;align-items:center;justify-content:center;font-size:18px}
  .nav-link{color:var(--gold-soft);text-decoration:none;font-size:14px;letter-spacing:1px;
            border:1px solid var(--hairline);padding:9px 18px;border-radius:999px;transition:all .2s}
  .nav-link:hover{border-color:var(--gold);color:var(--gold)}
  .hero{text-align:center;padding:72px 0 56px}
  .hero-eyebrow{color:var(--gold-soft);font-size:12px;letter-spacing:5px;font-weight:700;margin-bottom:22px}
  .hero h1{font-size:clamp(38px,8vw,60px);font-weight:900;line-height:1.12;letter-spacing:1px;
           font-family:"Songti SC","Noto Serif SC",serif}
  .hero h1 em{font-style:normal;color:var(--gold)}
  .hero p{color:var(--muted);font-size:16px;line-height:1.8;max-width:480px;margin:22px auto 0}
  .cta{display:inline-flex;gap:14px;margin-top:36px;flex-wrap:wrap;justify-content:center}
  .btn{display:inline-block;padding:15px 34px;border-radius:999px;font-weight:800;font-size:15px;
       letter-spacing:3px;text-decoration:none;transition:opacity .2s}
  .btn-gold{background:var(--gold);color:#0B0B0D}
  .btn-ghost{border:1px solid var(--hairline);color:var(--gold)}
  .btn:active{opacity:.85}
  .section{padding:56px 0}
  .section-title{color:var(--gold-soft);font-size:12px;letter-spacing:5px;font-weight:700;text-align:center;margin-bottom:14px}
  .section h2{text-align:center;font-size:28px;font-weight:800;font-family:"Songti SC","Noto Serif SC",serif;margin-bottom:40px}
  .features{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:14px}
  .feature{background:var(--panel);border:1px solid var(--line);border-radius:18px;padding:24px}
  .feature .ic{font-size:26px;margin-bottom:14px}
  .feature h3{font-size:16px;font-weight:800;margin-bottom:8px}
  .feature p{color:var(--muted);font-size:13px;line-height:1.7}
  .plan{background:linear-gradient(160deg,#1C1A15,#141416);border:1px solid var(--hairline);
        border-radius:22px;padding:34px;text-align:center;position:relative;overflow:hidden}
  .plan::before{content:"";position:absolute;top:-40%;left:50%;transform:translateX(-50%);width:300px;height:300px;
                background:radial-gradient(circle,rgba(232,201,125,.12),transparent);pointer-events:none}
  .plan .price{font-size:44px;font-weight:900;color:var(--gold);line-height:1;margin:14px 0 4px}
  .plan .price small{font-size:15px;color:var(--muted);font-weight:500}
  .plan ul{list-style:none;text-align:left;max-width:340px;margin:22px auto 0}
  .plan li{padding:9px 0;color:var(--muted);font-size:14px;border-bottom:1px solid var(--line);display:flex;gap:10px}
  .plan li::before{content:"✦";color:var(--gold);flex-shrink:0}
  .plan li:last-child{border-bottom:none}
  footer{text-align:center;padding:40px 0 30px;color:var(--gold-dim);font-size:11px;letter-spacing:3px}
</style>
</head>
<body>
<div class="wrap">
  <nav>
    <div class="brand"><div class="brand-mark">🍜</div>吃什么</div>
    <a class="nav-link" href="/portal">会员中心</a>
  </nav>

  <section class="hero">
    <div class="hero-eyebrow">CHEF'S SELECTION · TONIGHT</div>
    <h1>今晚这口，<br><em>替你收好</em></h1>
    <p>把食材丢进锅，AI 主厨替你组合成真正想吃的那一道。不是随便搜一道，是把你的食材，变成一桌对味的菜。</p>
    <div class="cta">
      <a class="btn btn-gold" href="/portal">进入会员中心</a>
      <a class="btn btn-ghost" href="#features">了解特色</a>
    </div>
  </section>

  <section class="section" id="features">
    <div class="section-title">WHY EATWHAT</div>
    <h2>不止推荐，是懂你</h2>
    <div class="features">
      <div class="feature"><div class="ic">🍳</div><h3>融合创意</h3><p>选什么食材，就出什么菜。MiniMax 主厨把你的食材组合成真实可做的融合菜，不是关键词堆砌。</p></div>
      <div class="feature"><div class="ic">✨</div><h3>黑金舞台</h3><p>推荐结果是一张高级餐厅菜单卡：大图、衬线菜名、金色编号，看一眼就知道今晚吃什么。</p></div>
      <div class="feature"><div class="ic">🫕</div><h3>物理锅互动</h3><p>点一下收下，按住抓起，摇一摇翻锅。选菜像玩一样自然。</p></div>
      <div class="feature"><div class="ic">🛵</div><h3>一键到位</h3><p>想吃就外卖到家，想做就菜谱直出，想出门就堂食导航。三条路都给你铺好。</p></div>
    </div>
  </section>

  <section class="section">
    <div class="section-title">MEMBERSHIP</div>
    <h2>会员，是一种偏爱</h2>
    <div class="plan">
      <div style="color:var(--gold-soft);letter-spacing:4px;font-size:12px;font-weight:700">吃什么会员</div>
      <div class="price">¥98<small>/年</small></div>
      <div style="color:var(--muted);font-size:13px">一年好胃口</div>
      <ul>
        <li>AI 主厨无限融合创意</li>
        <li>会员专属菜品推荐</li>
        <li>优先体验新功能</li>
        <li>会员专属客服通道</li>
      </ul>
      <div class="cta"><a class="btn btn-gold" href="/portal">开通会员</a></div>
    </div>
  </section>

  <footer>EATWHAT · 今晚这口，替你收好</footer>
</div>
</body>
</html>
''';
