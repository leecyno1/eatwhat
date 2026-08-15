import 'dart:convert';

/// 冷启动问卷答案模型
class ColdStartAnswer {
  final int questionId;
  final List<String> selectedOptions; // 多选
  final String? singleOption; // 单选

  const ColdStartAnswer({
    required this.questionId,
    required this.selectedOptions,
    this.singleOption,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedOptions': selectedOptions,
      'singleOption': singleOption,
    };
  }

  factory ColdStartAnswer.fromJson(Map<String, dynamic> json) {
    return ColdStartAnswer(
      questionId: json['questionId'] as int,
      selectedOptions: List<String>.from(json['selectedOptions'] ?? []),
      singleOption: json['singleOption'] as String?,
    );
  }
}

/// 冷启动问卷数据模型
class ColdStartQuestionnaireData {
  final List<ColdStartAnswer> answers;
  final DateTime completedAt;
  final bool skipped;

  const ColdStartQuestionnaireData({
    required this.answers,
    required this.completedAt,
    this.skipped = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'answers': answers.map((a) => a.toJson()).toList(),
      'completedAt': completedAt.toIso8601String(),
      'skipped': skipped,
    };
  }

  factory ColdStartQuestionnaireData.fromJson(Map<String, dynamic> json) {
    return ColdStartQuestionnaireData(
      answers: (json['answers'] as List<dynamic>?)
              ?.map((a) => ColdStartAnswer.fromJson(a))
              .toList() ??
          [],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : DateTime.now(),
      skipped: json['skipped'] as bool? ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ColdStartQuestionnaireData.fromJsonString(String jsonString) {
    return ColdStartQuestionnaireData.fromJson(jsonDecode(jsonString));
  }

  /// 创建空的问卷数据（用于跳过）
  factory ColdStartQuestionnaireData.empty() {
    return ColdStartQuestionnaireData(
      answers: [],
      completedAt: DateTime.now(),
      skipped: true,
    );
  }

  /// 检查是否有效完成
  bool get isValid => answers.isNotEmpty || skipped;
}

/// 问卷问题定义
class QuestionnaireQuestion {
  final int id;
  final String title;
  final String subtitle;
  final List<String> options;
  final bool isMultiSelect; // 是否多选

  const QuestionnaireQuestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.options,
    this.isMultiSelect = false,
  });
}

/// 预定义的问卷题目
class QuestionnaireQuestions {
  static const List<QuestionnaireQuestion> questions = [
    QuestionnaireQuestion(
      id: 1,
      title: '你更喜欢什么菜系？',
      subtitle: '可多选，我们会为你推荐更合适的美食',
      options: ['川菜', '粤菜', '湘菜', '鲁菜', '苏菜', '闽菜', '浙菜', '徽菜', '西餐', '日料', '韩料', '其他'],
      isMultiSelect: true,
    ),
    QuestionnaireQuestion(
      id: 2,
      title: '你有什么忌口吗？',
      subtitle: '选择后会为你避开相关食物',
      options: ['无忌口', '海鲜过敏', '芒果过敏', '乳糖不耐', '素食', '清真', '其他'],
      isMultiSelect: true,
    ),
    QuestionnaireQuestion(
      id: 3,
      title: '你喜欢什么口味？',
      subtitle: '可多选，让我们更了解你的味觉偏好',
      options: ['辣', '微辣', '不辣', '酸', '甜', '苦', '咸', '鲜'],
      isMultiSelect: true,
    ),
    QuestionnaireQuestion(
      id: 4,
      title: '你通常在什么场景用餐？',
      subtitle: '选择一个最常用的场景',
      options: ['在家做饭', '外卖', '堂食', '都可以'],
      isMultiSelect: false,
    ),
    QuestionnaireQuestion(
      id: 5,
      title: '你的用餐人数通常是？',
      subtitle: '这会帮助我们推荐合适的分量',
      options: ['1人', '2-3人', '4-6人', '6人以上'],
      isMultiSelect: false,
    ),
  ];

  static int get totalQuestions => questions.length;
}
