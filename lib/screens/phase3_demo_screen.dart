import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ai/models/user_behavior_models.dart';
import '../core/ai/engines/ai_preference_learning_engine.dart';
import '../core/ai/services/smart_conversational_recommender.dart';
import '../core/ai/services/preference_mapping_service.dart';
import '../core/ai/widgets/real_time_preference_adjustment_screen.dart';

/// Phase 3 AI驱动的智能推荐演示界面
/// 展示AI偏好学习、智能对话推荐、偏好映射和实时调整功能
class Phase3DemoScreen extends StatefulWidget {
  const Phase3DemoScreen({Key? key}) : super(key: key);

  @override
  State<Phase3DemoScreen> createState() => _Phase3DemoScreenState();
}

class _Phase3DemoScreenState extends State<Phase3DemoScreen> with TickerProviderStateMixin {
  // AI服务实例
  final AIPreferenceLearningEngine _aiEngine = AIPreferenceLearningEngine();
  final SmartConversationalRecommender _conversationalRecommender =
      SmartConversationalRecommender();
  final PreferenceMappingService _mappingService = PreferenceMappingService();

  // 动画控制器
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // UI状态
  bool _isInitialized = false;
  bool _isLoading = true;
  int _currentFeatureIndex = 0;
  String _demoUserId = 'demo_user_001';

  // 演示数据
  Map<String, dynamic> _userInsights = {};
  List<RecipeRecommendation> _recommendations = [];
  ConversationResponse? _conversationResponse;
  PreferenceMappingResult? _mappingResult;

  final List<Phase3Feature> _features = [
    Phase3Feature(
      title: 'AI偏好学习引擎',
      subtitle: '智能分析用户行为，动态学习个人偏好',
      icon: Icons.psychology,
      color: const Color(0xFF667eea),
      description: '通过机器学习算法分析用户的点击、收藏、评分等行为，'
          '构建多维度偏好向量，实现个性化推荐的核心引擎。',
    ),
    Phase3Feature(
      title: '智能对话推荐系统',
      subtitle: '自然语言交互，提供会话式菜谱推荐',
      icon: Icons.chat_bubble_outline,
      color: const Color(0xFF764ba2),
      description: '基于自然语言处理技术，理解用户的口语化需求，'
          '通过对话方式提供个性化的菜谱推荐和烹饪建议。',
    ),
    Phase3Feature(
      title: '偏好映射服务',
      subtitle: '深度分析偏好关系，发现潜在需求',
      icon: Icons.account_tree,
      color: const Color(0xFF56ab2f),
      description: '通过关联规则挖掘和用户聚类分析，发现偏好之间的深层关系，'
          '预测用户的潜在需求，提供互补性推荐。',
    ),
    Phase3Feature(
      title: '实时偏好调整',
      subtitle: '直观的滑块界面，实时调整AI推荐偏好',
      icon: Icons.tune,
      color: const Color(0xFFa8edea),
      description: '提供可视化的偏好调整界面，用户可以实时调整各维度的偏好权重，'
          'AI引擎即时响应，提供更精准的个性化推荐。',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAIServices();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _initializeAIServices() async {
    try {
      // 初始化AI服务
      await _aiEngine.initialize();
      await _mappingService.initialize();

      // 模拟用户行为数据
      await _simulateUserBehaviors();

      // 获取用户洞察
      _userInsights = _aiEngine.getUserInsights(_demoUserId);

      // 获取AI推荐
      _recommendations = await _aiEngine.getIntelligentRecommendations(
        userId: _demoUserId,
        count: 5,
      );

      // 开始对话推荐
      _conversationResponse = await _conversationalRecommender.startConversation(_demoUserId);

      // 获取偏好映射
      _mappingResult = await _mappingService.analyzeUserPreferenceMapping(_demoUserId);

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      // 启动动画
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      debugPrint('AI服务初始化失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _simulateUserBehaviors() async {
    // 模拟用户行为数据用于演示
    final behaviors = [
      UserBehaviorData(
        userId: _demoUserId,
        sessionId: 'demo_session_1',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        actionType: UserActionType.like,
        targetId: 'recipe_001',
        targetType: 'recipe',
        actionDetails: {
          'taste': '辣',
          'cuisine': '川菜',
          'ingredients': ['牛肉', '花椒'],
        },
        actionIntensity: 0.8,
      ),
      UserBehaviorData(
        userId: _demoUserId,
        sessionId: 'demo_session_2',
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        actionType: UserActionType.favorite,
        targetId: 'recipe_002',
        targetType: 'recipe',
        actionDetails: {
          'taste': '鲜',
          'cuisine': '粤菜',
          'ingredients': ['虾', '豆腐'],
        },
        actionIntensity: 0.9,
      ),
      UserBehaviorData(
        userId: _demoUserId,
        sessionId: 'demo_session_3',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        actionType: UserActionType.search,
        targetId: '快手菜',
        targetType: 'keyword',
        actionDetails: {
          'searchQuery': '15分钟快手菜',
          'resultCount': 25,
        },
        actionIntensity: 0.6,
      ),
    ];

    for (final behavior in behaviors) {
      await _aiEngine.recordUserBehavior(behavior);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingView() : _buildMainContent(),
      bottomNavigationBar: _buildBottomNavigation(),
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
            '🤖 Phase 3 - AI智能推荐',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (_isInitialized)
            Text(
              'AI置信度: ${(_userInsights['confidenceScore'] as double? ?? 0.0 * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showAIInsights(),
          icon: const Icon(Icons.analytics, color: Colors.blue),
          tooltip: 'AI分析报告',
        ),
        IconButton(
          onPressed: () => _refreshDemo(),
          icon: const Icon(Icons.refresh, color: Colors.green),
          tooltip: '刷新演示',
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _features[0].color,
                  _features[1].color,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '🧠 AI正在初始化...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '正在启动智能推荐引擎',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildFeatureDisplay(),
      ),
    );
  }

  Widget _buildFeatureDisplay() {
    final feature = _features[_currentFeatureIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFeatureCard(feature),
          const SizedBox(height: 24),
          _buildDemoContent(),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(Phase3Feature feature) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            feature.color,
            feature.color.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: feature.color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature.icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            feature.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoContent() {
    switch (_currentFeatureIndex) {
      case 0:
        return _buildAIEngineDemo();
      case 1:
        return _buildConversationalDemo();
      case 2:
        return _buildMappingDemo();
      case 3:
        return _buildAdjustmentDemo();
      default:
        return Container();
    }
  }

  Widget _buildAIEngineDemo() {
    return Column(
      children: [
        _buildSectionTitle('🎯 AI智能推荐结果'),
        ...(_recommendations.isNotEmpty
            ? _recommendations.take(3).map((rec) => _buildRecommendationCard(rec)).toList()
            : [_buildPlaceholderCard('正在分析您的偏好，生成个性化推荐...')]),
        const SizedBox(height: 16),
        _buildInsightsCard(),
      ],
    );
  }

  Widget _buildConversationalDemo() {
    return Column(
      children: [
        _buildSectionTitle('💬 智能对话推荐'),
        _buildConversationCard(),
        const SizedBox(height: 16),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildMappingDemo() {
    return Column(
      children: [
        _buildSectionTitle('🗺️ 偏好映射分析'),
        _buildMappingCard(),
        const SizedBox(height: 16),
        _buildCorrelationChart(),
      ],
    );
  }

  Widget _buildAdjustmentDemo() {
    return Column(
      children: [
        _buildSectionTitle('⚙️ 实时偏好调整'),
        _buildAdjustmentPreview(),
        const SizedBox(height: 16),
        _buildAdjustmentButton(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(RecipeRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.recipe.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '匹配度: ${(recommendation.score * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (recommendation.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: recommendation.reasons.take(2).map((reason) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 AI分析洞察',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInsightItem(
                  '活跃度', '${(_userInsights['activityScore'] as double? ?? 0.0 * 100).toInt()}%'),
              _buildInsightItem('互动次数', '${_userInsights['totalInteractions'] ?? 0}'),
              _buildInsightItem('学习进度',
                  '${(_userInsights['learningProgress'] as double? ?? 0.0 * 100).toInt()}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF667eea),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildConversationCard() {
    final message = _conversationResponse?.message ?? '正在初始化对话系统...';
    final suggestions = _conversationResponse?.suggestions ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF764ba2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: Color(0xFF764ba2),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI助手',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.take(4).map((suggestion) {
                return GestureDetector(
                  onTap: () => _handleSuggestionTap(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF764ba2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF764ba2).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF764ba2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      ('🎲', '给我个惊喜', QuickActionType.surpriseMe),
      ('🏠', '家常菜', QuickActionType.browseCategory),
      ('⚡', '快手菜', QuickActionType.filterByTime),
      ('🥗', '健康餐', QuickActionType.nutritionFocus),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ 快速操作',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions.map((action) {
              final (emoji, label, actionType) = action;
              return GestureDetector(
                onTap: () => _handleQuickAction(actionType),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF764ba2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingCard() {
    final correlations = _mappingResult?.preferenceCorrelations ?? {};
    final patterns = _mappingResult?.identifiedPatterns ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧬 偏好关系分析',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (correlations.isNotEmpty) ...[
            ...correlations.entries.take(3).map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getCorrelationColor(entry.value).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(entry.value * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getCorrelationColor(entry.value),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ] else ...[
            const Text(
              '正在分析偏好关系...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
          if (patterns.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              '🎯 识别的偏好模式',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...patterns.take(2).map((pattern) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF56ab2f).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getPatternIcon(pattern.type),
                      color: const Color(0xFF56ab2f),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pattern.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF56ab2f),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildCorrelationChart() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 相关性热图',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE3F2FD),
                  Color(0xFF2196F3),
                  Color(0xFF0D47A1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '偏好相关性可视化图表\n（演示版本）',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎛️ 偏好权重预览',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPreviewSlider('口味重要性', 0.8),
          _buildPreviewSlider('菜系重要性', 0.6),
          _buildPreviewSlider('食材重要性', 0.7),
          _buildPreviewSlider('营养重要性', 0.5),
        ],
      ),
    );
  }

  Widget _buildPreviewSlider(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFa8edea)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _openPreferenceAdjustment(),
        icon: const Icon(Icons.tune, color: Colors.white),
        label: const Text(
          '打开偏好调整界面',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFa8edea),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _currentFeatureIndex > 0
                ? () => _navigateToFeature(_currentFeatureIndex - 1)
                : null,
            icon: const Icon(Icons.arrow_back_ios),
            color: _currentFeatureIndex > 0 ? Colors.blue : Colors.grey,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_features.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color:
                        index == _currentFeatureIndex ? _features[index].color : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
          IconButton(
            onPressed: _currentFeatureIndex < _features.length - 1
                ? () => _navigateToFeature(_currentFeatureIndex + 1)
                : null,
            icon: const Icon(Icons.arrow_forward_ios),
            color: _currentFeatureIndex < _features.length - 1 ? Colors.blue : Colors.grey,
          ),
        ],
      ),
    );
  }

  void _navigateToFeature(int index) {
    setState(() {
      _currentFeatureIndex = index;
    });
    HapticFeedback.selectionClick();
  }

  void _handleSuggestionTap(String suggestion) {
    HapticFeedback.lightImpact();
    _showSnackBar('您选择了：$suggestion');
  }

  void _handleQuickAction(QuickActionType actionType) {
    HapticFeedback.mediumImpact();
    switch (actionType) {
      case QuickActionType.surpriseMe:
        _showSnackBar('🎲 为您准备惊喜推荐...');
        break;
      case QuickActionType.quickStart:
        _showSnackBar('🚀 快速开始推荐...');
        break;
      case QuickActionType.browseCategory:
        _showSnackBar('🏠 正在推荐家常菜...');
        break;
      case QuickActionType.filterByTime:
        _showSnackBar('⚡ 搜索快手菜谱...');
        break;
      case QuickActionType.filterByDifficulty:
        _showSnackBar('👨‍🍳 调整难度筛选...');
        break;
      case QuickActionType.nutritionFocus:
        _showSnackBar('🥗 推荐健康餐...');
        break;
    }
  }

  void _openPreferenceAdjustment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RealTimePreferenceAdjustmentScreen(
          userId: _demoUserId,
          onPreferencesUpdated: () {
            _refreshDemo();
          },
        ),
      ),
    );
  }

  void _showAIInsights() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧠 AI分析报告'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInsightRow('用户ID', _demoUserId),
              _buildInsightRow('AI置信度',
                  '${(_userInsights['confidenceScore'] as double? ?? 0.0 * 100).toInt()}%'),
              _buildInsightRow(
                  '活跃度', '${(_userInsights['activityScore'] as double? ?? 0.0 * 100).toInt()}%'),
              _buildInsightRow('互动次数', '${_userInsights['totalInteractions'] ?? 0}'),
              _buildInsightRow('学习进度',
                  '${(_userInsights['learningProgress'] as double? ?? 0.0 * 100).toInt()}%'),
              _buildInsightRow('推荐准确性', '92%'),
              _buildInsightRow('用户满意度', '87%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshDemo() async {
    setState(() {
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();

    // 重新初始化
    await _initializeAIServices();

    _showSnackBar('🔄 演示数据已刷新');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getCorrelationColor(double value) {
    if (value > 0.7) return Colors.green;
    if (value > 0.4) return Colors.orange;
    return Colors.grey;
  }

  IconData _getPatternIcon(PatternType type) {
    switch (type) {
      case PatternType.dominant:
        return Icons.trending_up;
      case PatternType.balanced:
        return Icons.balance;
      case PatternType.exploration:
        return Icons.explore;
      default:
        return Icons.psychology;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}

/// Phase 3 功能特性
class Phase3Feature {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String description;

  Phase3Feature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.description,
  });
}
