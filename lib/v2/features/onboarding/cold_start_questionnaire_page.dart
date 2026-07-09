import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/cold_start_questionnaire.dart';
import '../../core/services/cold_start_service.dart';

/// 冷启动问卷页面
class ColdStartQuestionnairePage extends StatefulWidget {
  const ColdStartQuestionnairePage({
    super.key,
    required this.onCompleted,
    required this.onSkipped,
  });

  final VoidCallback onCompleted;
  final VoidCallback onSkipped;

  @override
  State<ColdStartQuestionnairePage> createState() =>
      _ColdStartQuestionnairePageState();
}

class _ColdStartQuestionnairePageState
    extends State<ColdStartQuestionnairePage> {
  final PageController _pageController = PageController();
  final ColdStartService _coldStartService = ColdStartService();

  // 当前页面索引
  int _currentPage = 0;

  // 存储每个问题的答案
  final Map<int, List<String>> _multiSelectAnswers = {};
  final Map<int, String> _singleSelectAnswers = {};

  // 是否正在处理
  bool _isProcessing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 处理多选答案变化
  void _onMultiSelectChanged(int questionId, List<String> selectedOptions) {
    setState(() {
      _multiSelectAnswers[questionId] = selectedOptions;
    });
  }

  /// 处理单选答案变化
  void _onSingleSelectChanged(int questionId, String selectedOption) {
    setState(() {
      _singleSelectAnswers[questionId] = selectedOption;
      // 单选后自动跳转下一页
      _goToNextPage();
    });
  }

  /// 跳转到下一页
  void _goToNextPage() {
    if (_currentPage < QuestionnaireQuestions.totalQuestions - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 跳转到上一页
  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 检查当前问题是否已回答
  bool _isCurrentQuestionAnswered() {
    final question = QuestionnaireQuestions.questions[_currentPage];
    if (question.isMultiSelect) {
      final answers = _multiSelectAnswers[question.id];
      return answers != null && answers.isNotEmpty;
    } else {
      return _singleSelectAnswers[question.id] != null;
    }
  }

  /// 处理完成问卷
  Future<void> _handleComplete() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 构建答案列表
      final answers = <ColdStartAnswer>[];

      for (final question in QuestionnaireQuestions.questions) {
        if (question.isMultiSelect) {
          answers.add(ColdStartAnswer(
            questionId: question.id,
            selectedOptions: _multiSelectAnswers[question.id] ?? [],
          ));
        } else {
          answers.add(ColdStartAnswer(
            questionId: question.id,
            selectedOptions: [],
            singleOption: _singleSelectAnswers[question.id],
          ));
        }
      }

      // 创建问卷数据
      final questionnaireData = ColdStartQuestionnaireData(
        answers: answers,
        completedAt: DateTime.now(),
      );

      // 保存问卷数据
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'cold_start_questionnaire_data', questionnaireData.toJsonString());

      // 初始化用户偏好
      await _coldStartService.initializeUserPreference(questionnaireData);

      // 标记问卷完成
      await _coldStartService.markQuestionnaireCompleted();

      debugPrint('问卷完成，数据已保存');

      if (mounted) {
        widget.onCompleted();
      }
    } catch (e) {
      debugPrint('处理问卷完成失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 处理跳过问卷
  Future<void> _handleSkip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('跳过问卷'),
        content: const Text(
          '确定要跳过问卷吗？\n\n推荐质量可能会受到影响，建议完成问卷以获得更精准的美食推荐。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续填写'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定跳过'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // 保存跳过状态
      final questionnaireData = ColdStartQuestionnaireData.empty();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'cold_start_questionnaire_data', questionnaireData.toJsonString());

      await _coldStartService.markQuestionnaireCompleted();

      widget.onSkipped();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: _handleSkip,
        ),
        actions: [
          TextButton(
            onPressed: _handleSkip,
            child: const Text('跳过'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 进度条
            _buildProgressBar(),

            // 页面视图
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // 禁用手动滑动
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: QuestionnaireQuestions.totalQuestions,
                itemBuilder: (context, index) {
                  final question = QuestionnaireQuestions.questions[index];
                  return _buildQuestionPage(question);
                },
              ),
            ),

            // 底部按钮
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  /// 构建进度条
  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentPage + 1} / ${QuestionnaireQuestions.totalQuestions}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  QuestionnaireQuestions.questions[_currentPage].title,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / QuestionnaireQuestions.totalQuestions,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建问题页面
  Widget _buildQuestionPage(QuestionnaireQuestion question) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24.h),

          // 问题标题
          Text(
            question.title,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 8.h),

          // 问题副标题
          Text(
            question.subtitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),

          SizedBox(height: 32.h),

          // 选项列表
          Expanded(
            child: _buildOptionsList(question),
          ),
        ],
      ),
    );
  }

  /// 构建选项列表
  Widget _buildOptionsList(QuestionnaireQuestion question) {
    if (question.isMultiSelect) {
      return _buildMultiSelectOptions(question);
    } else {
      return _buildSingleSelectOptions(question);
    }
  }

  /// 构建多选选项
  Widget _buildMultiSelectOptions(QuestionnaireQuestion question) {
    final selectedOptions = _multiSelectAnswers[question.id] ?? [];

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];
        final isSelected = selectedOptions.contains(option);

        return _buildOptionChip(
          label: option,
          isSelected: isSelected,
          onTap: () {
            final newSelection = List<String>.from(selectedOptions);
            if (isSelected) {
              newSelection.remove(option);
            } else {
              newSelection.add(option);
            }
            _onMultiSelectChanged(question.id, newSelection);
          },
        );
      },
    );
  }

  /// 构建单选选项
  Widget _buildSingleSelectOptions(QuestionnaireQuestion question) {
    final selectedOption = _singleSelectAnswers[question.id];

    return ListView.separated(
      itemCount: question.options.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final option = question.options[index];
        final isSelected = selectedOption == option;

        return _buildOptionTile(
          label: option,
          isSelected: isSelected,
          onTap: () => _onSingleSelectChanged(question.id, option),
        );
      },
    );
  }

  /// 构建选项标签（多选用）
  Widget _buildOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  /// 构建选项卡片（单选用）
  Widget _buildOptionTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }

  /// 构建底部按钮
  Widget _buildBottomButtons() {
    final isLastPage =
        _currentPage == QuestionnaireQuestions.totalQuestions - 1;

    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          // 多选时显示的"下一步"按钮
          if (!isLastPage &&
              QuestionnaireQuestions.questions[_currentPage].isMultiSelect)
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _isCurrentQuestionAnswered() ? _goToNextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '下一步',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // 最后一页的"完成"按钮
          if (isLastPage)
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26.r),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        '完成',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

          // 返回按钮（除第一页外）
          if (_currentPage > 0)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: TextButton(
                onPressed: _goToPreviousPage,
                child: Text(
                  '返回上一题',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
