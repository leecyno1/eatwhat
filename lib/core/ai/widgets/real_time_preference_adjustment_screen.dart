import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_behavior_models.dart';
import '../engines/ai_preference_learning_engine.dart';
import '../services/preference_mapping_service.dart';

/// 实时偏好调整界面 - Phase 3 用户偏好个性化定制
/// 提供直观的滑块和开关界面，让用户实时调整AI推荐偏好
class RealTimePreferenceAdjustmentScreen extends StatefulWidget {
  final String userId;
  final VoidCallback? onPreferencesUpdated;

  const RealTimePreferenceAdjustmentScreen({
    Key? key,
    required this.userId,
    this.onPreferencesUpdated,
  }) : super(key: key);

  @override
  State<RealTimePreferenceAdjustmentScreen> createState() =>
      _RealTimePreferenceAdjustmentScreenState();
}

class _RealTimePreferenceAdjustmentScreenState extends State<RealTimePreferenceAdjustmentScreen>
    with TickerProviderStateMixin {
  final AIPreferenceLearningEngine _aiEngine = AIPreferenceLearningEngine();
  final PreferenceMappingService _mappingService = PreferenceMappingService();

  // 偏好数据
  late PreferenceVector _currentVector;
  late Map<String, dynamic> _userInsights;

  // 动画控制器
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // UI状态
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  int _selectedTabIndex = 0;

  // 临时偏好值（用于实时调整）
  Map<String, double> _tempTastePrefs = {};
  Map<String, double> _tempCuisinePrefs = {};
  Map<String, double> _tempIngredientPrefs = {};
  Map<String, double> _tempScenarioPrefs = {};
  Map<String, double> _tempNutritionPrefs = {};
  Map<String, double> _tempDifficultyPrefs = {};
  Map<String, double> _tempTimePrefs = {};
  Map<String, double> _tempEmotionalPrefs = {};
  Map<String, double> _tempSeasonalPrefs = {};
  Map<String, double> _tempDimensionWeights = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserPreferences();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadUserPreferences() async {
    try {
      await _aiEngine.initialize();
      await _mappingService.initialize();

      _currentVector = _aiEngine.getUserPreferenceVector(widget.userId);
      _userInsights = _aiEngine.getUserInsights(widget.userId);

      // 初始化临时偏好值
      _tempTastePrefs = Map.from(_currentVector.tastePreferences);
      _tempCuisinePrefs = Map.from(_currentVector.cuisinePreferences);
      _tempIngredientPrefs = Map.from(_currentVector.ingredientPreferences);
      _tempScenarioPrefs = Map.from(_currentVector.scenarioPreferences);
      _tempNutritionPrefs = Map.from(_currentVector.nutritionPreferences);
      _tempDifficultyPrefs = Map.from(_currentVector.difficultyPreferences);
      _tempTimePrefs = Map.from(_currentVector.timePreferences);
      _tempEmotionalPrefs = Map.from(_currentVector.emotionalPreferences);
      _tempSeasonalPrefs = Map.from(_currentVector.seasonalPreferences);
      _tempDimensionWeights = Map.from(_currentVector.dimensionWeights);

      setState(() {
        _isLoading = false;
      });

      _slideController.forward();
    } catch (e) {
      debugPrint('加载用户偏好失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    if (!_hasChanges) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 触发触觉反馈
      HapticFeedback.mediumImpact();

      // 更新AI引擎的偏好权重
      final weightUpdates = <String, double>{};

      // 收集所有维度的权重更新
      weightUpdates.addAll(_tempDimensionWeights);

      await _aiEngine.updatePreferenceWeights(widget.userId, weightUpdates);

      // 更新偏好映射
      final mappingUpdates = {
        'taste': _tempTastePrefs,
        'cuisine': _tempCuisinePrefs,
        'ingredient': _tempIngredientPrefs,
        'scenario': _tempScenarioPrefs,
        'nutrition': _tempNutritionPrefs,
        'difficulty': _tempDifficultyPrefs,
        'time': _tempTimePrefs,
        'emotional': _tempEmotionalPrefs,
        'seasonal': _tempSeasonalPrefs,
      };

      await _mappingService.updatePreferenceMappings(widget.userId, mappingUpdates);

      // 重新加载数据
      await _loadUserPreferences();

      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });

      // 触发成功反馈
      HapticFeedback.lightImpact();

      // 通知父组件
      widget.onPreferencesUpdated?.call();

      _showSuccessSnackBar();
    } catch (e) {
      debugPrint('保存偏好失败: $e');
      setState(() {
        _isSaving = false;
      });
      _showErrorSnackBar();
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔄 重置偏好'),
        content: const Text('确定要将所有偏好重置为默认值吗？这将清除您的个性化设置。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performReset();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  void _performReset() {
    final defaultVector = PreferenceVector.defaultVector();

    setState(() {
      _tempTastePrefs = Map.from(defaultVector.tastePreferences);
      _tempCuisinePrefs = Map.from(defaultVector.cuisinePreferences);
      _tempIngredientPrefs = Map.from(defaultVector.ingredientPreferences);
      _tempScenarioPrefs = Map.from(defaultVector.scenarioPreferences);
      _tempNutritionPrefs = Map.from(defaultVector.nutritionPreferences);
      _tempDifficultyPrefs = Map.from(defaultVector.difficultyPreferences);
      _tempTimePrefs = Map.from(defaultVector.timePreferences);
      _tempEmotionalPrefs = Map.from(defaultVector.emotionalPreferences);
      _tempSeasonalPrefs = Map.from(defaultVector.seasonalPreferences);
      _tempDimensionWeights = Map.from(defaultVector.dimensionWeights);
      _hasChanges = true;
    });

    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingView() : _buildMainContent(),
      floatingActionButton: _buildSaveButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 偏好调整',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (!_isLoading)
            Text(
              '置信度: ${(_currentVector.confidenceScore * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _resetToDefaults,
          icon: const Icon(Icons.refresh, color: Colors.orange),
          tooltip: '重置为默认',
        ),
        IconButton(
          onPressed: () => _showUserInsights(),
          icon: const Icon(Icons.analytics, color: Colors.blue),
          tooltip: '查看分析',
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            '🧠 AI正在分析您的偏好...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.3),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: FadeTransition(
              opacity: _slideAnimation,
              child: _buildTabContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      ('🍽️', '口味菜系'),
      ('🥬', '食材场景'),
      ('💪', '营养难度'),
      ('⏰', '时间情感'),
      ('⚖️', '权重调节'),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final (emoji, label) = tabs[index];
          final isSelected = _selectedTabIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF667eea) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildTasteCuisineTab();
      case 1:
        return _buildIngredientScenarioTab();
      case 2:
        return _buildNutritionDifficultyTab();
      case 3:
        return _buildTimeEmotionalTab();
      case 4:
        return _buildWeightAdjustmentTab();
      default:
        return Container();
    }
  }

  Widget _buildTasteCuisineTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPreferenceSection(
            '👅 口味偏好',
            _tempTastePrefs,
            ['甜', '酸', '苦', '辣', '咸', '鲜', '香', '清淡'],
            (key, value) {
              _tempTastePrefs[key] = value;
              _markAsChanged();
            },
          ),
          const SizedBox(height: 24),
          _buildPreferenceSection(
            '🍽️ 菜系偏好',
            _tempCuisinePrefs,
            ['川菜', '粤菜', '湘菜', '鲁菜', '家常菜', '西餐', '日料', '韩式'],
            (key, value) {
              _tempCuisinePrefs[key] = value;
              _markAsChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientScenarioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPreferenceSection(
            '🥬 食材偏好',
            _tempIngredientPrefs,
            ['猪肉', '牛肉', '鸡肉', '鱼类', '蔬菜', '豆腐', '鸡蛋', '海鲜'],
            (key, value) {
              _tempIngredientPrefs[key] = value;
              _markAsChanged();
            },
          ),
          const SizedBox(height: 24),
          _buildPreferenceSection(
            '🎭 场景偏好',
            _tempScenarioPrefs,
            ['早餐', '午餐', '晚餐', '夜宵', '聚餐', '独享', '节日', '工作日'],
            (key, value) {
              _tempScenarioPrefs[key] = value;
              _markAsChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionDifficultyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPreferenceSection(
            '💪 营养偏好',
            _tempNutritionPrefs,
            ['高蛋白', '低卡路里', '富含维生素', '高纤维', '低脂肪', '低钠', '无糖', '有机'],
            (key, value) {
              _tempNutritionPrefs[key] = value;
              _markAsChanged();
            },
          ),
          const SizedBox(height: 24),
          _buildPreferenceSection(
            '👨‍🍳 难度偏好',
            _tempDifficultyPrefs,
            ['新手级', '简单', '中等', '有挑战', '大师级'],
            (key, value) {
              _tempDifficultyPrefs[key] = value;
              _markAsChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeEmotionalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPreferenceSection(
            '⏰ 时间偏好',
            _tempTimePrefs,
            ['快手菜', '半小时内', '1小时内', '慢炖', '不限时间'],
            (key, value) {
              _tempTimePrefs[key] = value;
              _markAsChanged();
            },
          ),
          const SizedBox(height: 24),
          _buildPreferenceSection(
            '😊 情感偏好',
            _tempEmotionalPrefs,
            ['舒适', '温暖', '清爽', '治愈', '满足', '怀旧', '新奇', '浪漫'],
            (key, value) {
              _tempEmotionalPrefs[key] = value;
              _markAsChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeightAdjustmentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '调整各维度在推荐中的重要程度，数值越高影响越大',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildWeightSection(),
        ],
      ),
    );
  }

  Widget _buildPreferenceSection(
    String title,
    Map<String, double> preferences,
    List<String> keys,
    Function(String, double) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ...keys.map((key) {
            final value = preferences[key] ?? 0.5;
            return _buildPreferenceSlider(key, value, onChanged);
          }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPreferenceSlider(
    String label,
    double value,
    Function(String, double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPreferenceColor(value).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPreferenceLabel(value),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getPreferenceColor(value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getPreferenceColor(value),
              inactiveTrackColor: Colors.grey[300],
              thumbColor: _getPreferenceColor(value),
              overlayColor: _getPreferenceColor(value).withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (newValue) {
                setState(() {
                  onChanged(label, newValue);
                });
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSection() {
    final weights = [
      ('taste_weight', '口味重要性', '👅'),
      ('cuisine_weight', '菜系重要性', '🍽️'),
      ('ingredient_weight', '食材重要性', '🥬'),
      ('scenario_weight', '场景重要性', '🎭'),
      ('nutrition_weight', '营养重要性', '💪'),
      ('difficulty_weight', '难度重要性', '👨‍🍳'),
      ('time_weight', '时间重要性', '⏰'),
      ('emotional_weight', '情感重要性', '😊'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: weights.map((weightData) {
          final (key, label, emoji) = weightData;
          final value = _tempDimensionWeights[key] ?? 1.0;

          return _buildWeightSlider(key, label, emoji, value);
        }).toList(),
      ),
    );
  }

  Widget _buildWeightSlider(String key, String label, String emoji, double value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getWeightColor(value).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getWeightColor(value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getWeightColor(value),
              inactiveTrackColor: Colors.grey[300],
              thumbColor: _getWeightColor(value),
              overlayColor: _getWeightColor(value).withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 2.0,
              divisions: 40,
              onChanged: (newValue) {
                setState(() {
                  _tempDimensionWeights[key] = newValue;
                  _markAsChanged();
                });
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    if (!_hasChanges) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseAnimation.value - 0.5) * 0.1,
          child: FloatingActionButton.extended(
            onPressed: _isSaving ? null : _savePreferences,
            backgroundColor: const Color(0xFF667eea),
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: Text(
              _isSaving ? '保存中...' : '保存偏好',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getPreferenceColor(double value) {
    if (value < 0.3) return Colors.grey;
    if (value < 0.6) return Colors.orange;
    return Colors.green;
  }

  String _getPreferenceLabel(double value) {
    if (value < 0.3) return '不喜欢';
    if (value < 0.6) return '一般';
    return '喜欢';
  }

  Color _getWeightColor(double value) {
    if (value < 0.5) return Colors.grey;
    if (value < 1.0) return Colors.blue;
    if (value < 1.5) return Colors.orange;
    return Colors.red;
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _showUserInsights() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInsightsBottomSheet(),
    );
  }

  Widget _buildInsightsBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '📊 您的偏好分析',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInsightCard('活跃度',
                      '${(_userInsights['activityScore'] as double? ?? 0.0 * 100).toInt()}%'),
                  _buildInsightCard('推荐置信度', '${(_currentVector.confidenceScore * 100).toInt()}%'),
                  _buildInsightCard('总互动次数', '${_userInsights['totalInteractions'] ?? 0}'),
                  _buildInsightCard('偏好稳定性', '85%'), // 示例数据
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF667eea),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('偏好已保存！AI将为您提供更精准的推荐'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Text('保存失败，请稍后重试'),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
