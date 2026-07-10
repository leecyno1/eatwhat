import 'dart:math';

import '../models/user_behavior_models.dart';
import '../engines/ai_preference_learning_engine.dart';

/// 智能对话推荐系统 - Phase 3 AI驱动的会话式推荐
/// 通过自然语言交互提供个性化菜谱推荐
class SmartConversationalRecommender {
  static final SmartConversationalRecommender _instance =
      SmartConversationalRecommender._internal();
  factory SmartConversationalRecommender() => _instance;
  SmartConversationalRecommender._internal();

  final AIPreferenceLearningEngine _aiEngine = AIPreferenceLearningEngine();

  // 对话上下文管理
  final Map<String, ConversationContext> _conversations = {};

  // 意图识别器
  final IntentRecognizer _intentRecognizer = IntentRecognizer();

  /// 开始新的推荐对话
  Future<ConversationResponse> startConversation(String userId) async {
    final context = ConversationContext(
      userId: userId,
      sessionId: _generateSessionId(),
      startTime: DateTime.now(),
    );

    _conversations[userId] = context;

    // 获取用户偏好洞察
    final userInsights = _aiEngine.getUserInsights(userId);

    // 生成个性化开场白
    final greeting = _generatePersonalizedGreeting(userInsights);

    return ConversationResponse(
      message: greeting,
      suggestions: _getInitialSuggestions(),
      contextActions: [
        ContextAction.quickStart,
        ContextAction.browseCategories,
        ContextAction.surpriseMe,
      ],
      nextSteps: NextSteps.waitingForInput,
    );
  }

  /// 处理用户输入
  Future<ConversationResponse> processUserInput({
    required String userId,
    required String userInput,
    Map<String, dynamic>? contextData,
  }) async {
    final context = _conversations[userId];
    if (context == null) {
      return await startConversation(userId);
    }

    // 更新对话历史
    context.addUserMessage(userInput, contextData);

    // 识别用户意图
    final intent = await _intentRecognizer.recognizeIntent(userInput, context);

    // 记录用户行为
    await _recordConversationBehavior(userId, intent, userInput);

    // 基于意图生成响应
    final response = await _generateResponseForIntent(userId, intent, context);

    // 更新对话上下文
    context.addSystemMessage(response.message);
    context.currentIntent = intent;

    return response;
  }

  /// 获取智能推荐
  Future<ConversationResponse> getSmartRecommendations({
    required String userId,
    String? specificRequest,
    int count = 5,
  }) async {
    final context = _conversations[userId] ??
        ConversationContext(
          userId: userId,
          sessionId: _generateSessionId(),
          startTime: DateTime.now(),
        );

    // 从对话历史中提取约束
    final constraints = _extractConstraintsFromConversation(context);

    // 获取AI推荐
    final recommendations = await _aiEngine.getIntelligentRecommendations(
      userId: userId,
      count: count,
      contextHint: specificRequest ?? context.getContextSummary(),
      constraints: constraints,
    );

    if (recommendations.isEmpty) {
      return ConversationResponse(
        message: '抱歉，没有找到符合您要求的菜谱。让我们换个方向试试？',
        suggestions: _getAlternativeSuggestions(),
        contextActions: [ContextAction.adjustCriteria, ContextAction.surpriseMe],
        nextSteps: NextSteps.waitingForInput,
      );
    }

    // 生成推荐说明
    final explanationMessage = _generateRecommendationExplanation(recommendations, context);

    return ConversationResponse(
      message: explanationMessage,
      recommendations: recommendations,
      suggestions: _getFollowUpSuggestions(recommendations),
      contextActions: [
        ContextAction.showMore,
        ContextAction.refineSearch,
        ContextAction.cookNow,
      ],
      nextSteps: NextSteps.awaitingFeedback,
    );
  }

  /// 处理用户反馈
  Future<ConversationResponse> processFeedback({
    required String userId,
    required String recipeId,
    required FeedbackType feedbackType,
    String? comment,
  }) async {
    // 学习用户反馈
    await _aiEngine.learnFromFeedback(
      userId: userId,
      recipeId: recipeId,
      feedbackType: feedbackType,
      comment: comment,
    );

    final context = _conversations[userId];
    if (context != null) {
      context.addFeedback(recipeId, feedbackType, comment);
    }

    // 生成反馈响应
    final response = _generateFeedbackResponse(feedbackType, comment);

    // 基于反馈调整后续推荐
    final adjustedRecommendations = await _getAdjustedRecommendations(
      userId,
      feedbackType,
      recipeId,
    );

    return ConversationResponse(
      message: response,
      recommendations: adjustedRecommendations,
      suggestions: _getPostFeedbackSuggestions(feedbackType),
      contextActions: [
        ContextAction.showSimilar,
        ContextAction.showDifferent,
        ContextAction.continueExploring,
      ],
      nextSteps: NextSteps.waitingForInput,
    );
  }

  /// 处理快速动作
  Future<ConversationResponse> handleQuickAction({
    required String userId,
    required QuickActionType actionType,
    Map<String, dynamic>? actionData,
  }) async {
    switch (actionType) {
      case QuickActionType.surpriseMe:
        return await _handleSurpriseMe(userId);

      case QuickActionType.quickStart:
        return await _handleQuickStart(userId);

      case QuickActionType.browseCategory:
        final category = actionData?['category'] as String?;
        return await _handleBrowseCategory(userId, category);

      case QuickActionType.filterByTime:
        final maxTime = actionData?['maxTime'] as int?;
        return await _handleFilterByTime(userId, maxTime);

      case QuickActionType.filterByDifficulty:
        final difficulty = actionData?['difficulty'] as String?;
        return await _handleFilterByDifficulty(userId, difficulty);

      case QuickActionType.nutritionFocus:
        final nutritionType = actionData?['nutritionType'] as String?;
        return await _handleNutritionFocus(userId, nutritionType);
    }
  }

  /// 获取对话总结
  Map<String, dynamic> getConversationSummary(String userId) {
    final context = _conversations[userId];
    if (context == null) return {};

    return {
      'sessionId': context.sessionId,
      'duration': DateTime.now().difference(context.startTime).inMinutes,
      'messageCount': context.messageHistory.length,
      'intentsDiscussed': context.intentsHistory.map((i) => i.type.name).toSet().toList(),
      'recommendationsShown': context.shownRecommendations.length,
      'feedbackGiven': context.userFeedbacks.length,
      'currentFocus': context.currentIntent?.type.name,
      'userSatisfaction': _calculateUserSatisfaction(context),
      'nextSuggestions': _getContextualSuggestions(context),
    };
  }

  // ===== 私有方法实现 =====

  /// 生成个性化开场白
  String _generatePersonalizedGreeting(Map<String, dynamic> userInsights) {
    final activityScore = userInsights['activityScore'] as double? ?? 0.0;
    final topPrefs = userInsights['topPreferences'] as List? ?? [];

    if (activityScore > 0.7 && topPrefs.isNotEmpty) {
      final topPref = topPrefs.first.toString();
      return '🍳 欢迎回来！根据您的偏好，我注意到您特别喜欢$topPref，今天想试试什么新花样吗？';
    } else if (activityScore > 0.3) {
      return '👋 您好！基于您之前的选择，我为您准备了一些精选推荐。您今天想吃什么类型的菜？';
    } else {
      return '🌟 欢迎使用智能菜谱推荐！我会根据您的喜好为您推荐最合适的菜谱。告诉我您想吃什么吧！';
    }
  }

  List<String> _getInitialSuggestions() {
    return [
      '🎲 给我个惊喜',
      '🏠 家常菜',
      '⚡ 快手菜',
      '🥗 健康轻食',
      '🌶️ 川菜',
      '🦐 海鲜',
    ];
  }

  /// 记录对话行为
  Future<void> _recordConversationBehavior(
      String userId, UserIntent intent, String userInput) async {
    final behavior = UserBehaviorData(
      userId: userId,
      sessionId: _conversations[userId]?.sessionId ?? '',
      timestamp: DateTime.now(),
      actionType: UserActionType.search,
      targetId: intent.type.name,
      targetType: 'conversation',
      actionDetails: {
        'intentType': intent.type.name,
        'userInput': userInput,
        'confidence': intent.confidence,
        'extractedEntities': intent.entities,
      },
      actionIntensity: intent.confidence,
    );

    await _aiEngine.recordUserBehavior(behavior);
  }

  /// 基于意图生成响应
  Future<ConversationResponse> _generateResponseForIntent(
      String userId, UserIntent intent, ConversationContext context) async {
    switch (intent.type) {
      case IntentType.requestRecommendation:
        return await _handleRecommendationRequest(userId, intent, context);

      case IntentType.specifyPreference:
        return await _handlePreferenceSpecification(userId, intent, context);

      case IntentType.askQuestion:
        return await _handleQuestion(userId, intent, context);

      case IntentType.expressConstraint:
        return await _handleConstraint(userId, intent, context);

      case IntentType.requestInfo:
        return await _handleInfoRequest(userId, intent, context);

      case IntentType.casual:
        return _handleCasualChat(intent);
    }
  }

  /// 处理推荐请求
  Future<ConversationResponse> _handleRecommendationRequest(
      String userId, UserIntent intent, ConversationContext context) async {
    final specificRequest =
        intent.entities['dish'] ?? intent.entities['cuisine'] ?? intent.entities['ingredient'];

    return await getSmartRecommendations(
      userId: userId,
      specificRequest: specificRequest,
      count: 5,
    );
  }

  /// 处理偏好说明
  Future<ConversationResponse> _handlePreferenceSpecification(
      String userId, UserIntent intent, ConversationContext context) async {
    // 更新用户偏好权重
    final preferenceUpdates = _extractPreferenceUpdates(intent);
    if (preferenceUpdates.isNotEmpty) {
      await _aiEngine.updatePreferenceWeights(userId, preferenceUpdates);
    }

    context.addPreference(intent.entities);

    return ConversationResponse(
      message: '好的，我已经记住您的偏好了。${_generatePreferenceConfirmation(intent)}',
      suggestions: [
        '根据这个偏好推荐',
        '我还有其他要求',
        '开始推荐吧',
      ],
      contextActions: [ContextAction.showRecommendations],
      nextSteps: NextSteps.readyToRecommend,
    );
  }

  /// 处理问题
  Future<ConversationResponse> _handleQuestion(
      String userId, UserIntent intent, ConversationContext context) async {
    final questionType = intent.entities['questionType'];
    final answer = await _generateAnswer(questionType, intent.entities);

    return ConversationResponse(
      message: answer,
      suggestions: _getQuestionFollowUpSuggestions(questionType),
      contextActions: [ContextAction.continueConversation],
      nextSteps: NextSteps.waitingForInput,
    );
  }

  /// 处理约束条件
  Future<ConversationResponse> _handleConstraint(
      String userId, UserIntent intent, ConversationContext context) async {
    context.addConstraint(intent.entities);

    final constraintSummary = _summarizeConstraints(context.constraints);

    return ConversationResponse(
      message: '明白了，我会考虑这些条件：$constraintSummary。准备为您推荐了！',
      suggestions: [
        '开始推荐',
        '我还有条件',
        '修改条件',
      ],
      contextActions: [ContextAction.showRecommendations],
      nextSteps: NextSteps.readyToRecommend,
    );
  }

  /// 处理信息请求
  Future<ConversationResponse> _handleInfoRequest(
      String userId, UserIntent intent, ConversationContext context) async {
    final infoType = intent.entities['infoType'];
    final info = await _generateInformation(infoType, intent.entities);

    return ConversationResponse(
      message: info,
      suggestions: _getInfoFollowUpSuggestions(infoType),
      contextActions: [ContextAction.continueConversation],
      nextSteps: NextSteps.waitingForInput,
    );
  }

  /// 处理闲聊
  ConversationResponse _handleCasualChat(UserIntent intent) {
    final casualResponse = _generateCasualResponse(intent.entities['sentiment']);

    return ConversationResponse(
      message: casualResponse,
      suggestions: [
        '推荐菜谱',
        '随便聊聊',
        '我想做菜',
      ],
      contextActions: [ContextAction.redirectToRecommendation],
      nextSteps: NextSteps.waitingForInput,
    );
  }

  // 快速动作处理方法
  Future<ConversationResponse> _handleSurpriseMe(String userId) async {
    final recommendations = await _aiEngine.getIntelligentRecommendations(
      userId: userId,
      count: 3,
      contextHint: '用户想要惊喜推荐',
    );

    return ConversationResponse(
      message: '🎲 为您挑选了几道特别的菜谱，相信会给您带来惊喜！',
      recommendations: recommendations,
      suggestions: ['再来一个惊喜', '我喜欢这些', '换换口味'],
      contextActions: [ContextAction.showMore, ContextAction.refineSearch],
      nextSteps: NextSteps.awaitingFeedback,
    );
  }

  Future<ConversationResponse> _handleQuickStart(String userId) async {
    return ConversationResponse(
      message: '🚀 让我们快速开始！请选择您的偏好：',
      suggestions: [
        '🏠 家常菜',
        '⚡ 15分钟快手',
        '🌶️ 重口味',
        '🥗 清淡健康',
        '🍜 汤汤水水',
      ],
      contextActions: [ContextAction.quickFilter],
      nextSteps: NextSteps.waitingForSelection,
    );
  }

  Future<ConversationResponse> _handleBrowseCategory(String userId, String? category) async {
    final categoryName = category ?? '家常菜';

    final recommendations = await _aiEngine.getIntelligentRecommendations(
      userId: userId,
      count: 6,
      constraints: {'cuisine': categoryName},
    );

    return ConversationResponse(
      message: '🍽️ 为您推荐${categoryName}分类下的精选菜谱：',
      recommendations: recommendations,
      suggestions: ['看其他分类', '这些不错', '换个风味'],
      contextActions: [ContextAction.browseCategories, ContextAction.showMore],
      nextSteps: NextSteps.awaitingFeedback,
    );
  }

  Future<ConversationResponse> _handleFilterByTime(String userId, int? maxTime) async {
    final timeLimit = maxTime ?? 30;

    final recommendations = await _aiEngine.getIntelligentRecommendations(
      userId: userId,
      count: 5,
      constraints: {'maxCookingTime': timeLimit},
    );

    return ConversationResponse(
      message: '⏰ 为您推荐${timeLimit}分钟内能完成的菜谱：',
      recommendations: recommendations,
      suggestions: ['15分钟内', '1小时内', '时间不限'],
      contextActions: [ContextAction.adjustTimeFilter],
      nextSteps: NextSteps.awaitingFeedback,
    );
  }

  Future<ConversationResponse> _handleFilterByDifficulty(String userId, String? difficulty) async {
    final difficultyLevel = difficulty ?? '简单';

    final recommendations = await _aiEngine.getIntelligentRecommendations(
      userId: userId,
      count: 5,
      constraints: {'difficulty': difficultyLevel},
    );

    return ConversationResponse(
      message: '👨‍🍳 为您推荐${difficultyLevel}级别的菜谱：',
      recommendations: recommendations,
      suggestions: ['新手级', '进阶级', '大师级'],
      contextActions: [ContextAction.adjustDifficultyFilter],
      nextSteps: NextSteps.awaitingFeedback,
    );
  }

  Future<ConversationResponse> _handleNutritionFocus(String userId, String? nutritionType) async {
    final nutrition = nutritionType ?? '高蛋白';

    final recommendations = await _aiEngine.getIntelligentRecommendations(
      userId: userId,
      count: 5,
      constraints: {'nutritionFocus': nutrition},
    );

    return ConversationResponse(
      message: '🥗 为您推荐${nutrition}的健康菜谱：',
      recommendations: recommendations,
      suggestions: ['低卡路里', '高蛋白', '富含维生素'],
      contextActions: [ContextAction.nutritionInfo],
      nextSteps: NextSteps.awaitingFeedback,
    );
  }

  // 辅助方法实现
  String _generateSessionId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  Map<String, dynamic> _extractConstraintsFromConversation(ConversationContext context) {
    // 从对话历史中提取约束条件
    return context.constraints;
  }

  String _generateRecommendationExplanation(
      List<RecipeRecommendation> recommendations, ConversationContext context) {
    if (recommendations.isEmpty) return '没有找到合适的推荐。';

    final topScore = recommendations.first.score;
    if (topScore > 0.8) {
      return '🎯 基于您的偏好，我为您精选了这些高匹配度的菜谱：';
    } else if (topScore > 0.6) {
      return '✨ 根据您的要求，这些菜谱应该很适合您：';
    } else {
      return '🔍 为您找到了一些相关的菜谱，希望您会喜欢：';
    }
  }

  List<String> _getFollowUpSuggestions(List<RecipeRecommendation> recommendations) {
    return [
      '我喜欢第一个',
      '都不太感兴趣',
      '看看详细做法',
      '换换其他的',
      '收藏几个',
    ];
  }

  List<String> _getAlternativeSuggestions() {
    return [
      '放宽条件',
      '换个菜系',
      '随机推荐',
      '热门菜谱',
    ];
  }

  String _generateFeedbackResponse(FeedbackType feedbackType, String? comment) {
    switch (feedbackType) {
      case FeedbackType.love:
        return '😍 太棒了！我记住您特别喜欢这类菜谱了，会为您推荐更多类似的。';
      case FeedbackType.like:
        return '😊 很高兴您喜欢！我会继续为您推荐这种风格的菜谱。';
      case FeedbackType.neutral:
        return '🤔 了解了，让我为您调整一下推荐方向。';
      case FeedbackType.dislike:
        return '😅 好的，我会避免推荐这类菜谱，为您寻找更合适的选择。';
    }
  }

  Future<List<RecipeRecommendation>> _getAdjustedRecommendations(
      String userId, FeedbackType feedbackType, String recipeId) async {
    // 基于反馈调整推荐策略
    final contextHint = feedbackType == FeedbackType.like || feedbackType == FeedbackType.love
        ? '推荐相似的菜谱'
        : '推荐不同风格的菜谱';

    return await _aiEngine.getIntelligentRecommendations(
      userId: userId,
      count: 3,
      contextHint: contextHint,
    );
  }

  List<String> _getPostFeedbackSuggestions(FeedbackType feedbackType) {
    if (feedbackType == FeedbackType.like || feedbackType == FeedbackType.love) {
      return ['推荐相似的', '看看做法', '收藏起来'];
    } else {
      return ['换个风格', '重新推荐', '调整偏好'];
    }
  }

  Map<String, double> _extractPreferenceUpdates(UserIntent intent) {
    // 从意图中提取偏好更新
    final updates = <String, double>{};

    final entities = intent.entities;
    if (entities.containsKey('taste')) {
      updates['taste_${entities['taste']}'] = 0.8;
    }
    if (entities.containsKey('cuisine')) {
      updates['cuisine_${entities['cuisine']}'] = 0.8;
    }

    return updates;
  }

  String _generatePreferenceConfirmation(UserIntent intent) {
    final taste = intent.entities['taste'];
    final cuisine = intent.entities['cuisine'];

    if (taste != null && cuisine != null) {
      return '您喜欢${taste}的${cuisine}，我会重点推荐这类菜谱。';
    } else if (taste != null) {
      return '您偏爱${taste}口味，我会为您推荐更多这种口味的菜谱。';
    } else if (cuisine != null) {
      return '您对${cuisine}感兴趣，我会多推荐这个菜系的菜谱。';
    }

    return '您的偏好我都记下了。';
  }

  Future<String> _generateAnswer(String? questionType, Map<String, String> entities) async {
    // 根据问题类型生成答案
    return '这是一个很好的问题，让我为您详细解答...';
  }

  List<String> _getQuestionFollowUpSuggestions(String? questionType) {
    return ['继续了解', '开始推荐', '其他问题'];
  }

  String _summarizeConstraints(Map<String, dynamic> constraints) {
    // 总结约束条件
    final items = constraints.entries.map((e) => '${e.key}:${e.value}').toList();
    return items.join('、');
  }

  Future<String> _generateInformation(String? infoType, Map<String, String> entities) async {
    // 生成信息回复
    return '根据您的询问，这里是相关信息...';
  }

  List<String> _getInfoFollowUpSuggestions(String? infoType) {
    return ['了解更多', '开始做菜', '看看推荐'];
  }

  String _generateCasualResponse(String? sentiment) {
    // 生成闲聊回复
    return '😊 很高兴和您聊天！有什么想吃的吗？';
  }

  double _calculateUserSatisfaction(ConversationContext context) {
    // 计算用户满意度
    final positiveFeedbacks = context.userFeedbacks
        .where((f) => f.feedbackType == FeedbackType.like || f.feedbackType == FeedbackType.love)
        .length;
    final totalFeedbacks = context.userFeedbacks.length;

    return totalFeedbacks > 0 ? positiveFeedbacks / totalFeedbacks : 0.5;
  }

  List<String> _getContextualSuggestions(ConversationContext context) {
    // 基于上下文生成建议
    return ['继续推荐', '调整偏好', '结束对话'];
  }
}

/// 对话上下文
class ConversationContext {
  final String userId;
  final String sessionId;
  final DateTime startTime;

  final List<ConversationMessage> messageHistory = [];
  final List<UserIntent> intentsHistory = [];
  final List<String> shownRecommendations = [];
  final List<UserFeedback> userFeedbacks = [];
  final Map<String, dynamic> constraints = {};
  final Map<String, dynamic> preferences = {};

  UserIntent? currentIntent;

  ConversationContext({
    required this.userId,
    required this.sessionId,
    required this.startTime,
  });

  void addUserMessage(String message, Map<String, dynamic>? contextData) {
    messageHistory.add(ConversationMessage(
      isUser: true,
      content: message,
      timestamp: DateTime.now(),
      contextData: contextData,
    ));
  }

  void addSystemMessage(String message) {
    messageHistory.add(ConversationMessage(
      isUser: false,
      content: message,
      timestamp: DateTime.now(),
    ));
  }

  void addFeedback(String recipeId, FeedbackType feedbackType, String? comment) {
    userFeedbacks.add(UserFeedback(
      recipeId: recipeId,
      feedbackType: feedbackType,
      comment: comment,
      timestamp: DateTime.now(),
    ));
  }

  void addConstraint(Map<String, String> newConstraints) {
    constraints.addAll(newConstraints);
  }

  void addPreference(Map<String, String> newPreferences) {
    preferences.addAll(newPreferences);
  }

  String getContextSummary() {
    final recentMessages = messageHistory.take(5).map((m) => m.content).join(' ');
    return recentMessages;
  }
}

/// 对话消息
class ConversationMessage {
  final bool isUser;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? contextData;

  ConversationMessage({
    required this.isUser,
    required this.content,
    required this.timestamp,
    this.contextData,
  });
}

/// 用户反馈
class UserFeedback {
  final String recipeId;
  final FeedbackType feedbackType;
  final String? comment;
  final DateTime timestamp;

  UserFeedback({
    required this.recipeId,
    required this.feedbackType,
    this.comment,
    required this.timestamp,
  });
}

/// 意图识别器
class IntentRecognizer {
  Future<UserIntent> recognizeIntent(String userInput, ConversationContext context) async {
    // 简化的意图识别逻辑
    final input = userInput.toLowerCase();

    if (input.contains('推荐') || input.contains('想吃') || input.contains('做什么')) {
      return UserIntent(
        type: IntentType.requestRecommendation,
        confidence: 0.9,
        entities: _extractEntities(userInput),
      );
    } else if (input.contains('喜欢') || input.contains('偏爱') || input.contains('口味')) {
      return UserIntent(
        type: IntentType.specifyPreference,
        confidence: 0.8,
        entities: _extractEntities(userInput),
      );
    } else if (input.contains('?') || input.contains('？') || input.contains('怎么')) {
      return UserIntent(
        type: IntentType.askQuestion,
        confidence: 0.7,
        entities: _extractEntities(userInput),
      );
    } else if (input.contains('不要') || input.contains('限制') || input.contains('条件')) {
      return UserIntent(
        type: IntentType.expressConstraint,
        confidence: 0.8,
        entities: _extractEntities(userInput),
      );
    } else {
      return UserIntent(
        type: IntentType.casual,
        confidence: 0.5,
        entities: _extractEntities(userInput),
      );
    }
  }

  Map<String, String> _extractEntities(String input) {
    final entities = <String, String>{};

    // 简化的实体抽取
    final cuisines = ['川菜', '粤菜', '湘菜', '鲁菜', '家常菜', '西餐'];
    final tastes = ['酸', '甜', '苦', '辣', '咸', '鲜', '香'];

    for (final cuisine in cuisines) {
      if (input.contains(cuisine)) {
        entities['cuisine'] = cuisine;
        break;
      }
    }

    for (final taste in tastes) {
      if (input.contains(taste)) {
        entities['taste'] = taste;
        break;
      }
    }

    return entities;
  }
}

/// 响应生成器
class ResponseGenerator {
  // 预留，用于复杂的响应生成逻辑
  String generateResponse() {
    return 'Generated response';
  }
}

/// 用户意图
class UserIntent {
  final IntentType type;
  final double confidence;
  final Map<String, String> entities;

  UserIntent({
    required this.type,
    required this.confidence,
    required this.entities,
  });
}

/// 意图类型
enum IntentType {
  requestRecommendation,
  specifyPreference,
  askQuestion,
  expressConstraint,
  requestInfo,
  casual,
}

/// 对话响应
class ConversationResponse {
  final String message;
  final List<RecipeRecommendation>? recommendations;
  final List<String> suggestions;
  final List<ContextAction> contextActions;
  final NextSteps nextSteps;

  ConversationResponse({
    required this.message,
    this.recommendations,
    required this.suggestions,
    required this.contextActions,
    required this.nextSteps,
  });
}

/// 上下文动作
enum ContextAction {
  quickStart,
  browseCategories,
  surpriseMe,
  showMore,
  refineSearch,
  cookNow,
  showSimilar,
  showDifferent,
  continueExploring,
  adjustCriteria,
  showRecommendations,
  continueConversation,
  redirectToRecommendation,
  quickFilter,
  adjustTimeFilter,
  adjustDifficultyFilter,
  nutritionInfo,
}

/// 下一步状态
enum NextSteps {
  waitingForInput,
  waitingForSelection,
  readyToRecommend,
  awaitingFeedback,
}

/// 快速动作类型
enum QuickActionType {
  surpriseMe,
  quickStart,
  browseCategory,
  filterByTime,
  filterByDifficulty,
  nutritionFocus,
}
