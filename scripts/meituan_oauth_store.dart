import 'dart:convert';
import 'dart:io';

class MeituanOAuthCredential {
  const MeituanOAuthCredential({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.openId = '',
    this.nickname,
    this.maskedPhone,
  });

  factory MeituanOAuthCredential.fromJson(Map<String, dynamic> json) {
    return MeituanOAuthCredential(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      openId: json['openId']?.toString() ?? '',
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      nickname: json['nickname']?.toString(),
      maskedPhone: json['maskedPhone']?.toString(),
    );
  }

  final String accessToken;
  final String refreshToken;
  final String openId;
  final DateTime expiresAt;
  final String? nickname;
  final String? maskedPhone;

  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'openId': openId,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      if (nickname?.isNotEmpty == true) 'nickname': nickname,
      if (maskedPhone?.isNotEmpty == true) 'maskedPhone': maskedPhone,
    };
  }
}

abstract interface class MeituanOAuthStore {
  Future<MeituanOAuthCredential?> read(String eatWhatUserId);

  Future<void> write(
    String eatWhatUserId,
    MeituanOAuthCredential credential,
  );
}

class FileMeituanOAuthStore implements MeituanOAuthStore {
  FileMeituanOAuthStore(String path) : _file = File(path);

  final File _file;
  Future<void> _writeQueue = Future.value();

  @override
  Future<MeituanOAuthCredential?> read(String eatWhatUserId) async {
    final all = await _readAll();
    final raw = all[eatWhatUserId];
    if (raw is! Map) return null;
    return MeituanOAuthCredential.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> write(
    String eatWhatUserId,
    MeituanOAuthCredential credential,
  ) async {
    final operation = _writeQueue.then((_) async {
      final all = await _readAll();
      all[eatWhatUserId] = credential.toJson();
      await _file.parent.create(recursive: true);
      final temporary = File('${_file.path}.tmp');
      await temporary.writeAsString(jsonEncode(all), flush: true);
      await temporary.rename(_file.path);
    });
    _writeQueue = operation.catchError((_) {});
    await operation;
  }

  Future<Map<String, dynamic>> _readAll() async {
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FileSystemException {
      return {};
    } on FormatException {
      return {};
    }
    return {};
  }
}

class MemoryMeituanOAuthStore implements MeituanOAuthStore {
  final Map<String, MeituanOAuthCredential> _credentials = {};

  @override
  Future<MeituanOAuthCredential?> read(String eatWhatUserId) async {
    return _credentials[eatWhatUserId];
  }

  @override
  Future<void> write(
    String eatWhatUserId,
    MeituanOAuthCredential credential,
  ) async {
    _credentials[eatWhatUserId] = credential;
  }
}
