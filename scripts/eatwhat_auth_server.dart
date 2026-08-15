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
  });

  factory EatWhatUser.fromJson(Map<String, dynamic> json) => EatWhatUser(
        id: json['id']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        nickname: json['nickname']?.toString() ?? '',
        passwordHash: json['passwordHash']?.toString() ?? '',
        createdAt: DateTime.parse(json['createdAt'].toString()),
        lastLoginAt: DateTime.parse(json['lastLoginAt'].toString()),
      );

  final String id;
  final String username;
  final String email;
  final String nickname;
  final String passwordHash;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  EatWhatUser copyWith({DateTime? lastLoginAt}) => EatWhatUser(
        id: id,
        username: username,
        email: email,
        nickname: nickname,
        passwordHash: passwordHash,
        createdAt: createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      );

  Map<String, dynamic> get publicJson => {
        'id': id,
        'username': username,
        'email': email,
        'nickname': nickname,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt.toIso8601String(),
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
