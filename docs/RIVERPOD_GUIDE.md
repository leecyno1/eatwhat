# Riverpod 状态管理指南

本文档提供《吃什么》应用中 Riverpod 状态管理的完整指南。

## 目录

1. [快速开始](#快速开始)
2. [Provider 类型](#provider-类型)
3. [使用示例](#使用示例)
4. [最佳实践](#最佳实践)
5. [测试指南](#测试指南)

## 快速开始

### 安装依赖

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
```

### 包装应用

在 `main.dart` 中使用 `ProviderScope` 包装应用：

```dart
void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

## Provider 类型

### 1. Provider

用于提供不可变的值或服务实例。

```dart
// 服务 Provider
final foodServiceProvider = Provider<UnifiedFoodDataService>((ref) {
  return UnifiedFoodDataService();
});

// 计算 Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
```

### 2. StateProvider

用于简单的状态管理（如主题、语言等）。

```dart
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

// 使用
final themeMode = ref.watch(themeModeProvider);
ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
```

### 3. StateNotifierProvider

用于复杂的状态管理，支持业务逻辑。

```dart
// 定义状态
class AuthState {
  final String? userId;
  final bool isAuthenticated;
  
  const AuthState({this.userId, this.isAuthenticated = false});
  
  AuthState copyWith({String? userId, bool? isAuthenticated}) {
    return AuthState(
      userId: userId ?? this.userId,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// 定义 Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());
  
  Future<void> login(String username, String password) async {
    // 登录逻辑
    state = AuthState(userId: 'user_123', isAuthenticated: true);
  }
  
  Future<void> logout() async {
    state = const AuthState();
  }
}

// 创建 Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
```

### 4. FutureProvider

用于异步数据加载。

```dart
final recommendedFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final foodService = ref.watch(foodServiceProvider);
  return await foodService.getRecommendations([], UserPreference(userId: 'default'));
});
```

### 5. Provider.family

用于需要参数的 Provider。

```dart
final foodByIdProvider = FutureProvider.family<Food?, String>((ref, id) async {
  final foodState = ref.watch(foodProvider);
  return foodState.foods.firstWhere((food) => food.id == id);
});

// 使用
final food = ref.watch(foodByIdProvider('food_001'));
```

## 使用示例

### 在 Widget 中使用

#### ConsumerWidget

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return Text(
      authState.isAuthenticated ? '已登录' : '未登录',
    );
  }
}
```

#### Consumer

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authProvider);
        return Text(authState.isAuthenticated ? '已登录' : '未登录');
      },
    );
  }
}
```

#### HookConsumerWidget (with flutter_hooks)

```dart
class MyWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final authState = ref.watch(authProvider);
    
    return TextField(controller: controller);
  }
}
```

### 读取和修改状态

```dart
// 读取状态（会监听变化）
final authState = ref.watch(authProvider);

// 读取状态（不监听变化）
final authState = ref.read(authProvider);

// 调用方法
ref.read(authProvider.notifier).login('username', 'password');

// 修改 StateProvider
ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
```

## 最佳实践

### 1. 状态不可变性

始终使用 `copyWith` 创建新状态，而不是修改现有状态：

```dart
// ✅ 正确
state = state.copyWith(isLoading: true);

// ❌ 错误
state.isLoading = true;
```

### 2. Provider 命名规范

```dart
// 服务 Provider: xxxServiceProvider
final foodServiceProvider = Provider<FoodService>((ref) => FoodService());

// 状态 Provider: xxxProvider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);

// 计算 Provider: isXxx / hasXxx / xxxCount
final isAuthenticatedProvider = Provider<bool>((ref) => ...);
final cartTotalPriceProvider = Provider<double>((ref) => ...);
```

### 3. 避免过度使用 ref.read

在 `build` 方法中使用 `ref.watch`，在事件处理中使用 `ref.read`：

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ✅ 在 build 中使用 watch
  final authState = ref.watch(authProvider);
  
  return ElevatedButton(
    onPressed: () {
      // ✅ 在回调中使用 read
      ref.read(authProvider.notifier).logout();
    },
    child: Text('登出'),
  );
}
```

### 4. 使用 select 优化性能

只监听状态的特定部分：

```dart
// ❌ 整个状态变化都会重建
final authState = ref.watch(authProvider);

// ✅ 只有 isAuthenticated 变化才会重建
final isAuthenticated = ref.watch(authProvider.select((state) => state.isAuthenticated));
```

### 5. 依赖注入

Provider 之间可以相互依赖：

```dart
final foodProvider = StateNotifierProvider<FoodNotifier, FoodState>((ref) {
  // 注入依赖
  final foodService = ref.watch(foodServiceProvider);
  final authState = ref.watch(authProvider);
  
  return FoodNotifier(foodService, authState.userId);
});
```

## 测试指南

### 单元测试

```dart
void main() {
  test('应该能成功登录', () async {
    final container = ProviderContainer();
    
    // 执行操作
    await container.read(authProvider.notifier).login('user', 'pass');
    
    // 验证结果
    final authState = container.read(authProvider);
    expect(authState.isAuthenticated, true);
    
    // 清理
    container.dispose();
  });
}
```

### Widget 测试

```dart
void main() {
  testWidgets('应该显示登录状态', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MyWidget(),
        ),
      ),
    );
    
    expect(find.text('未登录'), findsOneWidget);
  });
}
```

### 覆盖 Provider

```dart
void main() {
  testWidgets('使用模拟数据测试', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 覆盖 Provider
          foodServiceProvider.overrideWithValue(MockFoodService()),
        ],
        child: MaterialApp(
          home: MyWidget(),
        ),
      ),
    );
  });
}
```

## 常见模式

### 1. 收藏功能

```dart
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier() : super(const FavoritesState());
  
  void toggleFavorite(String foodId) {
    if (state.foodIds.contains(foodId)) {
      state = state.copyWith(
        foodIds: state.foodIds.where((id) => id != foodId).toList(),
      );
    } else {
      state = state.copyWith(
        foodIds: [...state.foodIds, foodId],
      );
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  return FavoritesNotifier();
});

// 检查是否已收藏
final isFavoriteProvider = Provider.family<bool, String>((ref, foodId) {
  return ref.watch(favoritesProvider).foodIds.contains(foodId);
});
```

### 2. 购物车功能

```dart
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());
  
  void addItem(CartItem item) {
    final existingIndex = state.items.indexWhere((i) => i.foodId == item.foodId);
    
    if (existingIndex >= 0) {
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + item.quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(items: [...state.items, item]);
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

// 计算总价
final cartTotalPriceProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).totalPrice;
});
```

### 3. 搜索功能

```dart
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Food>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  
  final foodService = ref.watch(foodServiceProvider);
  return await foodService.search(query);
});
```

## 调试技巧

### 1. 使用 ProviderObserver

```dart
class MyObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('Provider ${provider.name ?? provider.runtimeType} updated');
    print('Previous: $previousValue');
    print('New: $newValue');
  }
}

void main() {
  runApp(
    ProviderScope(
      observers: [MyObserver()],
      child: MyApp(),
    ),
  );
}
```

### 2. 使用 Riverpod DevTools

安装 `flutter_riverpod` 后，可以在 DevTools 中查看 Provider 状态。

## 迁移指南

### 从 Provider 迁移到 Riverpod

```dart
// Provider (旧)
class MyNotifier extends ChangeNotifier {
  int _count = 0;
  int get count => _count;
  
  void increment() {
    _count++;
    notifyListeners();
  }
}

final myProvider = ChangeNotifierProvider((ref) => MyNotifier());

// Riverpod (新)
class MyState {
  final int count;
  const MyState({this.count = 0});
  
  MyState copyWith({int? count}) {
    return MyState(count: count ?? this.count);
  }
}

class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(const MyState());
  
  void increment() {
    state = state.copyWith(count: state.count + 1);
  }
}

final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});
```

## 参考资源

- [Riverpod 官方文档](https://riverpod.dev)
- [Flutter Riverpod 示例](https://github.com/rrousselGit/riverpod/tree/master/examples)
- [Riverpod 最佳实践](https://codewithandrea.com/articles/flutter-state-management-riverpod/)
