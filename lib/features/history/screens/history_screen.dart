import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../recommendation/widgets/food_card.dart';
import '../widgets/history_empty_state.dart';
import '../../../core/models/food.dart';
import '../../../core/services/storage_service.dart';

/// 历史记录页面
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  List<Food> _historyFoods = [];
  List<Food> _filteredFoods = [];
  bool _isLoading = true;
  String _filterBy = 'all'; // all, today, week, month

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _listController;
  late Animation<double> _listAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listController, curve: Curves.easeOutBack),
    );

    _loadHistory();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _listController.dispose();
    super.dispose();
  }

  /// 加载历史记录
  Future<void> _loadHistory() async {
    try {
      final historyData = StorageService.getFoodHistory();
      final foods = <Food>[];

      // 这里需要根据实际的存储格式来解析数据
      for (final data in historyData) {
        foods.add(Food.fromJson(data));
      }

      setState(() {
        _historyFoods = foods;
        _isLoading = false;
      });

      _applyFilter();
      _fadeController.forward();
      _listController.forward();
    } catch (e) {
      debugPrint('加载历史记录失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 应用筛选
  void _applyFilter() {
    final now = DateTime.now();
    List<Food> filtered = [];

    switch (_filterBy) {
      case 'today':
        // 筛选今天的记录
        filtered = _historyFoods.where((food) {
          // 这里需要根据实际的时间戳字段来筛选
          return true; // 暂时返回所有
        }).toList();
        break;
      case 'week':
        // 筛选本周的记录
        filtered = _historyFoods.where((food) {
          return true; // 暂时返回所有
        }).toList();
        break;
      case 'month':
        // 筛选本月的记录
        filtered = _historyFoods.where((food) {
          return true; // 暂时返回所有
        }).toList();
        break;
      case 'all':
      default:
        filtered = List.from(_historyFoods);
        break;
    }

    setState(() {
      _filteredFoods = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('浏览历史'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterBy = value;
              });
              _applyFilter();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('全部')),
              const PopupMenuItem(value: 'today', child: Text('今天')),
              const PopupMenuItem(value: 'week', child: Text('本周')),
              const PopupMenuItem(value: 'month', child: Text('本月')),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(),
      ),
    );
  }

  /// 构建主体内容
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载历史记录...'),
          ],
        ),
      );
    }

    if (_filteredFoods.isEmpty) {
      return HistoryEmptyState(
        filterBy: _filterBy,
        onClearFilter: () {
          setState(() {
            _filterBy = 'all';
            _applyFilter();
          });
        },
      );
    }

    return Column(
      children: [
        // 历史统计
        _buildHistoryStats(),

        // 历史列表
        Expanded(
          child: FadeTransition(
            opacity: _listAnimation,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredFoods.length,
              itemBuilder: (context, index) {
                final food = _filteredFoods[index];

                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + index * 50),
                  curve: Curves.easeOutBack,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Dismissible(
                    key: Key('history_${food.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '删除',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onDismissed: (direction) {
                      _removeFromHistory(food, index);
                    },
                    child: FoodCard(
                      food: food,
                      onTap: () => _showFoodDetail(food),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 构建历史统计
  Widget _buildHistoryStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              '总浏览数',
              _historyFoods.length.toString(),
              Icons.visibility,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              _getFilterDisplayName(),
              _filteredFoods.length.toString(),
              Icons.filter_list,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计项目
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
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

  /// 获取筛选显示名称
  String _getFilterDisplayName() {
    switch (_filterBy) {
      case 'today':
        return '今日浏览';
      case 'week':
        return '本周浏览';
      case 'month':
        return '本月浏览';
      case 'all':
      default:
        return '当前筛选';
    }
  }

  /// 从历史记录中移除
  Future<void> _removeFromHistory(Food food, int index) async {
    try {
      await StorageService.removeFoodHistory(food.id);

      setState(() {
        _historyFoods.removeWhere((f) => f.id == food.id);
        _filteredFoods.removeAt(index);
      });

      HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已从历史记录中移除 "${food.name}"'),
            action: SnackBarAction(
              label: '撤销',
              onPressed: () async {
                // 重新添加到历史记录
                await StorageService.addFoodHistory(food);
                _loadHistory();
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('移除历史记录失败: $e');
    }
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite(Food food) async {
    try {
      if (StorageService.isFoodFavorited(food.id)) {
        await StorageService.removeFavoriteFood(food.id);
      } else {
        await StorageService.addFavoriteFood(food);
      }

      setState(() {}); // 刷新UI
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('切换收藏失败: $e');
    }
  }

  /// 显示食物详情
  void _showFoodDetail(Food food) {
    // 这里可以导航到食物详情页面
    debugPrint('显示食物详情: ${food.name}');
  }
}
