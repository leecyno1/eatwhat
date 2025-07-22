import 'package:flutter/material.dart';

/// 搜索建议组件
class SearchSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final List<String> searchHistory;
  final Function(String) onSuggestionSelected;
  final Function(String) onHistorySelected;

  const SearchSuggestions({
    super.key,
    required this.suggestions,
    required this.searchHistory,
    required this.onSuggestionSelected,
    required this.onHistorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (searchHistory.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '最近搜索',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...searchHistory.take(5).map((query) => ListTile(
                    leading: const Icon(Icons.history, color: Colors.grey),
                    title: Text(query),
                    onTap: () => onHistorySelected(query),
                    trailing: const Icon(Icons.call_made, color: Colors.grey),
                  )),
            ],
            if (suggestions.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '推荐搜索',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...suggestions.map((suggestion) => ListTile(
                    leading: const Icon(Icons.search, color: Colors.grey),
                    title: Text(suggestion),
                    onTap: () => onSuggestionSelected(suggestion),
                    trailing: const Icon(Icons.call_made, color: Colors.grey),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
