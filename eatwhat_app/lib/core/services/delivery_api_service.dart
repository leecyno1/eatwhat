import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import '../models/food_item.dart';
import '../utils/api_config.dart';

/// 外卖平台API集成服务
/// 支持美团外卖和饿了么平台的数据获取
class DeliveryApiService {
  static const String _meiTuanBaseUrl = 'https://waimai.meituan.com/openapi/v1';
  static const String _elemeBaseUrl = 'https://open-api.ele.me/v2';
  
  final http.Client _httpClient;
  final ApiConfig _config;
  
  DeliveryApiService({
    http.Client? httpClient,
    ApiConfig? config,
  }) : _httpClient = httpClient ?? http.Client(),
       _config = config ?? ApiConfig();

  /// 获取美团外卖店铺信息
  /// 
  /// [poiId] 店铺ID
  /// 返回店铺详细信息，包括名称、地址、营业时间等
  Future<Restaurant?> getMeiTuanRestaurant(String poiId) async {
    try {
      final uri = Uri.parse('$_meiTuanBaseUrl/poi/get').replace(
        queryParameters: {
          'app_id': _config.meiTuanAppId,
          'app_secret': _config.meiTuanAppSecret,
          'poi_id': poiId,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'EatWhat/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 0 && data['data'] != null) {
          return Restaurant.fromMeiTuanJson(data['data']);
        } else {
          print('美团API返回错误: ${data['message']}');
          return null;
        }
      } else {
        print('美团API请求失败: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('获取美团店铺信息失败: $e');
      return null;
    }
  }

  /// 获取饿了么店铺信息
  /// 
  /// [restaurantId] 店铺ID
  /// 返回店铺详细信息
  Future<Restaurant?> getElemeRestaurant(String restaurantId) async {
    try {
      final uri = Uri.parse('$_elemeBaseUrl/restaurant/$restaurantId').replace(
        queryParameters: {
          'app_key': _config.elemeAppKey,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'EatWhat/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Restaurant.fromElemeJson(data['data']);
        } else {
          print('饿了么API返回错误: ${data['message']}');
          return null;
        }
      } else {
        print('饿了么API请求失败: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('获取饿了么店铺信息失败: $e');
      return null;
    }
  }

  /// 搜索附近的美团外卖店铺
  /// 
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [keyword] 搜索关键词（可选）
  /// [radius] 搜索半径（米，默认3000米）
  Future<List<Restaurant>> searchMeiTuanRestaurants({
    required double latitude,
    required double longitude,
    String? keyword,
    int radius = 3000,
  }) async {
    try {
      final queryParams = {
        'app_id': _config.meiTuanAppId,
        'app_secret': _config.meiTuanAppSecret,
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius': radius.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }

      final uri = Uri.parse('$_meiTuanBaseUrl/poi/search').replace(
        queryParameters: queryParams,
      );

      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'EatWhat/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 0 && data['data'] != null) {
          final List<dynamic> restaurants = data['data']['restaurants'] ?? [];
          return restaurants
              .map((json) => Restaurant.fromMeiTuanJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('搜索美团店铺失败: $e');
      return [];
    }
  }

  /// 搜索附近的饿了么店铺
  /// 
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [keyword] 搜索关键词（可选）
  /// [radius] 搜索半径（米，默认3000米）
  Future<List<Restaurant>> searchElemeRestaurants({
    required double latitude,
    required double longitude,
    String? keyword,
    int radius = 3000,
  }) async {
    try {
      final queryParams = {
        'app_key': _config.elemeAppKey,
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius': radius.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }

      final uri = Uri.parse('$_elemeBaseUrl/restaurants/search').replace(
        queryParameters: queryParams,
      );

      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'EatWhat/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> restaurants = data['data']['restaurants'] ?? [];
          return restaurants
              .map((json) => Restaurant.fromElemeJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('搜索饿了么店铺失败: $e');
      return [];
    }
  }

  /// 获取店铺菜单（美团）
  /// 
  /// [poiId] 店铺ID
  Future<List<FoodItem>> getMeiTuanMenu(String poiId) async {
    try {
      final uri = Uri.parse('$_meiTuanBaseUrl/poi/menu').replace(
        queryParameters: {
          'app_id': _config.meiTuanAppId,
          'app_secret': _config.meiTuanAppSecret,
          'poi_id': poiId,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'EatWhat/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 0 && data['data'] != null) {
          final List<dynamic> menuItems = data['data']['menu'] ?? [];
          return menuItems
              .map((json) => FoodItem.fromMeiTuanJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('获取美团菜单失败: $e');
      return [];
    }
  }

  /// 获取店铺菜单（饿了么）
  /// 
  /// [restaurantId] 店铺ID
  Future<List<FoodItem>> getElemeMenu(String restaurantId) async {
    try {
      final uri = Uri.parse('$_elemeBaseUrl/restaurant/$restaurantId/menu').replace(
        queryParameters: {
          'app_key': _config.elemeAppKey,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'EatWhat/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> menuItems = data['data']['menu'] ?? [];
          return menuItems
              .map((json) => FoodItem.fromElemeJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('获取饿了么菜单失败: $e');
      return [];
    }
  }

  /// 综合搜索附近餐厅（同时搜索美团和饿了么）
  /// 
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [keyword] 搜索关键词（可选）
  /// [radius] 搜索半径（米，默认3000米）
  Future<List<Restaurant>> searchNearbyRestaurants({
    required double latitude,
    required double longitude,
    String? keyword,
    int radius = 3000,
  }) async {
    try {
      // 并行搜索两个平台
      final futures = [
        searchMeiTuanRestaurants(
          latitude: latitude,
          longitude: longitude,
          keyword: keyword,
          radius: radius,
        ),
        searchElemeRestaurants(
          latitude: latitude,
          longitude: longitude,
          keyword: keyword,
          radius: radius,
        ),
      ];

      final results = await Future.wait(futures);
      final allRestaurants = <Restaurant>[];
      
      for (final restaurantList in results) {
        allRestaurants.addAll(restaurantList);
      }

      // 按距离排序
      allRestaurants.sort((a, b) => 
          (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));

      return allRestaurants;
    } catch (e) {
      print('综合搜索餐厅失败: $e');
      return [];
    }
  }

  /// 释放资源
  void dispose() {
    _httpClient.close();
  }
}

/// API配置异常
class ApiConfigException implements Exception {
  final String message;
  ApiConfigException(this.message);
  
  @override
  String toString() => 'ApiConfigException: $message';
}

/// 网络请求异常
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  
  NetworkException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'NetworkException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}