import 'package:flutter/material.dart';
import '../../../core/models/recipe.dart';

/// 菜谱筛选底部面板
class RecipeFilterSheet extends StatefulWidget {
  final String? selectedCuisine;
  final RecipeDifficulty? selectedDifficulty;
  final int? maxTime;
  final Function(String? cuisine, RecipeDifficulty? difficulty, int? maxTime)
      onApply;

  const RecipeFilterSheet({
    super.key,
    this.selectedCuisine,
    this.selectedDifficulty,
    this.maxTime,
    required this.onApply,
  });

  @override
  State<RecipeFilterSheet> createState() => _RecipeFilterSheetState();
}

class _RecipeFilterSheetState extends State<RecipeFilterSheet> {
  String? _selectedCuisine;
  RecipeDifficulty? _selectedDifficulty;
  int? _maxTime;

  final List<String> _cuisines = ['川菜', '粤菜', '江浙菜', '湘菜', '家常菜', '素食'];
  final List<RecipeDifficulty> _difficulties = RecipeDifficulty.values;
  final List<int> _timeLimits = [30, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _selectedCuisine = widget.selectedCuisine;
    _selectedDifficulty = widget.selectedDifficulty;
    _maxTime = widget.maxTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '筛选条件',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('重置'),
                ),
              ],
            ),
          ),

          // 筛选内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 菜系选择
                  _buildSectionTitle('菜系'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _cuisines.map((cuisine) {
                      final isSelected = _selectedCuisine == cuisine;
                      return FilterChip(
                        label: Text(cuisine),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCuisine = selected ? cuisine : null;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 难度选择
                  _buildSectionTitle('难度'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _difficulties.map((difficulty) {
                      final isSelected = _selectedDifficulty == difficulty;
                      return FilterChip(
                        label: Text(difficulty.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedDifficulty = selected ? difficulty : null;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 时间选择
                  _buildSectionTitle('制作时间'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeLimits.map((time) {
                      final isSelected = _maxTime == time;
                      return FilterChip(
                        label: Text('≤$time分钟'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _maxTime = selected ? time : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // 底部按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('应用'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedCuisine = null;
      _selectedDifficulty = null;
      _maxTime = null;
    });
  }

  void _applyFilters() {
    widget.onApply(_selectedCuisine, _selectedDifficulty, _maxTime);
    Navigator.pop(context);
  }
}
