import 'package:flutter/material.dart';

/// 口味反馈滑块组件
///
/// 提供 1-5 星评分或滑动条形式的反馈选择
/// 支持点击和拖动操作
class TasteFeedbackSlider extends StatefulWidget {
  /// 回调函数，传出强度值（0.0-1.0）
  final ValueChanged<double> onChanged;

  /// 初始值（0.0-1.0）
  final double initialValue;

  /// 标签文本
  final String label;

  /// 是否使用星评分模式，false 则使用滑动条模式
  final bool useStarRating;

  const TasteFeedbackSlider({
    super.key,
    required this.onChanged,
    this.initialValue = 0.5,
    this.label = '请选择反馈强度',
    this.useStarRating = true,
  });

  @override
  State<TasteFeedbackSlider> createState() => _TasteFeedbackSliderState();
}

class _TasteFeedbackSliderState extends State<TasteFeedbackSlider> {
  late double _currentValue;
  int _selectedStars = 3;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _selectedStars = _valueToStars(_currentValue);
  }

  /// 将 0.0-1.0 值转换为 1-5 星
  int _valueToStars(double value) {
    return (value * 4 + 1).round().clamp(1, 5);
  }

  /// 将 1-5 星转换为 0.0-1.0 值
  double _starsToValue(int stars) {
    return (stars - 1) / 4.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getIntensityText(_currentValue),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.useStarRating)
            _buildStarRating()
          else
            _buildSlider(),
          const SizedBox(height: 16),
          _buildIntensityIndicator(),
          const SizedBox(height: 20),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  /// 构建星评分组件
  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isSelected = starIndex <= _selectedStars;
        return GestureDetector(
          onTap: () => _onStarTapped(starIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              size: 40,
              color: isSelected ? Colors.amber : Colors.grey.shade400,
            ),
          ),
        );
      }),
    );
  }

  /// 构建滑动条组件
  Widget _buildSlider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.orange,
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: Colors.orange,
            overlayColor: Colors.orange.withValues(alpha: 0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: _currentValue,
            onChanged: (value) {
              setState(() {
                _currentValue = value;
                _selectedStars = _valueToStars(value);
              });
              widget.onChanged(value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('弱', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            Text('强', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  /// 构建强度指示器
  Widget _buildIntensityIndicator() {
    final percentage = (_currentValue * 100).round();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '强度: ',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _currentValue,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  /// 构建提交按钮
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          widget.onChanged(_currentValue);
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '确认反馈',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 处理星评分点击
  void _onStarTapped(int starIndex) {
    setState(() {
      _selectedStars = starIndex;
      _currentValue = _starsToValue(starIndex);
    });
    widget.onChanged(_currentValue);
  }

  /// 获取强度描述文本
  String _getIntensityText(double value) {
    if (value <= 0.2) return '非常不喜欢';
    if (value <= 0.4) return '不太喜欢';
    if (value <= 0.6) return '一般';
    if (value <= 0.8) return '比较喜欢';
    return '非常喜欢';
  }
}

/// 显示口味反馈滑块的对话框
Future<void> showTasteFeedbackDialog({
  required BuildContext context,
  required ValueChanged<double> onFeedback,
  bool isPositive = true,
}) async {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TasteFeedbackSlider(
          label: isPositive ? '喜欢这个推荐吗？' : '为什么不喜欢？',
          initialValue: isPositive ? 0.6 : 0.4,
          useStarRating: true,
          onChanged: onFeedback,
        ),
      ),
    ),
  );
}
