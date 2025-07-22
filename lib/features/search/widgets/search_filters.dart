import 'package:flutter/material.dart';

/// 搜索筛选器组件
class SearchFilters extends StatefulWidget {
  final List<String> selectedCuisines;
  final List<String> selectedTastes;
  final RangeValues caloriesRange;
  final RangeValues ratingRange;
  final Function(List<String>, List<String>, RangeValues, RangeValues) onFiltersChanged;

  const SearchFilters({
    super.key,
    required this.selectedCuisines,
    required this.selectedTastes,
    required this.caloriesRange,
    required this.ratingRange,
    required this.onFiltersChanged,
  });

  @override
  State<SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends State<SearchFilters> {
  late List<String> _selectedCuisines;
  late List<String> _selectedTastes;
  late RangeValues _caloriesRange;
  late RangeValues _ratingRange;

  // 可选的菜系类型
  static const List<String> _cuisineTypes = [
    '川菜',
    '粤菜',
    '鲁菜',
    '苏菜',
    '浙菜',
    '闽菜',
    '湘菜',
    '徽菜',
    '日料',
    '韩料',
    '泰菜',
    '西餐',
    '法餐',
    '意菜',
    '墨西哥菜',
    '印度菜',
    '中东菜',
    '素食',
    '快餐',
    '小吃',
    '甜品',
    '饮品'
  ];

  // 可选的口味属性
  static const List<String> _tasteAttributes = [
    '甜',
    '酸',
    '苦',
    '辣',
    '咸',
    '鲜',
    '香',
    '麻',
    '清淡',
    '浓郁',
    '爽口',
    '醇厚',
    '嫩滑',
    '酥脆',
    '温润',
    '清香',
    '浓香',
    '微甜',
    '微辣',
    '不辣'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCuisines = List.from(widget.selectedCuisines);
    _selectedTastes = List.from(widget.selectedTastes);
    _caloriesRange = widget.caloriesRange;
    _ratingRange = widget.ratingRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          // 头部
          _buildHeader(),

          // 筛选内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 菜系筛选
                  _buildCuisineFilter(),
                  const SizedBox(height: 24),

                  // 口味筛选
                  _buildTasteFilter(),
                  const SizedBox(height: 24),

                  // 热量筛选
                  _buildCaloriesFilter(),
                  const SizedBox(height: 24),

                  // 评分筛选
                  _buildRatingFilter(),
                ],
              ),
            ),
          ),

          // 底部按钮
          _buildBottomActions(),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '筛选条件',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _resetFilters,
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  /// 构建菜系筛选
  Widget _buildCuisineFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('菜系类型'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _cuisineTypes.map((cuisine) {
            final isSelected = _selectedCuisines.contains(cuisine);
            return FilterChip(
              label: Text(cuisine),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCuisines.add(cuisine);
                  } else {
                    _selectedCuisines.remove(cuisine);
                  }
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor:
                  Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
        if (_selectedCuisines.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '已选择 ${_selectedCuisines.length} 种菜系',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  /// 构建口味筛选
  Widget _buildTasteFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('口味偏好'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tasteAttributes.map((taste) {
            final isSelected = _selectedTastes.contains(taste);
            return FilterChip(
              label: Text(taste),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTastes.add(taste);
                  } else {
                    _selectedTastes.remove(taste);
                  }
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor:
                  Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
        if (_selectedTastes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '已选择 ${_selectedTastes.length} 种口味',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  /// 构建热量筛选
  Widget _buildCaloriesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('热量范围 (卡路里)'),
        const SizedBox(height: 12),
        RangeSlider(
          values: _caloriesRange,
          min: 0,
          max: 1000,
          divisions: 20,
          labels: RangeLabels(
            '${_caloriesRange.start.round()}',
            '${_caloriesRange.end.round()}',
          ),
          onChanged: (values) {
            setState(() => _caloriesRange = values);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_caloriesRange.start.round()} 卡',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${_caloriesRange.end.round()} 卡',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建评分筛选
  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('评分范围'),
        const SizedBox(height: 12),
        RangeSlider(
          values: _ratingRange,
          min: 0,
          max: 5,
          divisions: 10,
          labels: RangeLabels(
            _ratingRange.start.toStringAsFixed(1),
            _ratingRange.end.toStringAsFixed(1),
          ),
          onChanged: (values) {
            setState(() => _ratingRange = values);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  _ratingRange.start.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 12, color: Colors.amber),
              ],
            ),
            Row(
              children: [
                Text(
                  _ratingRange.end.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 12, color: Colors.amber),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 构建节标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// 构建底部操作按钮
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _applyFilters,
                child: const Text('应用筛选'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 重置筛选器
  void _resetFilters() {
    setState(() {
      _selectedCuisines.clear();
      _selectedTastes.clear();
      _caloriesRange = const RangeValues(0, 1000);
      _ratingRange = const RangeValues(0, 5);
    });
  }

  /// 应用筛选器
  void _applyFilters() {
    widget.onFiltersChanged(
      _selectedCuisines,
      _selectedTastes,
      _caloriesRange,
      _ratingRange,
    );
    Navigator.of(context).pop();
  }
}
