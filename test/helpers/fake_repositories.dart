/// Fake Repository 实现用于测试

/// Fake AuthRepository
class FakeAuthRepository {
  bool _isAuthenticated = false;
  String? _currentUserId;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;

  Future<void> login(String phone, String password) async {
    // 模拟登录
    _isAuthenticated = true;
    _currentUserId = 'test_user_$phone';
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUserId = null;
  }

  void reset() {
    _isAuthenticated = false;
    _currentUserId = null;
  }
}

/// Fake FoodRepository
class FakeFoodRepository {
  final List<Map<String, dynamic>> _foods = [
    {'id': '1', 'name': '宫保鸡丁', 'price': 28.0},
    {'id': '2', 'name': '鱼香肉丝', 'price': 26.0},
    {'id': '3', 'name': '麻辣豆腐', 'price': 18.0},
  ];

  Future<List<Map<String, dynamic>>> getFoods() async {
    return _foods;
  }

  Future<Map<String, dynamic>?> getFoodById(String id) async {
    return _foods.firstWhere(
      (food) => food['id'] == id,
      orElse: () => {},
    );
  }
}

/// Fake PreferenceRepository
class FakePreferenceRepository {
  final Map<String, dynamic> _preferences = {};

  Future<void> saveTastePreference(String userId, Map<String, dynamic> preference) async {
    _preferences[userId] = preference;
  }

  Future<Map<String, dynamic>?> getTastePreference(String userId) async {
    return _preferences[userId];
  }
}
