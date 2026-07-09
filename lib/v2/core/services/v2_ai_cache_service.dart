import 'dart:convert';

import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// V2 AI 结果缓存（轻量版）
///
/// - 主要用途：避免重复请求（图片/营养/饮品/占卜）。
/// - 存储介质：SharedPreferences（适合小体量 JSON 与 URL）。
class V2AiCacheService {
  V2AiCacheService._internal();
  static final V2AiCacheService instance = V2AiCacheService._internal();

  static const _prefix = 'v2_ai_cache:';

  Duration get defaultMaxAge => EnvConfig.aiCacheMaxAge;

  String _dataKey(String key) => '$_prefix$key:data';
  String _tsKey(String key) => '$_prefix$key:ts';

  Future<Map<String, dynamic>?> getJson(
    String key, {
    Duration? maxAge,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dataKey(key));
    final ts = prefs.getInt(_tsKey(key));
    if (raw == null || ts == null) return null;

    final ageMs = DateTime.now().millisecondsSinceEpoch - ts;
    final allowed = (maxAge ?? defaultMaxAge).inMilliseconds;
    if (allowed > 0 && ageMs > allowed) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setJson(String key, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dataKey(key), jsonEncode(value));
    await prefs.setInt(_tsKey(key), DateTime.now().millisecondsSinceEpoch);
  }

  Future<String?> getString(
    String key, {
    Duration? maxAge,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dataKey(key));
    final ts = prefs.getInt(_tsKey(key));
    if (raw == null || ts == null) return null;

    final ageMs = DateTime.now().millisecondsSinceEpoch - ts;
    final allowed = (maxAge ?? defaultMaxAge).inMilliseconds;
    if (allowed > 0 && ageMs > allowed) return null;

    return raw;
  }

  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dataKey(key), value);
    await prefs.setInt(_tsKey(key), DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> invalidate(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dataKey(key));
    await prefs.remove(_tsKey(key));
  }
}
