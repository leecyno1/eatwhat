import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import '../../../core/models/physical_entity.dart';
import '../../../core/models/physical_entity_factory.dart';
import '../../../core/physics/zero_gravity_physics.dart';
import '../../../core/models/food.dart';
import '../../../core/models/user_preference.dart';
import '../../../core/services/simple_food_database.dart';
import '../../../core/services/user_preference_manager.dart';
import '../../../core/models/user_taste_action.dart';
import '../../../core/repositories/user_preference_repository.dart';
import '../../../core/services/preference_event_service.dart';
import '../../../core/services/recommendation_engine.dart';
import '../../../core/services/recommendation_orchestrator.dart';

/// 物理实体控制器 - 管理零重力环境下的物理实体系统
class PhysicalEntityController extends ChangeNotifier {
  final List<PhysicalEntity> _entities = [];
  final List<PhysicalEntity> _selectedEntities = [];
  final List<PhysicalEntity> _likedEntities = []; // 喜欢的实体
  final List<PhysicalEntity> _dislikedEntities = []; // 不喜欢的实体
  final List<Food> _recommendedFoods = [];

  late UserPreference _userPreference;

  // 用户偏好管理器
  final UserPreferenceManager _preferenceManager = UserPreferenceManager();

  late final UserPreferenceRepository _preferenceRepository;
  late final PreferenceEventService _preferenceEventService;
  late final RecommendationOrchestrator _recommendationOrchestrator;
  final RecommendationEngine _recommendationEngine = RecommendationEngine();
  StreamSubscription<List<Food>>? _recommendationSubscription;

  // 状态标识
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isGeneratingRecommendations = false;
  bool _isPhysicsRunning = false;
  Size? _containerSize;

  // 物理引擎定时器
  Timer? _physicsTimer;

  // 渐进出现动画
  Timer? _gradualAppearanceTimer;
  bool _isGradualAppearanceEnabled = true;
  int _appearanceIndex = 0;
  final Duration _appearanceInterval = const Duration(milliseconds: 200);

  // 用户交互
  DateTime _lastInteractionTime = DateTime.now();

  // TODO: 从AuthService获取
  final String _currentUserId = 'default_user';

  // Getters
  List<PhysicalEntity> get entities => _entities;
  List<PhysicalEntity> get selectedEntities => _selectedEntities;
  List<PhysicalEntity> get likedEntities => _likedEntities;
  List<PhysicalEntity> get dislikedEntities => _dislikedEntities;
  List<Food> get recommendedFoods => _recommendedFoods;
  UserPreference get userPreference => _userPreference;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isGeneratingRecommendations => _isGeneratingRecommendations;
  bool get isPhysicsRunning => _isPhysicsRunning;
  bool get isGradualAppearanceEnabled => _isGradualAppearanceEnabled;
  int get selectedCount => _selectedEntities.length;

  /// 初始化控制器
  Future<void> initialize({Size? containerSize}) async {
    return initializeEntities();
  }

  /// 初始化实体 - 兼容方法
  Future<void> initializeEntities([BuildContext? context]) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('初始化物理实体系统...');

      _preferenceRepository = UserPreferenceRepository(userId: _currentUserId);
      _preferenceEventService = PreferenceEventService(_preferenceRepository);
      _recommendationOrchestrator = RecommendationOrchestrator(
        preferenceEventService: _preferenceEventService,
        recommendationEngine: _recommendationEngine,
        userPreferenceRepository: _preferenceRepository,
      );

      // 初始化用户偏好管理器
      await _preferenceManager.initialize();

      // 加载用户偏好
      _userPreference = await _preferenceRepository.get();
      await _recommendationOrchestrator.initialize();
      _recommendationSubscription =
          _recommendationOrchestrator.recommendationStream.listen((foods) {
        _recommendedFoods
          ..clear()
          ..addAll(foods);
        notifyListeners();
      });

      // 创建默认实体 - 使用新的偏好系统
      _entities.clear();

      // 使用新的偏好系统随机选择30个实体
      final selectedEntities = _preferenceManager.selectRandomEntities(count: 30);

      // 应用用户偏好到实体（动态大小和透明度）
      final entitiesWithPreferences =
          _preferenceManager.applyPreferencesToEntities(selectedEntities);

      _entities.addAll(entitiesWithPreferences);

      // 记录已显示的实体
      _preferenceManager.recordDisplayedEntities(_entities);

      if (_isGradualAppearanceEnabled) {
        // 初始时所有实体都隐藏
        for (int i = 0; i < _entities.length; i++) {
          _entities[i] = _entities[i].copyWith(opacity: 0.0);
        }
      }

      // 设置默认容器尺寸
      _containerSize = const Size(400, 600);

      // 分布实体，并设置初始随机速度
      PhysicalEntityFactory.distributeEntities(_entities, _containerSize!);

      // 给实体添加随机初始速度以创建动态效果
      final random = Random();
      for (int i = 0; i < _entities.length; i++) {
        _entities[i] = _entities[i].copyWith(
          velocity: Offset(
            (random.nextDouble() - 0.5) * 2.0, // -1.0 到 1.0
            (random.nextDouble() - 0.5) * 2.0,
          ),
          angularVelocity: (random.nextDouble() - 0.5) * 0.1,
        );
      }

      _isInitialized = true;
      debugPrint('物理实体系统初始化完成，共 ${_entities.length} 个实体');

      // 启动物理引擎
      _startPhysicsEngine();

      debugPrint('物理引擎已启动 - 气泡将开始物理运动');

      // 启动渐进出现动画
      if (_isGradualAppearanceEnabled) {
        _startGradualAppearance();
      }
    } catch (e) {
      debugPrint('物理实体控制器初始化错误: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 启动物理引擎
  void _startPhysicsEngine() {
    if (_physicsTimer != null) return;

    _isPhysicsRunning = true;

    // 启动物理引擎定时器
    _physicsTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_containerSize != null) {
        ZeroGravityPhysics.updatePhysics(_entities, _containerSize!);

        if (_shouldNotifyListeners()) {
          notifyListeners();
        }
      }
    });
  }

  /// 检查是否需要通知监听器 - 更严格的稳定性检查
  bool _shouldNotifyListeners() {
    double totalSpeed = 0.0;
    int movingEntities = 0;

    for (final entity in _entities) {
      final speed = entity.velocity.distance;
      totalSpeed += speed;
      if (speed > 0.1) movingEntities++;
    }

    // 极严格的更新条件 - 几乎静止才更新
    return totalSpeed > 0.01 && movingEntities > 0;
  }

  /// 停止物理引擎
  void _stopPhysicsEngine() {
    _physicsTimer?.cancel();
    _physicsTimer = null;
    _isPhysicsRunning = false;
  }

  /// 重新启动物理引擎
  void restartPhysics() {
    debugPrint('重新启动物理引擎');
    _stopPhysicsEngine();
    _startPhysicsEngine();
  }

  /// 暂停/恢复物理引擎
  void togglePhysics() {
    if (_isPhysicsRunning) {
      debugPrint('暂停物理引擎');
      _stopPhysicsEngine();
    } else {
      debugPrint('恢复物理引擎');
      _startPhysicsEngine();
    }
    notifyListeners();
  }

  /// 恢复物理引擎
  void resumePhysics() {
    if (!_isPhysicsRunning) {
      debugPrint('恢复物理引擎');
      _startPhysicsEngine();
      notifyListeners();
    }
  }

  /// 暂停物理引擎
  void pausePhysics() {
    if (_isPhysicsRunning) {
      debugPrint('暂停物理引擎');
      _stopPhysicsEngine();
      notifyListeners();
    }
  }

  /// 更新容器尺寸
  void updateContainerSize(Size newSize) {
    // 只有当尺寸真正改变时才重新分布
    if (_containerSize == null ||
        (_containerSize!.width != newSize.width || _containerSize!.height != newSize.height)) {
      _containerSize = newSize;

      // 只有在尺寸发生显著变化时才重新分布（避免微小变化导致的乱窜）
      if (_entities.isNotEmpty && _containerSize != null) {
        final sizeChange = (_containerSize!.width - newSize.width).abs() +
            (_containerSize!.height - newSize.height).abs();
        if (sizeChange > 10) {
          // 只有变化超过10像素时才重新分布
          debugPrint('容器尺寸显著变化，重新分布气泡: ${_containerSize} -> $newSize');
          ZeroGravityPhysics.redistributeEntities(_entities, newSize);

          // 延迟通知，避免在build过程中调用setState
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
        }
      }
    }
  }

  /// 切换实体选择状态
  void toggleEntitySelection(String entityId) {
    final entity = _entities.firstWhere((e) => e.id == entityId);
    toggleEntity(entity);
  }

  /// 选择/取消选择实体（点击和长按，无评分变化）
  void toggleEntity(PhysicalEntity entity) {
    final index = _entities.indexWhere((e) => e.id == entity.id);
    if (index == -1) return;

    final isSelected = !_entities[index].isSelected;
    _entities[index] = entity.copyWith(isSelected: isSelected);

    _selectedEntities.removeWhere((e) => e.id == entity.id);
    if (isSelected) {
      _selectedEntities.add(_entities[index]);
    }

    // 点击和长按不影响评分，只改变选中状态
    _lastInteractionTime = DateTime.now();
    notifyListeners();
  }

  /// 检查实体是否被选中
  bool isEntitySelected(PhysicalEntity entity) {
    return _selectedEntities.any((e) => e.id == entity.id);
  }

  /// 清除所有选择
  void clearSelection() {
    for (int i = 0; i < _entities.length; i++) {
      if (_entities[i].isSelected) {
        _entities[i] = _entities[i].copyWith(isSelected: false);
      }
    }
    _selectedEntities.clear();
    _recommendedFoods.clear();
    _lastInteractionTime = DateTime.now();
    notifyListeners();
  }

  /// 喜欢实体 (通过ID)
  void likeEntity(String entityId) {
    final entity = _entities.firstWhere((e) => e.id == entityId,
        orElse: () => throw ArgumentError('Entity not found: $entityId'));
    likeEntityByObject(entity);
  }

  /// 不喜欢实体 (通过ID)
  void dislikeEntity(String entityId) {
    final entity = _entities.firstWhere((e) => e.id == entityId,
        orElse: () => throw ArgumentError('Entity not found: $entityId'));
    dislikeEntityByObject(entity);
  }

  /// 喜欢实体 (通过实体对象)
  void likeEntityByObject(PhysicalEntity entity) {
    if (!_selectedEntities.any((e) => e.id == entity.id)) {
      final index = _entities.indexWhere((e) => e.id == entity.id);
      if (index != -1) {
        _entities[index] = entity.copyWith(isSelected: true);
        _selectedEntities.add(_entities[index]);
      }
    }

    // 使用新的偏好管理器
    _preferenceManager.likeEntity(entity.id, entity.name);
    _recordTasteAction(entity, 1.0);
    _lastInteractionTime = DateTime.now();
    notifyListeners();
  }

  /// 不喜欢实体 (通过实体对象)
  void dislikeEntityByObject(PhysicalEntity entity) {
    _selectedEntities.removeWhere((e) => e.id == entity.id);
    final index = _entities.indexWhere((e) => e.id == entity.id);
    if (index != -1) {
      _entities[index] = entity.copyWith(isSelected: false, opacity: 0.5);
    }

    // 使用新的偏好管理器
    _preferenceManager.dislikeEntity(entity.id, entity.name);
    _recordTasteAction(entity, -1.0);
    _lastInteractionTime = DateTime.now();
    notifyListeners();
  }

  /// 忽略实体
  void ignoreEntity(PhysicalEntity entity) {
    final index = _entities.indexWhere((e) => e.id == entity.id);
    if (index != -1) {
      _entities[index] = entity.copyWith(opacity: 0.3);
    }

    // 使用新的偏好管理器
    _preferenceManager.ignoreEntity(entity.id, entity.name);
    _lastInteractionTime = DateTime.now();
    notifyListeners();
  }

  /// 确认实体（右滑）
  void confirmEntity(PhysicalEntity entity) {
    if (!_selectedEntities.any((e) => e.id == entity.id)) {
      toggleEntity(entity);
    }

    // 使用新的偏好管理器
    _preferenceManager.selectEntity(entity.id, entity.name);
    _lastInteractionTime = DateTime.now();
  }

  /// 应用排斥力 - 暂时禁用
  void applyRepulsionForce(Offset position, {double radius = 60.0, double strength = 50.0}) {
    // 暂时禁用所有力的应用以保持静止
    /*
    if (_containerSize != null) {
      ZeroGravityPhysics.applyRepulsionForce(_entities, position, radius, strength);
      _lastInteractionTime = DateTime.now();
    }
    */
  }

  /// 应用吸引力 - 暂时禁用
  void applyAttractionForce(Offset position, {double radius = 80.0, double strength = 30.0}) {
    // 暂时禁用
    /*
    if (_containerSize != null) {
      ZeroGravityPhysics.applyAttractionForce(_entities, position, radius, strength);
      _lastInteractionTime = DateTime.now();
    }
    */
  }

  /// 应用涡旋力 - 暂时禁用
  void applyVortexForce(Offset position, {double radius = 70.0, double strength = 20.0}) {
    // 暂时禁用
    /*
    if (_containerSize != null) {
      ZeroGravityPhysics.applyVortexForce(_entities, position, radius, strength);
      _lastInteractionTime = DateTime.now();
    }
    */
  }

  /// 添加随机扰动 - 暂时禁用
  void addRandomDisturbance({double strength = 10.0}) {
    // 暂时禁用所有随机扰动
    /*
    ZeroGravityPhysics.applyRandomDisturbance(_entities, strength);
    _lastInteractionTime = DateTime.now();
    notifyListeners();
    */
  }

  /// 重新分布实体
  void redistributeEntities() {
    if (_containerSize != null) {
      ZeroGravityPhysics.redistributeEntities(_entities, _containerSize!);
      // 禁用初始速度以保持稳定
      // PhysicalEntityFactory.addRandomVelocity(_entities);
      _lastInteractionTime = DateTime.now();
      notifyListeners();
    }
  }

  /// 获取选中的实体列表
  List<PhysicalEntity> getSelectedEntities() {
    return _selectedEntities;
  }

  /// 重置所有实体到随机位置
  void resetEntities() {
    for (int i = 0; i < _entities.length; i++) {
      _entities[i] = _entities[i].copyWith(
        isSelected: false,
        velocity: Offset.zero,
      );
    }
    _selectedEntities.clear();
    _likedEntities.clear();
    _dislikedEntities.clear();

    // 重新分布到随机位置，但不添加随机速度
    if (_containerSize != null) {
      PhysicalEntityFactory.distributeEntities(_entities, _containerSize!);
      // 禁用初始速度以保持稳定
      // PhysicalEntityFactory.addRandomVelocity(_entities);
    }

    notifyListeners();
  }

  /// 更新实体位置
  void updateEntityPosition(String entityId, Offset globalPosition) {
    final index = _entities.indexWhere((e) => e.id == entityId);
    if (index != -1 && _containerSize != null) {
      // 转换为相对位置
      final localPosition = Offset(
        (globalPosition.dx - 100).clamp(0, _containerSize!.width),
        (globalPosition.dy - 200).clamp(0, _containerSize!.height),
      );
      _entities[index] = _entities[index].copyWith(position: localPosition);
      _lastInteractionTime = DateTime.now();
      notifyListeners();
    }
  }

  /// 给实体添加速度
  void applyVelocityToEntity(String entityId, Offset velocity) {
    final index = _entities.indexWhere((e) => e.id == entityId);
    if (index != -1) {
      final scaledVelocity = Offset(
        velocity.dx * 0.3, // 增加速度以更明显的效果
        velocity.dy * 0.3,
      );
      _entities[index] = _entities[index].copyWith(velocity: scaledVelocity);
      _lastInteractionTime = DateTime.now();
      notifyListeners();
    }
  }

  /// 应用排斥力到实体
  void applyRepulsionToEntity(String entityId, Offset center, double strength) {
    final index = _entities.indexWhere((e) => e.id == entityId);
    if (index != -1) {
      final entity = _entities[index];
      final direction = (entity.position - center).distance > 0
          ? (entity.position - center) / (entity.position - center).distance
          : Offset(1, 0);

      final force = direction * strength;
      final newVelocity = entity.velocity + force;

      _entities[index] = entity.copyWith(velocity: newVelocity);
      _lastInteractionTime = DateTime.now();
      notifyListeners();
    }
  }

  /// 跳过实体
  void skipEntity(String entityId) {
    // 不改变选中状态，只是记录跳过
    debugPrint('跳过实体: $entityId');
  }

  /// 收藏实体
  void favoriteEntity(String entityId) {
    final index = _entities.indexWhere((e) => e.id == entityId);
    if (index != -1) {
      _entities[index] = _entities[index].copyWith(isSelected: true, isHighlighted: true);
      if (!_selectedEntities.any((e) => e.id == entityId)) {
        _selectedEntities.add(_entities[index]);
      }
      _recordTasteAction(_entities[index], 0.5);
      notifyListeners();
    }
  }

  Future<void> _recordTasteAction(
    PhysicalEntity entity,
    double delta,
  ) async {
    final action = UserTasteAction(
      userId: _currentUserId,
      nodeId: entity.id,
      nodeType: entity.type,
      weightDelta: delta,
    );
    _userPreference = await _preferenceEventService.recordAction(action);
    await _recommendationOrchestrator.forceRefresh();
  }

  /// 生成推荐
  Future<void> generateRecommendations() async {
    _isGeneratingRecommendations = true;
    notifyListeners();

    try {
      debugPrint('基于物理实体生成美食推荐...');

      // 获取选中的实体偏好
      final preferences = _selectedEntities.map((entity) => entity.name).toList();
      final tastes = _selectedEntities
          .where((entity) => entity.type == PhysicalEntityType.taste)
          .map((entity) => entity.name)
          .toList();
      final cuisines = _selectedEntities
          .where((entity) => entity.type == PhysicalEntityType.cuisine)
          .map((entity) => entity.name)
          .toList();

      debugPrint('用户偏好: $preferences');
      debugPrint('口味偏好: $tastes');
      debugPrint('菜系偏好: $cuisines');

      // 使用美食数据库获取推荐
      final database = SimpleFoodDatabase();
      final recommendations = await database.getRecommendations(
        preferences: preferences,
        tastes: tastes.isNotEmpty ? tastes : null,
        limit: 10,
      );

      _recommendedFoods.clear();
      _recommendedFoods.addAll(recommendations);

      // 如果没有找到匹配的美食，提供默认推荐
      if (_recommendedFoods.isEmpty) {
        debugPrint('未找到匹配的美食，提供默认推荐');
        final defaultRecommendations = await database.getAllFoods();
        _recommendedFoods.addAll(defaultRecommendations.take(6));
      }

      debugPrint('生成了 ${_recommendedFoods.length} 个美食推荐');
    } catch (e, s) {
      debugPrint('生成推荐时出错: $e\\n$s');
      await _generateFallbackRecommendations();
    } finally {
      _isGeneratingRecommendations = false;
      notifyListeners();
    }
  }

  /// 生成备用推荐
  Future<void> _generateFallbackRecommendations() async {
    debugPrint('使用备用推荐策略');

    final fallbackFoods = [
      Food(
        id: 'fallback_001',
        name: '宫保鸡丁',
        description: '川菜经典，麻辣鲜香',
        cuisineType: '川菜',
        rating: 4.6,
        price: 28.0,
        tasteAttributes: ['辣', '鲜', '香'],
      ),
      Food(
        id: 'fallback_002',
        name: '糖醋里脊',
        description: '酸甜可口，老少皆宜',
        cuisineType: '家常菜',
        rating: 4.4,
        price: 32.0,
        tasteAttributes: ['甜', '酸', '香'],
      ),
      Food(
        id: 'fallback_003',
        name: '清蒸鲈鱼',
        description: '鲜美清淡，营养丰富',
        cuisineType: '粤菜',
        rating: 4.5,
        price: 45.0,
        tasteAttributes: ['鲜', '清淡'],
      ),
    ];

    _recommendedFoods.addAll(fallbackFoods);
  }

  /// 切换食物收藏状态
  void toggleFoodFavorite(String foodId) {
    final index = _recommendedFoods.indexWhere((food) => food.id == foodId);
    if (index != -1) {
      final food = _recommendedFoods[index];
      _recommendedFoods[index] = food.copyWith(isFavorite: !food.isFavorite);
      notifyListeners();
    }
  }

  /// 获取系统状态信息
  Map<String, dynamic> getSystemStatus() {
    final totalEnergy = ZeroGravityPhysics.calculateTotalKineticEnergy(_entities);
    final isAtRest = ZeroGravityPhysics.isSystemNearlyAtRest(_entities);

    return {
      'totalEntities': _entities.length,
      'selectedEntities': _selectedEntities.length,
      'totalKineticEnergy': totalEnergy,
      'isSystemAtRest': isAtRest,
      'isPhysicsRunning': _isPhysicsRunning,
      'lastInteractionTime': _lastInteractionTime,
    };
  }

  /// 高亮特定类型的实体
  void highlightEntitiesByType(PhysicalEntityType type) {
    for (int i = 0; i < _entities.length; i++) {
      if (_entities[i].type == type) {
        _entities[i] = _entities[i].copyWith(isHighlighted: true);
      } else {
        _entities[i] = _entities[i].copyWith(isHighlighted: false);
      }
    }
    notifyListeners();
  }

  /// 清除高亮
  void clearHighlight() {
    for (int i = 0; i < _entities.length; i++) {
      _entities[i] = _entities[i].copyWith(isHighlighted: false);
    }
    notifyListeners();
  }

  /// 启动渐进出现动画
  void _startGradualAppearance() {
    _appearanceIndex = 0;
    _gradualAppearanceTimer?.cancel();

    debugPrint('开始渐进出现动画，共 ${_entities.length} 个气泡');

    _gradualAppearanceTimer = Timer.periodic(_appearanceInterval, (timer) {
      if (_appearanceIndex >= _entities.length) {
        _gradualAppearanceTimer?.cancel();
        _gradualAppearanceTimer = null;
        debugPrint('渐进出现动画完成');
        return;
      }

      // 让下一个气泡渐现
      if (_appearanceIndex < _entities.length) {
        _entities[_appearanceIndex] = _entities[_appearanceIndex].copyWith(opacity: 1.0);
        _appearanceIndex++;
        notifyListeners();
      }
    });
  }

  /// 停止渐进出现动画
  void _stopGradualAppearance() {
    _gradualAppearanceTimer?.cancel();
    _gradualAppearanceTimer = null;
  }

  /// 切换渐进出现模式
  void toggleGradualAppearance() {
    _isGradualAppearanceEnabled = !_isGradualAppearanceEnabled;
    debugPrint('渐进出现模式: ${_isGradualAppearanceEnabled ? "开启" : "关闭"}');
    notifyListeners();
  }

  /// 重置并重新开始渐进出现动画
  void restartGradualAppearance() {
    if (!_isGradualAppearanceEnabled) return;

    _stopGradualAppearance();

    // 重置所有气泡为隐藏状态
    for (int i = 0; i < _entities.length; i++) {
      _entities[i] = _entities[i].copyWith(opacity: 0.0);
    }

    // 重新开始动画
    _startGradualAppearance();
  }

  /// 立即显示所有气泡（跳过渐进动画）
  void showAllEntitiesImmediately() {
    _stopGradualAppearance();

    for (int i = 0; i < _entities.length; i++) {
      _entities[i] = _entities[i].copyWith(opacity: 1.0);
    }

    _appearanceIndex = _entities.length;
    notifyListeners();
    debugPrint('立即显示所有 ${_entities.length} 个气泡');
  }

  // 消失的实体计数器
  int _disappearedCount = 0;
  final List<PhysicalEntity> _disappearedEntities = [];

  /// 上滑喜欢实体
  void swipeUpEntity(PhysicalEntity entity) {
    final index = _entities.indexWhere((e) => e.id == entity.id);
    if (index == -1) return;

    // 记录喜欢操作
    _preferenceManager.likeEntity(entity.id, entity.name);

    // 移动到上方边缘并添加视觉效果
    if (_containerSize != null) {
      final topPosition = Offset(
        _entities[index].position.dx,
        _entities[index].radius, // 贴着上边缘
      );
      _entities[index] = _entities[index].copyWith(
        position: topPosition,
        velocity: Offset.zero,
        isSelected: true,
      );

      // 添加到喜欢列表
      if (!_likedEntities.any((e) => e.id == entity.id)) {
        _likedEntities.add(_entities[index]);
      }
      _dislikedEntities.removeWhere((e) => e.id == entity.id);
    }

    debugPrint('👍 用户喜欢: ${entity.name}');
    _lastInteractionTime = DateTime.now();
    notifyListeners();
  }

  /// 下滑讨厌实体（实体消失）
  void swipeDownEntity(PhysicalEntity entity) {
    final index = _entities.indexWhere((e) => e.id == entity.id);
    if (index == -1) return;

    // 记录讨厌操作
    _preferenceManager.dislikeEntity(entity.id, entity.name);

    // 实体消失
    _entities[index] = _entities[index].copyWith(opacity: 0.0);
    _disappearedEntities.add(_entities[index]);
    _disappearedCount++;

    // 从选中列表中移除
    _selectedEntities.removeWhere((e) => e.id == entity.id);
    _likedEntities.removeWhere((e) => e.id == entity.id);

    // 添加到不喜欢列表
    if (!_dislikedEntities.any((e) => e.id == entity.id)) {
      _dislikedEntities.add(_entities[index]);
    }

    debugPrint('👎 用户讨厌: ${entity.name} (消失计数: $_disappearedCount)');

    // 每消失5个实体，补充5个新实体
    if (_disappearedCount >= 5) {
      _addReplacementEntities();
      _disappearedCount = 0;
    }

    _lastInteractionTime = DateTime.now();
    notifyListeners();
  }

  /// 添加替换实体（每5个消失后补充5个新实体）
  void _addReplacementEntities() {
    if (_containerSize == null) return;

    // 获取5个新的替换实体
    final newEntities = <PhysicalEntity>[];
    for (int i = 0; i < 5; i++) {
      final replacement = _preferenceManager.getReplacementEntity();
      if (replacement != null) {
        newEntities.add(replacement);
      }
    }

    if (newEntities.isNotEmpty) {
      // 为新实体分配位置
      PhysicalEntityFactory.distributeEntities(newEntities, _containerSize!);

      // 将新实体添加到列表中，替换已消失的实体
      int replacedCount = 0;
      for (int i = 0; i < _entities.length && replacedCount < newEntities.length; i++) {
        if (_entities[i].opacity <= 0.0) {
          _entities[i] = newEntities[replacedCount].copyWith(
            position: _entities[i].position,
            velocity: Offset.zero,
            opacity: 1.0,
          );
          replacedCount++;
        }
      }

      // 如果还有剩余的新实体，添加到列表末尾
      for (int i = replacedCount; i < newEntities.length; i++) {
        _entities.add(newEntities[i].copyWith(opacity: 1.0));
      }

      debugPrint('🔄 已补充 ${newEntities.length} 个新实体');
    }
  }

  /// 获取用户偏好统计
  Map<String, dynamic> getUserPreferenceStats() {
    return _preferenceManager.getPreferenceStats();
  }

  @override
  void dispose() {
    _stopPhysicsEngine();
    _stopGradualAppearance();
    _recommendationSubscription?.cancel();
    _recommendationOrchestrator.dispose();
    super.dispose();
  }
}
