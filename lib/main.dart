import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/bubble/controllers/bubble_controller.dart';
import 'features/bubble/screens/magic_bubble_screen.dart';
import 'features/recommendation/controllers/recommendation_controller.dart';
import 'features/recommendation/screens/recommendation_screen.dart';
import 'features/recommendation/screens/food_detail_screen.dart';

void main() {
  runApp(const EatWhatApp());
}

class EatWhatApp extends StatelessWidget {
  const EatWhatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BubbleController()),
        ChangeNotifierProvider(create: (context) => RecommendationController()),
      ],
      child: MaterialApp(
        title: '吃什么',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const MagicBubbleScreen(),
        routes: {
          '/recommendation': (context) => const RecommendationScreen(),
        },
      ),
    );
  }
}

class TestBubbleScreen extends StatefulWidget {
  const TestBubbleScreen({super.key});

  @override
  State<TestBubbleScreen> createState() => _TestBubbleScreenState();
}

class _TestBubbleScreenState extends State<TestBubbleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<BubbleController>();
      controller.initializeBubbles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('吃什么 - 气泡测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<BubbleController>(
        builder: (context, controller, child) {
          if (!controller.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // 选中的气泡显示区域
              Container(
                height: 100,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '已选择的气泡 (${controller.selectedBubbles.length}):',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: controller.selectedBubbles.isEmpty
                          ? const Text('点击下方气泡来选择你的偏好')
                          : Wrap(
                              spacing: 8,
                              children: controller.selectedBubbles
                                  .map((bubble) => Chip(
                                        label: Text(bubble.text),
                                        backgroundColor: Colors.blue.shade100,
                                        deleteIcon: const Icon(Icons.close, size: 16),
                                        onDeleted: () {
                                          controller.toggleBubble(bubble);
                                        },
                                      ))
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // 气泡网格显示区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: controller.bubbles.length,
                    itemBuilder: (context, index) {
                      final bubble = controller.bubbles[index];
                      return GestureDetector(
                        onTap: () {
                          controller.toggleBubble(bubble);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: bubble.isSelected 
                                ? Colors.blue.shade400
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: bubble.isSelected 
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                            boxShadow: bubble.isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  bubble.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  bubble.text,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: bubble.isSelected 
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // 底部按钮区域
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: controller.selectedBubbles.isEmpty
                            ? null
                            : () {
                                // 生成推荐
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '基于${controller.selectedBubbles.length}个偏好生成推荐中...',
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '生成推荐',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        controller.clearSelection();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('重置'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 