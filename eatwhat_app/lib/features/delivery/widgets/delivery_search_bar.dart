import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 外卖搜索栏组件
class DeliverySearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String? hintText;
  final bool showHistory;
  final int maxHistoryItems;
  
  const DeliverySearchBar({
    super.key,
    required this.onSearch,
    this.hintText,
    this.showHistory = true,
    this.maxHistoryItems = 10,
  });
  
  @override
  State<DeliverySearchBar> createState() => _DeliverySearchBarState();
}

class _DeliverySearchBarState extends State<DeliverySearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<String> _searchHistory = [];
  List<String> _hotSearches = [
    '麻辣烫',
    '奶茶',
    '汉堡',
    '火锅',
    '烧烤',
    '寿司',
    '披萨',
    '炸鸡',
  ];
  
  bool _showSuggestions = false;
  
  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _focusNode.addListener(_onFocusChanged);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus;
    });
  }
  
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('delivery_search_history');
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        setState(() {
          _searchHistory = historyList.cast<String>();
        });
      }
    } catch (e) {
      print('加载搜索历史失败: $e');
    }
  }
  
  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(_searchHistory);
      await prefs.setString('delivery_search_history', historyJson);
    } catch (e) {
      print('保存搜索历史失败: $e');
    }
  }
  
  void _addToHistory(String keyword) {
    if (keyword.trim().isEmpty) return;
    
    setState(() {
      // 移除已存在的相同关键词
      _searchHistory.remove(keyword);
      // 添加到开头
      _searchHistory.insert(0, keyword);
      // 限制历史记录数量
      if (_searchHistory.length > widget.maxHistoryItems) {
        _searchHistory = _searchHistory.take(widget.maxHistoryItems).toList();
      }
    });
    
    _saveSearchHistory();
  }
  
  void _clearHistory() {
    setState(() {
      _searchHistory.clear();
    });
    _saveSearchHistory();
  }
  
  void _removeFromHistory(String keyword) {
    setState(() {
      _searchHistory.remove(keyword);
    });
    _saveSearchHistory();
  }
  
  void _performSearch(String keyword) {
    if (keyword.trim().isEmpty) return;
    
    _addToHistory(keyword);
    widget.onSearch(keyword);
    _focusNode.unfocus();
  }
  
  void _onSearchTap(String keyword) {
    _controller.text = keyword;
    _performSearch(keyword);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索输入框
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _focusNode.hasFocus ? Colors.orange : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(
                Icons.search,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? '搜索美食、餐厅',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _performSearch,
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.clear,
                    color: Colors.grey,
                    size: 18,
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        
        // 搜索建议
        if (_showSuggestions && widget.showHistory)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 搜索历史
                if (_searchHistory.isNotEmpty) ..[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '搜索历史',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _clearHistory,
                          child: const Text(
                            '清空',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    children: _searchHistory.map((keyword) {
                      return Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                        child: GestureDetector(
                          onTap: () => _onSearchTap(keyword),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  keyword,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _removeFromHistory(keyword),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                
                // 热门搜索
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '热门搜索',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  children: _hotSearches.map((keyword) {
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 8, 16),
                      child: GestureDetector(
                        onTap: () => _onSearchTap(keyword),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange[200]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            keyword,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 搜索建议项组件
class SearchSuggestionItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  
  const SearchSuggestionItem({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.onRemove,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: Colors.grey[600],
      ),
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
        ),
      ),
      trailing: onRemove != null
          ? IconButton(
              onPressed: onRemove,
              icon: const Icon(
                Icons.close,
                size: 18,
                color: Colors.grey,
              ),
            )
          : null,
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}