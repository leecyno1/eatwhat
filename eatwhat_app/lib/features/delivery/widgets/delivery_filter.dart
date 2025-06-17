import 'package:flutter/material.dart';
import '../../../core/models/restaurant.dart';
import '../../../core/services/delivery_recommendation_service.dart';

/// 外卖过滤器
class DeliveryFilter extends StatefulWidget {
  final DeliveryFilterOptions initialOptions;
  final Function(DeliveryFilterOptions) onFilterChanged;
  final bool showQuickFilters;
  
  const DeliveryFilter({
    super.key,
    required this.initialOptions,
    required this.onFilterChanged,
    this.showQuickFilters = true,
  });
  
  @override
  State<DeliveryFilter> createState() => _DeliveryFilterState();
}

class _DeliveryFilterState extends State<DeliveryFilter> {
  late DeliveryFilterOptions _options;
  
  @override
  void initState() {
    super.initState();
    _options = widget.initialOptions;
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showQuickFilters) _buildQuickFilters(),
        _buildAdvancedFilters(),
      ],
    );
  }
  
  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickFilterChip(
              '免配送费',
              _options.freeDelivery,
              (value) => _updateFilter(_options.copyWith(freeDelivery: value)),
              icon: Icons.delivery_dining,
            ),
            const SizedBox(width: 8),
            _buildQuickFilterChip(
              '快速配送',
              _options.fastDelivery,
              (value) => _updateFilter(_options.copyWith(fastDelivery: value)),
              icon: Icons.flash_on,
            ),
            const SizedBox(width: 8),
            _buildQuickFilterChip(
              '高评分',
              _options.highRating,
              (value) => _updateFilter(_options.copyWith(highRating: value)),
              icon: Icons.star,
            ),
            const SizedBox(width: 8),
            _buildQuickFilterChip(
              '新店',
              _options.newRestaurants,
              (value) => _updateFilter(_options.copyWith(newRestaurants: value)),
              icon: Icons.new_releases,
            ),
            const SizedBox(width: 8),
            _buildQuickFilterChip(
              '品牌店',
              _options.brandRestaurants,
              (value) => _updateFilter(_options.copyWith(brandRestaurants: value)),
              icon: Icons.verified,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickFilterChip(
    String label,
    bool isSelected,
    Function(bool) onChanged,
    {IconData? icon}
  ) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ..[
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: onChanged,
      selectedColor: Colors.orange,
      backgroundColor: Colors.grey[100],
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Colors.orange : Colors.grey[300]!,
        width: 1,
      ),
    );
  }
  
  Widget _buildAdvancedFilters() {
    return ExpansionTile(
      title: const Text(
        '更多筛选',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      leading: const Icon(Icons.tune),
      children: [
        _buildPriceRangeFilter(),
        _buildDistanceFilter(),
        _buildDeliveryTimeFilter(),
        _buildCuisineTypeFilter(),
        _buildSortOptions(),
        _buildResetButton(),
      ],
    );
  }
  
  Widget _buildPriceRangeFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '价格区间',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(
              _options.minPrice ?? 0,
              _options.maxPrice ?? 100,
            ),
            min: 0,
            max: 100,
            divisions: 20,
            labels: RangeLabels(
              '¥${(_options.minPrice ?? 0).round()}',
              '¥${(_options.maxPrice ?? 100).round()}',
            ),
            onChanged: (values) {
              _updateFilter(_options.copyWith(
                minPrice: values.start,
                maxPrice: values.end,
              ));
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildDistanceFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '配送距离',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _options.maxDistance ?? 5.0,
            min: 0.5,
            max: 10.0,
            divisions: 19,
            label: '${(_options.maxDistance ?? 5.0).toStringAsFixed(1)}km',
            onChanged: (value) {
              _updateFilter(_options.copyWith(maxDistance: value));
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeliveryTimeFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '配送时间',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [15, 30, 45, 60].map((minutes) {
              final isSelected = _options.maxDeliveryTime == minutes;
              return ChoiceChip(
                label: Text('${minutes}分钟内'),
                selected: isSelected,
                onSelected: (selected) {
                  _updateFilter(_options.copyWith(
                    maxDeliveryTime: selected ? minutes : null,
                  ));
                },
                selectedColor: Colors.orange,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCuisineTypeFilter() {
    final cuisineTypes = [
      '中餐', '西餐', '日料', '韩料', '泰餐',
      '快餐', '甜品', '饮品', '火锅', '烧烤',
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '菜系类型',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: cuisineTypes.map((cuisine) {
              final isSelected = _options.cuisineTypes?.contains(cuisine) ?? false;
              return FilterChip(
                label: Text(
                  cuisine,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  final currentTypes = _options.cuisineTypes ?? [];
                  final newTypes = List<String>.from(currentTypes);
                  
                  if (selected) {
                    newTypes.add(cuisine);
                  } else {
                    newTypes.remove(cuisine);
                  }
                  
                  _updateFilter(_options.copyWith(cuisineTypes: newTypes));
                },
                selectedColor: Colors.orange,
                backgroundColor: Colors.grey[100],
                checkmarkColor: Colors.white,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSortOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '排序方式',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SortType.values.map((sortType) {
              final isSelected = _options.sortType == sortType;
              return ChoiceChip(
                label: Text(sortType.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  _updateFilter(_options.copyWith(
                    sortType: selected ? sortType : SortType.recommended,
                  ));
                },
                selectedColor: Colors.orange,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResetButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            _updateFilter(const DeliveryFilterOptions());
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.orange),
            foregroundColor: Colors.orange,
          ),
          child: const Text('重置筛选'),
        ),
      ),
    );
  }
  
  void _updateFilter(DeliveryFilterOptions newOptions) {
    setState(() {
      _options = newOptions;
    });
    widget.onFilterChanged(newOptions);
  }
}

/// 筛选选项数据类
class DeliveryFilterOptions {
  final bool freeDelivery;
  final bool fastDelivery;
  final bool highRating;
  final bool newRestaurants;
  final bool brandRestaurants;
  final double? minPrice;
  final double? maxPrice;
  final double? maxDistance;
  final int? maxDeliveryTime;
  final List<String>? cuisineTypes;
  final SortType sortType;
  
  const DeliveryFilterOptions({
    this.freeDelivery = false,
    this.fastDelivery = false,
    this.highRating = false,
    this.newRestaurants = false,
    this.brandRestaurants = false,
    this.minPrice,
    this.maxPrice,
    this.maxDistance,
    this.maxDeliveryTime,
    this.cuisineTypes,
    this.sortType = SortType.recommended,
  });
  
  DeliveryFilterOptions copyWith({
    bool? freeDelivery,
    bool? fastDelivery,
    bool? highRating,
    bool? newRestaurants,
    bool? brandRestaurants,
    double? minPrice,
    double? maxPrice,
    double? maxDistance,
    int? maxDeliveryTime,
    List<String>? cuisineTypes,
    SortType? sortType,
  }) {
    return DeliveryFilterOptions(
      freeDelivery: freeDelivery ?? this.freeDelivery,
      fastDelivery: fastDelivery ?? this.fastDelivery,
      highRating: highRating ?? this.highRating,
      newRestaurants: newRestaurants ?? this.newRestaurants,
      brandRestaurants: brandRestaurants ?? this.brandRestaurants,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      maxDistance: maxDistance ?? this.maxDistance,
      maxDeliveryTime: maxDeliveryTime ?? this.maxDeliveryTime,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      sortType: sortType ?? this.sortType,
    );
  }
  
  bool get hasActiveFilters {
    return freeDelivery ||
        fastDelivery ||
        highRating ||
        newRestaurants ||
        brandRestaurants ||
        minPrice != null ||
        maxPrice != null ||
        maxDistance != null ||
        maxDeliveryTime != null ||
        (cuisineTypes?.isNotEmpty ?? false) ||
        sortType != SortType.recommended;
  }
  
  int get activeFilterCount {
    int count = 0;
    if (freeDelivery) count++;
    if (fastDelivery) count++;
    if (highRating) count++;
    if (newRestaurants) count++;
    if (brandRestaurants) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (maxDistance != null) count++;
    if (maxDeliveryTime != null) count++;
    if (cuisineTypes?.isNotEmpty ?? false) count++;
    if (sortType != SortType.recommended) count++;
    return count;
  }
}

/// 排序类型
enum SortType {
  recommended('推荐排序'),
  distance('距离最近'),
  rating('评分最高'),
  deliveryTime('配送最快'),
  price('价格最低'),
  sales('销量最高');
  
  const SortType(this.displayName);
  final String displayName;
}

/// 筛选按钮
class FilterButton extends StatelessWidget {
  final DeliveryFilterOptions options;
  final VoidCallback onTap;
  
  const FilterButton({
    super.key,
    required this.options,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = options.hasActiveFilters;
    final activeCount = options.activeFilterCount;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasActiveFilters ? Colors.orange : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasActiveFilters ? Colors.orange : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              size: 16,
              color: hasActiveFilters ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              hasActiveFilters ? '筛选($activeCount)' : '筛选',
              style: TextStyle(
                color: hasActiveFilters ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: hasActiveFilters ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}