import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:eatwhat_app/core/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:eatwhat_app/core/models/physical_entity.dart';
import 'package:eatwhat_app/features/bubble/controllers/physical_entity_controller.dart';
import 'package:eatwhat_app/features/style_preview/style_preview_screen.dart';

// 简易假实现，避免在golden测试中触发插件/物理引擎等副作用
class FakePhysicalEntityController extends PhysicalEntityController {
  // 基础状态
  bool _isLoading = false;
  final List<PhysicalEntity> _entities = [
    PhysicalEntity(
      id: 'e1',
      name: '甜',
      description: 'Sweet',
      type: PhysicalEntityType.taste,
      emoji: '🍬',
      primaryColor: Colors.pink.shade200,
      secondaryColor: Colors.pink.shade100,
      position: const Offset(80, 100),
    ),
    PhysicalEntity(
      id: 'e2',
      name: '辣',
      description: 'Spicy',
      type: PhysicalEntityType.taste,
      emoji: '🌶️',
      primaryColor: Colors.red.shade200,
      secondaryColor: Colors.red.shade100,
      position: const Offset(180, 200),
    ),
    PhysicalEntity(
      id: 'e3',
      name: '鲜',
      description: 'Umami',
      type: PhysicalEntityType.taste,
      emoji: '🍲',
      primaryColor: Colors.blue.shade200,
      secondaryColor: Colors.blue.shade100,
      position: const Offset(140, 300),
    ),
  ];

  final List<PhysicalEntity> _liked = [];
  final List<PhysicalEntity> _disliked = [];
  Size? _containerSize;

  // Exposed getters used by the screen
  @override
  bool get isLoading => _isLoading;
  @override
  List<PhysicalEntity> get entities => _entities;
  @override
  List<PhysicalEntity> get likedEntities => _liked;
  @override
  List<PhysicalEntity> get dislikedEntities => _disliked;
  @override
  int get selectedCount => _entities.where((e) => e.isSelected == true).toList().length;

  // No-op methods for golden
  @override
  Future<void> initializeEntities([BuildContext? context]) async {
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // 避免触发真实控制器的资源释放逻辑（依赖外部服务/插件）
  }

  @override
  Future<void> initialize({Size? containerSize}) async {}

  @override
  void updateContainerSize(Size size) {
    _containerSize = size;
  }

  @override
  void resetEntities() {
    for (var i = 0; i < _entities.length; i++) {
      _entities[i] =
          _entities[i].copyWith(isSelected: false, position: Offset(80 + i * 60, 120 + i * 80));
    }
    notifyListeners();
  }

  @override
  Future<void> generateRecommendations() async {}

  @override
  void toggleEntitySelection(String id) {
    final idx = _entities.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _entities[idx] = _entities[idx].copyWith(isSelected: !_entities[idx].isSelected);
      notifyListeners();
    }
  }

  @override
  void pausePhysics() {}
  @override
  void restartPhysics() {}
  @override
  void updateEntityPosition(String id, Offset position) {
    final idx = _entities.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _entities[idx] = _entities[idx].copyWith(position: position);
      notifyListeners();
    }
  }

  @override
  void applyVelocityToEntity(String id, Offset velocity) {}

  @override
  void favoriteEntity(String id) {}
  @override
  void skipEntity(String id) {}
  @override
  void likeEntity(String id) {
    final e = _entities.firstWhere((x) => x.id == id);
    if (!_liked.any((x) => x.id == id)) _liked.add(e);
    _disliked.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  @override
  void dislikeEntity(String id) {
    final e = _entities.firstWhere((x) => x.id == id);
    if (!_disliked.any((x) => x.id == id)) _disliked.add(e);
    _liked.removeWhere((x) => x.id == id);
    notifyListeners();
  }
}

void main() {
  testWidgets('StylePreviewScreen golden', (tester) async {
    // Fixed logical size for deterministic golden
    const size = Size(375, 812); // iPhone X-ish
    tester.binding.window.physicalSizeTestValue = const Size(375 * 3, 812 * 3);
    tester.binding.window.devicePixelRatioTestValue = 3.0;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) => ChangeNotifierProvider<PhysicalEntityController>(
          create: (_) => FakePhysicalEntityController(),
          child: MaterialApp(
            theme: AppTheme.roundedPastel,
            home: const StylePreviewScreen(),
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );

    // 使用有限时长的 pump，避免因动画/定时器导致的无限等待
    await tester.pump(const Duration(milliseconds: 500));

    await expectLater(
      find.byType(StylePreviewScreen),
      matchesGoldenFile('goldens/style_preview.png'),
    );

    // cleanup
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });
  });
}
